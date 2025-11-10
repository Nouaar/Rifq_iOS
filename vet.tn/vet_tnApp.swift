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

// Handles Google Sign-In callback for SwiftUI lifecycle apps
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        // Let GoogleSignIn process the redirect
        return GIDSignIn.sharedInstance.handle(url)
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
        // Print the base URLs we’ll actually use (from Info.plist)
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
