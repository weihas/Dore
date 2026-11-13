import Foundation

struct FanReading: Identifiable {
    let id: Int
    let rpm: Double?
    let minimum: Double?
    let maximum: Double?
    var name: String { "风扇 \(id + 1)" }
}

struct HardwareMetrics {
    let systemPower: Double?
    let cpuPower: Double?
    let gpuPower: Double?
    let gpuUtilization: Double?
    let fanCount: Int?
    let fans: [FanReading]

    init(values: [String: Double]) {
        func valid(_ key: String, below upper: Double) -> Double? {
            guard let value = values[key], value.isFinite, value >= 0, value < upper else { return nil }
            return value
        }
        systemPower = valid("PSTR", below: 2000)
        cpuPower = valid("CPU Power", below: 2000)
        gpuPower = valid("GPU Power", below: 2000)
        gpuUtilization = valid("GPU Utilization", below: 101).flatMap { $0 <= 100 ? $0 : nil }
        let count = valid("FNum", below: 17).flatMap { $0.rounded() == $0 ? Int($0) : nil }
        fanCount = count
        fans = (0..<(count ?? 0)).map { index in
            let prefix = "F\(String(index, radix: 16).uppercased())"
            return FanReading(id: index, rpm: valid(prefix + "Ac", below: 30_000),
                              minimum: valid(prefix + "Mn", below: 30_000),
                              maximum: valid(prefix + "Mx", below: 30_000))
        }
    }
}
