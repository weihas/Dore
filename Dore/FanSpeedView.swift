import SwiftUI

struct FanSpeedView: View {
    let monitor: SystemMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(L("Fan Speed"), systemImage: "fan").font(.headline)
                Spacer()
                Text(monitor.paused ? L("Paused") : L("Live speed"))
                    .font(.caption).foregroundStyle(.secondary)
            }
            if monitor.hardware.fans.isEmpty {
                Text(monitor.hardware.fanCount == 0 ? L("This Mac has no fans") : L("Fan readings unavailable"))
                    .font(.subheadline).foregroundStyle(.secondary)
            } else {
                ForEach(monitor.hardware.fans) { fan in
                    if fan.id > 0 { Divider() }
                    fanRow(fan)
                }
            }
        }.dashboardSurface()
    }

    private func fanRow(_ fan: FanReading) -> some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                Text(fan.name).font(.subheadline)
                if let maximum = fan.maximum, maximum > 0 {
                    Text(String(format: L("Maximum %.0f RPM"), locale: .current, maximum))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let rpm = fan.rpm {
                if let maximum = fan.maximum, maximum > 0 {
                    ProgressView(value: min(rpm, maximum), total: maximum)
                        .frame(width: 130).tint(DoreStyle.accent)
                        .accessibilityLabel(L("%@ speed relative to maximum", String(fan.name)))
                }
                Text(String(format: "%.0f RPM", locale: .current, rpm)).font(.system(size: 22, weight: .medium, design: .rounded)).monospacedDigit()
                    .frame(minWidth: 110, alignment: .trailing)
            } else {
                Text(L("Unavailable")).foregroundStyle(.secondary)
            }
        }.padding(.vertical, 3)
    }

}

#Preview("风扇转速") {
    let monitor = SystemMonitor()
    FanSpeedView(monitor: monitor).padding(20).frame(width: 640)
}
