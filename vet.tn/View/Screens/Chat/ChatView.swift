//
//  ChatView.swift
//  vet.tn
//

import SwiftUI
import UserNotifications
import AVFoundation

struct ChatView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = ChatViewModel()
    @StateObject private var audioRecorder = AudioRecorder()
    @Environment(\.dismiss) private var dismiss
    
    let recipientId: String
    let recipientName: String
    let recipientAvatarUrl: String?
    
    @State private var messageText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var conversationId: String?
    @State private var showAudioRecording = false
    @GestureState private var dragOffset: CGFloat = 0
    @State private var audioMessageURLs: [String: URL] = [:] // Store audio URLs by message ID
    
    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()
            
                VStack(spacing: 0) {
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if viewModel.isLoading && viewModel.messages.isEmpty {
                                ProgressView()
                                    .padding()
                            } else if viewModel.messages.isEmpty {
                                Text("No messages yet. Start the conversation!")
                                    .font(.system(size: 14))
                                    .foregroundColor(.vetSubtitle)
                                    .padding()
                            } else {
                                ForEach(viewModel.messages) { message in
                                    // Check if message has audio URL (from backend or local)
                                    let audioURL: URL? = {
                                        if let backendURL = message.audioURL, let url = URL(string: backendURL) {
                                            return url
                                        } else if let localURL = audioMessageURLs[message.id] {
                                            return localURL
                                        }
                                        return nil
                                    }()
                                    
                                    if let audioURL = audioURL {
                                        // Show audio message bubble if we have the audio URL
                                        AudioMessageBubble(
                                            audioURL: audioURL,
                                            isFromCurrentUser: message.senderId == session.user?.id,
                                            duration: nil
                                        )
                                        .id(message.id)
                                    } else if message.content.contains("🎤 Audio message") {
                                        // If it's an audio message but we don't have the URL, show a placeholder
                                        HStack(alignment: .bottom, spacing: 8) {
                                            if message.senderId == session.user?.id {
                                                Spacer(minLength: 60)
                                            }
                                            
                                            Text("🎤 Audio message")
                                                .font(.system(size: 14))
                                                .foregroundColor(message.senderId == session.user?.id ? .white : .vetTitle)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 10)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                        .fill(message.senderId == session.user?.id ? Color.vetCanyon : Color.vetCardBackground)
                                                )
                                            
                                            if message.senderId != session.user?.id {
                                                Spacer(minLength: 60)
                                            }
                                        }
                                        .padding(.horizontal, 8)
                                        .id(message.id)
                                    } else {
                                        MessageBubble(
                                            message: message,
                                            isFromCurrentUser: message.senderId == session.user?.id,
                                            viewModel: viewModel
                                        )
                                        .id(message.id)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        // Scroll to bottom when new messages arrive
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onAppear {
                        // Scroll to bottom on appear after messages are loaded
                        if !viewModel.messages.isEmpty {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                if let lastMessage = viewModel.messages.last {
                                    withAnimation {
                                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                    .onChange(of: viewModel.isLoading) { isLoading in
                        // Scroll to bottom when loading completes
                        if !isLoading && !viewModel.messages.isEmpty {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                if let lastMessage = viewModel.messages.last {
                                    withAnimation {
                                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Input Area
                Divider()
                
                if audioRecorder.isRecording {
                    // Recording View
                    HStack(spacing: 16) {
                        // Waveform animation
                        HStack(spacing: 3) {
                            ForEach(0..<30, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.red)
                                    .frame(width: 3, height: CGFloat.random(in: 8...30))
                                    .animation(
                                        Animation.easeInOut(duration: 0.5)
                                            .repeatForever()
                                            .delay(Double(index) * 0.05),
                                        value: audioRecorder.isRecording
                                    )
                            }
                        }
                        .frame(height: 40)
                        
                        Text(audioRecorder.formatTime(audioRecorder.recordingTime))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.vetTitle)
                            .monospacedDigit()
                        
                        Spacer()
                        
                        // Cancel/Stop buttons
                        HStack(spacing: 12) {
                            Button {
                                audioRecorder.cancelRecording()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.vetSubtitle)
                                    .frame(width: 36, height: 36)
                                    .background(Color.vetCardBackground)
                                    .clipShape(Circle())
                            }
                            
                            Button {
                                if let audioURL = audioRecorder.stopRecording() {
                                    sendAudioMessage(audioURL: audioURL)
                                }
                            } label: {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Color.vetCanyon)
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.vetBackground)
                } else {
                    // Text Input Area
                    HStack(spacing: 12) {
                        // Microphone button with long press for recording
                        Button {
                            // Tap to toggle text/mic (for now, just start recording)
                            if messageText.isEmpty {
                                Task {
                                    await audioRecorder.startRecording()
                                }
                            }
                        } label: {
                            Image(systemName: messageText.isEmpty ? "mic.fill" : "plus")
                                .font(.system(size: 20))
                                .foregroundColor(.vetCanyon)
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.3)
                                .onEnded { _ in
                                    Task {
                                        await audioRecorder.startRecording()
                                    }
                                }
                        )
                        
                        TextField("Type a message...", text: $messageText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(1...4)
                            .focused($isTextFieldFocused)
                            .onSubmit {
                                sendMessage()
                            }
                        
                        Button {
                            sendMessage()
                        } label: {
                            if viewModel.isSending {
                                ProgressView()
                                    .tint(.white)
                                    .frame(width: 32, height: 32)
                            } else {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .vetSubtitle : .vetCanyon)
                            }
                        }
                        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.vetBackground)
                }
            }
        }
        .navigationTitle(recipientName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.sessionManager = session
            
            // Only load if we don't have messages yet or conversation ID changed
            if viewModel.messages.isEmpty || conversationId == nil {
                Task {
                    // Get or create conversation
                    if let conversation = await viewModel.getOrCreateConversation(participantId: recipientId) {
                        let convId = conversation.id
                        conversationId = convId
                        
                        // Load messages for this conversation
                        await viewModel.loadMessages(conversationId: convId)
                        
                        // Try to find audio files for any audio messages from current user
                        await restoreAudioURLs()
                        
                        // Update global unread count
                        await ChatManager.shared.updateUnreadCount()
                    }
                }
            } else if let convId = conversationId {
                // If we already have a conversation ID, reload messages to ensure we have the latest
                Task {
                    await viewModel.loadMessages(conversationId: convId)
                    await restoreAudioURLs()
                    await ChatManager.shared.updateUnreadCount()
                }
            }
        }
        .onDisappear {
            viewModel.stopPolling()
            // Update unread count when leaving the chat
            Task {
                await ChatManager.shared.updateUnreadCount()
            }
        }
    }
    
    private func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let textToSend = trimmed
        messageText = "" // Clear immediately for better UX
        
        Task {
            let success = await viewModel.sendMessage(
                content: textToSend,
                recipientId: recipientId,
                conversationId: conversationId
            )
            
            if !success {
                // Restore message if send failed
                messageText = textToSend
            }
        }
    }
    
    private func sendAudioMessage(audioURL: URL) {
        Task {
            // Upload audio file directly to backend
            let success = await viewModel.sendAudioMessage(
                content: "🎤 Audio message",
                recipientId: recipientId,
                conversationId: conversationId,
                audioURL: audioURL
            )
            
            if success {
                // Store audio URL if the message has one
                if let lastMessage = viewModel.messages.last,
                   lastMessage.senderId == session.user?.id,
                   let audioURL = lastMessage.audioURL,
                   let url = URL(string: audioURL) {
                    audioMessageURLs[lastMessage.id] = url
                }
            }
            
            // Clean up recording
            audioRecorder.audioURL = nil
            audioRecorder.recordingTime = 0
        }
    }
    
    private func restoreAudioURLs() async {
        // Find all audio messages from current user that don't have URLs yet
        guard let userId = session.user?.id else { return }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // Check each audio message from current user
        for message in viewModel.messages {
            if message.content.contains("🎤 Audio message"),
               message.senderId == userId,
               audioMessageURLs[message.id] == nil {
                // Try to find the audio file by message ID
                let audioURL = documentsPath.appendingPathComponent("audio_\(message.id).m4a")
                
                if FileManager.default.fileExists(atPath: audioURL.path) {
                    audioMessageURLs[message.id] = audioURL
                } else {
                    // Try to find by looking for audio files that might match
                    // This is a fallback if files were named differently
                    await findAudioFileForMessage(message: message, in: documentsPath)
                }
            }
        }
    }
    
    private func findAudioFileForMessage(message: ChatMessage, in directory: URL) async {
        // Try to find audio files that might match this message
        // This is a best-effort attempt to restore audio URLs
        do {
            let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.creationDateKey])
            let audioFiles = files.filter { $0.pathExtension == "m4a" }
            
            // Sort by creation date and try to match by approximate time
            // This is not perfect, but better than nothing
            let sortedFiles = audioFiles.sorted { file1, file2 in
                let date1 = (try? file1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                let date2 = (try? file2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                return date1 > date2
            }
            
            // Try to match by checking creation time against message timestamp
            if let messageDate = parseDate(message.createdAt) {
                for audioFile in sortedFiles {
                    if let fileDate = try? audioFile.resourceValues(forKeys: [.creationDateKey]).creationDate {
                        // Match if created within 5 seconds of message time
                        let timeDiff = abs(fileDate.timeIntervalSince(messageDate))
                        if timeDiff < 5.0 && audioMessageURLs[message.id] == nil {
                            audioMessageURLs[message.id] = audioFile
                            break
                        }
                    }
                }
            }
        } catch {
            print("❌ Failed to search for audio files: \(error)")
        }
    }
    
    private func parseDate(_ timestamp: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: timestamp)
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool
    @ObservedObject var viewModel: ChatViewModel
    @EnvironmentObject private var session: SessionManager
    
    @State private var showEditSheet = false
    @State private var editingContent = ""
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Other person's messages on the left
            if !isFromCurrentUser {
                VStack(alignment: .leading, spacing: 4) {
                    // Message content
                    Group {
                        if message.isDeleted == true {
                            Text("This message has been deleted")
                                .font(.system(size: 14))
                                .italic()
                                .foregroundColor(.vetSubtitle)
                        } else {
                            Text(message.content)
                                .font(.system(size: 15))
                                .foregroundColor(.vetTitle)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.vetCardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.vetStroke, lineWidth: 1)
                    )
                    
                    // Timestamp and edited indicator
                    HStack(spacing: 4) {
                        Text(formatTime(message.createdAt))
                            .font(.system(size: 11))
                            .foregroundColor(.vetSubtitle)
                        
                        if message.editedAt != nil {
                            Text("(edited)")
                                .font(.system(size: 10))
                                .foregroundColor(.vetSubtitle.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 4)
                }
                
                Spacer(minLength: 60)
            } else {
                // My messages on the right
                Spacer(minLength: 60)
                
                VStack(alignment: .trailing, spacing: 4) {
                    // Message content
                    Group {
                        if message.isDeleted == true {
                            Text("This message has been deleted")
                                .font(.system(size: 14))
                                .italic()
                                .foregroundColor(.vetSubtitle)
                        } else {
                            Text(message.content)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.vetCanyon)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.clear, lineWidth: 1)
                    )
                    .contextMenu {
                        if message.isDeleted != true {
                            Button {
                                editingContent = message.content
                                showEditSheet = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive) {
                                Task {
                                    _ = await viewModel.deleteMessage(messageId: message.id)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    
                    // Timestamp and edited indicator
                    HStack(spacing: 4) {
                        Text(formatTime(message.createdAt))
                            .font(.system(size: 11))
                            .foregroundColor(.vetSubtitle)
                        
                        if message.editedAt != nil {
                            Text("(edited)")
                                .font(.system(size: 10))
                                .foregroundColor(.vetSubtitle.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(.horizontal, 8)
        .sheet(isPresented: $showEditSheet) {
            EditMessageSheet(
                messageId: message.id,
                currentContent: message.content,
                onSave: { newContent in
                    Task {
                        _ = await viewModel.updateMessage(messageId: message.id, content: newContent)
                    }
                }
            )
        }
    }
    
    private func formatTime(_ timestamp: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: timestamp) {
            let displayFormatter = DateFormatter()
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return timestamp
    }
}

