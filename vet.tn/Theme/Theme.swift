import SwiftUI

// === Styles de boutons ===
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, minHeight: 56)
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.vetCanyon))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.9), value: configuration.isPressed)
    }
}


// === Modificateurs de vue ===
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color.vetCardBackground)
            .cornerRadius(16)
            .vetShadow(radius: 8, x: 0, y: 2)
    }
}

// === Styles de texte ===
extension Font {
    static func vetTitleFont() -> Font { .system(.title2, design: .rounded).weight(.bold) }
    static func vetBodyFont()  -> Font { .system(.body, design: .rounded) }
    static func vetSmallFont() -> Font { .system(.caption, design: .rounded) }
}
