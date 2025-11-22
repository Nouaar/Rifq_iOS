import Foundation
import Combine
import UIKit

@MainActor
final class SessionManager: ObservableObject {
    @Published private(set) var user: AppUser?
    @Published private(set) var tokens: AuthTokens?
    @Published var isAuthenticated: Bool = false
    @Published var lastError: String?
    // Indicates that we attempted to restore tokens/user from secure storage on app launch
    @Published var hasRestoredSession: Bool = false

    // Drives the EmailVerificationView
    @Published var requiresEmailVerification: Bool = false
    @Published var pendingEmail: String?
    
    // Navigation flags for Google auth
    @Published var shouldNavigateToLogin: Bool = false
    @Published var shouldNavigateToSignup: Bool = false

    // Profile completion flags
    @Published var requiresProfileCompletion: Bool = false
    @Published var shouldPresentEditProfile: Bool = false

    // Session-scoped alert to prompt user to complete profile (with "Later" option)
    @Published var showProfileCompletionAlert: Bool = false
    private var didShowProfilePrompt: Bool = false

    private let auth = AuthService.shared

    // Keep the password from sign-up so we can auto-login right after verification
    private var pendingPassword: String?

    // Local persistence keys
    private let userCacheKey = "AppUser.cache.v1"

    init() {
        // 1) Load any cached user immediately (MVVM: provide data to the View as soon as possible)
        loadCachedUser()
        // 2) Then restore tokens and refresh from backend
        Task { await loadFromKeychain() }
    }

    // MARK: - Persistence (Tokens)
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
        defer { self.hasRestoredSession = true }
        let access = (try? KeychainStorage.loadString(.accessToken)) ?? nil
        let refresh = (try? KeychainStorage.loadString(.refreshToken)) ?? nil

