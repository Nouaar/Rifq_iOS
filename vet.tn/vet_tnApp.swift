//
//  vet_tnApp.swift
//  vet.tn
//
//  Created by Mac on 3/11/2025.
//

import SwiftUI
import CoreData
import Combine
import GoogleSignIn
import UIKit
import Firebase
import FirebaseMessaging

// Handles Google Sign-In callback and push notifications for SwiftUI lifecycle apps
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Configure Firebase FIRST, before any Firebase calls
        // This must happen early to prevent "Firebase app not configured" warnings
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        // Set FCM delegate
        Messaging.messaging().delegate = FCMManager.shared
        
        // Initialize Stripe
        _ = StripeService.shared
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        // Let GoogleSignIn process the redirect
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    // Handle remote notifications registration
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Pass APNS token to FCM Manager (which forwards to Firebase)
        Task { @MainActor in
            FCMManager.shared.setAPNSToken(deviceToken)
        }
        
        #if DEBUG
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("📱 APNS device token registered: \(tokenString)")
        #endif
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        #if DEBUG
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
        #endif
    }
    
    // Handle remote notification when app is in background
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Task { @MainActor in
            FCMManager.shared.handleRemoteNotification(userInfo)
        }
        completionHandler(.newData)
    }
}

@main
struct vet_tnApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var theme = ThemeStore()
    @StateObject private var session = SessionManager()

    init() {
        // Configure Google Sign-In with your iOS OAuth client ID
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: "68176423413-uvu0od4sog6hiqnegaer9s44bo4qcgsa.apps.googleusercontent.com"
        )

        #if DEBUG
        // Print the base URLs we'll actually use (from Info.plist)
        let authBase = Bundle.main.object(forInfoDictionaryKey: "AUTH_BASE_URL") as? String ?? "MISSING"
        let apiBase  = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? "MISSING"
        print("🔧 AUTH_BASE_URL =", authBase)
        print("🔧 API_BASE_URL  =", apiBase)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            AppSetupView(session: session) {
                SplashView()
                    .environmentObject(theme)
                    .environmentObject(session)
                    .preferredColorScheme(theme.preferred)
            }
        }
    }
}

// MARK: - Setup View
/// Helper view to setup session manager after StateObject is available
private struct AppSetupView<Content: View>: View {
    let session: SessionManager
    let content: Content
    
    init(session: SessionManager, @ViewBuilder content: () -> Content) {
        self.session = session
        self.content = content()
    }
    
    var body: some View {
        content
            .task {
                // Setup session manager after view is created (StateObject is now available)
                setupSessionManager()
            }
    }
    
    private func setupSessionManager() {
        // Set session manager for FCM Manager
        FCMManager.shared.setSessionManager(session)
        
        // Set session manager for APIClient (for automatic token refresh)
        APIClient.auth.setSessionManager(session)
        APIClient.shared.setSessionManager(session)
        
        // Register for push notifications
        FCMManager.shared.registerForPushNotifications()
    }
}
