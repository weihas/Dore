import Foundation

enum TemperatureGroup: String, CaseIterable, Identifiable {
    case cpu = "CPU", gpu = "GPU", memory = "内存", storage = "存储", airflow = "气流", other = "其他传感器"
    var id: String { rawValue }
    var title: String {
        switch self {
        case .cpu: String(localized: "CPU")
        case .gpu: String(localized: "GPU")
        case .memory: String(localized: "Memory")
        case .storage: String(localized: "Storage")
        case .airflow: String(localized: "Airflow")
        case .other: String(localized: "Other Sensors")
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
        if id.hasPrefix("Tp") { return String(localized: "CPU temperature sensor") }
        if id.hasPrefix("Te") { return String(localized: "CPU temperature sensor") }
        if id.hasPrefix("Tg") { return String(localized: "GPU sensor") }
        #endif
        if group == .memory { return String(localized: "Memory temperature sensor") }
        if group == .storage { return String(localized: "Storage temperature sensor") }
        let names = ["TaFL": String(localized: "Front left airflow"), "TaFR": String(localized: "Front right airflow"), "TaRL": String(localized: "Rear left airflow"), "TaRR": String(localized: "Rear right airflow")]
        return names[id] ?? String(localized: "Unidentified temperature channel")
    }
}