        if let access = access, let refresh = refresh {
            self.tokens = AuthTokens(accessToken: access, refreshToken: refresh)
            do {
                let me = try await auth.me(accessToken: access)
                setUserFromServer(me) // MERGE instead of replace
                // If user is not verified, require verification instead of auto-auth
                if me.isVerified == false {
                    self.isAuthenticated = false
                    self.requiresEmailVerification = true
                    self.pendingEmail = me.email
                } else {
                // Keep user signed in on cold start
                self.isAuthenticated = true
                    self.requiresEmailVerification = false
                    self.pendingEmail = nil
                    
                    // Notify FCM that user is authenticated (for token refresh)
                    NotificationCenter.default.post(name: NSNotification.Name("UserDidLogin"), object: nil)
                }
            } catch {
                // Try to refresh tokens first
                await refreshTokensIfPossible()
                // If refresh also fails (e.g., user deleted from database), clear session
                if !isAuthenticated {
                    await logout()
                }
            }
        } else {
            // No tokens found; still mark restoration done so UI can decide quickly
            self.isAuthenticated = false
        }
    }

    // MARK: - Persistence (User)
    private func cacheUser(_ user: AppUser?) {
        let defaults = UserDefaults.standard
        if let user {
            if let data = try? JSONEncoder().encode(user) {
                defaults.set(data, forKey: userCacheKey)
            }
        } else {
            defaults.removeObject(forKey: userCacheKey)
        }
    }

    private func loadCachedUser() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: userCacheKey),
           let cached = try? JSONDecoder().decode(AppUser.self, from: data) {
            // Provide cached profile to the UI immediately (even before network)
            self.user = cached
            // Light evaluation; will re-evaluate after fresh server copy
            evaluateProfileCompletion(for: cached)
        }
    }

    // Centralized setter to keep cache in sync
    private func setUser(_ newUser: AppUser?, evaluate: Bool) {
        self.user = newUser
        cacheUser(newUser)
        if evaluate {
            evaluateProfileCompletion(for: newUser)
        }
    }

    // Merge server result with cached/current so we don't lose fields the server omits
    func setUserFromServer(_ server: AppUser) {
        let merged = mergedUser(server: server, cached: self.user)
        setUser(merged, evaluate: true)
    }

    private func mergedUser(server: AppUser, cached: AppUser?) -> AppUser {
        func prefer(_ server: String?, _ cached: String?) -> String? {
            let s = server?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !s.isEmpty { return server }
            let c = cached?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return c.isEmpty ? nil : cached
        }
        let name = prefer(server.name, cached?.name)
        let avatarUrl = prefer(server.avatarUrl, cached?.avatarUrl)
        let phone = prefer(server.phone, cached?.phone)
        let country = prefer(server.country, cached?.country)
        let city = prefer(server.city, cached?.city)
        let pets = server.pets ?? cached?.pets
        let hasPhoto = server.hasPhoto ?? cached?.hasPhoto ?? {
            // derive if needed from avatar
            let s = (server.avatarUrl ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let c = (cached?.avatarUrl ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return (!s.isEmpty || !c.isEmpty)
        }()
        let hasPets = server.hasPets ?? cached?.hasPets ?? {
            let s = !(server.pets?.isEmpty ?? true)
            let c = !(cached?.pets?.isEmpty ?? true)
            return s || c
        }()
        let role = server.role ?? cached?.role // Prefer server role, fallback to cached

        return AppUser(
            id: server.id,                 // always prefer server id/email
            email: server.email,
            name: name,
            avatarUrl: avatarUrl,
            isVerified: server.isVerified ?? cached?.isVerified,
            phone: phone,
            country: country,
            city: city,
            pets: pets,
            hasPhoto: hasPhoto,
            hasPets: hasPets,
            role: role
        )
    }

    // MARK: - Signup (email/password)
    func signUp(name: String, email: String, password: String) async -> Bool {
        lastError = nil
        do {
            let resp = try await auth.register(name: name, email: email, password: password)
            #if DEBUG
            print("Register: \(resp.message ?? "OK")")
            #endif

            if let t = resp.tokens {
                self.tokens = t
                persist(tokens: t)
                let me = try await auth.me(accessToken: t.accessToken)
                setUserFromServer(me)
                self.isAuthenticated = true
                self.requiresEmailVerification = (resp.verificationRequired == true) || (me.isVerified == false)
                self.pendingEmail = self.requiresEmailVerification ? me.email : nil
                self.pendingPassword = nil
                
                // Notify FCM that user logged in
                if !self.requiresEmailVerification {
                    NotificationCenter.default.post(name: NSNotification.Name("UserDidLogin"), object: nil)
                }
                
                return true
            } else {
                do {
                    let loginResp = try await auth.login(email: email, password: password)
                    self.tokens = loginResp.tokens
                    persist(tokens: loginResp.tokens)
                    let me = try await auth.me(accessToken: loginResp.tokens.accessToken)
                    setUserFromServer(me)
                    self.isAuthenticated = true
                    self.requiresEmailVerification = (resp.verificationRequired == true) || (me.isVerified == false)
                    self.pendingEmail = self.requiresEmailVerification ? me.email : nil
                    self.pendingPassword = nil
                    return true
                } catch {
                    if case let APIClient.APIError.http(status, _) = error, status == 401 {
                        self.requiresEmailVerification = true
                        self.pendingEmail = email
                        self.pendingPassword = password
                        self.isAuthenticated = false
                        return true
                    }
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
    func verifyEmail(email: String, code: String) async -> Bool {
        lastError = nil

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

            if let pwd = pendingPassword {
                do {
                    let loginResp = try await auth.login(email: resolved, password: pwd)
                    self.tokens = loginResp.tokens
                    persist(tokens: loginResp.tokens)
                    let me = try await auth.me(accessToken: loginResp.tokens.accessToken)
                    setUserFromServer(me)
                    self.isAuthenticated = true
                    self.pendingPassword = nil
                    
                    // Notify FCM that user logged in
                    NotificationCenter.default.post(name: NSNotification.Name("UserDidLogin"), object: nil)
                    
                    return true
                } catch {
                    self.lastError = "Verified. Please sign in to continue."
                    self.isAuthenticated = false
                    self.pendingPassword = nil
                    return true
                }
            } else if let token = tokens?.accessToken {
                let me = try await auth.me(accessToken: token)
                setUserFromServer(me)
                self.isAuthenticated = true
                
                // Notify FCM that user logged in
                NotificationCenter.default.post(name: NSNotification.Name("UserDidLogin"), object: nil)
                
                return true
            } else {
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

    // MARK: - Forgot / Reset Password
    func forgotPassword(email: String) async throws -> MessageResponse {
        return try await auth.forgotPassword(email: email)
    }

    func resetPassword(email: String, code: String, newPassword: String) async -> Bool {
        lastError = nil
        do {
            _ = try await auth.resetPassword(email: email, code: code, newPassword: newPassword)
            return true
        } catch {
            if let urlErr = error as? URLError, urlErr.code == .timedOut {
                self.lastError = "The server is taking too long to respond. Please try again."
            } else if case let APIClient.APIError.http(_, message) = error {
                self.lastError = friendly(message, fallback: "Could not reset password. Please check the code and try again.")
            } else {
                self.lastError = error.localizedDescription
            }
            return false
        }
    }

    // MARK: - Login (email/password)
    func signIn(email: String, password: String) async {
        lastError = nil
        do {
            let resp = try await auth.login(email: email, password: password)
            self.tokens = resp.tokens
            persist(tokens: resp.tokens)
            let me = try await auth.me(accessToken: resp.tokens.accessToken)
            setUserFromServer(me)
            self.isAuthenticated = true
            
            // Notify FCM that user logged in
            NotificationCenter.default.post(name: NSNotification.Name("UserDidLogin"), object: nil)
        } catch {
            if let urlErr = error as? URLError, urlErr.code == .timedOut {
                self.lastError = "The server is taking too long to respond. Please try again."
            } else if case let APIClient.APIError.http(status, message) = error {
                switch status {
                case 400, 401:
                    self.lastError = "Invalid email or password."
                case 403:
                    self.lastError = friendly(message, fallback: "Please verify your email before signing in.")
                    self.requiresEmailVerification = true
                    self.pendingEmail = email
                default:
                    self.lastError = friendly(message, fallback: "Sign in failed. Please try again.")
                }
            } else {
                self.lastError = error.localizedDescription
            }
            self.isAuthenticated = false
        }
    }

    // MARK: - Google SIGNUP flow
    func googleSignup(idToken: String, email: String) async {
        lastError = nil
        requiresEmailVerification = false
        pendingEmail = nil
        shouldNavigateToLogin = false
        shouldNavigateToSignup = false

        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        do {
            var emailExists = false
            do {
                emailExists = try await auth.checkEmailExists(email: cleanEmail)
            } catch {
                #if DEBUG
                print("⚠️ Email-exists check failed (endpoint might not exist): \(error)")
                #endif
            }
            
            if emailExists {
                self.lastError = "Email already exists, you can login"
                self.shouldNavigateToLogin = true
                self.isAuthenticated = false
                return
            }

            let resp = try await auth.google(idToken: idToken)
            self.tokens = resp.tokens
            persist(tokens: resp.tokens)

            let me = try await auth.me(accessToken: resp.tokens.accessToken)
            setUserFromServer(me)
            
            if me.isVerified == false {
                self.requiresEmailVerification = true
                self.pendingEmail = cleanEmail
                self.isAuthenticated = true
                _ = try? await auth.resendVerification(email: cleanEmail)
            } else {
                self.lastError = "Email already exists, you can login"
                self.shouldNavigateToLogin = true
                self.isAuthenticated = false
                self.tokens = nil
                persist(tokens: nil)
            }
        } catch {
            if let urlErr = error as? URLError, urlErr.code == .timedOut {
                self.lastError = "The server is taking too long to respond. Please try again."
            } else if case let APIClient.APIError.http(status, message) = error {
                if status == 400 || status == 409 {
                    self.lastError = "Email already exists, you can login"
                    self.shouldNavigateToLogin = true
                } else if status == 404 {
                    self.lastError = friendly(message, fallback: "Could not verify email. Please try again.")
                } else {
                    self.lastError = friendly(message, fallback: "Google signup failed. Please try again.")
                }
            } else {
                self.lastError = error.localizedDescription
            }
            self.isAuthenticated = false
        }
    }

    // MARK: - Google SIGNIN flow
    func googleSignin(idToken: String, email: String) async {
        lastError = nil
        // We always require in-app email verification for Google sign-in
        requiresEmailVerification = false
        pendingEmail = nil
        shouldNavigateToLogin = false
        shouldNavigateToSignup = false

        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        do {
            var emailExists = false
            do {
                emailExists = try await auth.checkEmailExists(email: cleanEmail)
            } catch {
                #if DEBUG
                print("⚠️ Email-exists check failed (endpoint might not exist): \(error)")
                #endif
            }
            
            let resp = try await auth.google(idToken: idToken)
            self.tokens = resp.tokens
            persist(tokens: resp.tokens)

            let me = try await auth.me(accessToken: resp.tokens.accessToken)
            setUserFromServer(me)
            
            // User must exist in backend to sign in with Google
            if !emailExists {
                self.lastError = "Account not found. Please sign up first."
                self.shouldNavigateToSignup = true
                self.isAuthenticated = false
                self.tokens = nil
                persist(tokens: nil)
                return
            }
            
            // Do NOT mark as fully authenticated yet; require in-app verification first
            self.isAuthenticated = false
                self.requiresEmailVerification = true
                self.pendingEmail = cleanEmail
            
            // Request a verification code for Google sign-in. Backend is now
            // configured to allow resends for Google accounts even if already verified.
                _ = try? await auth.resendVerification(email: cleanEmail)
        } catch {
            if let urlErr = error as? URLError, urlErr.code == .timedOut {
                self.lastError = "The server is taking too long to respond. Please try again."
            } else if case let APIClient.APIError.http(status, message) = error {
                if status == 404 {
                    self.lastError = "Email is not verified, please signup"
                    self.shouldNavigateToSignup = true
                } else if status == 401 {
                    self.lastError = friendly(message, fallback: "Email is not verified, please signup")
                    self.shouldNavigateToSignup = true
                } else {
                    self.lastError = friendly(message, fallback: "Google sign-in failed. Please try again.")
                }
            } else {
                self.lastError = error.localizedDescription
            }
            self.isAuthenticated = false
        }
    }

    // MARK: - Legacy Google method (kept for compatibility; not used by new flow)
    func signInWithGoogle(idToken: String) async {
        // Prefer using googleSignup/googleSignin with email.
        await googleSignin(idToken: idToken, email: user?.email ?? "")
    }

    // MARK: - Logout
    func logout() async {
        lastError = nil
        requiresEmailVerification = false
        pendingEmail = nil
        pendingPassword = nil
        shouldNavigateToLogin = false
        shouldNavigateToSignup = false
        requiresProfileCompletion = false
        shouldPresentEditProfile = false
        showProfileCompletionAlert = false
        didShowProfilePrompt = false
        let refresh = tokens?.refreshToken
        if let refresh {
            _ = try? await auth.logout(refreshToken: refresh)
        }
        tokens = nil
        setUser(nil, evaluate: false)   // clears cache
        isAuthenticated = false
        persist(tokens: nil)
    }

    // MARK: - Refresh
    // MARK: - Refresh User Data
    func refreshUserData() async {
        guard let token = tokens?.accessToken else { return }
        do {
            let auth = AuthService.shared
            let updatedUser = try await auth.me(accessToken: token)
            setUserFromServer(updatedUser)
        } catch {
            #if DEBUG
            print("⚠️ Failed to refresh user data: \(error)")
            #endif
        }
    }
    
    func refreshTokensIfPossible() async {
        guard let refresh = tokens?.refreshToken else { return }
        do {
            let newTokens = try await auth.refresh(refreshToken: refresh)
            tokens = newTokens
            persist(tokens: newTokens)
            let me = try await auth.me(accessToken: newTokens.accessToken)
            setUserFromServer(me)
            isAuthenticated = true
            
            // Notify FCM that user is authenticated (for token refresh)
            NotificationCenter.default.post(name: NSNotification.Name("UserDidLogin"), object: nil)
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

    private func evaluateProfileCompletion(for user: AppUser?) {
        let needs = needsProfileCompletion(for: user)
        requiresProfileCompletion = needs

        if needs {
            if !didShowProfilePrompt {
                showProfileCompletionAlert = true
                didShowProfilePrompt = true
            }
            shouldPresentEditProfile = false
        } else {
            showProfileCompletionAlert = false
            didShowProfilePrompt = false
            shouldPresentEditProfile = false
        }
    }

    private func needsProfileCompletion(for user: AppUser?) -> Bool {
        // Only require completion if photo, phone, or location is missing.
        // Location is considered missing if either country OR city is empty.
        guard let user else { return true }

        let missingAvatar: Bool = {
            if let hasPhoto = user.hasPhoto {
                return !hasPhoto
            }
            return user.avatarUrl?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
        }()

        let missingPhone = (user.phone?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)

        let missingCountry = (user.country?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let missingCity = (user.city?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let missingLocation = missingCountry || missingCity

        return missingAvatar || missingPhone || missingLocation
    }

    // MARK: - Update Profile
    func updateProfile(
        name: String?,
        phone: String?,
        country: String?,
        city: String?,
        hasPhoto: Bool,
        hasPets: Bool,
        image: UIImage? = nil
    ) async -> Bool {
        guard let current = user else { return false }
        let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone?.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCountry = country?.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCity = city?.trimmingCharacters(in: .whitespacesAndNewlines)

        if let accessToken = tokens?.accessToken {
            do {
                let updatedUser: AppUser
                if let img = image {
                    updatedUser = try await auth.updateProfileMultipart(
                        name: trimmedName,
                        phone: trimmedPhone,
                        country: trimmedCountry,
                        city: trimmedCity,
                        hasPhoto: hasPhoto,
                        hasPets: hasPets,
                        image: img,
                        accessToken: accessToken
                    )
                } else {
                    updatedUser = try await auth.updateProfile(
                    name: trimmedName,
                    phone: trimmedPhone,
                    country: trimmedCountry,
                    city: trimmedCity,
                    hasPhoto: hasPhoto,
                    hasPets: hasPets,
                    accessToken: accessToken
                )
                }
                setUserFromServer(updatedUser) // already full; still merge for safety
                return true
            } catch {
                // Recovery path: if the server saved successfully but response decoding failed,
                // fetch /auth/me. If that object is "minimal", merge the submitted fields so
                // the UI shows what you just saved and the cache keeps them across relaunch.
                #if DEBUG
                print("⚠️ updateProfile failed: \(error). Attempting to refetch /auth/me …")
                #endif
                if let token = tokens?.accessToken {
                    do {
                        let me = try await auth.me(accessToken: token)
                        // Merge the submitted values into the refetched user
                        let merged = mergedUser(server: me, cached: self.user).updating(
                            name: trimmedName,
                            avatarUrl: nil,
                            phone: trimmedPhone,
                            country: trimmedCountry,
                            city: trimmedCity,
                            pets: nil,
                            hasPhoto: hasPhoto,
                            hasPets: hasPets
                        )
                        setUser(merged, evaluate: true)
                        return true
                    } catch {
                        #if DEBUG
                        print("❌ Refetch /auth/me also failed: \(error)")
                        #endif
                        return false
                    }
                } else {
                    return false
                }
            }
        }

        // No access token: local fallback but report unsuccessful to caller
        let avatar = hasPhoto
            ? (current.avatarUrl?.isEmpty == false ? current.avatarUrl : "local-avatar-\(UUID().uuidString)")
            : nil

        let pets: [UserPet]? = hasPets
            ? (current.pets?.isEmpty == false ? current.pets : [UserPet(id: UUID().uuidString, name: "New Friend")])
            : []

        let updated = current.updating(
            name: trimmedName,
            avatarUrl: avatar,
            phone: trimmedPhone,
            country: trimmedCountry,
            city: trimmedCity,
            pets: pets,
            hasPhoto: hasPhoto,
            hasPets: hasPets
        )

        setUser(updated, evaluate: true)
        return false
    }
}
