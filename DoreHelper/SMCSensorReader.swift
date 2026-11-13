import Foundation
import IOKit

/// Read-only AppleSMC transport. No write-key command is implemented.
/// The 80-byte driver ABI uses native-endian fields and a 32-byte payload.
final class SMCSensorReader {
    private var connection: io_connect_t = 0
    private var keys: [String]?
    private var metadata: [String: (UInt32, UInt32)] = [:]
    private(set) var diagnostic = "尚未读取"

    deinit {
        if connection != 0 { IOServiceClose(connection) }
    }

    func read() -> Double? {
        let values = readAll().filter { Self.isCPUKey($0.key) }.map(\.value)
        return values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
    }

    static func isCPUKey(_ key: String) -> Bool {
        #if arch(arm64)
        return key.hasPrefix("Tp") || key.hasPrefix("Te")
        #else
        return ["TC0D", "TC0F", "TC0P"].contains(key)
        #endif
    }

    func readAll() -> [String: Double] {
        if connection == 0 {
            let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
            guard service != 0 else { diagnostic = "设备未提供 AppleSMC"; return [:] }
            defer { IOObjectRelease(service) }
            let result = IOServiceOpen(service, mach_task_self_, 0, &connection)
            guard result == KERN_SUCCESS else {
                diagnostic = "温度传感器访问被拒绝（\(result)）"
                return [:]
            }
        }
        if keys == nil { keys = discoverTemperatureKeys() }
        var readings: [String: Double] = [:]
        for key in keys ?? [] {
            if let value = temperature(key) { readings[key] = value }
        }
        diagnostic = readings.isEmpty ? "未发现可读取的温度传感器" : "已读取 \(readings.count) 个温度传感器"
        return readings
    }

    private func discoverTemperatureKeys() -> [String]? {
        guard let payload = payload("#KEY") else { return nil }
        let count = payload.prefix(4).reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
        guard count > 0, count < 20_000 else { return nil }
        return (0..<count).compactMap { index in
            guard let response = call(command: 8, index: index) else { return nil }
            let code = uint32(response, at: 0)
            let key = String(bytes: [UInt8((code >> 24) & 255), UInt8((code >> 16) & 255), UInt8((code >> 8) & 255), UInt8(code & 255)], encoding: .ascii) ?? ""
            guard key.hasPrefix("T"), payloadForDiscovery(key) else { return nil }
            return key
        }.sorted()
    }

    private func payloadForDiscovery(_ key: String) -> Bool {
        // Cache metadata even when a sensor is temporarily unavailable. Subsequent
        // samples retry it instead of permanently excluding sleeping hardware.
        _ = payload(key)
        guard let (size, type) = metadata[key] else { return false }
        return (type == fourCC("flt ") && size == 4) || (type == fourCC("sp78") && size == 2)
    }

    /// PSTR is the system total rail reading, not CPU-only power or charger rating.
    func readSystemPower() -> Double? {
        guard let value = number("PSTR") else { return nil }
        return value.isFinite && value >= 0 && value < 2000 ? value : nil
    }

    func readFans() -> [String: Double] {
        guard let count = number("FNum"), count >= 0, count <= 16,
              count.rounded() == count else { return [:] }
        var values = ["FNum": count]
        for index in 0..<Int(count) {
            for suffix in ["Ac", "Mn", "Mx"] {
                let key = "F\(String(index, radix: 16).uppercased())\(suffix)"
                if let rpm = number(key), rpm.isFinite, rpm >= 0, rpm < 30_000 {
                    values[key] = rpm
                }
            }
        }
        return values
    }

    private func number(_ key: String) -> Double? {
        guard connection != 0, let bytes = payload(key),
              let (size, type) = metadata[key] else { return nil }
        let value: Double
        if type == fourCC("flt "), size == 4 {
            value = Double(Float(bitPattern: uint32(bytes, at: 0)))
        } else if type == fourCC("ui8 "), size == 1 {
            value = Double(bytes[0])
        } else if type == fourCC("ui16"), size == 2 {
            value = Double(UInt16(bytes[0]) << 8 | UInt16(bytes[1]))
        } else if size == 2 {
            let format = [UInt8((type >> 24) & 255), UInt8((type >> 16) & 255), UInt8((type >> 8) & 255), UInt8(type & 255)]
            guard [102, 115].contains(format[0]), format[1] == 112,
                  let fractionalBits = Int(String(UnicodeScalar(format[3])), radix: 16), fractionalBits <= 15 else { return nil }
            let raw = UInt16(bytes[0]) << 8 | UInt16(bytes[1])
            value = (format[0] == 115 ? Double(Int16(bitPattern: raw)) : Double(raw)) / pow(2, Double(fractionalBits))
        } else { return nil }
        return value.isFinite ? value : nil
    }

    private func temperature(_ key: String) -> Double? {
        guard let bytes = payload(key), let (size, type) = metadata[key] else { return nil }
        let value: Double
        if type == fourCC("flt "), size == 4 {
            value = Double(Float(bitPattern: uint32(bytes, at: 0)))
        } else if type == fourCC("sp78"), size == 2 {
            value = Double(Int16(bitPattern: UInt16(bytes[0]) << 8 | UInt16(bytes[1]))) / 256
        } else { return nil }
        return value.isFinite && value > 0 && value < 130 ? value : nil
    }

    private func payload(_ key: String) -> [UInt8]? {
        if metadata[key] == nil {
            guard let info = call(command: 9, key: fourCC(key)) else { return nil }
            let size = uint32(info, at: 28)
            guard size > 0, size <= 32 else { return nil }
            metadata[key] = (size, uint32(info, at: 32))
        }
        guard let (size, _) = metadata[key], let output = call(command: 5, key: fourCC(key), size: size) else { return nil }
        return Array(output[48..<(48 + Int(size))])
    }

    private func call(command: UInt8, key: UInt32 = 0, size: UInt32 = 0, index: UInt32 = 0) -> [UInt8]? {
        var input = [UInt8](repeating: 0, count: 80)
        func store(_ value: UInt32, at offset: Int) {
            withUnsafeBytes(of: value) { input.replaceSubrange(offset..<(offset + 4), with: $0) }
        }
        store(key, at: 0)
        store(size, at: 28)
        store(index, at: 44)
        input[42] = command
        var output = [UInt8](repeating: 0, count: 80)
        var outputSize = 80
        let result = input.withUnsafeBytes { source in
            output.withUnsafeMutableBytes { destination in
                IOConnectCallStructMethod(connection, 2, source.baseAddress, 80, destination.baseAddress, &outputSize)
            }
        }
        guard result == KERN_SUCCESS, outputSize == 80, output[40] == 0 else { return nil }
        return output
    }

    private func fourCC(_ text: String) -> UInt32 {
        text.utf8.reduce(0) { ($0 << 8) | UInt32($1) }
    }

    private func uint32(_ bytes: [UInt8], at offset: Int) -> UInt32 {
        bytes.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: offset, as: UInt32.self) }
    }
}
