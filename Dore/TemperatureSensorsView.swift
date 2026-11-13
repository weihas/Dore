import SwiftUI

private extension TemperatureGroup {
    var symbol: String {
        switch self {
        case .cpu: "cpu"
        case .gpu: "square.3.layers.3d"
        case .memory: "memorychip"
        case .storage: "internaldrive"
        case .airflow: "wind"
        case .other: "sensor"
        }
    }
    var tint: Color {
        switch self {
        case .cpu: .blue
        case .gpu: .purple
        case .memory: .teal
        case .storage: .orange
        case .airflow: .cyan
        case .other: .secondary
        }
    }
}

struct TemperatureSensorsView: View {
    let monitor: SystemMonitor
    @State private var search = ""
    @State private var hottestFirst = false
    @State private var expanded: Set<TemperatureGroup> = []

    private func readings(_ group: TemperatureGroup) -> [TemperatureSensor] {
        monitor.temperatureSensors.filter {
            $0.group == group && (search.isEmpty || $0.id.localizedCaseInsensitiveContains(search) ||
                $0.name.localizedCaseInsensitiveContains(search) || $0.group.rawValue.localizedCaseInsensitiveContains(search))
        }.sorted { hottestFirst && $0.value != $1.value ? $0.value > $1.value : $0.id < $1.id }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("温度概览").font(.title2.weight(.semibold))
                    Text("硬件温度与实时传感器读数").font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Label(monitor.paused ? "已暂停" : "实时", systemImage: monitor.paused ? "pause.circle" : "waveform.path")
                    .font(.caption).foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                ForEach([TemperatureGroup.cpu, .gpu, .memory]) { group in
                    let values = monitor.temperatureSensors.filter { $0.group == group }
                    if !values.isEmpty { overview(group, sensors: values) }
                }
            }
            HStack {
                Text("传感器").font(.headline)
                Text("\(monitor.temperatureSensors.count)").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("搜索", text: $search).textFieldStyle(.plain)
                    if !search.isEmpty {
                        Button { search = "" } label: { Image(systemName: "xmark.circle.fill") }
                            .buttonStyle(.plain).foregroundStyle(.secondary).help("清除搜索")
                    }
                }.padding(.horizontal, 9).padding(.vertical, 6)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 7))
                    .frame(width: 160)
                Menu {
                    Picker("排序", selection: $hottestFirst) {
                        Text("按标识排序").tag(false)
                        Text("高温优先").tag(true)
                    }
                    Divider()
                    Button("展开全部") { expanded = Set(TemperatureGroup.allCases) }
                    Button("收起全部") { expanded = [] }
                } label: { Image(systemName: "line.3.horizontal.decrease") }
                    .menuStyle(.borderlessButton).fixedSize().help("排序与展开")
            }
            LazyVStack(spacing: 10) {
                ForEach(TemperatureGroup.allCases) { group in
                    let sensors = readings(group)
                    if !sensors.isEmpty { sensorGroup(group, sensors: sensors) }
                }
            }
            if TemperatureGroup.allCases.allSatisfy({ readings($0).isEmpty }) {
                ContentUnavailableView(search.isEmpty ? "暂无温度读数" : "没有匹配的传感器",
                    systemImage: "thermometer.medium",
                    description: Text(search.isEmpty ? monitor.temperatureDiagnostic : "尝试搜索硬件名称或传感器标识。"))
            }
            Text("概览显示各组平均温度。展开分组查看当前值与本次最高值；未知通道保留原始标识。")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func overview(_ group: TemperatureGroup, sensors: [TemperatureSensor]) -> some View {
        let average = sensors.map(\.value).reduce(0, +) / Double(sensors.count)
        return VStack(alignment: .leading, spacing: 14) {
            Label(group.rawValue, systemImage: group.symbol)
                .font(.subheadline.weight(.medium)).foregroundStyle(group.tint)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(average, format: .number.precision(.fractionLength(1)))
                    .font(.system(size: 28, weight: .medium)).monospacedDigit()
                Text("°C").font(.body).foregroundStyle(.secondary)
            }
            HStack {
                Text("平均温度")
                Spacer()
                Text("\(sensors.count) 个")
            }.font(.caption).foregroundStyle(.secondary)
        }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
            .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(.primary.opacity(0.06)) }
    }

    private func sensorGroup(_ group: TemperatureGroup, sensors: [TemperatureSensor]) -> some View {
        let isExpanded = expanded.contains(group) || !search.isEmpty
        let average = sensors.map(\.value).reduce(0, +) / Double(sensors.count)
        return VStack(spacing: 0) {
            Button {
                if expanded.contains(group) { expanded.remove(group) } else { expanded.insert(group) }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: group.symbol).font(.system(size: 17)).foregroundStyle(group.tint)
                        .frame(width: 32, height: 32)
                        .background(group.tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(group.rawValue).font(.subheadline.weight(.semibold))
                        Text("\(sensors.count) 个传感器").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(String(format: "%.1f °C", average)).monospacedDigit().font(.subheadline)
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary).frame(width: 12)
                }.padding(14).contentShape(Rectangle())
            }.buttonStyle(.plain).accessibilityLabel("\(group.rawValue)，\(sensors.count) 个传感器，\(isExpanded ? "收起" : "展开")")
            if isExpanded {
                Divider().padding(.horizontal, 14)
                HStack {
                    Text("传感器标识")
                    Spacer()
                    Text("当前 / 本次最高")
                }.font(.caption).foregroundStyle(.secondary).padding(.horizontal, 16).padding(.top, 12)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 24), GridItem(.flexible())], spacing: 0) {
                    ForEach(sensors) { sensor in
                        HStack(spacing: 8) {
                            Text(sensor.id).font(.system(.caption, design: .monospaced)).foregroundStyle(.secondary)
                            Spacer(minLength: 0)
                            Text(String(format: "%.1f°", sensor.value)).monospacedDigit()
                            Text(String(format: "/ %.1f°", sensor.peak)).monospacedDigit().foregroundStyle(.tertiary)
                        }.font(.system(size: 12)).padding(.vertical, 10)
                            .help("\(sensor.name) · \(sensor.id)")
                            .overlay(alignment: .bottom) { Divider().opacity(0.4) }
                    }
                }.padding(.horizontal, 16).padding(.bottom, 10)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(.primary.opacity(0.06)) }
    }
}

