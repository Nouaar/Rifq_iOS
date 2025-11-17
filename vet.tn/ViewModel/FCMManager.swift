//
//  FCMManager.swift
//  vet.tn
//
//  Firebase Cloud Messaging Manager for push notifications
//

import Foundation
import Combine
import UserNotifications
import UIKit

@MainActor
final class FCMManager: NSObject, ObservableObject {
    static let shared = FCMManager()
    
    @Published var fcmToken: String?
    @Published var isRegistered: Bool = false
    
    private weak var sessionManager: SessionManager?
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func setSessionManager(_ session: SessionManager) {
        self.sessionManager = session
    }
    
    // MARK: - Registration
    
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if granted {
                    #if DEBUG
                    print("✅ Push notification permission granted")
                    #endif
                    await self.getFCMToken()
                } else {
                    #if DEBUG
                    print("❌ Push notification permission denied")
                    #endif
                }
                
                if let error = error {
                    #if DEBUG
                    print("⚠️ Push notification error: \(error.localizedDescription)")
                    #endif
                }
            }
        }
    }
    
    func getFCMToken() async {
        // TODO: Get FCM token once Firebase SDK is integrated
        // Example:
        /*
        do {
            let token = try await Messaging.messaging().token()
            await MainActor.run {
                self.fcmToken = token
                self.sendTokenToBackend(token: token)
            }
        } catch {
            #if DEBUG
            print("❌ Failed to get FCM token: \(error)")
            #endif
        }
        */
        
        #if DEBUG
        print("📱 FCM token requested")
        print("⚠️ Firebase SDK not yet integrated. Add 'Firebase/Messaging' via SPM or CocoaPods")
        #endif
        
        // Simulate token for now (remove once Firebase is integrated)
        let simulatedToken = UUID().uuidString
        self.fcmToken = simulatedToken
        await sendTokenToBackend(token: simulatedToken)
    }
    
    private func sendTokenToBackend(token: String) async {
        guard let session = sessionManager,
              let userId = session.user?.id,
              let accessToken = session.tokens?.accessToken else {
            #if DEBUG
            print("⚠️ Cannot send FCM token: Not authenticated")
            #endif
            return
        }
        
        // TODO: Send token to backend
        // Example endpoint: POST /users/fcm-token
        /*
        do {
            let headers = ["Authorization": "Bearer \(accessToken)"]
            let body = ["fcmToken": token]
            _ = try await APIClient.auth.request(
                "POST",
                path: "/users/fcm-token",
                headers: headers,
                body: body,
                responseType: APIClient.Empty.self
            )
            isRegistered = true
            #if DEBUG
            print("✅ FCM token sent to backend")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to send FCM token to backend: \(error)")
            #endif
        }
        */
        
        #if DEBUG
        print("📤 FCM token would be sent to backend: \(token)")
        #endif
        isRegistered = true
    }
    
    // MARK: - Handle Remote Notifications
    
    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) {
        #if DEBUG
        print("📬 Received remote notification: \(userInfo)")
        #endif
        
        // Extract notification data
        if let conversationId = userInfo["conversationId"] as? String {
            // Navigate to conversation or update UI
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenConversation"),
                object: nil,
                userInfo: ["conversationId": conversationId]
            )
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension FCMManager: UNUserNotificationCenterDelegate {
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
        
        // Handle notification data
        handleRemoteNotification(notification.request.content.userInfo)
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handleRemoteNotification(response.notification.request.content.userInfo)
        completionHandler()
    }
}

