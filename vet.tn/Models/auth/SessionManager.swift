import Foundation
import Combine

@MainActor
final class SessionManager: ObservableObject {
    @Published private(set) var user: AppUser?
    @Published private(set) var tokens: AuthTokens?
    @Published var isAuthenticated: Bool = false
    @Published var lastError: String?

    // Drives the EmailVerificationView
    @Published var requiresEmailVerification: Bool = false
    @Published var pendingEmail: String?

    private let auth = AuthService.shared

    // Keep the password from sign-up so we can auto-login right after verification
    private var pendingPassword: String?

    init() {
        Task { await loadFromKeychain() }
    }

    private func persist(tokens: AuthTokens?) {
        if let t = tokens {
            try? KeychainStorage.saveString(t.accessToken, for: .accessToken)
            try? KeychainStorage.saveString(t.refreshToken, for: .refreshToken)
        } else {
            KeychainStorage.delete(.accessToken)
            KeychainStorage.delete(.refreshToken)
        }
    }

    private func loadFromKeychain() async {
        let access = (try? KeychainStorage.loadString(.accessToken)) ?? nil
        let refresh = (try? KeychainStorage.loadString(.refreshToken)) ?? nil

        if let access = access, let refresh = refresh {
            self.tokens = AuthTokens(accessToken: access, refreshToken: refresh)
            do {
                let me = try await auth.me(accessToken: access)
                self.user = me
                // Keep user signed in on cold start
                self.isAuthenticated = true
            } catch {
                await refreshTokensIfPossible()
            }
        }
    }

    // MARK: - Signup (email/password)
    // Goal: behave like sign-in as soon as verification allows it.
    func signUp(name: String, email: String, password: String) async -> Bool {
        lastError = nil
        do {
            let resp = try await auth.register(name: name, email: email, password: password)
            #if DEBUG
            print("Register: \(resp.message ?? "OK")")
            #endif

            if let t = resp.tokens {
                // Backend issued tokens on register: same as sign-in
                self.tokens = t
                persist(tokens: t)
                let me = try await auth.me(accessToken: t.accessToken)
                self.user = me
                self.isAuthenticated = true
                self.requiresEmailVerification = (resp.verificationRequired == true) || (me.isVerified == false)
                self.pendingEmail = self.requiresEmailVerification ? me.email : nil
                self.pendingPassword = nil
                return true
            } else {
                // No tokens yet. Try immediate login.
                do {
                    let loginResp = try await auth.login(email: email, password: password)
                    self.tokens = loginResp.tokens
                    persist(tokens: loginResp.tokens)
                    let me = try await auth.me(accessToken: loginResp.tokens.accessToken)
                    self.user = me
                    self.isAuthenticated = true
                    self.requiresEmailVerification = (resp.verificationRequired == true) || (me.isVerified == false)
                    self.pendingEmail = self.requiresEmailVerification ? me.email : nil
                    self.pendingPassword = nil
                    return true
                } catch {
                    // If login fails with 401, verification is required before we can create a session.
                    if case let APIClient.APIError.http(status, _) = error, status == 401 {
                        self.requiresEmailVerification = true
                        self.pendingEmail = email
                        self.pendingPassword = password   // remember so we can auto-login after verify
                        self.isAuthenticated = false
                        // This is a successful step towards verification, not a fatal error.
                        return true
                    }
                    // Other errors bubble up as a failure
                    throw error
                }
            }
        } catch {
            if let urlErr = error as? URLError {
                switch urlErr.code {
                case .timedOut:
                    self.lastError = "The server is taking too long to respond. Please try again."
                case .cannotConnectToHost, .networkConnectionLost, .dnsLookupFailed, .cannotFindHost, .notConnectedToInternet:
                    self.lastError = "Network issue. Check your connection and try again."
                default:
                    self.lastError = urlErr.localizedDescription
                }
            } else if case let APIClient.APIError.http(status, _) = error {
                switch status {
                case 400, 409:
                    self.lastError = "This email is already registered. Please sign in or continue with Google."
                default:
                    self.lastError = "Registration failed. Please try again."
                }
            } else if let authErr = error as? AuthError {
                self.lastError = authErr.localizedDescription
            } else {
                self.lastError = error.localizedDescription
            }
            return false
        }
    }

    // MARK: - Verify Email
    // After verification, auto-login using the stored signup password, then fetch /me and mark authenticated.
    func verifyEmail(email: String, code: String) async -> Bool {
        lastError = nil

        // Resolve email from parameter or session, then normalize
        let candidate = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolved = (!candidate.isEmpty ? candidate : (pendingEmail ?? user?.email ?? "")).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !resolved.isEmpty, resolved.contains("@"), resolved.contains(".") else {
            self.lastError = "Missing or invalid email for verification."
            return false
        }

        do {
            let resp = try await auth.verifyEmail(email: resolved, code: code)
            #if DEBUG
            print("Verify: \(resp.message)")
            #endif

            self.requiresEmailVerification = false
            self.pendingEmail = nil

            // If we have a pending password from signup, auto-login now to mirror sign-in behavior.
            if let pwd = pendingPassword {
                do {
                    let loginResp = try await auth.login(email: resolved, password: pwd)
                    self.tokens = loginResp.tokens
                    persist(tokens: loginResp.tokens)
                    let me = try await auth.me(accessToken: loginResp.tokens.accessToken)
                    self.user = me
                    self.isAuthenticated = true
                    self.pendingPassword = nil
                    return true
                } catch {
                    // If auto-login fails for any reason, fall back to requiring manual sign-in
                    self.lastError = "Verified. Please sign in to continue."
                    self.isAuthenticated = false
                    self.pendingPassword = nil
                    return true
                }
            } else if let token = tokens?.accessToken {
                // If we already had tokens (rare in this flow), just refresh user
                let me = try await auth.me(accessToken: token)
                self.user = me
                self.isAuthenticated = true
                return true
            } else {
                // No password and no tokens: ask user to sign in manually
                self.lastError = "Verified. Please sign in to continue."
                self.isAuthenticated = false
                return true
            }
        } catch {
            if let urlErr = error as? URLError, urlErr.code == .timedOut {
                self.lastError = "The server is taking too long to respond. Please try again."
            } else if case let APIClient.APIError.http(status, message) = error {
                switch status {
                case 400, 401:
                    self.lastError = friendly(message, fallback: "Invalid verification code. Please try again.")
                default:
                    self.lastError = friendly(message, fallback: "Could not verify email. Please try again.")
                }
            } else {
                self.lastError = error.localizedDescription
            }
            return false
        }
    }

