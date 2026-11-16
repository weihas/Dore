import SwiftUI

struct PowerSummaryView: View {
    let monitor: SystemMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            DorePageHeading(title: String(localized: "Power"), subtitle: String(localized: "System power consumption and power source"))
            HStack(alignment: .center, spacing: 30) {
                VStack(alignment: .leading, spacing: 14) {
                    Label("System Power", systemImage: "bolt.fill").font(.system(size: 12, weight: .medium)).foregroundStyle(DoreStyle.accent)
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(monitor.systemPower.map { String(format: "%.1f", locale: .current, $0) } ?? "—")
                            .font(.system(size: 42, weight: .regular)).monospacedDigit()
                        Text("W").font(.title2).foregroundStyle(.secondary)
                    }
                    Text(monitor.paused ? String(localized: "Paused — showing last reading") : monitor.systemPower == nil ? String(localized: "Waiting for power readings") : String(localized: "Power during the sampling interval"))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 18) {
                    Label(monitor.onAC ? String(localized: "AC Power") : String(localized: "Battery Power"), systemImage: monitor.onAC ? "powerplug" : "battery.100")
                        .font(.subheadline)
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("Session Peak").font(.caption).foregroundStyle(.secondary)
                        Text(monitor.systemPower == nil ? "—" : String(format: "%.1f W", locale: .current, monitor.powerPeak))
                            .font(.system(size: 22, weight: .medium)).monospacedDigit()
                    }
                }
            }.dashboardSurface()
            DoreSectionHeading(title: String(localized: "Component Power"), detail: String(localized: "Sampling interval averages"))
            HStack(spacing: 16) {
                component(String(localized: "Processor"), symbol: "cpu", watts: monitor.hardware.cpuPower)
                component(String(localized: "Graphics"), symbol: "square.3.layers.3d", watts: monitor.hardware.gpuPower)
            }
            Text("Component readings do not include all system power. System readings differ from wall power or the charger's rated output.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func component(_ title: String, symbol: String, watts: Double?) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Label(title, systemImage: symbol).font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
            Text(watts.map { String(format: "%.2f W", locale: .current, $0) } ?? String(localized: "Unavailable"))
                .font(.system(size: 26, weight: .medium)).monospacedDigit()
        }.dashboardSurface()
    }
}

#Preview("电源设计") {
    let monitor = SystemMonitor()
    PowerSummaryView(monitor: monitor).padding(28).frame(width: 760).background(DoreBackdrop())
}
