import SwiftUI

struct OverviewMetricsView: View {
    let monitor: SystemMonitor
    let select: (MonitorSection) -> Void

    var body: some View {
        GroupBox {
            HStack(alignment: .top, spacing: 0) {
                ring("处理器", symbol: "cpu", value: monitor.samples.count > 1 ? monitor.cpu : nil,
                     tint: .blue, detail: "\(monitor.cores) 核心", secondary: power(monitor.hardware.cpuPower), section: .cpu)
                Divider().frame(height: 220).padding(.top, 8)
                ring("内存", symbol: "memorychip", value: monitor.lastUpdated == nil ? nil : monitor.memoryPercent,
                     tint: .purple, detail: "已用 \(byteString(monitor.memoryUsed))",
                     secondary: "共 \(byteString(monitor.memoryTotal))", section: .memory)
                Divider().frame(height: 220).padding(.top, 8)
                ring("GPU", symbol: "square.3.layers.3d", value: monitor.hardware.gpuUtilization,
                     tint: .teal, detail: "图形处理器", secondary: power(monitor.hardware.gpuPower), section: .power)
            }.padding(.vertical, 16)
        }
    }

    private func power(_ value: Double?) -> String {
        value.map { String(format: "%.2f W", $0) } ?? "功耗暂不可用"
    }

    private func ring(_ title: String, symbol: String, value: Double?, tint: Color,
                      detail: String, secondary: String, section: MonitorSection) -> some View {
        Button { select(section) } label: {
            VStack(spacing: 16) {
                Label(title, systemImage: symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                UsageRing(value: value, tint: tint)
                VStack(spacing: 5) {
                    Text(detail).font(.system(size: 12, weight: .medium))
                    Text(secondary).font(.caption).foregroundStyle(.secondary).monospacedDigit()
                }
                .lineLimit(1).minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(title == "GPU" ? "查看 GPU 功耗与散热详情；圆环为最繁忙 GPU 的使用率" : "查看\(title)详情")
        .accessibilityLabel("\(title)，\(value.map { String(format: "使用率 %.0f%%", $0) } ?? "暂不可用")，\(detail)，\(secondary)")
    }
}

private struct UsageRing: View {
    let value: Double?
    let tint: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle().stroke(tint.opacity(0.12), lineWidth: 9)
            if let value {
                Circle()
                    .trim(from: 0, to: min(1, max(0, value / 100)))
                    .stroke(tint, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: value)
                VStack(spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(value, format: .number.precision(.fractionLength(0)))
                            .font(.system(size: 30, weight: .medium, design: .rounded))
                            .monospacedDigit()
                        Text("%").font(.system(size: 14)).foregroundStyle(.secondary)
                    }
                    Text("使用率").font(.system(size: 10)).foregroundStyle(.secondary)
                }
            } else {
                Text("暂不可用").font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(width: 122, height: 122)
        .padding(5)
        .accessibilityHidden(true)
    }
}

#Preview("总览圆环") {
    let monitor: SystemMonitor = {
        let monitor = SystemMonitor()
        monitor.cpu = 23
        monitor.memoryUsed = monitor.memoryTotal * 0.7
        monitor.lastUpdated = Date()
        monitor.samples = (0..<2).map { _ in
            MetricSample(date: Date(), cpu: 23, memory: 70, download: 0, upload: 0)
        }
        monitor.hardware = HardwareMetrics(values: ["CPU Power": 2.45, "GPU Power": 0.62, "GPU Utilization": 11])
        return monitor
    }()
    OverviewMetricsView(monitor: monitor) { _ in }
        .padding(20).frame(width: 620)
}
