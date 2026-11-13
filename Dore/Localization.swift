import Foundation

/// Resolve text at the presentation boundary; persisted settings and sensor IDs stay unchanged.
nonisolated func L(_ key: String, _ arguments: CVarArg...) -> String {
    let format = Bundle.main.localizedString(forKey: key, value: key, table: "Localizable")
    guard !arguments.isEmpty else { return format }
    return String(format: format, locale: Locale.current, arguments: arguments)
}

/// The XPC service returns stable codes so its process language cannot leak into the UI.
nonisolated func localizedSensorDiagnostic(_ diagnostic: String) -> String {
    let fields = diagnostic.split(separator: ":", maxSplits: 1).map(String.init)
    switch fields.first {
    case "smc.pending": return L("Not read yet")
    case "smc.unavailable": return L("AppleSMC is not available on this Mac")
    case "smc.empty": return L("No readable temperature sensors found")
    case "smc.denied": return L("Temperature sensor access denied (%@)", fields.count > 1 ? fields[1] : "—")
    case "smc.read": return L("Temperature sensors read: %@", fields.count > 1 ? fields[1] : "—")
    default: return diagnostic
    }
}
