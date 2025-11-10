import SwiftUI

struct TopBar: View {
    let title: String
    var showBack: Bool = false
    var onBack: (() -> Void)? = nil
    var onNotifications: (() -> Void)? = nil
    var onSettings: (() -> Void)? = nil   // (kept in case you still want a custom action)

    @EnvironmentObject private var theme: ThemeStore

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if showBack {
                    Button { onBack?() } label: { headerBadge("chevron.left") }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Back")
                }

                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.vetTitle)

                Spacer()

                HStack(spacing: 10) {
                    Button { onNotifications?() } label: {
                        headerBadge("bell.fill")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Notifications")

                    // Settings menu with theme switch
                    Menu {
                        // Optional: call a custom settings action first
                        if onSettings != nil {
                            Button("Open Settings…") { onSettings?() }
                            Divider()
                        }
                        Picker("Appearance", selection: $theme.selection) {
                            Label("System", systemImage: "circle.lefthalf.filled")
                                .tag(AppTheme.system)
                            Label("Light", systemImage: "sun.max.fill")
                                .tag(AppTheme.light)
                            Label("Dark",  systemImage: "moon.fill")
                                .tag(AppTheme.dark)
                        }
                    } label: {
                        headerBadge("gearshape.fill")
                    }
                    .accessibilityLabel("Appearance")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .background(Color.vetSand)
            .overlay(
                Rectangle()
                    .fill(Color.vetStroke.opacity(0.4))
                    .frame(height: 1),
                alignment: .bottom
            )
        }
    }

    // iOS-style badge
    private func headerBadge(_ system: String) -> some View {
        Image(systemName: system)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.vetTitle)
            .frame(width: 32, height: 32)
            .background(Color.vetCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.vetStroke))
    }
}
