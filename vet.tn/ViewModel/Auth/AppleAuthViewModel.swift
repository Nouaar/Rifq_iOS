//
//  AppleAuthViewModel.swift
//  vet.tn
//
//  Created by Mac on 7/11/2025.
//

import Foundation
import Combine
import AuthenticationServices
import UIKit

final class AppleAuthViewModel: NSObject, ObservableObject {
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

    private var currentSource: Source = .login
    private var currentSession: SessionManager?

    @MainActor
    func signIn(session: SessionManager, source: Source = .login) {
        guard !isLoading else { return }
        
        self.currentSource = source
        self.currentSession = session
        self.isLoading = true
        self.errorMessage = nil
        self.infoMessage = nil

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AppleAuthViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Invalid Apple ID credential"
            }
            return
        }

        // Get identity token
        guard let identityTokenData = appleIDCredential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Missing Apple ID token"
            }
            return
        }

        // Get email (may be nil on subsequent sign-ins)
        let email = appleIDCredential.email ?? userEmail ?? ""
        let fullName = appleIDCredential.fullName
        let name = fullName != nil ? "\(fullName?.givenName ?? "") \(fullName?.familyName ?? "")".trimmingCharacters(in: .whitespacesAndNewlines) : nil

        // Store email for subsequent sign-ins (Apple only provides it on first sign-in)
        if !email.isEmpty {
            self.userEmail = email
            UserDefaults.standard.set(email, forKey: "AppleSignInEmail")
        } else {
            // Try to retrieve from previous sign-in
            self.userEmail = UserDefaults.standard.string(forKey: "AppleSignInEmail") ?? ""
        }

        Task { @MainActor in
            guard let session = self.currentSession else {
                self.isLoading = false
                self.errorMessage = "Session not available"
                return
            }

            switch self.currentSource {
            case .signup:
                await session.appleSignup(identityToken: identityToken, email: self.userEmail ?? "", name: name)
            case .login:
                await session.appleSignin(identityToken: identityToken, email: self.userEmail ?? "")
            }

            self.isLoading = false

            if let err = session.lastError, !err.isEmpty {
                self.errorMessage = err
                return
            }

            // Success — session is authenticated, capture details
            self.userEmail = session.user?.email ?? self.userEmail
            self.accessToken = session.tokens?.accessToken
            self.refreshToken = session.tokens?.refreshToken

            // Optional info banner on first-time signup flow
            if self.currentSource == .signup {
                self.infoMessage = "Your Apple account is ready. You're signed in."
            } else {
                self.infoMessage = nil
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled:
                    // User canceled, don't show error
                    self.errorMessage = nil
                case .failed:
                    self.errorMessage = "Apple Sign In failed. Please try again."
                case .invalidResponse:
                    self.errorMessage = "Invalid response from Apple. Please try again."
                case .notHandled:
                    self.errorMessage = "Apple Sign In not handled. Please try again."
                case .unknown:
                    self.errorMessage = "An unknown error occurred. Please try again."
                @unknown default:
                    self.errorMessage = "Apple Sign In failed. Please try again."
                }
            } else {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleAuthViewModel: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            // Fallback to key window
            return UIApplication.shared.windows.first { $0.isKeyWindow } ?? UIWindow()
        }
        return window
    }
}

