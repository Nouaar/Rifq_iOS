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

// Handles Google Sign-In callback and push notifications for SwiftUI lifecycle apps
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        // Let GoogleSignIn process the redirect
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    // Handle remote notifications
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // TODO: Once Firebase is integrated, pass token to FCM
        // Messaging.messaging().apnsToken = deviceToken
        #if DEBUG
        print("📱 Device token registered: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
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
        
        // Register for push notifications
        FCMManager.shared.registerForPushNotifications()

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
            SplashView()
                .environmentObject(theme)
                .environmentObject(session)
                .preferredColorScheme(theme.preferred)
        }
    }
}
