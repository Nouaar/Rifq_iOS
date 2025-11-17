//
//  SocketManager.swift
//  vet.tn
//
//  Socket.IO Manager for real-time messaging
//

import Foundation
import Combine

@MainActor
final class SocketManager: ObservableObject {
    static let shared = SocketManager()
    
    @Published var isConnected: Bool = false
    @Published var connectionError: String?
    
    private var socket: Any? // Will be SocketIOClient once dependency is added
    private var accessToken: String?
    private var userId: String?
    
    // Event handlers
    var onMessageReceived: ((ChatMessage) -> Void)?
    var onMessageUpdated: ((ChatMessage) -> Void)?
    var onMessageDeleted: ((String) -> Void)?
    var onConversationUpdated: ((Conversation) -> Void)?
    var onTyping: ((String, String, Bool) -> Void)? // conversationId, userId, isTyping
    
    private init() {}
    
    // MARK: - Connection Management
    
    func connect(userId: String, accessToken: String) {
        self.userId = userId
        self.accessToken = accessToken
        
        // TODO: Initialize Socket.IO client once dependency is added
        // Example implementation:
        /*
        guard let baseURL = getBaseURL() else {
            connectionError = "Missing base URL"
            return
        }
        
        let manager = SocketManager(socketURL: baseURL, config: [
            .log(true),
            .compress,
            .connectParams(["token": accessToken, "userId": userId])
        ])
        
        socket = manager.defaultSocket
        
        setupEventHandlers()
        socket?.connect()
        */
        
        #if DEBUG
        print("🔌 Socket.IO connection requested for user: \(userId)")
        print("⚠️ Socket.IO dependency not yet added. Add 'Socket.IO-Client-Swift' via SPM or CocoaPods")
        #endif
        
        // Simulate connection for now (remove once Socket.IO is integrated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isConnected = true
        }
    }
    
    func disconnect() {
        // socket?.disconnect()
        isConnected = false
        userId = nil
        accessToken = nil
        #if DEBUG
        print("🔌 Socket.IO disconnected")
        #endif
    }
    
    // MARK: - Event Handlers Setup
    
    private func setupEventHandlers() {
        // TODO: Set up Socket.IO event handlers once dependency is added
        /*
        socket?.on("connect") { [weak self] data, ack in
            Task { @MainActor [weak self] in
                self?.isConnected = true
                self?.connectionError = nil
                print("✅ Socket.IO connected")
            }
        }
        
        socket?.on("disconnect") { [weak self] data, ack in
            Task { @MainActor [weak self] in
                self?.isConnected = false
                print("❌ Socket.IO disconnected")
            }
        }
        
        socket?.on("error") { [weak self] data, ack in
            Task { @MainActor [weak self] in
                if let error = data.first as? String {
                    self?.connectionError = error
                    print("❌ Socket.IO error: \(error)")
                }
            }
        }
        
        socket?.on("new_message") { [weak self] data, ack in
            Task { @MainActor [weak self] in
                guard let self = self,
                      let jsonData = data.first as? [String: Any],
                      let json = try? JSONSerialization.data(withJSONObject: jsonData),
                      let message = try? JSONDecoder().decode(ChatMessage.self, from: json) else {
                    return
                }
                self.onMessageReceived?(message)
            }
        }
        
        socket?.on("message_updated") { [weak self] data, ack in
            Task { @MainActor [weak self] in
                guard let self = self,
                      let jsonData = data.first as? [String: Any],
                      let json = try? JSONSerialization.data(withJSONObject: jsonData),
                      let message = try? JSONDecoder().decode(ChatMessage.self, from: json) else {
                    return
                }
                self.onMessageUpdated?(message)
            }
        }
        
        socket?.on("message_deleted") { [weak self] data, ack in
            Task { @MainActor [weak self] in
                guard let self = self,
                      let messageId = data.first as? String else {
                    return
                }
                self.onMessageDeleted?(messageId)
            }
        }
        
        socket?.on("conversation_updated") { [weak self] data, ack in
            Task { @MainActor [weak self] in
                guard let self = self,
                      let jsonData = data.first as? [String: Any],
                      let json = try? JSONSerialization.data(withJSONObject: jsonData),
                      let conversation = try? JSONDecoder().decode(Conversation.self, from: json) else {
                    return
                }
                self.onConversationUpdated?(conversation)
            }
        }
        
        socket?.on("typing") { [weak self] data, ack in
            Task { @MainActor [weak self] in
                guard let self = self,
                      let jsonData = data.first as? [String: Any],
                      let conversationId = jsonData["conversationId"] as? String,
                      let userId = jsonData["userId"] as? String,
                      let isTyping = jsonData["isTyping"] as? Bool else {
                    return
                }
                self.onTyping?(conversationId, userId, isTyping)
            }
        }
        */
    }
    
    // MARK: - Emit Events
    
    func joinConversation(_ conversationId: String) {
        // socket?.emit("join_conversation", conversationId)
        #if DEBUG
        print("📨 Joining conversation: \(conversationId)")
        #endif
    }
    
    func leaveConversation(_ conversationId: String) {
        // socket?.emit("leave_conversation", conversationId)
        #if DEBUG
        print("📨 Leaving conversation: \(conversationId)")
        #endif
    }
    
    func sendTypingIndicator(conversationId: String, isTyping: Bool) {
        // socket?.emit("typing", [
        //     "conversationId": conversationId,
        //     "isTyping": isTyping
        // ])
        #if DEBUG
        print("⌨️ Typing indicator: \(isTyping ? "typing" : "stopped") in \(conversationId)")
        #endif
    }
    
    // MARK: - Helper
    
    private func getBaseURL() -> URL? {
        func url(from key: String) -> URL? {
            guard let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String,
                  let url = URL(string: raw) else { return nil }
            return url
        }
        return url(from: "AUTH_BASE_URL") ?? url(from: "API_BASE_URL")
    }
}

