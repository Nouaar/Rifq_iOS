//
//  VetTabBar.swift
//  vet.tn
//

import SwiftUI

// Tabs
enum VetTab: CaseIterable, Hashable {
    case pets, clinic, join, profile

    var title: String {
        switch self {
        case .pets:    return "My pets"
        case .clinic:  return "Clinic"
        case .join:    return "Join"
        case .profile: return "Profile"
        }
    }
    var systemImage: String {
        switch self {
        case .pets:    return "pawprint.fill"
        case .clinic:  return "cross.case.fill"
        case .join:    return "person.crop.circle.badge.plus"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

struct VetTabBar: View {
    @Binding var selection: VetTab
    @Namespace private var highlightNS

    var body: some View {
        HStack(spacing: 12) {
            ForEach(VetTab.allCases, id: \.self) { tab in
                let isActive = (tab == selection)

                Button {
                    guard selection != tab else { return }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                        selection = tab
                    }
                } label: {
                    ZStack {
                        // Moving highlight “pill”
                        if isActive {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.vetCanyon.opacity(0.14))
                                .matchedGeometryEffect(id: "highlight", in: highlightNS)
                                .frame(height: 44)
                        }

                        VStack(spacing: 4) {
                            Image(systemName: tab.systemImage)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(isActive ? .vetCanyon : .vetSubtitle)
                                .scaleEffect(isActive ? 1.06 : 1.0)

                            Text(tab.title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(isActive ? .vetCanyon : .vetSubtitle)
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 44)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle()) // full tap area
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(height: 74)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.vetCardBackground)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: -2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.vetStroke.opacity(0.35), lineWidth: 1)
        )
        .animation(.spring(response: 0.28, dampingFraction: 0.9), value: selection)
    }
}

#Preview("VetTabBar") {
    ZStack(alignment: .bottom) {
        Color.vetBackground.ignoresSafeArea()
        StatefulPreviewWrapper(VetTab.pets) { sel in
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