    // MARK: - Resend Verification
    func resendVerification(email: String) async -> Bool {
        lastError = nil
        do {
            let resp = try await auth.resendVerification(email: email)
            #if DEBUG
            print("Resend: \(resp.message)")
            #endif
            return true
        } catch {
            if let urlErr = error as? URLError, urlErr.code == .timedOut {
                self.lastError = "The server is taking too long to respond. Please try again."
            } else if case let APIClient.APIError.http(status, message) = error {
                switch status {
                case 400:
                    self.lastError = friendly(message, fallback: "Verification code still valid. Please wait before requesting a new code.")
                case 404:
                    self.lastError = friendly(message, fallback: "User not found.")
                default:
                    self.lastError = friendly(message, fallback: "Could not resend code. Please try again.")
                }
            } else {
                self.lastError = error.localizedDescription
            }
            return false
        }
    }

    // MARK: - Login (email/password) — unchanged
    func signIn(email: String, password: String) async {
        lastError = nil
        do {
            let resp = try await auth.login(email: email, password: password)
            self.tokens = resp.tokens
            persist(tokens: resp.tokens)
            let me = try await auth.me(accessToken: resp.tokens.accessToken)
            self.user = me
            self.isAuthenticated = true
        } catch {
            if let urlErr = error as? URLError, urlErr.code == .timedOut {
                self.lastError = "The server is taking too long to respond. Please try again."
            } else if case let APIClient.APIError.http(status, message) = error {
                switch status {
                case 400, 401:
                    self.lastError = "Invalid email or password."
                case 403:
                    self.lastError = friendly(message, fallback: "Please verify your email before signing in.")
                default:
                    self.lastError = friendly(message, fallback: "Sign in failed. Please try again.")
                }
            } else {
                self.lastError = error.localizedDescription
            }
            self.isAuthenticated = false
        }
    }

    // MARK: - Google
    // New behavior: If user is not verified, do NOT route to verification.
    // Show an error and keep the user on the login screen.
    func signInWithGoogle(idToken: String) async {
        lastError = nil
        // Ensure Google path never triggers email verification UI
        requiresEmailVerification = false
        pendingEmail = nil

        do {
            let resp = try await auth.google(idToken: idToken)
            self.tokens = resp.tokens
            persist(tokens: resp.tokens)

            // Normalize by fetching /me (which should include isVerified)
            let me = try await auth.me(accessToken: resp.tokens.accessToken)
            self.user = me

            // Treat nil as not verified
            if me.isVerified == true {
                self.isAuthenticated = true
            } else {
                // Not verified: show message and do not keep a partial session
                self.lastError = "Email is not valid, please signup."
                self.isAuthenticated = false
                // Clear any temporary session artifacts
                self.tokens = nil
                persist(tokens: nil)
                self.user = nil
            }
        } catch {
            if let urlErr = error as? URLError, urlErr.code == .timedOut {
                self.lastError = "The server is taking too long to respond. Please try again."
            } else if case let APIClient.APIError.http(_, message) = error {
                self.lastError = friendly(message, fallback: "Google sign-in failed. Please try again.")
            } else {
                self.lastError = error.localizedDescription
            }
            self.isAuthenticated = false
        }
    }

    // MARK: - Logout
    func logout() async {
        lastError = nil
        requiresEmailVerification = false
        pendingEmail = nil
        pendingPassword = nil
        let refresh = tokens?.refreshToken
        if let refresh {
            _ = try? await auth.logout(refreshToken: refresh)
        }
        tokens = nil
        user = nil
        isAuthenticated = false
        persist(tokens: nil)
    }

    // MARK: - Refresh
    func refreshTokensIfPossible() async {
        guard let refresh = tokens?.refreshToken else { return }
        do {
            let newTokens = try await auth.refresh(refreshToken: refresh)
            tokens = newTokens
            persist(tokens: newTokens)
            let me = try await auth.me(accessToken: newTokens.accessToken)
            user = me
            isAuthenticated = true
        } catch {
            await logout()
        }
    }

    func authorizedHeaders() -> [String: String] {
        guard let token = tokens?.accessToken else { return [:] }
        return ["Authorization": "Bearer \(token)"]
    }

    private func friendly(_ rawMessage: String, fallback: String) -> String {
        let trimmed = rawMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return fallback }
        return trimmed
    }
}
