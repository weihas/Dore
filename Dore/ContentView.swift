import SwiftUI
import Charts
import AppKit

enum MonitorSection: String, CaseIterable, Identifiable {
    case overview = "总览", cpu = "处理器", memory = "内存", network = "网络", storage = "存储", power = "电源", thermal = "散热"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .overview: "square.grid.2x2"
        case .cpu: "cpu"
        case .memory: "memorychip"
        case .network: "network"
        case .storage: "internaldrive"
        case .power: "bolt.fill"
        case .thermal: "thermometer.medium"
        }
    }
    var tint: Color {
        switch self {
        case .overview, .cpu: DoreStyle.accent
        case .memory: DoreStyle.secondary
        case .network: DoreStyle.accent
        case .storage: DoreStyle.amber
        case .power: DoreStyle.accent
        case .thermal: DoreStyle.amber
        }
    }

}

struct ContentView: View {
    let monitor: SystemMonitor
    @State private var selection: MonitorSection = .overview
    @State private var period = 60

    init(monitor: SystemMonitor, initialSection: MonitorSection = .overview) {
        self.monitor = monitor
        _selection = State(initialValue: initialSection)
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("监控") {
                    ForEach(MonitorSection.allCases) { section in
                        Label(section.rawValue, systemImage: section.symbol)
                            .padding(.vertical, 4)
                            .tag(section)
                    }
                }
            }
            .listStyle(.sidebar)
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    HStack(spacing: 10) {
                        Image(systemName: "waveform.path").foregroundStyle(.secondary)
                        Text("Dore").font(.headline).foregroundStyle(.secondary)
                        Spacer()
                    }.padding(.vertical, 8)
                }.font(.caption).foregroundStyle(.secondary).padding(18)
            }
            .navigationTitle("Dore")
            .navigationSplitViewColumnWidth(min: 170, ideal: 190, max: 240)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if selection == .overview {
                        OverviewDashboardView(monitor: monitor, samples: visibleSamples) { selection = $0 }
                        powerStrip
                    } else {
                        detailContent
                    }
                }
                .padding(22)
                .frame(maxWidth: 960)
                .frame(maxWidth: .infinity)
            }
            .background(DoreBackdrop())
            .navigationTitle(selection.rawValue)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    if [.overview, .cpu, .memory, .network].contains(selection) {
                        Picker("时间范围", selection: $period) {
                            Text("1 分钟").tag(60)
                            Text("5 分钟").tag(300)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .frame(width: 140)
                        .help("图表时间范围")
                    }
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
        .frame(minWidth: 900, minHeight: 640)
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
            Button { selection = .thermal } label: {
                Label("温控\(monitor.thermalDescription)", systemImage: "thermometer.medium")
            }.buttonStyle(.borderless).font(.system(size: 11)).help("查看散热详情")
            Divider().frame(height: 24).padding(.horizontal, 8)
            Button("电源详情") { selection = .power }.buttonStyle(.borderless).font(.system(size: 11))
        }.dashboardSurface()
    }

    private var visibleSamples: [MetricSample] {
        let end = monitor.samples.last?.date ?? Date()
        return monitor.samples.filter { end.timeIntervalSince($0.date) <= Double(period) }
    }

    @ViewBuilder private var detailContent: some View {
        switch selection {
        case .cpu, .memory, .network, .storage:
            HardwareDetailView(monitor: monitor, section: selection, samples: visibleSamples, period: period)
        case .power:
            PowerSummaryView(monitor: monitor)
            informationCard("供电信息", rows: [("电量", monitor.battery.map { "\(Int($0))%" } ?? "此设备没有内置电池"), ("供电方式", monitor.onAC ? "交流电源" : "电池"), ("充电状态", monitor.charging ? "正在充电" : "未充电")])
        case .thermal:
            DorePageHeading(title: "散热", subtitle: "温度、风扇与系统热状态")
            FanSpeedView(monitor: monitor)
            TemperatureSensorsView(monitor: monitor)
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
        }.dashboardSurface()
    }
}

struct HistoryChart: View {
    let samples: [MetricSample]
    let value: KeyPath<MetricSample, Double>
    let tint: Color
    let percentage: Bool
    var showsAxes = false

