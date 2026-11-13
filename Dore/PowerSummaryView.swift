import SwiftUI

struct PowerSummaryView: View {
    let monitor: SystemMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            DorePageHeading(title: "电源", subtitle: "整机能耗与供电状态")
            HStack(alignment: .center, spacing: 30) {
                VStack(alignment: .leading, spacing: 14) {
                    Label("整机功耗", systemImage: "bolt.fill").font(.system(size: 12, weight: .medium)).foregroundStyle(DoreStyle.accent)
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(monitor.systemPower.map { String(format: "%.1f", $0) } ?? "—")
                            .font(.system(size: 42, weight: .regular)).monospacedDigit()
                        Text("W").font(.title2).foregroundStyle(.secondary)
                    }
                    Text(monitor.paused ? "采样已暂停，显示最后读数" : monitor.systemPower == nil ? "等待硬件功耗读数" : "采样间隔内的实时功耗")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 18) {
                    Label(monitor.onAC ? "交流电源" : "电池供电", systemImage: monitor.onAC ? "powerplug" : "battery.100")
                        .font(.subheadline)
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("本次最高").font(.caption).foregroundStyle(.secondary)
                        Text(monitor.systemPower == nil ? "—" : String(format: "%.1f W", monitor.powerPeak))
                            .font(.system(size: 22, weight: .medium)).monospacedDigit()
                    }
                }
            }.dashboardSurface()
            DoreSectionHeading(title: "部件能耗", detail: "采样间隔平均值")
            HStack(spacing: 16) {
                component("处理器", symbol: "cpu", watts: monitor.hardware.cpuPower)
                component("图形处理器", symbol: "square.3.layers.3d", watts: monitor.hardware.gpuPower)
            }
            Text("部件功耗不包含整机全部能耗；整机读数不等同于插座测量值或充电器额定功率。")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func component(_ title: String, symbol: String, watts: Double?) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Label(title, systemImage: symbol).font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
            Text(watts.map { String(format: "%.2f W", $0) } ?? "暂不可用")
                .font(.system(size: 26, weight: .medium)).monospacedDigit()
        }.dashboardSurface()
    }
}

#Preview("电源设计") {
    let monitor = SystemMonitor()
    PowerSummaryView(monitor: monitor).padding(28).frame(width: 760).background(DoreBackdrop())
}