struct CompactTemperaturesView: View {
    let monitor: SystemMonitor

    var body: some View {
        DisclosureGroup {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(TemperatureGroup.allCases) { group in
                        let sensors = monitor.temperatureSensors.filter { $0.group == group }
                        if !sensors.isEmpty {
                            Text(group.rawValue).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                            ForEach(sensors) { sensor in
                                HStack {
                                    Text(sensor.id).font(.system(.caption, design: .monospaced))
                                    Spacer()
                                    Text(String(format: "%.1f °C", sensor.value)).monospacedDigit()
                                }.font(.caption).help(sensor.name)
                            }
                            Divider()
                        }
                    }
                }.padding(.trailing, 8).padding(.top, 8)
            }.frame(height: 220)
        } label: {
            HStack {
                Label("全部温度", systemImage: "thermometer.medium")
                Spacer()
                Text("\(monitor.temperatureSensors.count) 个").foregroundStyle(.secondary)
            }.font(.system(size: 12))
        }
    }
}

#Preview("温度传感器") {
    // Fixed preview-only readings; production always uses the XPC service.
    let monitor: SystemMonitor = {
        let monitor = SystemMonitor()
        monitor.temperatureSensors = [
            TemperatureSensor(id: "Tp00", value: 36.7, peak: 42.6),
            TemperatureSensor(id: "Tp04", value: 35.8, peak: 39.8),
            TemperatureSensor(id: "Tg08", value: 33.1, peak: 35.2),
            TemperatureSensor(id: "Tm00", value: 34.9, peak: 36.1),
            TemperatureSensor(id: "TH0x", value: 30, peak: 30.2),
            TemperatureSensor(id: "TaFL", value: 30.6, peak: 31.0),
            TemperatureSensor(id: "TVD0", value: 45.4, peak: 46.0)
        ]
        return monitor
    }()
    ScrollView {
        TemperatureSensorsView(monitor: monitor).padding(24)
    }.frame(width: 720, height: 680)
        .background(Color(nsColor: .windowBackgroundColor))
}
