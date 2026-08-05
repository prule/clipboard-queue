import SwiftUI

/// Bordered white control: `padding:4-6px 11-14px; border:1px #d2d2d8; radius; hover #f4f4f6`.
struct BorderedButtonStyle: ButtonStyle {
    var font: Font = Theme.ui(13)
    var vPadding: CGFloat = 6
    var hPadding: CGFloat = 12
    var radius: CGFloat = 7
    var shadow: Bool = false

    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .foregroundStyle(Theme.inkSoft)
            .padding(.vertical, vPadding)
            .padding(.horizontal, hPadding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(hovering || configuration.isPressed ? Theme.controlHover : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Theme.controlBorder, lineWidth: 1)
            )
            .shadow(color: shadow ? .black.opacity(0.04) : .clear, radius: 0, x: 0, y: 1)
            .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .onHover { hovering = $0 }
    }
}

/// Filled accent (or grey, when parked) control.
struct FilledButtonStyle: ButtonStyle {
    var color: Color
    var font: Font = Theme.ui(13, .medium)
    var vPadding: CGFloat = 6
    var hPadding: CGFloat = 14
    var radius: CGFloat = 7
    var expands: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .foregroundStyle(.white)
            .padding(.vertical, vPadding)
            .padding(.horizontal, hPadding)
            .frame(maxWidth: expands ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(color.opacity(configuration.isPressed ? 0.85 : 1))
            )
            .shadow(color: .black.opacity(0.14), radius: 1, x: 0, y: 1)
            .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

/// Flat row that tints on hover — sidebar footer actions and popover menu items.
struct HoverRowStyle: ButtonStyle {
    var hoverColor: Color
    var radius: CGFloat = 6
    var vPadding: CGFloat = 6
    var hPadding: CGFloat = 9

    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, vPadding)
            .padding(.horizontal, hPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(hovering ? hoverColor : .clear)
            )
            .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .onHover { hovering = $0 }
    }
}

/// The 7px accent dot on the clipboard preview: opacity 1 → .35 over a 1.8s cycle.
struct PulseDot: View {
    var color: Color
    var size: CGFloat = 7
    var active: Bool = true

    @State private var dim = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .opacity(active ? (dim ? 0.35 : 1) : 0.35)
            .animation(active ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true) : .default,
                       value: dim)
            .onAppear { dim = true }
    }
}

/// `height:5px;border-radius:3px;background:#e6e6ea` with an accent fill.
struct ProgressBar: View {
    var value: Double
    var color: Color
    var height: CGFloat = 5

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                    .fill(Theme.paneBorder)
                RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                    .fill(color)
                    .frame(width: max(0, min(1, value)) * geo.size.width)
                    .animation(.easeOut(duration: 0.25), value: value)
            }
        }
        .frame(height: height)
    }
}

/// The design draws its own traffic lights inside the 52px sidebar header, so the
/// native ones are hidden and these take over.
struct TrafficLights: View {
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 8) {
            light(Theme.tlRed, "xmark") { NSApp.keyWindow?.performClose(nil) }
            light(Theme.tlYellow, "minus") { NSApp.keyWindow?.performMiniaturize(nil) }
            light(Theme.tlGreen, "arrow.up.left.and.arrow.down.right") { NSApp.keyWindow?.performZoom(nil) }
        }
        .onHover { hovering = $0 }
    }

    private func light(_ color: Color, _ glyph: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
                .overlay(
                    Image(systemName: glyph)
                        .font(.system(size: 6, weight: .bold))
                        .foregroundStyle(.black.opacity(0.55))
                        .opacity(hovering ? 1 : 0)
                )
        }
        .buttonStyle(.plain)
    }
}
