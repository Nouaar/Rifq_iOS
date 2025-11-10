import Foundation

// MARK: - Local error type (fixes "APIClient has no member 'Error'")
enum AuthError: LocalizedError {
    case validation(String)
    var errorDescription: String? {
        switch self {
        case .validation(let message): return message
        }
    }
}

// MARK: - Models returned by your backend
// If you already define these elsewhere, remove/adjust here.
struct MessageResponse: Codable { let message: String }
struct RegisterResponse: Codable {
    let message: String?
    let verificationRequired: Bool?
    let user: AppUser?
    let tokens: AuthTokens?
}

// MARK: - Auth Service
final class AuthService {
    static let shared = AuthService()
    // Route ALL auth endpoints to the dedicated AUTH_BASE_URL
    private let api = APIClient.auth

    // MARK: - Helpers
    @inline(__always) private func trimmed(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    @inline(__always) private func normalizedEmail(_ s: String) -> String {
        trimmed(s).lowercased()
    }

    // MARK: - Register (role is always "owner")
    // CreateUserDto requires at least: name, email, password
    func register(
        name: String,
        email: String,
        password: String,
        captchaToken: String? = nil,
        appVersion: String = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "unknown"
    ) async throws -> RegisterResponse {

        struct RegisterBody: Encodable {
            let name: String
            let email: String
            let password: String
            let role: String          // <- forced to "owner"
            let captchaToken: String?
        }

        // Basic client-side guardrails
        let cleanEmail = normalizedEmail(email)
        guard cleanEmail.contains("@"), cleanEmail.contains(".") else {
            throw AuthError.validation("Adresse e-mail invalide.")
        }
        guard password.count >= 6 else {
            throw AuthError.validation("Le mot de passe doit contenir au moins 6 caractères.")
        }

        // Always use "owner" on register
        let body = RegisterBody(
            name: trimmed(name),
            email: cleanEmail,
            password: password,
            role: "owner",
            captchaToken: captchaToken
        )

        // Idempotency protects against duplicate submissions on double-taps/timeouts
        let headers: [String: String] = [
            "X-Idempotency-Key": UUID().uuidString,
            "Accept-Language": Locale.preferredLanguages.first ?? "en",
            "X-App-Version": appVersion,
            "X-Client": "ios"
        ]

        return try await api.request(
            "POST",
            path: "/auth/register",
            headers: headers,
            body: body,
            responseType: RegisterResponse.self,
            timeout: 45,
            retries: 0,          // writes should not be retried
            retryDelay: 0
        )
    }

    // MARK: - Login
    func login(email: String, password: String) async throws -> AuthResponse {
        struct LoginBody: Encodable { let email: String; let password: String }
        return try await api.request(
            "POST",
            path: "/auth/login",
            body: LoginBody(email: email, password: password),
            responseType: AuthResponse.self,
            // Auth can also be slow on first spin-up
            timeout: 35,
            retries: 2,
            retryDelay: 0.9
        )
    }

    // MARK: - Google sign-in — server expects { id_token } at POST /auth/google
    func google(idToken: String) async throws -> AuthResponse {
        struct GoogleBody: Encodable { let id_token: String }
        return try await api.request(
            "POST",
            path: "/auth/google",
            body: GoogleBody(id_token: idToken),
            responseType: AuthResponse.self,
            timeout: 35,
            retries: 2,
            retryDelay: 0.9
        )
    }

    // MARK: - Refresh
    // JwtRefreshGuard expects Authorization: Bearer <refreshToken> AND body.refreshToken
    func refresh(refreshToken: String) async throws -> AuthTokens {
        struct RefreshBody: Encodable { let refreshToken: String }
        let headers = ["Authorization": "Bearer \(refreshToken)"]
        return try await api.request(
            "POST",
            path: "/auth/refresh",
            headers: headers,
            body: RefreshBody(refreshToken: refreshToken),
            responseType: AuthTokens.self,
            timeout: 25,
            retries: 2,
            retryDelay: 0.8
        )
    }

    // MARK: - Me
    func me(accessToken: String) async throws -> AppUser {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        return try await api.request(
            "GET",
            path: "/auth/me",
            headers: headers,
            responseType: AppUser.self,
            timeout: 20,
            retries: 1,
            retryDelay: 0.75
        )
    }

    // MARK: - Logout
    func logout(refreshToken: String) async throws {
        let headers = ["Authorization": "Bearer \(refreshToken)"]
        _ = try await api.request(
            "POST",
            path: "/auth/logout",
            headers: headers,
            body: APIClient.Empty(),
            responseType: APIClient.Empty.self,
            timeout: 20,
            retries: 1,
            retryDelay: 0.75
        )
    }

    // MARK: - Email Verification
    // Server expects: { "email": "...", "code": "123456" }
    func verifyEmail(email: String, code: String) async throws -> MessageResponse {
        struct VerifyBody: Encodable { let email: String; let code: String }
        return try await api.request(
            "POST",
            path: "/auth/verify",
            body: VerifyBody(email: email, code: code),
            responseType: MessageResponse.self,
            timeout: 40,
            retries: 2,
            retryDelay: 1.0
        )
    }

    // MARK: - Resend verification code
    // Confirm path with your controller (e.g., /auth/verify/resend)
    func resendVerification(email: String) async throws -> MessageResponse {
        struct ResendBody: Encodable { let email: String }
        return try await api.request(
            "POST",
            path: "/auth/verify/resend",
            body: ResendBody(email: email),
            responseType: MessageResponse.self,
            timeout: 25,
            retries: 1,
            retryDelay: 0.8
        )
    }
}
