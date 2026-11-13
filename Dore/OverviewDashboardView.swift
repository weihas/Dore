import SwiftUI
import AppKit

struct OverviewDashboardView: View {
    let monitor: SystemMonitor
    let samples: [MetricSample]
    let select: (MonitorSection) -> Void

    var body: some View {
        VStack(spacing: 16) {
            deviceHeader
            DoreSectionHeading(title: "性能与资源", detail: "")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 16, alignment: .top)], spacing: 16) {
                cpuCard
                memoryCard
                gpuCard
                networkCard
            }
            storageCard
        }
    }

    private var deviceHeader: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 28) {
                deviceImage
                deviceInformation.frame(minWidth: 360)
            }
            VStack(alignment: .leading, spacing: 12) {
                deviceImage.frame(maxWidth: .infinity)
                deviceInformation
            }
        }
        .dashboardSurface()
    }

    private var deviceImage: some View {
        Group {
            if let image = NSImage(named: NSImage.computerName) {
                Image(nsImage: image).resizable().scaledToFit()
            } else {
                Image(systemName: "desktopcomputer").resizable().scaledToFit().padding(35)
            }
        }
        .frame(width: 160, height: 150)
        .accessibilityHidden(true)
    }

    private var deviceInformation: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(Host.current().localizedName ?? "我的 Mac")
                    .font(.system(size: 20, weight: .semibold)).textSelection(.enabled)
                Text("\(monitor.chip) · macOS \(osVersion)")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 12) {
                GridRow {
                    specification("机型标识", monitor.model)
                    specification("逻辑核心", "\(monitor.cores) 核")
                }
                GridRow {
                    specification("物理内存", byteString(monitor.memoryTotal))
                    specification("磁盘容量", monitor.diskTotal > 0 ? byteString(monitor.diskTotal) : "正在读取…")
                }
            }
            HStack(spacing: 7) {
                Image(systemName: "thermometer.medium")
                Text("温控\(monitor.thermalDescription)")
                Text("·").foregroundStyle(.tertiary)
                Text("已运行 \(Int(ProcessInfo.processInfo.systemUptime / 3600)) 小时")
            }.font(.caption).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private var osVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion)" + (version.patchVersion > 0 ? ".\(version.patchVersion)" : "")
    }

    private func specification(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.system(size: 12, weight: .medium)).textSelection(.enabled)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cpuCard: some View {
        dashboardCard("处理器", symbol: "cpu", tint: DoreStyle.accent, section: .cpu) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(monitor.samples.count > 1 ? String(format: "%.1f", monitor.cpu) : "—")
                    .font(.system(size: 34, weight: .medium)).monospacedDigit()
                Text("%").font(.title3).foregroundStyle(.secondary)
                Spacer()
                Text("\(monitor.cores) 核心").font(.caption).foregroundStyle(.secondary)
            }
            HistoryChart(samples: samples, value: \.cpu, tint: DoreStyle.accent, percentage: true).frame(height: 60)
            HStack {
                Label(monitor.cpuTemperature.map { String(format: "%.0f °C", $0) } ?? "温度暂不可用", systemImage: "thermometer.medium")
                Spacer()
                Text(watts(monitor.hardware.cpuPower))
            }.font(.caption).foregroundStyle(.secondary)
        }
    }

    private var memoryCard: some View {
        dashboardCard("内存", symbol: "memorychip", tint: DoreStyle.secondary, section: .memory) {
            HStack(spacing: 18) {
                UsageRing(value: monitor.lastUpdated == nil ? nil : monitor.memoryPercent, tint: DoreStyle.secondary)
                VStack(spacing: 14) {
                    reading("联动", byteString(monitor.memoryWired))
                    reading("压缩", byteString(monitor.memoryCompressed))
                    reading("可用", byteString(max(0, monitor.memoryTotal - monitor.memoryUsed)))
                }
            }.frame(maxWidth: .infinity)
            Divider().opacity(0.5)
            chartHeader("已用 \(byteString(monitor.memoryUsed))", "共 \(byteString(monitor.memoryTotal))")
            HistoryChart(samples: samples, value: \.memory, tint: DoreStyle.secondary, percentage: true).frame(height: 50)
        }
    }

    private var gpuCard: some View {
        dashboardCard("图形处理器", symbol: "square.3.layers.3d", tint: DoreStyle.accent, section: .power) {
            HStack(alignment: .firstTextBaseline) {
                Text(monitor.hardware.gpuUtilization.map { String(format: "%.0f%%", $0) } ?? "—")
                    .font(.system(size: 28, weight: .medium)).monospacedDigit()
                Spacer()
                Text(watts(monitor.hardware.gpuPower)).font(.subheadline).foregroundStyle(.secondary)
            }
            ProgressView(value: monitor.hardware.gpuUtilization ?? 0, total: 100).tint(DoreStyle.accent)
            Text(monitor.hardware.gpuUtilization == nil ? "等待硬件读数" : "最繁忙 GPU 的使用率")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var networkCard: some View {
        dashboardCard("网络", symbol: "network", tint: DoreStyle.accent, section: .network) {
            HStack {
                transfer("下载", value: monitor.download, symbol: "arrow.down", tint: DoreStyle.accent)
                Spacer()
                transfer("上传", value: monitor.upload, symbol: "arrow.up", tint: DoreStyle.secondary)
            }
            HistoryChart(samples: samples, value: \.download, tint: DoreStyle.accent, percentage: false).frame(height: 58)
            Text("Wi-Fi 与以太网 · 实时速率").font(.caption).foregroundStyle(.secondary)
        }
    }

    private var storageCard: some View {
        dashboardCard("存储", symbol: "internaldrive", tint: DoreStyle.amber, section: .storage) {
            HStack(alignment: .firstTextBaseline) {
                Text(byteString(monitor.diskFree)).font(.system(size: 24, weight: .medium)).monospacedDigit()
                Text("可用空间").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text("已用 \(Int(monitor.diskPercent))% ").font(.subheadline).monospacedDigit()
            }
            ProgressView(value: monitor.diskPercent, total: 100).tint(DoreStyle.amber)
            chartHeader("Macintosh HD", "共 \(byteString(monitor.diskTotal))")
        }
    }

    private func dashboardCard<Content: View>(_ title: String, symbol: String, tint: Color,
                                              section: MonitorSection, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Button { select(section) } label: {
                HStack(spacing: 9) {
                    Image(systemName: symbol).foregroundStyle(tint)
                        .frame(width: 18, height: 18)
                    Text(title).font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.system(size: 11, weight: .medium)).foregroundStyle(.tertiary)
                }.contentShape(Rectangle())
            }.buttonStyle(.plain).help("查看\(title)详情")
            content()
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .dashboardSurface()
    }

    private func reading(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer(minLength: 6)
            Text(value).monospacedDigit()
        }.font(.system(size: 12))
    }

    private func chartHeader(_ title: String, _ value: String) -> some View {
        HStack { Text(title); Spacer(); Text(value) }.font(.caption).foregroundStyle(.secondary)
    }

    private func transfer(_ title: String, value: Double, symbol: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol).font(.caption).foregroundStyle(tint)
            Text(rateString(value)).font(.system(size: 20, weight: .medium)).monospacedDigit()
        }
    }

    private func watts(_ value: Double?) -> String {
        value.map { String(format: "%.2f W", $0) } ?? "暂不可用"
    }
}

#Preview("总览卡片") {
    let monitor = SystemMonitor()
    OverviewDashboardView(monitor: monitor, samples: []) { _ in }
        .padding(20)
        .frame(width: 760, height: 1080)
        .task { monitor.start() }
}
