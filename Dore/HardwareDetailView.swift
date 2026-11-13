import SwiftUI

struct HardwareDetailView: View {
    let monitor: SystemMonitor
    let section: MonitorSection
    let samples: [MetricSample]
    let period: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(statistics.enumerated()), id: \.element.title) { index, stat in
                    if index > 0 { Divider().frame(height: 54).padding(.horizontal, 20) }
                    VStack(alignment: .leading, spacing: 12) {
                        Text(stat.title).font(.system(size: 11)).foregroundStyle(.secondary)
                        Text(stat.value).font(.system(size: 26, weight: .medium))
                            .monospacedDigit().textSelection(.enabled)
                            .foregroundStyle(.primary)
                            .lineLimit(1).minimumScaleFactor(0.65)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
            }.dashboardSurface()
            switch section {
            case .cpu:
                history("CPU 使用率", symbol: "waveform.path", value: \.cpu, tint: DoreStyle.accent, percentage: true)
                information("处理器信息", rows: [
                    ("芯片", monitor.chip), ("逻辑核心", "\(monitor.cores) 核"),
                    ("空闲比例", cpuReady ? percent(100 - monitor.cpu) : "正在采样…"),
                    ("系统温控", monitor.thermalDescription)
                ])
            case .memory:
                history("内存使用率", symbol: "waveform.path", value: \.memory, tint: DoreStyle.secondary, percentage: true)
                memoryAllocation
                note("已使用内存根据活动、联动与压缩页估算，可能与活动监视器略有差异。")
            case .network:
                history("下载速率", symbol: "arrow.down", value: \.download, tint: DoreStyle.accent, percentage: false)
                history("上传速率", symbol: "arrow.up", value: \.upload, tint: DoreStyle.secondary, percentage: false)
                information("采样信息", rows: [("统计范围", "Wi-Fi 与以太网物理接口"),
                    ("历史记录", "最近 5 分钟，仅保留在内存中")])
            case .storage:
                storageAllocation
                information("磁盘信息", rows: [("卷名称", "Macintosh HD"), ("总容量", diskReady ? byteString(monitor.diskTotal) : "正在读取…"),
                    ("已使用", diskReady ? byteString(max(0, monitor.diskTotal - monitor.diskFree)) : "正在读取…"),
                    ("可用空间", diskReady ? byteString(monitor.diskFree) : "正在读取…")])
                note("可用空间不包含系统可清除缓存，可能与系统设置显示的数值不同。")
            default: EmptyView()
            }
        }
    }

    private var cpuReady: Bool { monitor.samples.count > 1 }
    private var memoryReady: Bool { monitor.lastUpdated != nil }
    private var diskReady: Bool { monitor.diskTotal > 0 }
    private var interval: String { period == 60 ? "最近 1 分钟" : "最近 5 分钟" }

    private var header: some View {
        DorePageHeading(title: section.rawValue, subtitle: subtitle)
    }

    private var subtitle: String {
        switch section {
        case .cpu: monitor.chip
        case .memory: "\(byteString(monitor.memoryTotal)) 物理内存"
        case .network: "Wi-Fi 与以太网 · 实时传输"
        case .storage: "Macintosh HD · 本机磁盘空间"
        default: ""
        }
    }

    private struct Statistic {
        let title: String
        let value: String
        init(_ title: String, _ value: String) { self.title = title; self.value = value }
    }

    private var statistics: [Statistic] {
        switch section {
        case .cpu:
            return [Statistic("当前使用率", cpuReady ? percent(monitor.cpu) : "正在采样…"),
                    Statistic("CPU 温度", monitor.cpuTemperature.map { String(format: "%.0f °C", $0) } ?? "暂不可用"),
                    Statistic("CPU 功耗", monitor.hardware.cpuPower.map { String(format: "%.2f W", $0) } ?? "暂不可用")]
        case .memory:
            return [Statistic("当前使用率", memoryReady ? percent(monitor.memoryPercent) : "正在采样…"),
                    Statistic("已使用", memoryReady ? byteString(monitor.memoryUsed) : "正在采样…"),
                    Statistic("可用", memoryReady ? byteString(max(0, monitor.memoryTotal - monitor.memoryUsed)) : "正在采样…")]
        case .network:
            return [Statistic("下载速率", cpuReady ? rateString(monitor.download) : "正在采样…"),
                    Statistic("上传速率", cpuReady ? rateString(monitor.upload) : "正在采样…")]
        case .storage:
            return [Statistic("可用空间", diskReady ? byteString(monitor.diskFree) : "正在读取…"),
                    Statistic("已用比例", diskReady ? percent(monitor.diskPercent) : "正在读取…"),
                    Statistic("总容量", diskReady ? byteString(monitor.diskTotal) : "正在读取…")]
        default: return []
        }
    }

    private func history(_ title: String, symbol: String, value: KeyPath<MetricSample, Double>, tint: Color, percentage: Bool) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                cardTitle(title, symbol: symbol, tint: tint)
                Spacer()
                Text(interval).font(.caption).foregroundStyle(.secondary)
            }
            HistoryChart(samples: samples, value: value, tint: tint, percentage: percentage, showsAxes: true)
                .frame(height: 155)
                .overlay {
                    if samples.count < 2 {
                        Text("正在收集采样数据…").font(.caption).foregroundStyle(.secondary)
                    }
                }
            HStack {
                Text(samples.first.map { $0.date.formatted(date: .omitted, time: .standard) } ?? "等待采样")
                Spacer()
                Text(monitor.paused ? "暂停时刻" : "最新采样")
            }.font(.caption2).foregroundStyle(.tertiary)
        }.dashboardSurface()
    }

    private var memoryAllocation: some View {
        VStack(alignment: .leading, spacing: 18) {
            cardTitle("内存分配", symbol: "square.stack.3d.up", tint: DoreStyle.secondary)
            allocationRow("联动内存", bytes: monitor.memoryWired, total: monitor.memoryTotal, tint: DoreStyle.secondary, ready: memoryReady)
            allocationRow("已压缩", bytes: monitor.memoryCompressed, total: monitor.memoryTotal, tint: DoreStyle.secondary.opacity(0.7), ready: memoryReady)
            allocationRow("可用内存", bytes: max(0, monitor.memoryTotal - monitor.memoryUsed), total: monitor.memoryTotal, tint: DoreStyle.accent, ready: memoryReady)
            Text("各项占物理内存的比例；联动与压缩内存包含在已使用内存中。")
                .font(.caption).foregroundStyle(.secondary)
        }.dashboardSurface()
    }

    private var storageAllocation: some View {
        VStack(alignment: .leading, spacing: 20) {
            cardTitle("空间分配", symbol: "chart.bar.fill", tint: DoreStyle.amber)
            ProgressView(value: min(100, max(0, monitor.diskPercent)), total: 100).tint(DoreStyle.amber)
                .accessibilityLabel("磁盘已用比例")
            HStack {
                Label(diskReady ? "已用 \(byteString(max(0, monitor.diskTotal - monitor.diskFree)))" : "正在读取…", systemImage: "circle.fill").foregroundStyle(DoreStyle.amber)
                Spacer()
                Text(diskReady ? "可用 \(byteString(monitor.diskFree))" : "正在读取…").foregroundStyle(.secondary)
            }.font(.caption).monospacedDigit()
        }.dashboardSurface()
    }

    private func allocationRow(_ title: String, bytes: Double, total: Double, tint: Color, ready: Bool) -> some View {
        VStack(spacing: 9) {
            HStack {
                Text(title).foregroundStyle(.secondary)
                Spacer()
                Text(ready ? byteString(bytes) : "正在采样…").monospacedDigit()
            }.font(.system(size: 12))
            ProgressView(value: ready && total > 0 ? min(1, max(0, bytes / total)) : 0).tint(tint)
                .accessibilityLabel(title)
        }
    }

    private func information(_ title: String, rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            cardTitle(title, symbol: "info.circle", tint: section.tint)
            ForEach(rows.indices, id: \.self) { index in
                if index > 0 { Divider().opacity(0.5) }
                HStack(alignment: .firstTextBaseline, spacing: 20) {
                    Text(rows[index].0).foregroundStyle(.secondary)
                    Spacer()
                    Text(rows[index].1).multilineTextAlignment(.trailing).textSelection(.enabled)
                }.font(.system(size: 12))
            }
        }.dashboardSurface()
    }

    private func cardTitle(_ title: String, symbol: String, tint: Color) -> some View {
        HStack(spacing: 9) {
            Image(systemName: symbol).foregroundStyle(tint)
                .frame(width: 18, height: 18)
            Text(title).font(.system(size: 14, weight: .semibold))
        }
    }

    private func percent(_ value: Double) -> String { String(format: "%.1f%%", value) }
    private func note(_ text: String) -> some View {
        Label(text, systemImage: "info.circle").font(.caption).foregroundStyle(.secondary).padding(.horizontal, 4)
    }
}

private struct HardwareDetailPreview: View {
    let section: MonitorSection
    @State private var monitor = SystemMonitor()
    var body: some View {
        ScrollView {
            HardwareDetailView(monitor: monitor, section: section, samples: monitor.samples, period: 60)
                .padding(20)
        }.frame(width: 720, height: 1060).task { monitor.start() }
    }
}

#Preview("处理器详情") { HardwareDetailPreview(section: .cpu) }
#Preview("内存详情") { HardwareDetailPreview(section: .memory) }
#Preview("网络详情") { HardwareDetailPreview(section: .network) }
#Preview("存储详情") { HardwareDetailPreview(section: .storage) }
