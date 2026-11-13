import SwiftUI

/// Semantic system colors and native grouped surfaces, shared by all pages.
enum DoreStyle {
    static let accent = Color.accentColor
    static let secondary = Color.indigo
    static let amber = Color.orange
}

struct DoreBackdrop: View {
    var body: some View { Color(nsColor: .windowBackgroundColor) }
}

private struct DoreSurface: ViewModifier {
    let inset: CGFloat
    func body(content: Content) -> some View {
        GroupBox {
            content.padding(inset)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}

extension View {
    func dashboardSurface(inset: CGFloat = 10) -> some View { modifier(DoreSurface(inset: inset)) }
}

struct DorePageHeading: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.title2.weight(.semibold))
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 4)
    }
}

struct DoreSectionHeading: View {
    let title: String
    let detail: String
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.subheadline.weight(.semibold))
            Spacer()
            Text(detail).font(.caption).foregroundStyle(.secondary)
        }
    }
}
