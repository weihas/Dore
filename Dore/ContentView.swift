import SwiftUI
import Charts
import AppKit

enum MonitorSection: String, CaseIterable, Identifiable {
    case overview = "总览", cpu = "处理器", memory = "内存", network = "网络", storage = "存储", power = "电源与散热"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .overview: "square.grid.2x2"
        case .cpu: "cpu"
        case .memory: "memorychip"
        case .network: "network"
        case .storage: "internaldrive"
        case .power: "bolt.heart"
        }
    }
    var tint: Color {
        switch self {
        case .overview, .cpu: .blue
        case .memory: .purple
        case .network: .teal
        case .storage: .orange
        case .power: .green
        }
    }

}

struct ContentView: View {
    let monitor: SystemMonitor
    @State private var selection: MonitorSection = .overview
    @State private var period = 60

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("监控") {
                    ForEach(MonitorSection.allCases) { section in
                        Label(section.rawValue, systemImage: section.symbol)
                            .tag(section)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Dore")
            .navigationSplitViewColumnWidth(min: 170, ideal: 190, max: 240)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if selection == .overview {
                        deviceCard
                        OverviewMetricsView(monitor: monitor) { selection = $0 }
                        HStack(alignment: .top, spacing: 12) {
                            networkCard
                            storageCard
                        }
                        powerStrip
                    } else {
                        detailContent
                    }
                }
                .padding(20)
                .frame(maxWidth: 1000)
                .frame(maxWidth: .infinity)
            }
            .background(Color(nsColor: .windowBackgroundColor))
            .navigationTitle(selection.rawValue)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Picker("时间范围", selection: $period) {
                        Text("1 分钟").tag(60)
                        Text("5 分钟").tag(300)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 140)
                    .help("图表时间范围")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { monitor.togglePause() } label: {
                        Label(monitor.paused ? "继续监控" : "暂停监控", systemImage: monitor.paused ? "play" : "pause")
                    }
                    .help(monitor.paused ? "继续监控" : "暂停监控")
                }
                ToolbarItem(placement: .primaryAction) {
                    SettingsLink { Label("设置", systemImage: "gearshape") }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    Divider()
                    HStack {
                        Text(monitor.paused ? "监控已暂停" : "实时更新")
                        Spacer()
                        Text("数据仅保留在本机")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
                .background(.bar)
            }
        }
        .frame(minWidth: 820, minHeight: 600)
    }

    private var deviceCard: some View {
        HStack(spacing: 14) {
            Image(systemName: monitor.battery == nil ? "desktopcomputer" : "laptopcomputer")
                .font(.system(size: 32, weight: .regular))
                .foregroundStyle(.secondary)
                .frame(width: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text(Host.current().localizedName ?? "我的 Mac").font(.headline)
                Text("\(monitor.chip) · \(byteString(monitor.memoryTotal)) 内存")
                    .font(.subheadline).foregroundStyle(.secondary)
                Text("macOS \(ProcessInfo.processInfo.operatingSystemVersion.majorVersion).\(ProcessInfo.processInfo.operatingSystemVersion.minorVersion) · \(monitor.model)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("温控\(monitor.thermalDescription)")
                Text("已运行 \(Int(ProcessInfo.processInfo.systemUptime / 3600)) 小时")
                    .foregroundStyle(.secondary)
            }.font(.caption)
        }
        .padding(.vertical, 8)
    }

    private func metricCard(_ section: MonitorSection, value: String, unit: String, subtitle: String, data: KeyPath<MetricSample, Double>) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            cardHeading(section)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value).font(.system(size: 24, weight: .regular)).monospacedDigit()
                Text(unit).font(.system(size: 17)).foregroundStyle(.secondary)
                Spacer()
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            HistoryChart(samples: visibleSamples, value: data, tint: section.tint, percentage: true)
                .frame(height: 70)
            HStack {
                Text(section == .cpu ? "CPU 使用率" : "内存使用率")
                Spacer()
                Text(monitor.samples.count < 2 ? "正在采样…" : "最近 \(period == 60 ? "1" : "5") 分钟")
            }.font(.caption).foregroundStyle(.secondary)
        }.padding(6).cardSurface()
    }

    private func cardHeading(_ section: MonitorSection) -> some View {
        Button { selection = section } label: {
            HStack(spacing: 8) {
                Image(systemName: section.symbol).foregroundStyle(.secondary)
                Text(section.rawValue).fontWeight(.semibold)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 9, weight: .semibold)).foregroundStyle(.secondary)
            }.font(.system(size: 12)).contentShape(Rectangle())
        }.buttonStyle(.plain)
    }

    private var networkCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            cardHeading(.network)
            HStack {
                transferValue("下载", symbol: "arrow.down", value: monitor.download, tint: .teal)
                Spacer()
                transferValue("上传", symbol: "arrow.up", value: monitor.upload, tint: .blue)
            }
            HistoryChart(samples: visibleSamples, value: \.download, tint: .teal, percentage: false).frame(height: 48)
            Text("物理网络接口 · 实时传输速率").font(.caption).foregroundStyle(.secondary)
        }.padding(6).cardSurface()
    }

    private var storageCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            cardHeading(.storage)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(byteString(monitor.diskFree)).font(.system(size: 22, weight: .regular)).monospacedDigit()
                Text("可用").font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer()
            }
            VStack(spacing: 9) {
                ProgressView(value: monitor.diskPercent, total: 100)
                    .tint(.accentColor)
                HStack {
                    Text("已使用 \(Int(monitor.diskPercent))%").foregroundStyle(.secondary)
                    Spacer()
                    Text("共 \(byteString(monitor.diskTotal))").foregroundStyle(.secondary)
                }.font(.caption)
            }.frame(height: 48)
            Text("Macintosh HD · 数据卷可用空间").font(.caption).foregroundStyle(.secondary)
        }.padding(6).cardSurface()
    }

    private var powerStrip: some View {
        HStack(spacing: 14) {
            Image(systemName: "bolt.fill").foregroundStyle(.secondary).font(.title3).frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(monitor.battery.map { "电池电量 \(Int($0))%" } ?? "交流电供电").font(.system(size: 12, weight: .semibold))
                Text(monitor.charging ? "正在充电" : monitor.onAC ? "已连接电源" : "正在使用电池").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if let watts = monitor.systemPower {
                Text(String(format: "%.1f W", watts)).font(.subheadline).monospacedDigit()
                    .help("整机功耗")
            }
            Label("温控\(monitor.thermalDescription)", systemImage: "thermometer.medium").font(.system(size: 11)).foregroundStyle(.secondary)
            Divider().frame(height: 24).padding(.horizontal, 8)
            Button("查看详情") { selection = .power }.buttonStyle(.borderless).font(.system(size: 11))
        }.padding(6).cardSurface()
    }

    private var visibleSamples: [MetricSample] {
        let end = monitor.samples.last?.date ?? Date()
        return monitor.samples.filter { end.timeIntervalSince($0.date) <= Double(period) }
    }

    @ViewBuilder private var detailContent: some View {
        switch selection {
        case .cpu:
            metricCard(.cpu, value: String(format: "%.1f", monitor.cpu), unit: "%", subtitle: monitor.chip, data: \.cpu)
            informationCard("处理器信息", rows: [("芯片", monitor.chip), ("逻辑核心", "\(monitor.cores) 核"), ("空闲", String(format: "%.1f%%", 100 - monitor.cpu)), ("系统温控状态", monitor.thermalDescription)])
        case .memory:
            metricCard(.memory, value: String(format: "%.1f", monitor.memoryPercent), unit: "%", subtitle: "物理内存使用率", data: \.memory)
            informationCard("内存分配", rows: [("物理内存", byteString(monitor.memoryTotal)), ("已使用", byteString(monitor.memoryUsed)), ("联动内存", byteString(monitor.memoryWired)), ("已压缩", byteString(monitor.memoryCompressed)), ("可用", byteString(monitor.memoryTotal - monitor.memoryUsed))])
            Text("已使用内存根据活动、联动与压缩页估算，可能与活动监视器略有差异。").font(.caption).foregroundStyle(.secondary)
        case .network:
            networkCard
            VStack(alignment: .leading, spacing: 16) {
                Label("上传速率", systemImage: "arrow.up").font(.headline).foregroundStyle(.blue)
                HistoryChart(samples: visibleSamples, value: \.upload, tint: .blue, percentage: false).frame(height: 150)
            }.padding(6).cardSurface()
            informationCard("网络采样", rows: [("下载", rateString(monitor.download)), ("上传", rateString(monitor.upload)), ("统计范围", "Wi-Fi 与以太网物理接口"), ("历史记录", "最近 5 分钟，仅保留在内存中")])
        case .storage:
            storageCard
            informationCard("磁盘空间", rows: [("总容量", byteString(monitor.diskTotal)), ("已使用", byteString(monitor.diskTotal - monitor.diskFree)), ("可用空间", byteString(monitor.diskFree))])
            Text("可用空间不包含系统可清除缓存，可能与系统设置显示的数值不同。").font(.caption).foregroundStyle(.secondary)
        case .power:
            PowerSummaryView(monitor: monitor)
            TemperatureSensorsView(monitor: monitor)
            DisclosureGroup("电源信息") {
                informationCard("电源状态", rows: [("电量", monitor.battery.map { "\(Int($0))%" } ?? "此设备没有内置电池"), ("供电方式", monitor.onAC ? "交流电源" : "电池"), ("充电状态", monitor.charging ? "正在充电" : "未充电"), ("系统温控", monitor.thermalDescription)])
                    .padding(.top, 8)
            }.font(.subheadline)
        case .overview: EmptyView()
        }
    }

    private func informationCard(_ title: String, rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).font(.system(size: 14, weight: .semibold)).padding(.bottom, 12)
            ForEach(rows.indices, id: \.self) { index in
                if index > 0 { Divider() }
                HStack {
                    Text(rows[index].0).foregroundStyle(.secondary)
                    Spacer()
                    Text(rows[index].1).textSelection(.enabled)
                }.font(.system(size: 12)).padding(.vertical, 13)
            }
        }.padding(6).cardSurface()
    }
}

