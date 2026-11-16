import AppKit
import SwiftUI

/// Independently sized metrics, arranged in the order supplied to MenuBarMetrics.
enum MenuBarMetricItem: Hashable {
    case cpuGraph
    case memory
    case cpuTemperature

    fileprivate var width: CGFloat {
        switch self {
        case .cpuGraph: 45
        case .memory: 56
        case .cpuTemperature: 37
        }
    }

    /// Compatibility with the persisted menu bar layout preference.
    static func items(for layout: String) -> [Self] {
        switch layout {
        case "CPU": [.cpuGraph]
        case "内存": [.memory]
        default: [.cpuGraph, .memory, .cpuTemperature]
        }
    }
}

/// Composes a template image so macOS supplies the correct menu bar tint.
@MainActor
struct MenuBarMetrics {
    let monitor: SystemMonitor
    let items: [MenuBarMetricItem]
    private let spacing: CGFloat = 8

    init(monitor: SystemMonitor, items: [MenuBarMetricItem]) {
        self.monitor = monitor
        self.items = items
    }

    init(monitor: SystemMonitor, layout: String) {
        self.init(monitor: monitor, items: MenuBarMetricItem.items(for: layout))
    }

    private var visibleItems: [MenuBarMetricItem] {
        items.filter { $0 != .cpuTemperature || monitor.cpuTemperature != nil }
    }

    var image: NSImage {
        // Capture readings before NSImage's deferred drawing closure runs.
        let components = visibleItems.map { $0.component(monitor: monitor) }
        let width = components.reduce(0) { $0 + $1.width } + CGFloat(max(components.count - 1, 0)) * spacing
        let spacing = spacing
        let image = NSImage(size: NSSize(width: max(width, 1), height: 20), flipped: false) { _ in
            var x: CGFloat = 0
            for component in components {
                component.draw(x)
                x += component.width + spacing
            }
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = accessibilityDescription
        return image
    }

    var accessibilityDescription: String {
        let status = monitor.paused ? String(localized: "Monitoring paused. ") : ""
        let descriptions = visibleItems.map { $0.component(monitor: monitor).accessibilityDescription }
        return status + descriptions.joined(separator: " ") + " " + String(localized: "Click to open the monitor.")
    }
}

private struct MenuBarMetricComponent {
    let width: CGFloat
    let accessibilityDescription: String
    let draw: (CGFloat) -> Void
}

private extension MenuBarMetricItem {
    @MainActor
    func component(monitor: SystemMonitor) -> MenuBarMetricComponent {
        switch self {
        case .cpuGraph:
            let history = monitor.samples
            return MenuBarMetricComponent(width: width, accessibilityDescription: String(format: String(localized: "CPU %@%%"), locale: .current, String(Int(monitor.cpu)))) { x in
                MenuBarDrawing.verticalLabel("CPU", x: x)
                let frame = NSRect(x: x + 9, y: 0.75, width: 35, height: 16.5)
                let border = NSBezierPath(roundedRect: frame, xRadius: 1.5, yRadius: 1.5)
                NSColor.black.withAlphaComponent(0.5).setStroke()
                border.lineWidth = 0.75
                border.stroke()
                let plot = frame.insetBy(dx: 1.2, dy: 1.2)
                guard let end = history.last?.date else { return }
                let points = history.filter { end.timeIntervalSince($0.date) <= 60 }.map { sample in
                    NSPoint(x: plot.maxX - end.timeIntervalSince(sample.date) / 60 * plot.width,
                            y: plot.minY + min(100, max(0, sample.cpu)) / 100 * plot.height)
                }
                guard let first = points.first, let last = points.last else { return }
                let area = NSBezierPath()
                area.move(to: NSPoint(x: first.x, y: plot.minY))
                points.forEach { area.line(to: $0) }
                area.line(to: NSPoint(x: last.x, y: plot.minY))
                area.close()
                NSColor.black.withAlphaComponent(0.75).setFill()
                area.fill()
                let line = NSBezierPath()
                line.move(to: first)
                points.dropFirst().forEach { line.line(to: $0) }
                line.lineWidth = 0.8
                NSColor.black.setStroke()
                line.stroke()
            }
        case .memory:
            let percent = monitor.memoryPercent
            return MenuBarMetricComponent(width: width, accessibilityDescription: String(format: String(localized: "Memory %@%%"), locale: .current, String(Int(percent)))) { x in
                MenuBarDrawing.verticalLabel("RAM", x: x)
                let bar = NSRect(x: x + 9, y: 0.5, width: 6, height: 17)
                NSColor.black.withAlphaComponent(0.2).setFill()
                NSBezierPath(roundedRect: bar, xRadius: 1.3, yRadius: 1.3).fill()
                NSColor.black.setFill()
                let level = NSRect(x: bar.minX, y: bar.minY, width: bar.width,
                                   height: bar.height * min(100, max(0, percent)) / 100)
                NSBezierPath(rect: level).fill()
                MenuBarDrawing.text("\(Int(percent))%", rect: NSRect(x: x + 20, y: 0, width: 36, height: 18), size: 14, weight: .regular)
            }
        case .cpuTemperature:
            let temperature = monitor.cpuTemperature
            let description = temperature.map { String(format: String(localized: "CPU temperature %@ degrees Celsius. "), locale: .current, String(Int($0.rounded()))) } ?? String(localized: "CPU temperature unavailable. ")
            return MenuBarMetricComponent(width: width, accessibilityDescription: description) { x in
                guard let temperature else { return }
                MenuBarDrawing.verticalLabel("CPU", x: x)
                MenuBarDrawing.text("\(Int(temperature.rounded()))°", rect: NSRect(x: x + 11, y: 0, width: 26, height: 18), size: 14, weight: .regular)
            }
        }
    }
}

private enum MenuBarDrawing {
    static func verticalLabel(_ label: String, x: CGFloat) {
        for (index, character) in label.enumerated() {
            text(String(character), rect: NSRect(x: x, y: 12 - CGFloat(index) * 6, width: 7, height: 7), size: 6, weight: .bold)
        }
    }

    static func text(_ value: String, rect: NSRect, size: CGFloat, weight: NSFont.Weight) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .right
        (value as NSString).draw(in: rect, withAttributes: [
            .font: NSFont.monospacedDigitSystemFont(ofSize: size, weight: weight),
            .foregroundColor: NSColor.black,
            .paragraphStyle: paragraph
        ])
    }
}

#Preview("菜单栏组合") {
    let monitor = SystemMonitor()
    VStack(alignment: .leading, spacing: 16) {
        Image(nsImage: MenuBarMetrics(monitor: monitor, items: [.cpuGraph, .memory, .cpuTemperature]).image)
        Image(nsImage: MenuBarMetrics(monitor: monitor, items: [.memory, .cpuGraph]).image)
        Image(nsImage: MenuBarMetrics(monitor: monitor, items: [.cpuGraph]).image)
    }
    .padding(12)
    .task { monitor.start() }
}

/// Read live state here rather than in App.body, keeping scene updates independent
/// of the monitoring cadence.
struct MenuBarLabel: View {
    let monitor: SystemMonitor
    let layout: String

    var body: some View {
        if layout == "功耗" {
            Image(systemName: "bolt.fill")
            Text(monitor.systemPower.map { String(format: "%.1f W", locale: .current, $0) } ?? String(localized: "Power unavailable"))
        } else if layout == "图标" {
            Image(systemName: "waveform.path")
        } else {
            let metrics = MenuBarMetrics(monitor: monitor, layout: layout)
            Image(nsImage: metrics.image)
                .accessibilityLabel(metrics.accessibilityDescription)
        }
    }
}
