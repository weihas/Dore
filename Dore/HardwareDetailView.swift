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
                history(String(localized: "CPU Usage"), symbol: "waveform.path", value: \.cpu, tint: DoreStyle.accent, percentage: true)
                information(String(localized: "Processor Information"), rows: [
                    (String(localized: "Chip"), monitor.chip), (String(localized: "Logical Cores"), String(format: String(localized: "Cores: %@"), locale: .current, String(monitor.cores))),
                    (String(localized: "Idle"), cpuReady ? percent(100 - monitor.cpu) : String(localized: "Sampling…")),
                    (String(localized: "Thermal State"), monitor.thermalDescription)
                ])
            case .memory:
                history(String(localized: "Memory Usage"), symbol: "waveform.path", value: \.memory, tint: DoreStyle.secondary, percentage: true)
                memoryAllocation
                note(String(localized: "Used memory is estimated from active, wired and compressed pages and may differ slightly from Activity Monitor."))
            case .network:
                history(String(localized: "Download Rate"), symbol: "arrow.down", value: \.download, tint: DoreStyle.accent, percentage: false)
                history(String(localized: "Upload Rate"), symbol: "arrow.up", value: \.upload, tint: DoreStyle.secondary, percentage: false)
                information(String(localized: "Sampling Information"), rows: [(String(localized: "Interfaces"), String(localized: "Wi-Fi and Ethernet interfaces")),
                    (String(localized: "History"), String(localized: "Last 5 minutes, held in memory only"))])
            case .storage:
                storageAllocation
                information(String(localized: "Disk Information"), rows: [(String(localized: "Volume Name"), "Macintosh HD"), (String(localized: "Capacity"), diskReady ? byteString(monitor.diskTotal) : String(localized: "Reading…")),
                    (String(localized: "Used"), diskReady ? byteString(max(0, monitor.diskTotal - monitor.diskFree)) : String(localized: "Reading…")),
                    (String(localized: "Available Space"), diskReady ? byteString(monitor.diskFree) : String(localized: "Reading…"))])
                note(String(localized: "Available space excludes purgeable caches and may differ from System Settings."))
            default: EmptyView()
            }
        }
    }

    private var cpuReady: Bool { monitor.samples.count > 1 }
    private var memoryReady: Bool { monitor.lastUpdated != nil }
    private var diskReady: Bool { monitor.diskTotal > 0 }
    private var interval: String { period == 60 ? String(localized: "Last minute") : String(localized: "Last 5 minutes") }

    private var header: some View {
        DorePageHeading(title: section.title, subtitle: subtitle)
    }

    private var subtitle: String {
        switch section {
        case .cpu: monitor.chip
        case .memory: String(format: String(localized: "%@ physical memory"), locale: .current, String(byteString(monitor.memoryTotal)))
        case .network: String(localized: "Wi-Fi & Ethernet · Live transfer")
        case .storage: String(localized: "Macintosh HD · Local storage")
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
            return [Statistic(String(localized: "Current Usage"), cpuReady ? percent(monitor.cpu) : String(localized: "Sampling…")),
                    Statistic(String(localized: "CPU Temperature"), monitor.cpuTemperature.map { String(format: "%.0f °C", locale: .current, $0) } ?? String(localized: "Unavailable")),
                    Statistic(String(localized: "CPU Power"), monitor.hardware.cpuPower.map { String(format: "%.2f W", locale: .current, $0) } ?? String(localized: "Unavailable"))]
        case .memory:
            return [Statistic(String(localized: "Current Usage"), memoryReady ? percent(monitor.memoryPercent) : String(localized: "Sampling…")),
                    Statistic(String(localized: "Used"), memoryReady ? byteString(monitor.memoryUsed) : String(localized: "Sampling…")),
                    Statistic(String(localized: "Available"), memoryReady ? byteString(max(0, monitor.memoryTotal - monitor.memoryUsed)) : String(localized: "Sampling…"))]
        case .network:
            return [Statistic(String(localized: "Download Rate"), cpuReady ? rateString(monitor.download) : String(localized: "Sampling…")),
                    Statistic(String(localized: "Upload Rate"), cpuReady ? rateString(monitor.upload) : String(localized: "Sampling…"))]
        case .storage:
            return [Statistic(String(localized: "Available Space"), diskReady ? byteString(monitor.diskFree) : String(localized: "Reading…")),
                    Statistic(String(localized: "Space Used"), diskReady ? percent(monitor.diskPercent) : String(localized: "Reading…")),
                    Statistic(String(localized: "Capacity"), diskReady ? byteString(monitor.diskTotal) : String(localized: "Reading…"))]
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
                        Text("Collecting samples…").font(.caption).foregroundStyle(.secondary)
                    }
                }
            HStack {
                Text(samples.first.map { $0.date.formatted(date: .omitted, time: .standard) } ?? String(localized: "Waiting for samples"))
                Spacer()
                Text(monitor.paused ? String(localized: "Paused sample") : String(localized: "Latest sample"))
            }.font(.caption2).foregroundStyle(.tertiary)
        }.dashboardSurface()
    }

    private var memoryAllocation: some View {
        VStack(alignment: .leading, spacing: 18) {
            cardTitle(String(localized: "Memory Allocation"), symbol: "square.stack.3d.up", tint: DoreStyle.secondary)
            allocationRow(String(localized: "Wired Memory"), bytes: monitor.memoryWired, total: monitor.memoryTotal, tint: DoreStyle.secondary, ready: memoryReady)
            allocationRow(String(localized: "Compressed Memory"), bytes: monitor.memoryCompressed, total: monitor.memoryTotal, tint: DoreStyle.secondary.opacity(0.7), ready: memoryReady)
            allocationRow(String(localized: "Available Memory"), bytes: max(0, monitor.memoryTotal - monitor.memoryUsed), total: monitor.memoryTotal, tint: DoreStyle.accent, ready: memoryReady)
            Text("Shown as a share of physical memory. Wired and compressed memory are included in used memory.")
                .font(.caption).foregroundStyle(.secondary)
        }.dashboardSurface()
    }

    private var storageAllocation: some View {
        VStack(alignment: .leading, spacing: 20) {
            cardTitle(String(localized: "Space Allocation"), symbol: "chart.bar.fill", tint: DoreStyle.amber)
            ProgressView(value: min(100, max(0, monitor.diskPercent)), total: 100).tint(DoreStyle.amber)
                .accessibilityLabel("Disk space used")
            HStack {
                Label(diskReady ? String(format: String(localized: "%@ used"), locale: .current, String(byteString(max(0, monitor.diskTotal - monitor.diskFree)))) : String(localized: "Reading…"), systemImage: "circle.fill").foregroundStyle(DoreStyle.amber)
                Spacer()
                Text(diskReady ? String(format: String(localized: "%@ available"), locale: .current, String(byteString(monitor.diskFree))) : String(localized: "Reading…")).foregroundStyle(.secondary)
            }.font(.caption).monospacedDigit()
        }.dashboardSurface()
    }

    private func allocationRow(_ title: String, bytes: Double, total: Double, tint: Color, ready: Bool) -> some View {
        VStack(spacing: 9) {
            HStack {
                Text(title).foregroundStyle(.secondary)
                Spacer()
                Text(ready ? byteString(bytes) : String(localized: "Sampling…")).monospacedDigit()
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

    private func percent(_ value: Double) -> String { String(format: "%.1f%%", locale: .current, value) }
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
