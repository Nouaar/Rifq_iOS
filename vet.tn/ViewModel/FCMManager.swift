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
import Firebase
import FirebaseMessaging

@MainActor
final class FCMManager: NSObject, ObservableObject {
    static let shared = FCMManager()
    
    @Published var fcmToken: String?
    @Published var isRegistered: Bool = false
    
    private weak var sessionManager: SessionManager?
    private let chatService = ChatService.shared
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        
        // Set FCM delegate
        Messaging.messaging().delegate = self
        
        // Listen for session changes to send token
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("UserDidLogin"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, let token = self.fcmToken else { return }
                await self.sendTokenToBackend(token: token)
            }
        }
    }
    
    func setSessionManager(_ session: SessionManager) {
        self.sessionManager = session
        // Send token if we already have one
        Task {
            if let token = fcmToken {
                await sendTokenToBackend(token: token)
            }
        }
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
                    
                    // Register for remote notifications
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                    
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
        do {
            let token = try await Messaging.messaging().token()
            // Since FCMManager is @MainActor, we can directly update properties
            self.fcmToken = token
            await self.sendTokenToBackend(token: token)
            #if DEBUG
            print("✅ FCM token obtained: \(token)")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to get FCM token: \(error)")
            #endif
        }
    }
    
    func setAPNSToken(_ deviceToken: Data) {
        // Forward APNS token to Firebase
        Messaging.messaging().apnsToken = deviceToken
        #if DEBUG
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("📱 APNS token received and forwarded to Firebase: \(tokenString)")
        #endif
    }
    
    private func sendTokenToBackend(token: String) async {
        guard let session = sessionManager,
              let accessToken = session.tokens?.accessToken else {
            #if DEBUG
            print("⚠️ Cannot send FCM token: Not authenticated")
            #endif
            return
        }
        
        do {
            let headers = ["Authorization": "Bearer \(accessToken)"]
            struct FCMTokenRequest: Encodable {
                let fcmToken: String?
            }
            let body = FCMTokenRequest(fcmToken: token)
            
            _ = try await APIClient.auth.request(
                "POST",
                path: "/users/fcm-token",
                headers: headers,
                body: body,
                responseType: APIClient.Empty.self,
                timeout: 30,
                retries: 1
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
    }
    
    // MARK: - Handle Remote Notifications
    
    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) {
        #if DEBUG
        print("📬 Received remote notification: \(userInfo)")
        #endif
        
        // Extract notification data
        guard let type = userInfo["type"] as? String else {
            return
        }
        
        if type == "message" {
            // Handle message notification
            if let conversationId = userInfo["conversationId"] as? String,
               let messageId = userInfo["messageId"] as? String {
                // Post notification to refresh chat
                NotificationCenter.default.post(
                    name: NSNotification.Name("NewMessageReceived"),
                    object: nil,
                    userInfo: [
                        "conversationId": conversationId,
                        "messageId": messageId
                    ]
                )
                
                // Also post for navigation
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenConversation"),
                    object: nil,
                    userInfo: ["conversationId": conversationId]
                )
            }
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

// MARK: - MessagingDelegate

extension FCMManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Task { @MainActor in
            guard let token = fcmToken else { return }
            self.fcmToken = token
            await sendTokenToBackend(token: token)
            #if DEBUG
            print("📱 FCM registration token: \(token)")
            #endif
        }
    }
}

