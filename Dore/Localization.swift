import Foundation

/// The XPC service returns stable codes so its process language cannot leak into the UI.
nonisolated func localizedSensorDiagnostic(_ diagnostic: String) -> String {
    let fields = diagnostic.split(separator: ":", maxSplits: 1).map(String.init)
    switch fields.first {
    case "smc.pending": return String(localized: "Not read yet")
    case "smc.unavailable": return String(localized: "AppleSMC is not available on this Mac")
    case "smc.empty": return String(localized: "No readable temperature sensors found")
    case "smc.denied": return String(format: String(localized: "Temperature sensor access denied (%@)"), locale: .current, fields.count > 1 ? fields[1] : "—")
    case "smc.read": return String(format: String(localized: "Temperature sensors read: %@"), locale: .current, fields.count > 1 ? fields[1] : "—")
    default: return diagnostic
    }
}
