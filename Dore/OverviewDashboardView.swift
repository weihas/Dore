import SwiftUI
import AppKit

struct OverviewDashboardView: View {
    let monitor: SystemMonitor
    let samples: [MetricSample]
    let select: (MonitorSection) -> Void

    var body: some View {
        VStack(spacing: 16) {
            deviceHeader
            DoreSectionHeading(title: L("Performance & Resources"), detail: "")
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
                Text(Host.current().localizedName ?? L("My Mac"))
                    .font(.system(size: 20, weight: .semibold)).textSelection(.enabled)
                Text("\(monitor.chip) · macOS \(osVersion)")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 12) {
                GridRow {
                    specification(L("Model Identifier"), monitor.model)
                    specification(L("Logical Cores"), L("Cores: %@", String(monitor.cores)))
                }
                GridRow {
                    specification(L("Physical Memory"), byteString(monitor.memoryTotal))
                    specification(L("Disk Capacity"), monitor.diskTotal > 0 ? byteString(monitor.diskTotal) : L("Reading…"))
                }
            }
            HStack(spacing: 7) {
                Image(systemName: "thermometer.medium")
                Text(L("Thermal: %@", String(monitor.thermalDescription)))
                Text("·").foregroundStyle(.tertiary)
                Text(L("Uptime (hours): %@", String(Int(ProcessInfo.processInfo.systemUptime / 3600))))
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
        dashboardCard(L("Processor"), symbol: "cpu", tint: DoreStyle.accent, section: .cpu) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(monitor.samples.count > 1 ? String(format: "%.1f", locale: .current, monitor.cpu) : "—")
                    .font(.system(size: 34, weight: .medium)).monospacedDigit()
                Text("%").font(.title3).foregroundStyle(.secondary)
                Spacer()
                Text(L("Core count: %@", String(monitor.cores))).font(.caption).foregroundStyle(.secondary)
            }
            HistoryChart(samples: samples, value: \.cpu, tint: DoreStyle.accent, percentage: true).frame(height: 60)
            HStack {
                Label(monitor.cpuTemperature.map { String(format: "%.0f °C", locale: .current, $0) } ?? L("Temperature unavailable"), systemImage: "thermometer.medium")
                Spacer()
                Text(watts(monitor.hardware.cpuPower))
            }.font(.caption).foregroundStyle(.secondary)
        }
    }

    private var memoryCard: some View {
        dashboardCard(L("Memory"), symbol: "memorychip", tint: DoreStyle.secondary, section: .memory) {
            HStack(spacing: 18) {
                UsageRing(value: monitor.lastUpdated == nil ? nil : monitor.memoryPercent, tint: DoreStyle.secondary)
                VStack(spacing: 14) {
                    reading(L("Wired"), byteString(monitor.memoryWired))
                    reading(L("Compressed"), byteString(monitor.memoryCompressed))
                    reading(L("Available"), byteString(max(0, monitor.memoryTotal - monitor.memoryUsed)))
                }
            }.frame(maxWidth: .infinity)
            Divider().opacity(0.5)
            chartHeader(L("%@ used", String(byteString(monitor.memoryUsed))), L("Total: %@", String(byteString(monitor.memoryTotal))))
            HistoryChart(samples: samples, value: \.memory, tint: DoreStyle.secondary, percentage: true).frame(height: 50)
        }
    }

    private var gpuCard: some View {
        dashboardCard(L("Graphics"), symbol: "square.3.layers.3d", tint: DoreStyle.accent, section: .power) {
            HStack(alignment: .firstTextBaseline) {
                Text(monitor.hardware.gpuUtilization.map { String(format: "%.0f%%", locale: .current, $0) } ?? "—")
                    .font(.system(size: 28, weight: .medium)).monospacedDigit()
                Spacer()
                Text(watts(monitor.hardware.gpuPower)).font(.subheadline).foregroundStyle(.secondary)
            }
            ProgressView(value: monitor.hardware.gpuUtilization ?? 0, total: 100).tint(DoreStyle.accent)
            Text(monitor.hardware.gpuUtilization == nil ? L("Waiting for hardware readings") : L("Usage of the busiest GPU"))
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var networkCard: some View {
        dashboardCard(L("Network"), symbol: "network", tint: DoreStyle.accent, section: .network) {
            HStack {
                transfer(L("Download"), value: monitor.download, symbol: "arrow.down", tint: DoreStyle.accent)
                Spacer()
                transfer(L("Upload"), value: monitor.upload, symbol: "arrow.up", tint: DoreStyle.secondary)
            }
            HistoryChart(samples: samples, value: \.download, tint: DoreStyle.accent, percentage: false).frame(height: 58)
            Text(L("Wi-Fi & Ethernet · Live rates")).font(.caption).foregroundStyle(.secondary)
        }
    }

    private var storageCard: some View {
        dashboardCard(L("Storage"), symbol: "internaldrive", tint: DoreStyle.amber, section: .storage) {
            HStack(alignment: .firstTextBaseline) {
                Text(byteString(monitor.diskFree)).font(.system(size: 24, weight: .medium)).monospacedDigit()
                Text(L("Available Space")).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(L("%@%% used", String(Int(monitor.diskPercent)))).font(.subheadline).monospacedDigit()
            }
            ProgressView(value: monitor.diskPercent, total: 100).tint(DoreStyle.amber)
            chartHeader("Macintosh HD", L("Total: %@", String(byteString(monitor.diskTotal))))
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
            }.buttonStyle(.plain).help(L("View %@ details", String(title)))
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
        value.map { String(format: "%.2f W", locale: .current, $0) } ?? L("Unavailable")
    }
}

#Preview("总览卡片") {
    let monitor = SystemMonitor()
    OverviewDashboardView(monitor: monitor, samples: []) { _ in }
        .padding(20)
        .frame(width: 760, height: 1080)
        .task { monitor.start() }
}
