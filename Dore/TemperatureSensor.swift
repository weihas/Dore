import Foundation

enum TemperatureGroup: String, CaseIterable, Identifiable {
    case cpu = "CPU", gpu = "GPU", memory = "内存", storage = "存储", airflow = "气流", other = "其他传感器"
    var id: String { rawValue }
    var title: String {
        switch self {
        case .cpu: L("CPU")
        case .gpu: L("GPU")
        case .memory: L("Memory")
        case .storage: L("Storage")
        case .airflow: L("Airflow")
        case .other: L("Other Sensors")
        }
    }
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
        if id.hasPrefix("Tp") { return L("CPU temperature sensor") }
        if id.hasPrefix("Te") { return L("CPU temperature sensor") }
        if id.hasPrefix("Tg") { return L("GPU sensor") }
        #endif
        if group == .memory { return L("Memory temperature sensor") }
        if group == .storage { return L("Storage temperature sensor") }
        let names = ["TaFL": L("Front left airflow"), "TaFR": L("Front right airflow"), "TaRL": L("Rear left airflow"), "TaRR": L("Rear right airflow")]
        return names[id] ?? L("Unidentified temperature channel")
    }
}
