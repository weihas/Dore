import Foundation
import Darwin
import IOKit

/// Read-only IOReport energy sampling. Symbols are optional because IOReport is
/// a private system API. A missing channel remains unavailable, never zero-filled.
final class EnergyReader {
    private typealias CopyChannels = @convention(c) (CFString?, CFString?, UInt64, UInt64, UInt64) -> Unmanaged<CFDictionary>?
    private typealias Subscribe = @convention(c) (UnsafeMutableRawPointer?, CFMutableDictionary?, UnsafeMutablePointer<Unmanaged<CFMutableDictionary>?>?, UInt64, CFTypeRef?) -> Unmanaged<CFTypeRef>?
    private typealias Sample = @convention(c) (CFTypeRef?, CFMutableDictionary?, CFTypeRef?) -> Unmanaged<CFDictionary>?
    private typealias Label = @convention(c) (CFDictionary?) -> Unmanaged<CFString>?
    private typealias Integer = @convention(c) (CFDictionary?, Int32) -> Int64
    private typealias Identifier = @convention(c) (CFDictionary?) -> UInt64

    private let library: UnsafeMutableRawPointer?
    private var subscription: CFTypeRef?
    private var channels: CFMutableDictionary?
    private var sample: Sample?
    private var name: Label?
    private var unit: Label?
    private var integer: Integer?
    private var channelID: Identifier?
    private var driverID: Identifier?
    private var previous: (time: TimeInterval, energy: [String: Double])?

    init() {
        library = dlopen("/usr/lib/libIOReport.dylib", RTLD_LAZY | RTLD_LOCAL)
        guard let library else { return }
        func symbol<T>(_ name: String, _ type: T.Type) -> T? {
            guard let pointer = dlsym(library, name) else { return nil }
            return unsafeBitCast(pointer, to: type)
        }
        guard let copy = symbol("IOReportCopyChannelsInGroup", CopyChannels.self),
              let subscribe = symbol("IOReportCreateSubscription", Subscribe.self) else { return }
        sample = symbol("IOReportCreateSamples", Sample.self)
        name = symbol("IOReportChannelGetChannelName", Label.self)
        unit = symbol("IOReportChannelGetUnitLabel", Label.self)
        integer = symbol("IOReportSimpleGetIntegerValue", Integer.self)
        channelID = symbol("IOReportChannelGetChannelID", Identifier.self)
        driverID = symbol("IOReportChannelGetDriverID", Identifier.self)
        guard let available = copy("Energy Model" as CFString, nil, 0, 0, 0)?.takeRetainedValue(),
              let desired = CFDictionaryCreateMutableCopy(nil, 0, available) else { return }
        if ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 27 {
            let list = ((desired as NSDictionary)["IOReportChannels"] as? [NSDictionary] ?? []).filter {
                // The legacy CPU counter stalls on macOS 27. Do not report its
                // unchanged value as zero watts when a CLPC mapping is absent.
                !(name?($0 as CFDictionary)?.takeUnretainedValue() as String? ?? "").hasSuffix("CPU Energy")
            } + Self.clpcCPUChannels()
            let key = "IOReportChannels" as CFString
            let array = list as CFArray
            CFDictionarySetValue(desired, Unmanaged.passUnretained(key).toOpaque(), Unmanaged.passUnretained(array).toOpaque())
        }
        var subscribed: Unmanaged<CFMutableDictionary>?
        subscription = subscribe(nil, desired, &subscribed, 0, nil)?.takeRetainedValue()
        channels = subscribed?.takeRetainedValue()
    }

