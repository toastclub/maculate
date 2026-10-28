import SwiftUI

struct GlassControlSurface: ViewModifier {
    var prominent = false
    var size: ControlSize = .regular

    func body(content: Content) -> some View {
        content
            .font(nil)
            .buttonBorderShape(.circle)
            .labelStyle(.iconOnly)
#if os(macOS)
            .controlSize(size)
#else
            .controlSize(.large)
#endif
            .modify {
                if #available(macOS 26.0, iOS 26.0, *) {
                    if prominent { $0.buttonStyle(.glassProminent) }
                    else { $0.buttonStyle(.glass) }
                } else {
                    if prominent { $0.buttonStyle(.borderedProminent) }
                    else { $0.buttonStyle(.bordered) }
                }
            }
    }
}
