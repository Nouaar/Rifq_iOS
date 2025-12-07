//  ChatAIView.swift


import SwiftUI
import PhotosUI
import UIKit

struct ChatAIView: View {
    @Binding var tabSelection: VetTab

    var useSystemNavBar: Bool = false

    @State private var input: String = ""
    @StateObject private var vm = ChatAIViewModel()
    @EnvironmentObject private var session: SessionManager
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var selectedPreview: UIImage?
    @State private var showCamera = false
    @State private var showClearConfirm = false
    @State private var showPhotoPicker = false
    @State private var showImageOptions = false

    var body: some View {
        VStack(spacing: 0) {

            if useSystemNavBar {
            } else {
                ChatTopBar(
                    onBack: { lightHaptic(); tabSelection = .home },
                    onClearHistory: { showClearConfirm = true }
                )
            }

            // MESSAGES
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if vm.messages.count <= 1 {
                            quickQuestionButtons
                        }
                        
                        ForEach(vm.messages) { msg in
                            ChatBubble(msg: msg)
                                .id(msg.id)
                        }
                        
                        if vm.isLoading {
                            HStack {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("AI is thinking...")
                                            .font(.system(size: 14))
                                            .foregroundColor(.vetSubtitle)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(Color.vetCardBackground)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(Color.vetStroke, lineWidth: 1)
                                    )
                                }
                                Spacer(minLength: 40)
                            }
                        }
                    }
                    .padding(16)
                }
                .background(Color.vetBackground)
                .onChange(of: vm.messages.count) { _ in
                    if let last = vm.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            if let error = vm.errorMessage {
                HStack {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.red.opacity(0.1))
                        )
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            inputToolbar
        }
        .preference(key: TabBarHiddenPreferenceKey.self, value: true)

        .if(useSystemNavBar) { view in
            view
                .navigationTitle("Vet AI")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        VStack(spacing: 2) {
                            Text("Vet AI")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.vetTitle)
                            Text("Online")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showClearConfirm = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.vetTitle)
                        }
                    }
                }
        }

        .if(!useSystemNavBar) { view in
            view.backSwipe { tabSelection = .home }
        }
        .onChange(of: photosPickerItem) { _ in handlePhotoSelection() }
        .fullScreenCover(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera, selectedImage: $capturedImage)
        }
        .onChange(of: capturedImage) { newValue in
            if let image = newValue {
                selectedPreview = image
                capturedImage = nil
            }
        }
        .onAppear {
            vm.sessionManager = session
            Task { await vm.fetchHistory() }
        }
        .alert("Clear conversation", isPresented: $showClearConfirm) {
            Button("Delete", role: .destructive) {
                Task { await vm.clearHistoryServer() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete your conversation history? This cannot be undone.")
        }
    }


    private var inputToolbar: some View {
        VStack(spacing: 10) {
            if let preview = selectedPreview {
                HStack(spacing: 12) {
                    Image(uiImage: preview)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Image attached")
                            .font(.system(size: 14))
                            .foregroundColor(.vetTitle)
                    }
                    
                    Spacer()
                    
                    Button {
                        selectedPreview = nil
                    } label: {
                        Text("Remove")
                            .font(.system(size: 14))
                            .foregroundColor(.vetCanyon)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            HStack(spacing: 12) {
                TextField("Type your question...", text: $input, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    .cornerRadius(24)
                    .submitLabel(.send)
                    .onSubmit { send() }
                    .disabled(vm.isLoading)
                    .lineLimit(3)
                
                Button {
                    lightHaptic()
                    showImageOptions = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.vetCanyon)
                        .frame(width: 48, height: 48)
                        .background(Color.white)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                }
                .disabled(vm.isLoading)
                .confirmationDialog("Add Photo", isPresented: $showImageOptions, titleVisibility: .visible) {
                    Button("Choose Photo") {
                        showPhotoPicker = true
                    }
                    Button("Take Photo") {
                        showCamera = true
                    }
                    Button("Cancel", role: .cancel) { }
                }
                .photosPicker(
                    isPresented: $showPhotoPicker,
                    selection: $photosPickerItem,
                    matching: .images,
                    photoLibrary: .shared()
                )
                
                Button(action: send) {
                    if vm.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                            .frame(width: 48, height: 48)
                            .background(Color.vetCanyon)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.vetCanyon)
                            .clipShape(Circle())
                    }
                }
                .disabled(vm.isLoading || (input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedPreview == nil))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.vetCardBackground)
        }
    }

    private var quickQuestionButtons: some View {
        let quickQuestions = [
            "What vaccines does my dog need?",
            "Why is my cat vomiting?",
            "How often should I bathe my pet?",
            "What's the best food for puppies?",
            "Signs of pet dehydration?"
        ]
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Quick Questions")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.vetSubtitle)
                .padding(.horizontal, 16)
            
            VStack(spacing: 8) {
                ForEach(quickQuestions, id: \.self) { question in
                    Button {
                        Task {
                            await vm.sendMessage(userMessage: question, imageBase64: nil)
                        }
                    } label: {
                        HStack {
                            Text(question)
                                .font(.system(size: 13))
                                .foregroundColor(.vetTitle)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.vetCanyon.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.vetCanyon.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .disabled(vm.isLoading)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
    }



    private func send() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || selectedPreview != nil else { return }
        guard !vm.isLoading else { return }

        var imageBase64: String? = nil
        if let image = selectedPreview {
            if let imageData = compressImageToBase64(image: image, maxKB: 1000) {
                imageBase64 = imageData
            } else {
                imageBase64 = image.jpegData(compressionQuality: 0.8)?.base64EncodedString()
            }
        }

        let messageText = trimmed

        input = ""
        selectedPreview = nil

        Task {
            await vm.sendMessage(userMessage: messageText, imageBase64: imageBase64)
        }
    }
    
    private func compressImageToBase64(image: UIImage, maxKB: Int, maxDim: Int = 1024) -> String? {
        let maxBytes = maxKB * 1024
        
        let size = image.size
        let maxSide = max(size.width, size.height)
        var scaledImage = image
        
        if maxSide > CGFloat(maxDim) {
            let scale = CGFloat(maxDim) / maxSide
            let newSize = CGSize(width: size.width * scale, height: size.height * scale)
            let renderer = UIGraphicsImageRenderer(size: newSize)
            scaledImage = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
        }
        
        var quality: CGFloat = 0.9
        let minQuality: CGFloat = 0.3
        
        while quality >= minQuality {
            if let data = scaledImage.jpegData(compressionQuality: quality),
               data.count <= maxBytes {
                return data.base64EncodedString()
            }
            quality -= 0.1
        }
        
        return scaledImage.jpegData(compressionQuality: 0.6)?.base64EncodedString()
    }

    private func lightHaptic() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}


struct ChatTopBar: View {
    let onBack: () -> Void
    let onClearHistory: () -> Void
    
    var body: some View {
        HStack {
            // Back button
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.vetTitle)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("Vet AI")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.vetTitle)
                Text("Online")
                    .font(.system(size: 12))
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            Button(action: onClearHistory) {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.vetTitle)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.vetSand)  
        .overlay(
            Rectangle()
                .fill(Color.vetStroke.opacity(0.4))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}


struct ChatBubble: View {
    let msg: ChatMsg

    var body: some View {
        HStack {
            if msg.role == .assistant {
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
                .foregroundColor(msg.role == .user ? .white : .vetTitle)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(msg.role == .user ? Color.vetCanyon : Color.vetCardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(msg.role == .user ? Color.vetCanyon : Color.vetStroke, lineWidth: 1)
                )

            if let image = msg.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.vetStroke.opacity(0.5), lineWidth: 1)
                    )
            }
        }
    }
}


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
        picker.modalPresentationStyle = .fullScreen
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
                DispatchQueue.main.async {
                    self.parent.selectedImage = image
                }
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
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


extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}


#Preview("Chat AI – pushed (system back)") {
    NavigationStack {
        ChatAIView(tabSelection: .constant(.home), useSystemNavBar: true)
    }
}

#Preview("Chat AI – tab (custom back)") {
    StatefulPreviewWrapper(VetTab.ai) { sel in
        ChatAIView(tabSelection: sel, useSystemNavBar: false)
    }
}
