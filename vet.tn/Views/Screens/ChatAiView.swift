//  ChatAIView.swift
//  vet.tn
//

import SwiftUI

struct ChatAIView: View {
    // 👇 Contrôle de l’onglet (utilisé SEULEMENT en mode onglet)
    @Binding var tabSelection: VetTab

    // ✅ Active le back système (NavigationStack) quand true
    var useSystemNavBar: Bool = false

    @State private var input: String = ""
    @State private var messages: [ChatMsg] = [
        .init(role: .system,    text: "🐶 Max • AI Vet"),
        .init(role: .user,      text: "My dog has an ear infection"),
        .init(role: .assistant, text: "Otitis is usually caused by bacteria. I recommend a vet visit.")
    ]

    var body: some View {
        VStack(spacing: 0) {

            // HEADER
            if useSystemNavBar {
                // 👉 Laisse iOS gérer la barre + back système
                // (rien à dessiner ici — le header système s’affiche via .navigationTitle/.toolbar plus bas)
            } else {
                // 👉 Ancien header custom (retour vers onglet .pets)
                TopBar(
                    title: "Chat AI",
                    showBack: true,
                    onBack: { lightHaptic(); tabSelection = .pets }
                )
            }

            // MESSAGES
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    suggestionCard

                    ForEach(messages) { msg in
                        ChatBubble(msg: msg)
                    }

                    recommendationCard
                }
                .padding(16)
            }
            .background(Color.vetBackground)

            // INPUT BAR
            HStack(spacing: 10) {
                TextField("Ask something…", text: $input, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.vetStroke))
                    .cornerRadius(12)
                    .submitLabel(.send)
                    .onSubmit { send() }

                Button(action: send) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .bold))
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.vetCanyon))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(Color.vetBackground)
        }
        // Cache la tab bar custom pendant le chat (dans les deux modes)
        .preference(key: TabBarHiddenPreferenceKey.self, value: true)

        // 👉 Config du header système quand useSystemNavBar == true
        .if(useSystemNavBar) { view in
            view
                .navigationTitle("Chat AI")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        headerBadge("bell.fill")
                        headerBadge("gearshape.fill")
                    }
                }
        }

        // 👉 Swipe back custom UNIQUEMENT en mode onglet
        .if(!useSystemNavBar) { view in
            view.backSwipe { tabSelection = .pets }
        }
    }

    // MARK: - Subviews

    private var suggestionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("🐶 Max • AI Vet")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.vetTitle)
                Spacer()
            }

            Text("Ask me anything about Max’s health")
                .font(.system(size: 14))
                .foregroundColor(.vetSubtitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.vetStroke))
                .cornerRadius(12)
        }
        .padding(12)
        .background(Color.vetSand.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var recommendationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                Text("Consultation Recommended")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
            }
            .foregroundColor(.vetTitle)

            Text("The symptoms suggest a condition needing professional attention.")
                .font(.system(size: 13))
                .foregroundColor(.vetSubtitle)

            Button {
                // TODO: route to Find Vet / Map
            } label: {
                Text("FIND A VET")
                    .font(.system(size: 15, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.vetCanyon))
            .foregroundColor(.white)
        }
        .padding(14)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.vetCanyon.opacity(0.35), lineWidth: 2))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    private func headerBadge(_ system: String) -> some View {
        Image(systemName: system)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.vetTitle)
            .frame(width: 32, height: 32)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.vetStroke))
    }

    // MARK: - Actions

    private func send() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        messages.append(.init(role: .user, text: trimmed))
        input = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            messages.append(.init(role: .assistant, text: "Thanks! I'll analyse this and suggest next steps."))
        }
    }

    private func lightHaptic() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}

// MARK: - Chat bubbles & models

struct ChatBubble: View {
    let msg: ChatMsg

    var body: some View {
        HStack {
            if msg.role == .assistant || msg.role == .system {
                bubble
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                bubble
            }
        }
    }

    private var bubble: some View {
        Text(msg.text)
            .font(.system(size: 14))
            .foregroundColor(.vetTitle)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(msg.role == .user ? Color.vetCanyon.opacity(0.16) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(msg.role == .user ? Color.vetCanyon : Color.vetStroke, lineWidth: 1)
            )
    }
}

struct ChatMsg: Identifiable {
    enum Role { case user, assistant, system }
    let id = UUID()
    let role: Role
    let text: String
}

// MARK: - Small utility to conditionally apply modifiers

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}

// MARK: - Preview

#Preview("Chat AI – pushed (system back)") {
    NavigationStack {
        // En mode poussé, on n’utilise pas le binding tabSelection
        ChatAIView(tabSelection: .constant(.pets), useSystemNavBar: true)
    }
}

#Preview("Chat AI – tab (custom back)") {
    StatefulPreviewWrapper(VetTab.join) { sel in
        ChatAIView(tabSelection: sel, useSystemNavBar: false)
    }
}
