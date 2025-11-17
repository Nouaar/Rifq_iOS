//
//  ChatManager.swift
//  vet.tn
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ChatManager: ObservableObject {
    static let shared = ChatManager()
    
    @Published var unreadCount: Int = 0
    
    private var chatViewModel: ChatViewModel?
    weak var sessionManager: SessionManager?
    
    private var conversationsPollingTimer: Timer?
    
    private init() {
        // Listen for unread count updates
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("UnreadMessagesUpdated"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                guard let self = self else { return }
                if let userInfo = notification.userInfo,
                   let count = userInfo["count"] as? Int {
                    self.unreadCount = count
                }
            }
        }
    }
    
    func setSessionManager(_ session: SessionManager) {
        sessionManager = session
        if chatViewModel == nil {
            chatViewModel = ChatViewModel()
            chatViewModel?.sessionManager = session
        }
    }
    
    func startPolling() {
        stopPolling()
        guard let viewModel = chatViewModel else { return }
        
        // Poll conversations every 10 seconds to update unread count
        conversationsPollingTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.chatViewModel?.loadConversations()
            }
        }
    }
    
    func stopPolling() {
        conversationsPollingTimer?.invalidate()
        conversationsPollingTimer = nil
    }
    
    func updateUnreadCount() async {
        guard let viewModel = chatViewModel else { return }
        await viewModel.loadConversations()
        unreadCount = viewModel.unreadCount
    }
    
    deinit {
        // Remove notification observer
        NotificationCenter.default.removeObserver(self)
        // Note: Timer cleanup is handled by stopPolling() which should be called explicitly.
        // Since this is a singleton, deinit may never be called during normal app lifecycle.
        // We cannot call stopPolling() here because deinit is nonisolated and stopPolling() is MainActor-isolated.
    }
}