struct HistoryChart: View {
    let samples: [MetricSample]
    let value: KeyPath<MetricSample, Double>
    let tint: Color
    let percentage: Bool

    var body: some View {
        Chart(samples) { sample in
            AreaMark(x: .value("时间", sample.date), yStart: .value("基线", 0), yEnd: .value("数值", sample[keyPath: value]))
                .foregroundStyle(tint.opacity(0.08))
                .interpolationMethod(.linear)
            LineMark(x: .value("时间", sample.date), y: .value("数值", sample[keyPath: value]))
                .foregroundStyle(tint).lineStyle(StrokeStyle(lineWidth: 1.7, lineCap: .round))
                .interpolationMethod(.linear)
        }
        .chartYScale(domain: 0...(percentage ? 100 : max(1024, (samples.map { $0[keyPath: value] }.max() ?? 0) * 1.15)))
        .chartXAxis(.hidden).chartYAxis(.hidden)
        .background(alignment: .center) {
            VStack { Divider(); Spacer(); Divider(); Spacer(); Divider() }.opacity(0.35)
        }
        .accessibilityLabel("\(percentage ? "使用率" : "传输速率")历史图表，共 \(samples.count) 个采样点")
    }
}

private struct CardSurface: ViewModifier {
    func body(content: Content) -> some View {
        GroupBox {
            content.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

extension View {
    fileprivate func cardSurface() -> some View { modifier(CardSurface()) }
}

private func transferValue(_ title: String, symbol: String, value: Double, tint: Color) -> some View {
    VStack(alignment: .leading, spacing: 7) {
        Label(title, systemImage: symbol).font(.caption).foregroundStyle(tint)
        Text(rateString(value)).font(.title3).monospacedDigit()
    }
}

struct MonitorPopover: View {
    let monitor: SystemMonitor
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "waveform.path").foregroundStyle(.blue)
                Text("Dore").font(.headline)
                Spacer()
                Text(monitor.paused ? "已暂停" : "实时监控").font(.caption).foregroundStyle(.secondary)
                Circle().fill(monitor.paused ? .orange : .green).frame(width: 6, height: 6)
            }
            HStack(spacing: 12) {
                miniMetric("CPU", value: monitor.cpu, tint: .blue, key: \.cpu)
                miniMetric("内存", value: monitor.memoryPercent, tint: .purple, key: \.memory)
            }
            HStack {
                transferValue("下载", symbol: "arrow.down", value: monitor.download, tint: .teal)
                Spacer()
                transferValue("上传", symbol: "arrow.up", value: monitor.upload, tint: .blue)
            }.padding(4).cardSurface()
            HStack {
                Label("可用空间", systemImage: "internaldrive").foregroundStyle(.secondary)
                Spacer()
                Text(byteString(monitor.diskFree)).monospacedDigit()
            }.font(.system(size: 12))
            HStack {
                Label(monitor.battery == nil ? "交流电源" : "电池", systemImage: "bolt.fill").foregroundStyle(.secondary)
                Spacer()
                Text(monitor.battery.map { "\(Int($0))%" } ?? "已连接")
                Text("· 温控\(monitor.thermalDescription)").foregroundStyle(.secondary)
            }.font(.system(size: 12))
            HStack {
                Label("整机功耗", systemImage: "bolt.circle").foregroundStyle(.secondary)
                Spacer()
                if let watts = monitor.systemPower {
                    Text(String(format: "%.1f W", watts)).monospacedDigit()
                } else {
                    Text("暂不可用").foregroundStyle(.secondary)
                }
            }.font(.system(size: 12))
            CompactHardwareView(monitor: monitor)
            CompactTemperaturesView(monitor: monitor)
            Divider()
            HStack {
                Button {
                    openWindow(id: "dashboard")
                    NSApp.activate(ignoringOtherApps: true)
                    dismiss()
                } label: { Label("打开仪表盘", systemImage: "macwindow") }
                .buttonStyle(.borderless)
                Spacer()
                Button { monitor.togglePause() } label: { Image(systemName: monitor.paused ? "play" : "pause") }
                    .help(monitor.paused ? "继续监控" : "暂停监控")
                SettingsLink { Image(systemName: "gearshape") }.help("设置")
                Button { NSApp.terminate(nil) } label: { Image(systemName: "power") }.help("退出 Dore")
            }.buttonStyle(.borderless).font(.system(size: 12))
        }.padding(16).frame(width: 350)
    }

    private func miniMetric(_ title: String, value: Double, tint: Color, key: KeyPath<MetricSample, Double>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 11, weight: .medium)).foregroundStyle(tint)
            Text("\(Int(value))%").font(.system(size: 22, weight: .regular)).monospacedDigit()
            HistoryChart(samples: Array(monitor.samples.suffix(30)), value: key, tint: tint, percentage: true).frame(height: 42)
        }.padding(4).cardSurface()
    }
}

