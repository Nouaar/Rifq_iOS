import SwiftUI

struct VetOutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, minHeight: 56)
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.vetTitle)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.vetStroke, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.vetCardBackground)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.9), value: configuration.isPressed)
    }
}
