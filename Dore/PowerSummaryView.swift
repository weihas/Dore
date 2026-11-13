import SwiftUI

struct PowerSummaryView: View {
    let monitor: SystemMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            DorePageHeading(title: L("Power"), subtitle: L("System power consumption and power source"))
            HStack(alignment: .center, spacing: 30) {
                VStack(alignment: .leading, spacing: 14) {
                    Label(L("System Power"), systemImage: "bolt.fill").font(.system(size: 12, weight: .medium)).foregroundStyle(DoreStyle.accent)
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(monitor.systemPower.map { String(format: "%.1f", locale: .current, $0) } ?? "—")
                            .font(.system(size: 42, weight: .regular)).monospacedDigit()
                        Text("W").font(.title2).foregroundStyle(.secondary)
                    }
                    Text(monitor.paused ? L("Paused — showing last reading") : monitor.systemPower == nil ? L("Waiting for power readings") : L("Power during the sampling interval"))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 18) {
                    Label(monitor.onAC ? L("AC Power") : L("Battery Power"), systemImage: monitor.onAC ? "powerplug" : "battery.100")
                        .font(.subheadline)
                    VStack(alignment: .trailing, spacing: 6) {
                        Text(L("Session Peak")).font(.caption).foregroundStyle(.secondary)
                        Text(monitor.systemPower == nil ? "—" : String(format: "%.1f W", locale: .current, monitor.powerPeak))
                            .font(.system(size: 22, weight: .medium)).monospacedDigit()
                    }
                }
            }.dashboardSurface()
            DoreSectionHeading(title: L("Component Power"), detail: L("Sampling interval averages"))
            HStack(spacing: 16) {
                component(L("Processor"), symbol: "cpu", watts: monitor.hardware.cpuPower)
                component(L("Graphics"), symbol: "square.3.layers.3d", watts: monitor.hardware.gpuPower)
            }
            Text(L("Component readings do not include all system power. System readings differ from wall power or the charger's rated output."))
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func component(_ title: String, symbol: String, watts: Double?) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Label(title, systemImage: symbol).font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
            Text(watts.map { String(format: "%.2f W", locale: .current, $0) } ?? L("Unavailable"))
                .font(.system(size: 26, weight: .medium)).monospacedDigit()
        }.dashboardSurface()
    }
}

#Preview("电源设计") {
    let monitor = SystemMonitor()
    PowerSummaryView(monitor: monitor).padding(28).frame(width: 760).background(DoreBackdrop())
}
