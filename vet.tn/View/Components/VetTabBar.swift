//
//  VetTabBar.swift
//  vet.tn
//

import SwiftUI

// Tabs
enum VetTab: CaseIterable, Hashable {
    case home, find, ai, store, profile

    var title: String {
        switch self {
        case .home:    return "Home"
        case .find:    return "Find"
        case .ai:      return "AI Chat"
        case .store:   return "Store"
        case .profile: return "Profile"
        }
    }
    var systemImage: String {
        switch self {
        case .home:    return "pawprint.fill"
        case .find:    return "map"
        case .ai:      return "sparkles"
        case .store:   return "bag.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

struct VetTabBar: View {
    @Binding var selection: VetTab
    @Namespace private var highlightNS

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.vetCardBackground)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: -2)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.vetStroke.opacity(0.35), lineWidth: 1)
                )

            HStack(alignment: .center, spacing: 12) {
                standardButton(for: .home)
                standardButton(for: .find)

                Spacer(minLength: 0)

                centerAIButton()

                Spacer(minLength: 0)

                standardButton(for: .store)
                standardButton(for: .profile)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(height: 90)
        .animation(.spring(response: 0.28, dampingFraction: 0.9), value: selection)
    }

    private func standardButton(for tab: VetTab) -> some View {
        let isActive = (tab == selection)

        return Button {
            guard selection != tab else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                selection = tab
            }
        } label: {
            ZStack {
                if isActive {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.vetCanyon.opacity(0.14))
                        .matchedGeometryEffect(id: "highlight-\(tab)", in: highlightNS)
                        .frame(height: 44)
                }

                VStack(spacing: 3) {
                    Image(systemName: tab.systemImage)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isActive ? .vetCanyon : .vetSubtitle)
                        .scaleEffect(isActive ? 1.06 : 1.0)

                    Text(tab.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isActive ? .vetCanyon : .vetSubtitle)
                        .lineLimit(1)                 // titres sur 1 ligne
                        .minimumScaleFactor(0.75)     // réduit légèrement si manque de place
                        .allowsTightening(true)       // évite l’ellipse trop tôt
                }
                .padding(.horizontal, 10)            // moins de padding pour plus de largeur utile
                .frame(height: 44)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func centerAIButton() -> some View {
        let isActive = selection == .ai

        return Button {
            guard selection != .ai else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                selection = .ai
            }
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.vetCanyon,
                                Color.vetCanyon.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.vetCanyon.opacity(0.28), radius: 10, x: 0, y: 8)
                    .frame(width: isActive ? 74 : 68, height: isActive ? 74 : 68)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.4), lineWidth: 2)
                    )

                VStack(spacing: 6) {
                    Image(systemName: VetTab.ai.systemImage)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(isActive ? 1.08 : 1.0)
                    Text("AI")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.95))
                        .opacity(isActive ? 1.0 : 0.85)
                        .lineLimit(1)
                }
            }
            .offset(y: -24) // un peu moins haut pour laisser respirer les titres
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

#Preview("VetTabBar") {
    ZStack(alignment: .bottom) {
        Color.vetBackground.ignoresSafeArea()
        StatefulPreviewWrapper(VetTab.home) { sel in
            VetTabBar(selection: sel)
                .padding(.bottom, 8)
        }
    }
}

// Little helper for interactive previews
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content
    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: value)
        self.content = content
    }
    var body: some View { content($value) }
}

struct TabBarHiddenPreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}
