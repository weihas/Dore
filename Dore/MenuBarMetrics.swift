import AppKit
import SwiftUI

/// A template image lets macOS supply the menu bar's tint, including highlighted states.
/// Fixed point sizes keep the status item stable as its live readings change.
@MainActor
struct MenuBarMetrics {
    let monitor: SystemMonitor
    let layout: String

    var image: NSImage {
        let cpu = layout != "内存"
        let memory = layout != "CPU"
        let temperatureValue = monitor.cpuTemperature
        let temperature = layout == "全部" && temperatureValue != nil
        let width: CGFloat = (cpu ? 51 : 0) + (memory ? 61 : 0) + (temperature ? 43 : 0)
        let history = monitor.samples
        let memoryPercent = monitor.memoryPercent
        // Keep CPU and RAM one point below center.
        let image = NSImage(size: NSSize(width: max(width - 7, 1), height: 20), flipped: false) { rect in
            var x: CGFloat = 0
            if cpu {
                Self.verticalLabel("CPU", x: x)
                let frame = NSRect(x: x + 8, y: 0.75, width: 35, height: 16.5)
                let border = NSBezierPath(roundedRect: frame, xRadius: 1.5, yRadius: 1.5)
                NSColor.black.withAlphaComponent(0.5).setStroke()
                border.lineWidth = 0.75
                border.stroke()
                let plot = frame.insetBy(dx: 1.2, dy: 1.2)
                if let end = history.last?.date {
                    let points = history.filter { end.timeIntervalSince($0.date) <= 60 }.map { sample in
                        NSPoint(x: plot.maxX - end.timeIntervalSince(sample.date) / 60 * plot.width,
                                y: plot.minY + min(100, max(0, sample.cpu)) / 100 * plot.height)
                    }
                    if let first = points.first, let last = points.last {
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
                }
                x += 51
            }
            if memory {
                Self.verticalLabel("RAM", x: x)
                let bar = NSRect(x: x + 8, y: 0.5, width: 6, height: 17)
                NSColor.black.withAlphaComponent(0.2).setFill()
                NSBezierPath(roundedRect: bar, xRadius: 1.3, yRadius: 1.3).fill()
                NSColor.black.setFill()
                let level = NSRect(x: bar.minX, y: bar.minY, width: bar.width,
                                   height: bar.height * min(100, max(0, memoryPercent)) / 100)
                NSBezierPath(rect: level).fill()
                Self.text("\(Int(memoryPercent))%", rect: NSRect(x: x + 18, y: 0, width: 36, height: 18), size: 14, weight: .regular)
                x += 61
            }
            if temperature, let temperatureValue {
                Self.verticalLabel("CPU", x: x)
                Self.text("\(Int(temperatureValue.rounded()))°", rect: NSRect(x: x + 10, y: 0, width: 26, height: 18), size: 14, weight: .regular)
            }
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = accessibilityDescription
        return image
    }

    var accessibilityDescription: String {
        let status = monitor.paused ? L("Monitoring paused. ") : ""
        let temperature = monitor.cpuTemperature.map { L("CPU temperature %@ degrees Celsius. ", String(Int($0.rounded()))) } ?? L("CPU temperature unavailable. ")
        return L("%@CPU %@%%, memory %@%%. %@Click to open the monitor.", String(status), String(Int(monitor.cpu)), String(Int(monitor.memoryPercent)), String(temperature))
    }

    private static func verticalLabel(_ label: String, x: CGFloat) {
        for (index, character) in label.enumerated() {
            text(String(character), rect: NSRect(x: x, y: 12 - CGFloat(index) * 6, width: 7, height: 7), size: 6, weight: .bold)
        }
    }

    private static func text(_ value: String, rect: NSRect, size: CGFloat, weight: NSFont.Weight) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .right
        (value as NSString).draw(in: rect, withAttributes: [
            .font: NSFont.monospacedDigitSystemFont(ofSize: size, weight: weight),
            .foregroundColor: NSColor.black,
            .paragraphStyle: paragraph
        ])
    }


}

#Preview("菜单栏状态项") {
    let monitor = SystemMonitor()
    Image(nsImage: MenuBarMetrics(monitor: monitor, layout: "全部").image)
        .padding(12)
        .task { monitor.start() }
}