struct MonitorSettings: View {
    @AppStorage("refreshInterval") private var refreshInterval = 2.0
    @AppStorage("menuBarLayout") private var menuMetric = "全部"
    @AppStorage("appearance") private var appearance = "system"

    var body: some View {
        Form {
            Section("监控") {
                Picker("更新频率", selection: $refreshInterval) {
                    Text("每秒").tag(1.0)
                    Text("每 2 秒").tag(2.0)
                    Text("每 5 秒").tag(5.0)
                }
                Picker("菜单栏显示", selection: $menuMetric) {
                    Text("CPU 曲线、内存与温度").tag("全部")
                    Text("CPU 曲线").tag("CPU")
                    Text("内存使用率").tag("内存")
                    Text("整机功耗（W）").tag("功耗")
                    Text("仅图标").tag("图标")
                }
            }
            Section("外观") {
                Picker("主题", selection: $appearance) {
                    Text("跟随系统").tag("system")
                    Text("浅色").tag("light")
                    Text("深色").tag("dark")
                }
            }
            Section {
                Text("数据仅在本地采集，历史记录在退出后清除。")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }.formStyle(.grouped).padding(10).frame(width: 430, height: 320)
    }
}

#Preview("总览") {
    let monitor = SystemMonitor()
    ContentView(monitor: monitor)
        .frame(width: 960, height: 680)
        .task { monitor.start() }
}

#Preview("菜单栏") {
    let monitor = SystemMonitor()
    MonitorPopover(monitor: monitor)
        .task { monitor.start() }
}
