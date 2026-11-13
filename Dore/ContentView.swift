import SwiftUI
import Charts
import AppKit

enum MonitorSection: String, CaseIterable, Identifiable {
    case overview = "总览", cpu = "处理器", memory = "内存", network = "网络", storage = "存储", power = "电源", thermal = "散热"
    var id: String { rawValue }
    var title: String {
        switch self {
        case .overview: L("Overview")
        case .cpu: L("Processor")
        case .memory: L("Memory")
        case .network: L("Network")
        case .storage: L("Storage")
        case .power: L("Power")
        case .thermal: L("Thermals")
        }
    }
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
                Section(L("Monitoring")) {
                    ForEach(MonitorSection.allCases) { section in
                        Label(section.title, systemImage: section.symbol)
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
            .navigationTitle(Text(verbatim: selection.title))
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    if [.overview, .cpu, .memory, .network].contains(selection) {
                        Picker(L("Time Range"), selection: $period) {
                            Text(L("1 minute")).tag(60)
                            Text(L("5 minutes")).tag(300)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .frame(width: 140)
                        .help(L("Chart time range"))
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { monitor.togglePause() } label: {
                        Label(monitor.paused ? L("Resume Monitoring") : L("Pause Monitoring"), systemImage: monitor.paused ? "play" : "pause")
                    }
                    .help(monitor.paused ? L("Resume Monitoring") : L("Pause Monitoring"))
                }
                ToolbarItem(placement: .primaryAction) {
                    SettingsLink { Label(L("Settings"), systemImage: "gearshape") }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    Divider()
                    HStack {
                        Text(monitor.paused ? L("Monitoring paused") : L("Live updates"))
                        Spacer()
                        Text(L("Data stays on this Mac"))
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
                Text(monitor.battery.map { L("Battery %@%%", String(Int($0))) } ?? L("Connected to AC Power")).font(.system(size: 12, weight: .semibold))
                Text(monitor.charging ? L("Charging") : monitor.onAC ? L("Power connected") : L("Running on battery")).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if let watts = monitor.systemPower {
                Text(String(format: "%.1f W", locale: .current, watts)).font(.subheadline).monospacedDigit()
                    .help(L("System Power"))
            }
            Button { selection = .thermal } label: {
                Label(L("Thermal: %@", String(monitor.thermalDescription)), systemImage: "thermometer.medium")
            }.buttonStyle(.borderless).font(.system(size: 11)).help(L("View thermal details"))
            Divider().frame(height: 24).padding(.horizontal, 8)
            Button(L("Power Details")) { selection = .power }.buttonStyle(.borderless).font(.system(size: 11))
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
            informationCard(L("Power Information"), rows: [(L("Battery Level"), monitor.battery.map { "\(Int($0))%" } ?? L("No built-in battery")), (L("Power Source"), monitor.onAC ? L("AC Power") : L("Battery")), (L("Charging Status"), monitor.charging ? L("Charging") : L("Not Charging"))])
        case .thermal:
            DorePageHeading(title: L("Thermals"), subtitle: L("Temperatures, fans and thermal state"))
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
            AreaMark(x: .value(L("Time"), sample.date), yStart: .value(L("Baseline"), 0), yEnd: .value(L("Value"), sample[keyPath: value]))
                .foregroundStyle(LinearGradient(colors: [tint.opacity(0.22), tint.opacity(0.01)], startPoint: .top, endPoint: .bottom))
                .interpolationMethod(.linear)
            LineMark(x: .value(L("Time"), sample.date), y: .value(L("Value"), sample[keyPath: value]))
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
        .accessibilityLabel(L("%@ history, samples: %@", String(percentage ? L("Usage") : L("Transfer rate")), String(samples.count)))
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
                Text(monitor.paused ? L("Paused") : L("Live monitoring")).font(.caption).foregroundStyle(.secondary)
                Circle().fill(monitor.paused ? .orange : .green).frame(width: 6, height: 6)
            }
            HStack(spacing: 12) {
                miniMetric("CPU", value: monitor.cpu, tint: DoreStyle.accent, key: \.cpu)
                miniMetric(L("Memory"), value: monitor.memoryPercent, tint: DoreStyle.secondary, key: \.memory)
            }
            HStack {
                transferValue(L("Download"), symbol: "arrow.down", value: monitor.download, tint: .teal)
                Spacer()
                transferValue(L("Upload"), symbol: "arrow.up", value: monitor.upload, tint: .blue)
            }.padding(4).cardSurface()
            HStack {
                Label(L("Available Space"), systemImage: "internaldrive").foregroundStyle(.secondary)
                Spacer()
                Text(byteString(monitor.diskFree)).monospacedDigit()
            }.font(.system(size: 12))
            HStack {
                Label(monitor.battery == nil ? L("AC Power") : L("Battery"), systemImage: "bolt.fill").foregroundStyle(.secondary)
                Spacer()
                Text(monitor.battery.map { "\(Int($0))%" } ?? L("Connected"))
                Text(L("· Thermal: %@", String(monitor.thermalDescription))).foregroundStyle(.secondary)
            }.font(.system(size: 12))
            HStack {
                Label(L("System Power"), systemImage: "bolt.circle").foregroundStyle(.secondary)
                Spacer()
                if let watts = monitor.systemPower {
                    Text(String(format: "%.1f W", locale: .current, watts)).monospacedDigit()
                } else {
                    Text(L("Unavailable")).foregroundStyle(.secondary)
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
                } label: { Label(L("Open Dashboard"), systemImage: "macwindow") }
                .buttonStyle(.borderless)
                Spacer()
                Button { monitor.togglePause() } label: { Image(systemName: monitor.paused ? "play" : "pause") }
                    .help(monitor.paused ? L("Resume Monitoring") : L("Pause Monitoring"))
                SettingsLink { Image(systemName: "gearshape") }.help(L("Settings"))
                Button { NSApp.terminate(nil) } label: { Image(systemName: "power") }.help(L("Quit Dore"))
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
            DorePageHeading(title: L("Preferences"), subtitle: L("Make Dore work your way"))
                .padding(.horizontal, 26).padding(.top, 20)
        Form {
            Section(L("Monitoring")) {
                Picker(L("Refresh Interval"), selection: $refreshInterval) {
                    Text(L("Every second")).tag(1.0)
                    Text(L("Every 2 seconds")).tag(2.0)
                    Text(L("Every 5 seconds")).tag(5.0)
                }
                Picker(L("Menu Bar"), selection: $menuMetric) {
                    Text(L("CPU, Memory & Temperature")).tag("全部")
                    Text(L("CPU Graph")).tag("CPU")
                    Text(L("Memory Usage")).tag("内存")
                    Text(L("System Power (W)")).tag("功耗")
                    Text(L("Icon Only")).tag("图标")
                }
            }
            Section(L("Appearance")) {
                Picker(L("Theme"), selection: $appearance) {
                    Text(L("System")).tag("system")
                    Text(L("Light")).tag("light")
                    Text(L("Dark")).tag("dark")
                }
            }
            Section {
                Text(L("Data is collected locally. History is cleared when Dore quits."))
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