    /// Known macOS 27 CPU report IDs documented by macmon's firmware analysis:
    /// https://github.com/vladkens/macmon/blob/main/src/clpc.rs
    /// Select by driver identity, never by a guessed marketing model or rail key.
    private static func clpcCPUChannels() -> [NSDictionary] {
        let keys: [String: UInt64] = [
            "AppleT6000CLPCv3": 0x47479059, "AppleT6002CLPC": 0xb501816b,
            "AppleT6020CLPC": 0xe301cd75, "AppleT6022CLPC": 0x76f5fd21,
            "AppleT6030CLPC": 0xbe03a01a, "AppleT6031CLPC": 0xd81e0084,
            "AppleT6032CLPC": 0xf4a21308, "AppleT6041CLPC": 0x263cf1f0,
            "AppleT6050CLPC": 0xd3ab60bb, "AppleT6050dCLPC": 0x18b3010e,
            "AppleT8103CLPCv3": 0x2cdd31f2, "AppleT8112CLPC": 0xb5435137,
            "AppleT8122CLPC": 0x54b51c99, "AppleT8132CLPC": 0x4a854d94,
            "AppleT8140CLPC": 0x9bf54436, "AppleT8142CLPC": 0x43708744,
            "AppleT8152CLPC": 0x485d4bfc
        ]
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("AppleCLPC"), &iterator) == KERN_SUCCESS else { return [] }
        defer { IOObjectRelease(iterator) }
        var result: [NSDictionary] = []
        while case let service = IOIteratorNext(iterator), service != 0 {
            defer { IOObjectRelease(service) }
            guard let bundle = IORegistryEntryCreateCFProperty(service, "CFBundleIdentifier" as CFString, nil, 0)?.takeRetainedValue() as? String,
                  bundle.hasPrefix("com.apple.driver."),
                  let lowID = keys[String(bundle.dropFirst("com.apple.driver.".count))] else { continue }
            var driverID: UInt64 = 0
            guard IORegistryEntryGetRegistryEntryID(service, &driverID) == KERN_SUCCESS else { continue }
            let reportID = (UInt64(16) << 32) | lowID
            let format = UInt64(1) | (2 << 16) | (1 << 32)
            let nanojoules = (UInt64(3) << 56) | (118 << 32)
            result.append(NSMutableDictionary(dictionary: [
                "DriverID": NSNumber(value: driverID), "DriverName": "AppleCLPC",
                "IOReportGroupName": "CLPC", "IOReportSubGroupName": "Energy Counters",
                "IOReportChannelInfo": ["IOReportChannelUnit": NSNumber(value: nanojoules)],
                "LegendChannel": [NSNumber(value: reportID), NSNumber(value: format), "CPU Energy"]
            ]))
        }
        return result
    }

    deinit {
        subscription = nil
        channels = nil
        if let library { dlclose(library) }
    }

    func read() -> [String: Double] {
        guard let subscription, let channels, let sample, let name, let unit, let integer, let channelID, let driverID,
              let snapshot = sample(subscription, channels, nil)?.takeRetainedValue(),
              let entries = (snapshot as NSDictionary)["IOReportChannels"] as? [NSDictionary] else {
            previous = nil
            return [:]
        }
        let now = ProcessInfo.processInfo.systemUptime
        var energy: [String: Double] = [:]
        var groups: [String: String] = [:]
        for entry in entries {
            let channel = entry as CFDictionary
            guard let label = name(channel)?.takeUnretainedValue() as String?,
                  let units = unit(channel)?.takeUnretainedValue() as String? else { continue }
            let group: String
            if label.hasSuffix("CPU Energy") { group = "CPU Power" }
            else if label.hasSuffix("GPU Energy") { group = "GPU Power" }
            else { continue }
            let scale: Double
            switch units {
            case "J": scale = 1
            case "mJ": scale = 1e-3
            case "uJ", "µJ", "μJ": scale = 1e-6
            case "nJ": scale = 1e-9
            default: continue
            }
            let counter = integer(channel, 0)
            guard counter >= 0 else { continue }
            let identity = "\(driverID(channel)):\(channelID(channel))"
            energy[identity] = Double(counter) * scale
            groups[identity] = group
        }
        defer { previous = (now, energy) }
        guard let previous else { return [:] }
        let elapsed = now - previous.time
        // Re-prime after sleep, a long pause, or a counter reset.
        guard elapsed >= 0.1, elapsed <= 15 else { return [:] }
        var result: [String: Double] = [:]
        for group in ["CPU Power", "GPU Power"] {
            let labels = groups.filter { $0.value == group }.map(\.key)
            guard !labels.isEmpty else { continue }
            // Don't mix a changed set of devices into an earlier baseline.
            guard labels.allSatisfy({ previous.energy[$0] != nil }) else { continue }
            var watts = 0.0
            var valid = true
            for label in labels {
                guard let current = energy[label], let old = previous.energy[label], current >= old else {
                    valid = false
                    break
                }
                watts += (current - old) / elapsed
            }
            if valid, watts.isFinite, watts >= 0, watts < 2000 { result[group] = watts }
        }
        return result
    }
}
