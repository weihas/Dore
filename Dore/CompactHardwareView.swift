import SwiftUI

struct CompactHardwareView: View {
    let monitor: SystemMonitor

    var body: some View {
        VStack(spacing: 9) {
            HStack {
                Label(L("CPU Power"), systemImage: "cpu").foregroundStyle(.secondary)
                Spacer()
                power(monitor.hardware.cpuPower)
                Text("·").foregroundStyle(.tertiary)
                Text("GPU").foregroundStyle(.secondary)
                power(monitor.hardware.gpuPower)
            }
            ForEach(monitor.hardware.fans) { fan in
                HStack {
                    Label(fan.name, systemImage: "fan").foregroundStyle(.secondary)
                    Spacer()
                    if let rpm = fan.rpm {
                        Text(String(format: "%.0f RPM", locale: .current, rpm)).monospacedDigit()
                    } else {
                        Text(L("Unavailable")).foregroundStyle(.secondary)
                    }
                }
            }
        }.font(.system(size: 12))
    }

    @ViewBuilder private func power(_ watts: Double?) -> some View {
        if let watts {
            Text(String(format: "%.2f W", locale: .current, watts)).monospacedDigit()
        } else {
            Text(L("Unavailable")).foregroundStyle(.secondary)
        }
    }
}
