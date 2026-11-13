import SwiftUI

@main
struct DoreApp: App {
    @State private var monitor = SystemMonitor()
    @AppStorage("menuBarLayout") private var menuMetric = "全部"
    @AppStorage("appearance") private var appearance = "system"

    private var colorScheme: ColorScheme? {
        appearance == "light" ? .light : appearance == "dark" ? .dark : nil
    }

    var body: some Scene {
        Window("Dore", id: "dashboard") {
            ContentView(monitor: monitor)
                .preferredColorScheme(colorScheme)
                .task { monitor.start() }
        }
        .defaultSize(width: 1080, height: 780)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }

        MenuBarExtra {
            MonitorPopover(monitor: monitor)
                .preferredColorScheme(colorScheme)
                .task { monitor.start() }
        } label: {
            if menuMetric == "功耗" {
                Image(systemName: "bolt.fill")
                Text(monitor.systemPower.map { String(format: "%.1f W", locale: .current, $0) } ?? L("Power unavailable"))
            } else if menuMetric == "图标" {
                Image(systemName: "waveform.path")
            } else {
                Image(nsImage: MenuBarMetrics(monitor: monitor, layout: menuMetric).image)
                    .accessibilityLabel(MenuBarMetrics(monitor: monitor, layout: menuMetric).accessibilityDescription)
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            MonitorSettings()
                .preferredColorScheme(colorScheme)
        }
    }
}
