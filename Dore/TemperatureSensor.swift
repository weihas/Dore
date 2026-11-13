import Foundation

enum TemperatureGroup: String, CaseIterable, Identifiable {
    case cpu = "CPU", gpu = "GPU", memory = "内存", storage = "存储", airflow = "气流", other = "其他传感器"
    var id: String { rawValue }
}

struct TemperatureSensor: Identifiable, Sendable {
    let id: String
    let value: Double
    var peak: Double = 0

    var group: TemperatureGroup {
        #if arch(arm64)
        if id.hasPrefix("Tp") || id.hasPrefix("Te") { return .cpu }
        if id.hasPrefix("Tg") { return .gpu }
        #else
        if id.hasPrefix("TC") { return .cpu }
        if id.hasPrefix("TG") { return .gpu }
        #endif
        if id.hasPrefix("Tm"), id != "Tm0P" { return .memory }
        if ["TH0a", "TH0b", "TH0x"].contains(id) { return .storage }
        if ["TaFL", "TaFR", "TaRL", "TaRR"].contains(id) { return .airflow }
        return .other
    }

    var name: String {
        #if arch(arm64)
        if id.hasPrefix("Tp") { return "CPU 温度传感器" }
        if id.hasPrefix("Te") { return "CPU 温度传感器" }
        if id.hasPrefix("Tg") { return "GPU 传感器" }
        #endif
        if group == .memory { return "内存温度传感器" }
        if group == .storage { return "存储温度传感器" }
        let names = ["TaFL": "前侧左气流", "TaFR": "前侧右气流", "TaRL": "后侧左气流", "TaRR": "后侧右气流"]
        return names[id] ?? "未识别温度通道"
    }
}