    var body: some View {
        Chart(samples) { sample in
            AreaMark(x: .value("时间", sample.date), yStart: .value("基线", 0), yEnd: .value("数值", sample[keyPath: value]))
                .foregroundStyle(LinearGradient(colors: [tint.opacity(0.22), tint.opacity(0.01)], startPoint: .top, endPoint: .bottom))
                .interpolationMethod(.linear)
            LineMark(x: .value("时间", sample.date), y: .value("数值", sample[keyPath: value]))
                .foregroundStyle(tint).lineStyle(StrokeStyle(lineWidth: 1.7, lineCap: .round))
                .interpolationMethod(.linear)
        }
        .chartYScale(domain: 0...(percentage ? 100 : max(1024, (samples.map { $0[keyPath: value] }.max() ?? 0) * 1.15)))
        .chartXAxis(showsAxes ? .automatic : .hidden)
        .chartYAxis {
            if showsAxes {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 4]))
                        .foregroundStyle(Color.primary.opacity(0.08))
                    AxisValueLabel {
                        if let number = value.as(Double.self) {
                            Text(percentage ? "\(Int(number))%" : rateString(number))
                                .font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .background(alignment: .center) {
            VStack { Divider(); Spacer(); Divider(); Spacer(); Divider() }.opacity(showsAxes ? 0 : 0.20)
        }
        .accessibilityLabel("\(percentage ? "使用率" : "传输速率")历史图表，共 \(samples.count) 个采样点")
    }
}

private struct CardSurface: ViewModifier {
    func body(content: Content) -> some View {
        content.dashboardSurface(inset: 12)
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
                Image(systemName: "waveform.path").foregroundStyle(DoreStyle.accent)
                Text("Dore").font(.headline)
                Spacer()
                Text(monitor.paused ? "已暂停" : "实时监控").font(.caption).foregroundStyle(.secondary)
                Circle().fill(monitor.paused ? .orange : .green).frame(width: 6, height: 6)
            }
            HStack(spacing: 12) {
                miniMetric("CPU", value: monitor.cpu, tint: DoreStyle.accent, key: \.cpu)
                miniMetric("内存", value: monitor.memoryPercent, tint: DoreStyle.secondary, key: \.memory)
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
        VStack(alignment: .leading, spacing: 0) {
            DorePageHeading(title: "偏好设置", subtitle: "按照你的习惯调整 Dore")
                .padding(.horizontal, 26).padding(.top, 20)
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
        }.formStyle(.grouped).scrollContentBackground(.hidden)
        }.frame(width: 480, height: 440).background(DoreBackdrop()).tint(DoreStyle.accent)
    }
}

#Preview("总览") { DashboardDesignPreview(section: .overview) }
#Preview("处理器") { DashboardDesignPreview(section: .cpu) }
#Preview("内存") { DashboardDesignPreview(section: .memory) }
#Preview("网络") { DashboardDesignPreview(section: .network) }
#Preview("存储") { DashboardDesignPreview(section: .storage) }
#Preview("电源") { DashboardDesignPreview(section: .power) }
#Preview("散热") { DashboardDesignPreview(section: .thermal) }
#Preview("设置") { MonitorSettings() }
#Preview("菜单栏") { MonitorPopover(monitor: SystemMonitor()) }

/// Deterministic preview data; the running app continues to use SystemMonitor's hardware sampling.
private struct DashboardDesignPreview: View {
    let section: MonitorSection
    var width: CGFloat = 1080
    @State private var monitor: SystemMonitor = {
        let monitor = SystemMonitor()
        monitor.cpu = 24.6
        monitor.memoryUsed = monitor.memoryTotal * 0.64
        monitor.memoryWired = monitor.memoryTotal * 0.15
        monitor.memoryCompressed = monitor.memoryTotal * 0.23
        monitor.diskTotal = 1_000_000_000_000
        monitor.diskFree = 730_000_000_000
        monitor.download = 2_500_000
        monitor.upload = 180_000
        monitor.lastUpdated = Date()
        monitor.systemPower = 28.4
        monitor.powerPeak = 42.7
        monitor.hardware = HardwareMetrics(values: ["CPU Power": 8.4, "GPU Power": 2.1, "GPU Utilization": 18,
            "FNum": 2, "F0Ac": 1100, "F0Mx": 3600, "F1Ac": 1050, "F1Mx": 3600])
        monitor.temperatureSensors = [TemperatureSensor(id: "Tp00", value: 42, peak: 48),
            TemperatureSensor(id: "Tg08", value: 38, peak: 44), TemperatureSensor(id: "Tm00", value: 35, peak: 38)]
        let end = Date()
        monitor.samples = (0..<60).map { i in
            let wave = abs(sin(Double(i) * 0.24))
            return MetricSample(date: end.addingTimeInterval(Double(i - 59)), cpu: 12 + wave * 26,
                memory: 61 + wave * 3, download: 500_000 + wave * 2_000_000, upload: 20_000 + wave * 160_000)
        }
        return monitor
    }()
    var body: some View {
        ContentView(monitor: monitor, initialSection: section).frame(width: width, height: 820)
    }
}

#Preview("紧凑窗口") { DashboardDesignPreview(section: .overview, width: 900) }
