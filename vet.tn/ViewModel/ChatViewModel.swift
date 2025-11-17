//
//  ChatViewModel.swift
//  vet.tn
//

import Foundation
import SwiftUI
import Combine
import UIKit
import UserNotifications

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var messages: [ChatMessage] = []
    @Published var isLoading: Bool = false
    @Published var isSending: Bool = false
    @Published var error: String?
    @Published var unreadCount: Int = 0
    
    private let chatService = ChatService.shared
    private let socketManager = SocketManager.shared
    weak var sessionManager: SessionManager?
    
    private var pollingTimer: Timer?
    private var currentConversationId: String?
    private var useSockets: Bool = true // Toggle to use sockets or polling
    
    func loadConversations() async {
        guard let session = sessionManager,
              let accessToken = session.tokens?.accessToken else {
            error = "Not authenticated"
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            conversations = try await chatService.getConversations(accessToken: accessToken)
            updateUnreadCount()
            
            // Connect to socket if not already connected
            if useSockets, let userId = session.user?.id, !socketManager.isConnected {
                setupSocketHandlers()
                socketManager.connect(userId: userId, accessToken: accessToken)
            }
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            print("❌ Failed to load conversations: \(error)")
            #endif
        }
        
        isLoading = false
    }
    
    func loadMessages(conversationId: String) async {
        guard let session = sessionManager,
              let accessToken = session.tokens?.accessToken else {
            error = "Not authenticated"
            return
        }
        
        currentConversationId = conversationId
        isLoading = true
        error = nil
        
        do {
            messages = try await chatService.getMessages(conversationId: conversationId, accessToken: accessToken)
            // Mark as read when loading messages (user is viewing the conversation)
            try await chatService.markAsRead(conversationId: conversationId, accessToken: accessToken)
            // Refresh conversations to update unread count
            await loadConversations()
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            print("❌ Failed to load messages: \(error)")
            #endif
        }
        
        isLoading = false
        
        // Use sockets for real-time updates, fallback to polling if sockets not available
        if useSockets && socketManager.isConnected {
            socketManager.joinConversation(conversationId)
        } else {
            startPolling(conversationId: conversationId)
        }
    }
    
    func markConversationAsRead(conversationId: String) async {
        guard let session = sessionManager,
              let accessToken = session.tokens?.accessToken else {
            return
        }
        
        do {
            try await chatService.markAsRead(conversationId: conversationId, accessToken: accessToken)
            await loadConversations()
        } catch {
            #if DEBUG
            print("⚠️ Failed to mark as read: \(error)")
            #endif
        }
    }
    
    func updateMessage(messageId: String, content: String) async -> Bool {
        guard let session = sessionManager,
              let accessToken = session.tokens?.accessToken else {
            error = "Not authenticated"
            return false
        }
        
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        
        do {
            let updatedMessage = try await chatService.updateMessage(
                messageId: messageId,
                content: trimmed,
                accessToken: accessToken
            )
            
            // Update message in local array
            if let index = messages.firstIndex(where: { $0.id == messageId }) {
                messages[index] = updatedMessage
            }
            
            // Refresh conversations to update last message
            await loadConversations()
            return true
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            print("❌ Failed to update message: \(error)")
            #endif
            return false
        }
    }
    
    func deleteMessage(messageId: String) async -> Bool {
        guard let session = sessionManager,
              let accessToken = session.tokens?.accessToken else {
            error = "Not authenticated"
            return false
        }
        
        do {
            let deletedMessage = try await chatService.deleteMessage(
                messageId: messageId,
                accessToken: accessToken
            )
            
            // Update message in local array
            if let index = messages.firstIndex(where: { $0.id == messageId }) {
                messages[index] = deletedMessage
            }
            
            // Refresh conversations
            await loadConversations()
            return true
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            print("❌ Failed to delete message: \(error)")
            #endif
            return false
        }
    }
    
    func getOrCreateConversation(participantId: String) async -> Conversation? {
        guard let session = sessionManager,
              let accessToken = session.tokens?.accessToken else {
            error = "Not authenticated"
            return nil
        }
        
        isLoading = true
        error = nil
        
        do {
            let conversation = try await chatService.getOrCreateConversation(
                participantId: participantId,
                accessToken: accessToken
            )
            // Refresh conversations list
            await loadConversations()
            isLoading = false
            return conversation
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            #if DEBUG
            print("❌ Failed to get/create conversation: \(error)")
            #endif
            return nil
        }
    }
    
    func sendMessage(content: String, recipientId: String, conversationId: String?) async -> Bool {
        guard let session = sessionManager,
              let accessToken = session.tokens?.accessToken else {
            error = "Not authenticated"
            return false
        }
        
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        
        isSending = true
        error = nil
        
        do {
            let sentMessage = try await chatService.sendMessage(
                recipientId: recipientId,
                content: trimmed,
                conversationId: conversationId,
                accessToken: accessToken
            )
            
            // Add to local messages
            messages.append(sentMessage)
            
            // Update conversation list
            await loadConversations()
            
            isSending = false
            return true
        } catch {
            self.error = error.localizedDescription
            isSending = false
            #if DEBUG
            print("❌ Failed to send message: \(error)")
            #endif
            return false
        }
    }
    
    func sendAudioMessage(content: String, recipientId: String, conversationId: String?, audioURL: URL) async -> Bool {
        guard let session = sessionManager,
              let accessToken = session.tokens?.accessToken else {
            error = "Not authenticated"
            return false
        }
        
        isSending = true
        error = nil
        
        do {
            let sentMessage = try await chatService.sendAudioMessage(
                recipientId: recipientId,
                content: content,
                conversationId: conversationId,
                audioURL: audioURL,
                accessToken: accessToken
            )
            
            // Add to local messages
            messages.append(sentMessage)
            
            // Update conversation list
            await loadConversations()
            
            isSending = false
            return true
        } catch {
            self.error = error.localizedDescription
            isSending = false
            #if DEBUG
            print("❌ Failed to send audio message: \(error)")
            #endif
            return false
        }
    }
    
    func deleteConversation(conversationId: String) async -> Bool {
        guard let session = sessionManager,
              let accessToken = session.tokens?.accessToken else {
            error = "Not authenticated"
            return false
        }
        
        do {
            try await chatService.deleteConversation(
                conversationId: conversationId,
                accessToken: accessToken
            )
            
            // Remove from conversations list
            conversations.removeAll { $0.id == conversationId }
            return true
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            print("❌ Failed to delete conversation: \(error)")
            #endif
            return false
        }
    }
    
    // MARK: - Real-time Polling
    
    func startPolling(conversationId: String) {
        stopPolling()
        currentConversationId = conversationId
        
        // Poll every 3 seconds for new messages
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.pollMessages(conversationId: conversationId)
            }
        }
    }
    
    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        
        // Leave socket room if using sockets
        if useSockets, let conversationId = currentConversationId {
            socketManager.leaveConversation(conversationId)
        }
        
        currentConversationId = nil
    }
    
    func startConversationsPolling() {
        stopPolling()
        
        // Poll conversations every 5 seconds
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.loadConversations()
            }
        }
    }
    
    private func pollMessages(conversationId: String) async {
        guard let session = sessionManager,
              let accessToken = session.tokens?.accessToken else {
            return
        }
        
        do {
            let newMessages = try await chatService.getMessages(
                conversationId: conversationId,
                accessToken: accessToken
            )
            
            // Only update if we got new messages
            if newMessages.count > messages.count {
                let previousMessages = messages
                let currentUserId = session.user?.id ?? ""
                
                // Find new messages from the other user before updating
                let newMessagesFromOther = newMessages.filter { newMsg in
                    newMsg.senderId != currentUserId && 
                    !previousMessages.contains(where: { $0.id == newMsg.id })
                }
                
                // Update messages
                messages = newMessages
                
                // If we received new messages from the other user, schedule notification
                if !newMessagesFromOther.isEmpty, let firstNewMessage = newMessagesFromOther.first {
                    scheduleMessageNotification(message: firstNewMessage)
                }
                
                // Refresh conversations to update unread count
                await loadConversations()
            }
        } catch {
            // Silently fail polling errors
            #if DEBUG
            print("⚠️ Polling error: \(error)")
            #endif
        }
    }
    
    private func scheduleMessageNotification(message: ChatMessage) {
        #if os(iOS)
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            
            // Get sender name from conversations
            let senderName = self.conversations.first { $0.id == message.conversationId }?
                .participants?.first { $0.id == message.senderId }?.name ?? "Someone"
            
            let content = UNMutableNotificationContent()
            content.title = senderName
            content.body = message.content
            content.sound = .default
            content.userInfo = [
                "conversationId": message.conversationId,
                "senderId": message.senderId
            ]
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(
                identifier: "message-\(message.id)",
                content: content,
                trigger: trigger
            )
            
            center.add(request) { error in
                if let error = error {
                    #if DEBUG
                    print("⚠️ Failed to schedule message notification: \(error)")
                    #endif
                }
            }
        }
        #endif
    }
    
    private func updateUnreadCount() {
        let newCount = conversations.reduce(0) { $0 + ($1.unreadCount ?? 0) }
        
        // Only update and notify if count changed
        if newCount != unreadCount {
            unreadCount = newCount
            
            // Post notification for UI updates
            NotificationCenter.default.post(
                name: NSNotification.Name("UnreadMessagesUpdated"),
                object: nil,
                userInfo: ["count": unreadCount]
            )
            
            // Schedule local notification if there are unread messages
            if unreadCount > 0 {
                scheduleNotificationIfNeeded(count: unreadCount)
            }
        }
    }
    
    private func scheduleNotificationIfNeeded(count: Int) {
        #if os(iOS)
        // Check if app is in background
        let center = UNUserNotificationCenter.current()
        
        // Request permission if needed
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                let content = UNMutableNotificationContent()
                content.title = "New Message"
                content.body = count == 1 
                    ? "You have 1 new message"
                    : "You have \(count) new messages"
                content.sound = .default
                content.badge = NSNumber(value: count)
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "unread-messages-\(UUID().uuidString)",
                    content: content,
                    trigger: trigger
                )
                
                center.add(request) { error in
                    if let error = error {
                        #if DEBUG
                        print("⚠️ Failed to schedule notification: \(error)")
                        #endif
                    }
                }
            }
        }
        #endif
    }
    
    // MARK: - Socket Handlers Setup
    
    private func setupSocketHandlers() {
        socketManager.onMessageReceived = { [weak self] message in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                // Only add if it's for the current conversation
                if message.conversationId == self.currentConversationId {
                    // Check if message already exists
                    if !self.messages.contains(where: { $0.id == message.id }) {
                        self.messages.append(message)
                        // Mark as read if user is viewing this conversation
                        if let conversationId = self.currentConversationId {
                            try? await self.chatService.markAsRead(conversationId: conversationId, accessToken: self.sessionManager?.tokens?.accessToken ?? "")
                        }
                    }
                }
                
                // Always refresh conversations to update last message
                await self.loadConversations()
            }
        }
        
        socketManager.onMessageUpdated = { [weak self] message in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if let index = self.messages.firstIndex(where: { $0.id == message.id }) {
                    self.messages[index] = message
                }
                
                await self.loadConversations()
            }
        }
        
        socketManager.onMessageDeleted = { [weak self] messageId in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if let index = self.messages.firstIndex(where: { $0.id == messageId }) {
                    self.messages.remove(at: index)
                }
                
                await self.loadConversations()
            }
        }
        
        socketManager.onConversationUpdated = { [weak self] conversation in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if let index = self.conversations.firstIndex(where: { $0.id == conversation.id }) {
                    self.conversations[index] = conversation
                } else {
                    // New conversation
                    self.conversations.insert(conversation, at: 0)
                }
                
                self.updateUnreadCount()
            }
        }
    }
    
    deinit {
        Task { @MainActor [weak self] in
            self?.stopPolling()
            if self?.useSockets == true {
                self?.socketManager.disconnect()
            }
        }
    }
}
