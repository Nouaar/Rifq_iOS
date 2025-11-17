//
//  NotificationManager.swift
//  vet.tn
//

import Foundation
import Combine

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var unreadCount: Int = 0
    
    private var notificationViewModel: NotificationViewModel?
    weak var sessionManager: SessionManager?
    private var pollingTimer: Timer?
    
    private init() {
        // Listen for unread count updates
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("UnreadNotificationsUpdated"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if let userInfo = notification.userInfo,
                   let count = userInfo["count"] as? Int {
                    self.unreadCount = count
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setSessionManager(_ session: SessionManager) {
        sessionManager = session
        if notificationViewModel == nil {
            notificationViewModel = NotificationViewModel()
            notificationViewModel?.setSessionManager(session)
        }
    }
    
    func startPolling() {
        stopPolling()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                await self.updateUnreadCount()
            }
        }
        // Initial load
        Task {
            await updateUnreadCount()
        }
    }
    
    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }
    
    func updateUnreadCount() async {
        await notificationViewModel?.updateUnreadCount()
        if let count = notificationViewModel?.unreadCount {
            unreadCount = count
        }
    }
}

