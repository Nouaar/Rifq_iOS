//
//  ConversationsListView.swift
//  vet.tn
//

import SwiftUI

struct ConversationsListView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = ChatViewModel()
    @StateObject private var chatManager = ChatManager.shared
    @State private var selectedConversation: Conversation?
    @State private var conversationToDelete: Conversation?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.conversations.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.conversations.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.vetSubtitle.opacity(0.5))
                    Text("No conversations yet")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.vetSubtitle)
                    Text("Start chatting with vets or pet sitters")
                        .font(.system(size: 14))
                        .foregroundColor(.vetSubtitle.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                List {
                    ForEach(viewModel.conversations) { conversation in
                        NavigationLink {
                            if let participant = getOtherParticipant(conversation) {
                                ChatView(
                                    recipientId: participant.id,
                                    recipientName: participant.name ?? participant.email ?? "User",
                                    recipientAvatarUrl: participant.avatarUrl
                                )
                                .onAppear {
                                    // Mark conversation as read when opening
                                    Task {
                                        await viewModel.markConversationAsRead(conversationId: conversation.id)
                                    }
                                }
                            }
                        } label: {
                            ConversationRow(conversation: conversation, currentUserId: session.user?.id ?? "")
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                conversationToDelete = conversation
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .alert("Delete Conversation", isPresented: $showDeleteConfirmation) {
                    Button("Cancel", role: .cancel) {
                        conversationToDelete = nil
                    }
                    Button("Delete", role: .destructive) {
                        if let conversation = conversationToDelete {
                            Task {
                                let success = await viewModel.deleteConversation(conversationId: conversation.id)
                                if success {
                                    await chatManager.updateUnreadCount()
                                }
                            }
                        }
                        conversationToDelete = nil
                    }
                } message: {
                    Text("Are you sure you want to delete this conversation? This action cannot be undone.")
                }
            }
        }
        .navigationTitle("Messages")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.sessionManager = session
            chatManager.setSessionManager(session)
            
            Task {
                await viewModel.loadConversations()
                viewModel.startConversationsPolling()
                await chatManager.updateUnreadCount()
            }
        }
        .onDisappear {
            viewModel.stopPolling()
        }
        .refreshable {
            await viewModel.loadConversations()
        }
    }
    
    private func getOtherParticipant(_ conversation: Conversation) -> ConversationParticipant? {
        guard let currentUserId = session.user?.id else { return nil }
        return conversation.participants?.first { $0.id != currentUserId }
    }
}

// MARK: - Conversation Row

struct ConversationRow: View {
    let conversation: Conversation
    let currentUserId: String
    
    var otherParticipant: ConversationParticipant? {
        conversation.participants?.first { $0.id != currentUserId }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.vetCanyon.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                if let avatarUrl = otherParticipant?.avatarUrl, !avatarUrl.isEmpty {
                    AsyncImage(url: URL(string: avatarUrl)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Text((otherParticipant?.name?.prefix(1) ?? "?").uppercased())
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.vetCanyon)
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    Text((otherParticipant?.name?.prefix(1) ?? "?").uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.vetCanyon)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(otherParticipant?.name ?? otherParticipant?.email ?? "Unknown")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.vetTitle)
                    
                    Spacer()
                    
                    if let lastMessageAt = conversation.lastMessageAt {
                        Text(formatTime(lastMessageAt))
                            .font(.system(size: 12))
                            .foregroundColor(.vetSubtitle)
                    }
                }
                
                HStack {
                    Text(conversation.lastMessage?.content ?? "No messages yet")
                        .font(.system(size: 14))
                        .foregroundColor(.vetSubtitle)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let unread = conversation.unreadCount, unread > 0 {
                        Text("\(unread)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.vetCanyon)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatTime(_ timestamp: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: timestamp) else {
            return timestamp
        }
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let displayFormatter = DateFormatter()
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            return displayFormatter.string(from: date)
        }
    }
}

