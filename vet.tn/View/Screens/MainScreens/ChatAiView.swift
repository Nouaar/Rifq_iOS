//  ChatAIView.swift
//  vet.tn
//

import SwiftUI
import PhotosUI
import UIKit

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
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var selectedPreview: UIImage?
    @State private var showCamera = false

    var body: some View {
        VStack(spacing: 0) {

            // HEADER
            if useSystemNavBar {
                // 👉 Laisse iOS gérer la barre + back système
                // (rien à dessiner ici — le header système s’affiche via .navigationTitle/.toolbar plus bas)
            } else {
                // 👉 Ancien header custom (retour vers onglet .home)
                TopBar(
                    title: "Chat AI",
                    showBack: true,
                    onBack: { lightHaptic(); tabSelection = .home }
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

            inputToolbar
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
            view.backSwipe { tabSelection = .home }
        }
        .onChange(of: photosPickerItem) { _ in handlePhotoSelection() }
        .sheet(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera, selectedImage: $capturedImage)
        }
        .onChange(of: capturedImage) { newValue in
            if let image = newValue {
                selectedPreview = image
                capturedImage = nil
            }
        }
    }

    // MARK: - Subviews

    private var inputToolbar: some View {
        VStack(spacing: 10) {
            if let preview = selectedPreview {
                HStack(spacing: 12) {
                    Image(uiImage: preview)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.vetStroke.opacity(0.6), lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Photo attached")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.vetTitle)
                        Text("Sent with your next message")
                            .font(.system(size: 11))
                            .foregroundColor(.vetSubtitle)
                    }

                    Spacer()

                    Button {
                        selectedPreview = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.vetSubtitle)
                    }
                }
                .padding(.horizontal, 14)
            }

            HStack(spacing: 12) {
                HStack(spacing: 10) {
                    PhotosPicker(selection: $photosPickerItem, matching: .images) {
                        attachmentButton(icon: "photo.on.rectangle", label: "Photos")
                    }

                    Button {
                        #if os(iOS)
                        lightHaptic()
                        showCamera = true
                        #endif
                    } label: {
                        attachmentButton(icon: "camera.fill", label: "Camera")
                    }
                }

                TextField("Ask something…", text: $input, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color.vetCardBackground)
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
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .background(Color.vetBackground)
    }

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
                .background(Color.vetCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.vetStroke, lineWidth: 1)
                )
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
        .background(Color.vetCardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.vetCanyon.opacity(0.35), lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .vetLightShadow()
    }

    private func headerBadge(_ system: String) -> some View {
        Image(systemName: system)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.vetTitle)
            .frame(width: 32, height: 32)
            .background(Color.vetCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.vetStroke))
    }

    // MARK: - Actions

    private func send() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || selectedPreview != nil else { return }

        let messageText = trimmed.isEmpty ? "Shared a photo" : trimmed
        let image = selectedPreview

        messages.append(.init(role: .user, text: messageText, image: image))

        input = ""
        selectedPreview = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let response = image != nil
                ? "Thanks for the photo! I’ll analyse it and suggest next steps."
                : "Thanks! I'll analyse this and suggest next steps."
            messages.append(.init(role: .assistant, text: response))
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
        VStack(alignment: .leading, spacing: 10) {
        Text(msg.text)
            .font(.system(size: 14))
            .foregroundColor(.vetTitle)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(msg.role == .user ? Color.vetCanyon.opacity(0.16) : Color.vetCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(msg.role == .user ? Color.vetCanyon : Color.vetStroke, lineWidth: 1)
            )

            if let image = msg.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.vetStroke.opacity(0.5), lineWidth: 1)
                    )
            }
        }
    }
}

struct ChatMsg: Identifiable {
    enum Role { case user, assistant, system }
    let id = UUID()
    let role: Role
    let text: String
    let image: UIImage?

    init(role: Role, text: String, image: UIImage? = nil) {
        self.role = role
        self.text = text
        self.image = image
    }
}

// MARK: - Attachment Helpers

private func attachmentButton(icon: String, label: String) -> some View {
    VStack(spacing: 4) {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.vetCanyon)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.vetCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.vetStroke.opacity(0.6), lineWidth: 1)
            )

        Text(label)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.vetSubtitle)
    }
}

private struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

private extension ChatAIView {
    func handlePhotoSelection() {
        guard let item = photosPickerItem else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    selectedPreview = image
                }
            }
            await MainActor.run {
                photosPickerItem = nil
            }
        }
    }
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
        ChatAIView(tabSelection: .constant(.home), useSystemNavBar: true)
    }
}

#Preview("Chat AI – tab (custom back)") {
    StatefulPreviewWrapper(VetTab.ai) { sel in
        ChatAIView(tabSelection: sel, useSystemNavBar: false)
    }
}
