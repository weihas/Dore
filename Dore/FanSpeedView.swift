import SwiftUI

struct FanSpeedView: View {
    let monitor: SystemMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("风扇转速", systemImage: "fan").font(.headline)
                Spacer()
                Text(monitor.paused ? "已暂停" : "实时转速")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if monitor.hardware.fans.isEmpty {
                Text(monitor.hardware.fanCount == 0 ? "此设备没有风扇" : "暂时无法读取风扇")
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
                    Text(String(format: "最高转速 %.0f RPM", maximum))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let rpm = fan.rpm {
                if let maximum = fan.maximum, maximum > 0 {
                    ProgressView(value: min(rpm, maximum), total: maximum)
                        .frame(width: 130).tint(DoreStyle.accent)
                        .accessibilityLabel("\(fan.name)转速占最大转速的比例")
                }
                Text(String(format: "%.0f RPM", rpm)).font(.system(size: 22, weight: .medium, design: .rounded)).monospacedDigit()
                    .frame(minWidth: 110, alignment: .trailing)
            } else {
                Text("暂不可用").foregroundStyle(.secondary)
            }
        }.padding(.vertical, 3)
    }

}

#Preview("风扇转速") {
    let monitor = SystemMonitor()
    FanSpeedView(monitor: monitor).padding(20).frame(width: 640)
}
