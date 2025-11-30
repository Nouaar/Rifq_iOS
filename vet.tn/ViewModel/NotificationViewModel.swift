//
//  NotificationViewModel.swift
//  vet.tn
//

import Foundation
import Combine

@MainActor
final class NotificationViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading = false
    @Published var error: String?
    
    weak var sessionManager: SessionManager?
    private let notificationService = NotificationService.shared
    private var pollingTimer: Timer?
    
    // Cooldown to prevent spamming API requests
    private var lastUnreadCountRequestTime: Date?
    private let unreadCountCooldownInterval: TimeInterval = 60.0 // Minimum 5 seconds between requests
    
    func setSessionManager(_ session: SessionManager) {
        sessionManager = session
    }
    
    func loadNotifications() async {
        guard let session = sessionManager,
              let accessToken = session.tokens?.accessToken else {
            error = "Not authenticated"
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            notifications = try await notificationService.getNotifications(unreadOnly: false, accessToken: accessToken)
            await updateUnreadCount()
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            #if DEBUG
            print("❌ Failed to load notifications: \(error)")
            #endif
        }
    }
    
    func updateUnreadCount() async {
        // Cooldown check - prevent spamming
        if let lastRequest = lastUnreadCountRequestTime {
            let timeSinceLastRequest = Date().timeIntervalSince(lastRequest)
            if timeSinceLastRequest < unreadCountCooldownInterval {
                // Too soon, skip this request
                return
            }
        }
        
        guard let session = sessionManager,
              let accessToken = session.tokens?.accessToken else {
            return
        }
        
        // Update last request time
        lastUnreadCountRequestTime = Date()
        
        do {
            unreadCount = try await notificationService.getUnreadCount(accessToken: accessToken)
            // Post notification for other views to update badges
            NotificationCenter.default.post(
                name: NSNotification.Name("UnreadNotificationsUpdated"),
                object: nil,
                userInfo: ["count": unreadCount]
            )
        } catch {
            #if DEBUG
            print("❌ Failed to update unread count: \(error)")
            #endif
        }
    }
    
    func markAsRead(notificationId: String) async {
        guard let session = sessionManager,
              let accessToken = session.tokens?.accessToken else {
            return
        }
        
        do {
            _ = try await notificationService.markAsRead(notificationId: notificationId, accessToken: accessToken)
            // Reload notifications to get updated state
            await loadNotifications()
        } catch {
            #if DEBUG
            print("❌ Failed to mark notification as read: \(error)")
            #endif
        }
    }
    
    func markAllAsRead() async {
        guard let session = sessionManager,
              let accessToken = session.tokens?.accessToken else {
            return
        }
        
        do {
            try await notificationService.markAllAsRead(accessToken: accessToken)
            // Reload notifications to get updated state
            await loadNotifications()
        } catch {
            #if DEBUG
            print("❌ Failed to mark all notifications as read: \(error)")
            #endif
        }
    }
    
    func startPolling() {
        stopPolling()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.updateUnreadCount()
                await self?.loadNotifications()
            }
        }
    }
    
    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }
}

