import SwiftUI

struct GlassControlSurface: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        if #available(macOS 26.0, iOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: Circle())
        } else {
            content
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(LinearGradient(colors: [
                            .white.opacity(colorScheme == .dark ? 0.25 : 0.8),
                            .primary.opacity(0.08)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.75)
                        .allowsHitTesting(false)
                }
                .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
        }
    }
}
