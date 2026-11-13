import SwiftUI

struct PowerSummaryView: View {
    let monitor: SystemMonitor

    var body: some View {
        VStack(spacing: 14) {
            systemPower
            GroupBox {
                HStack(spacing: 24) {
                    componentPower("CPU", symbol: "cpu", watts: monitor.hardware.cpuPower)
                    Divider().frame(height: 54)
                    componentPower("GPU", symbol: "square.3.layers.3d", watts: monitor.hardware.gpuPower)
                }.padding(10)
            }
            .help("CPU 与 GPU 功耗由硬件能量计数换算，为采样间隔内的平均瓦数；不包含整机全部部件。")
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("风扇转速", systemImage: "fan").font(.headline)
                        Spacer()
                        Text(monitor.paused ? "已暂停" : "实时转速")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if monitor.hardware.fans.isEmpty {
                        Text(monitor.hardware.fanCount == 0 ? "此设备没有风扇" : "暂时无法读取风扇")
                            .font(.subheadline).foregroundStyle(.secondary)
                    } else {
                        ForEach(monitor.hardware.fans) { fan in
                            if fan.id > 0 { Divider() }
                            fanRow(fan)
                        }
                    }
                }.padding(10).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func componentPower(_ title: String, symbol: String, watts: Double?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol).font(.subheadline).foregroundStyle(.secondary)
            if let watts {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(watts, format: .number.precision(.fractionLength(2)))
                        .font(.system(size: 26, weight: .medium)).monospacedDigit()
                    Text("W").foregroundStyle(.secondary)
                }
            } else {
                Text("暂不可用").font(.subheadline).foregroundStyle(.secondary)
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private func fanRow(_ fan: FanReading) -> some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                Text(fan.name).font(.subheadline)
                if let maximum = fan.maximum, maximum > 0 {
                    Text(String(format: "最高转速 %.0f RPM", maximum))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let rpm = fan.rpm {
                if let maximum = fan.maximum, maximum > 0 {
                    ProgressView(value: min(rpm, maximum), total: maximum)
                        .frame(width: 100).tint(.secondary)
                        .accessibilityLabel("\(fan.name)转速占最大转速的比例")
                }
                Text(String(format: "%.0f RPM", rpm)).monospacedDigit()
                    .frame(minWidth: 82, alignment: .trailing)
            } else {
                Text("暂不可用").foregroundStyle(.secondary)
            }
        }.padding(.vertical, 3)
    }

    private var systemPower: some View {
        HStack(spacing: 16) {
            Image(systemName: "bolt.fill")
                .font(.title2).foregroundStyle(.orange)
                .frame(width: 44, height: 44)
                .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text("整机功耗").font(.headline)
                Text(monitor.paused ? "采样已暂停" : "实时硬件读数")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if let watts = monitor.systemPower {
                VStack(alignment: .trailing, spacing: 5) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(watts, format: .number.precision(.fractionLength(1)))
                            .font(.system(size: 28, weight: .medium)).monospacedDigit()
                        Text("W").font(.body).foregroundStyle(.secondary)
                    }
                    Text(String(format: "本次最高 %.1f W", monitor.powerPeak))
                        .font(.caption).foregroundStyle(.secondary).monospacedDigit()
                }
            } else {
                Text("暂不可用").foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
        .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(.primary.opacity(0.06)) }
        .help("AppleSMC PSTR 整机功耗，不等同于插座侧测量值或充电器额定功率。")
    }
}

#Preview("实时功耗") {
    let monitor: SystemMonitor = {
        let monitor = SystemMonitor()
        monitor.systemPower = 22.3
        monitor.powerPeak = 35.8
        monitor.hardware = HardwareMetrics(values: ["CPU Power": 4.82, "GPU Power": 1.36,
            "FNum": 2, "F0Ac": 1000, "F0Mx": 3625, "F1Ac": 1000, "F1Mx": 3625])
        return monitor
    }()
    PowerSummaryView(monitor: monitor).padding().frame(width: 600)
}
