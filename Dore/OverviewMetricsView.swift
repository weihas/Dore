import SwiftUI

struct UsageRing: View {
    let value: Double?
    let tint: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle().stroke(tint.opacity(0.12), lineWidth: 9)
            if let value {
                Circle()
                    .trim(from: 0, to: min(1, max(0, value / 100)))
                    .stroke(tint, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: value)
                VStack(spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(value, format: .number.precision(.fractionLength(0)))
                            .font(.system(size: 26, weight: .medium))
                            .monospacedDigit()
                        Text("%").font(.system(size: 14)).foregroundStyle(.secondary)
                    }
                    Text("使用率").font(.system(size: 10)).foregroundStyle(.secondary)
                }
            } else {
                Text("暂不可用").font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(width: 104, height: 104)
        .padding(5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("使用率")
        .accessibilityValue(value.map { String(format: "%.0f%%", $0) } ?? "暂不可用")
    }
}

#Preview("使用率圆环") {
    HStack(spacing: 24) {
        UsageRing(value: 64, tint: DoreStyle.secondary)
        UsageRing(value: nil, tint: DoreStyle.secondary)
    }.padding(20)
}
