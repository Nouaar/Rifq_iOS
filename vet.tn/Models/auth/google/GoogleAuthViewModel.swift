//
//  GoogleAuthViewModel.swift
//  vet.tn
//
//  Created by Mac on 7/11/2025.
//

import Foundation
import Combine
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices
import UIKit

// Simple local store to remember which Google emails have been seen on this device.
private final class SeenGoogleEmails {
    static let shared = SeenGoogleEmails()
    private let key = "SeenGoogleEmails.v1"
    private var cache: Set<String>

    private init() {
        if let arr = UserDefaults.standard.array(forKey: key) as? [String] {
            cache = Set(arr)
        } else {
            cache = []
        }
    }

    func contains(_ email: String) -> Bool { cache.contains(email.lowercased()) }

    func add(_ email: String) {
        let lowered = email.lowercased()
        guard !cache.contains(lowered) else { return }
        cache.insert(lowered)
        UserDefaults.standard.set(Array(cache), forKey: key)
    }
}

final class GoogleAuthViewModel: ObservableObject {
    enum Source {
        case signup
        case login
    }

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?
    @Published var userEmail: String?
    @Published var accessToken: String?
    @Published var refreshToken: String?

    // We now delegate network to SessionManager/AuthService
    @MainActor
    func signIn(session: SessionManager, source: Source = .login) {
        guard let rootVC = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
                .keyWindow?.rootViewController else {
            self.errorMessage = "No root view controller"
            return
        }

        isLoading = true
        errorMessage = nil
        infoMessage = nil

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
                return
            }

            guard let user = result?.user else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Google sign-in failed."
                }
                return
            }

            // Read email from Google result if available (for display only)
            let googleEmail = user.profile?.email ?? ""

            guard let idToken = user.idToken?.tokenString else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Missing Google ID token"
                }
                return
            }

            Task { @MainActor in
                await session.signInWithGoogle(idToken: idToken)
                self.isLoading = false

                if let err = session.lastError, !err.isEmpty {
                    // Backend decides if the account exists or needs verification
                    self.errorMessage = err
                    return
                }

                // Success — session is authenticated, capture details
                self.userEmail = session.user?.email ?? googleEmail
                self.accessToken = session.tokens?.accessToken
                self.refreshToken = session.tokens?.refreshToken

                // Optional info banner on first-time signup flow
                if source == .signup {
                    self.infoMessage = "Your Google account is ready. You’re signed in."
                } else {
                    self.infoMessage = nil
                }
            }
        }
    }
}
