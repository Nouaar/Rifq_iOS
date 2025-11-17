import Foundation
import UIKit

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
            let role: String
            let captchaToken: String?
        }

        let cleanEmail = normalizedEmail(email)
        guard cleanEmail.contains("@"), cleanEmail.contains(".") else {
            throw AuthError.validation("Adresse e-mail invalide.")
        }
        guard password.count >= 6 else {
            throw AuthError.validation("Le mot de passe doit contenir au moins 6 caractères.")
        }

        let body = RegisterBody(
            name: trimmed(name),
            email: cleanEmail,
            password: password,
            role: "owner",
            captchaToken: captchaToken
        )

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
            retries: 0,
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
            // Increase timeout to accommodate potential cold starts on hosted infra
            timeout: 50,
            // Avoid stacking very long waits; let user retry manually if it still fails
            retries: 0,
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
    func refresh(refreshToken: String) async throws -> AuthTokens {
        struct RefreshBody: Encodable { let refreshToken: String }
        let headers = ["Authorization": "Bearer \(refreshToken)"]
        return try await api.request(
            "POST",
            path: "/auth/refresh",
            headers: headers,
            body: RefreshBody(refreshToken: refreshToken),
            responseType: AuthTokens.self,
            timeout: 40,
            retries: 1,
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
            timeout: 35,
            retries: 1,
            retryDelay: 0.75
        )
    }

    // MARK: - Fetch user by id
    func user(id: String, accessToken: String) async throws -> AppUser {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        return try await api.request(
            "GET",
            path: "/users/\(id)",
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

    // MARK: - Forgot password
    func forgotPassword(email: String) async throws -> MessageResponse {
        struct Body: Encodable { let email: String }
        return try await api.request(
            "POST",
            path: "/auth/forgot-password",
            body: Body(email: normalizedEmail(email)),
            responseType: MessageResponse.self,
            timeout: 40,
            retries: 1,
            retryDelay: 0.8
        )
    }

    // MARK: - Reset password
    func resetPassword(email: String, code: String, newPassword: String) async throws -> MessageResponse {
        struct Body: Encodable { let email: String; let code: String; let newPassword: String }
        return try await api.request(
            "POST",
            path: "/auth/reset-password",
            body: Body(email: normalizedEmail(email), code: code, newPassword: newPassword),
            responseType: MessageResponse.self,
            timeout: 45,
            retries: 1,
            retryDelay: 0.8
        )
    }

    // MARK: - Resend verification code
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

    // MARK: - Check if email exists
    func checkEmailExists(email: String) async throws -> Bool {
        struct ExistsResponse: Decodable { let exists: Bool }
        let clean = normalizedEmail(email)
        
        // Build URL with query parameters properly
        guard let baseURL = URL(string: (Bundle.main.object(forInfoDictionaryKey: "AUTH_BASE_URL") as? String) ?? "http://localhost:3000") else {
            throw URLError(.badURL)
        }
        var components = URLComponents(url: baseURL.appendingPathComponent("auth/email-exists"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "email", value: clean)]
        
        guard let finalURL = components?.url else {
            throw URLError(.badURL)
        }
        
        // Use URLSession directly for this query string request
        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 20
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw APIClient.APIError.http(status: httpResponse.statusCode, message: message)
        }
        
        let resp = try JSONDecoder().decode(ExistsResponse.self, from: data)
        return resp.exists
    }

    // MARK: - Update profile
    // Backend returns the updated user object directly.
    func updateProfile(
        name: String?,
        phone: String?,
        country: String?,
        city: String?,
        hasPhoto: Bool,
        hasPets: Bool,
        accessToken: String
    ) async throws -> AppUser {
        struct UpdateBody: Encodable {
            let name: String?
            let phoneNumber: String?
            let country: String?
            let city: String?
            let hasPhoto: Bool
            let hasPets: Bool
        }

        let body = UpdateBody(
            name: name?.trimmingCharacters(in: .whitespacesAndNewlines),
            phoneNumber: phone?.trimmingCharacters(in: .whitespacesAndNewlines),
            country: country?.trimmingCharacters(in: .whitespacesAndNewlines),
            city: city?.trimmingCharacters(in: .whitespacesAndNewlines),
            hasPhoto: hasPhoto,
            hasPets: hasPets
        )

        let headers = ["Authorization": "Bearer \(accessToken)"]

        return try await api.request(
            "PATCH",
            path: "/users/profile",
            headers: headers,
            body: body,
            responseType: AppUser.self,
            timeout: 25,
            retries: 1,
            retryDelay: 0.75
        )
    }

    // MARK: - Upload profile photo (multipart/form-data)
    // Backend accepts multipart on PATCH /users/profile with field name "image"
    func updateProfileMultipart(
        name: String?,
        phone: String?,
        country: String?,
        city: String?,
        hasPhoto: Bool,
        hasPets: Bool,
        image: UIImage,
        accessToken: String
    ) async throws -> AppUser {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            throw AuthError.validation("Could not encode image.")
        }
        func url(from key: String) -> URL? {
            guard let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String,
                  let url = URL(string: raw) else { return nil }
            return url
        }
        let base = url(from: "AUTH_BASE_URL") ?? url(from: "API_BASE_URL")
        guard var url = base else {
            throw AuthError.validation("Missing AUTH_BASE_URL/API_BASE_URL in Info.plist")
        }
        url.append(path: "/users/profile")

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        func appendField(_ name: String, _ value: String?, to data: inout Data) {
            guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(value)\r\n".data(using: .utf8)!)
        }
        func appendBool(_ name: String, _ value: Bool, to data: inout Data) {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            data.append((value ? "true" : "false").data(using: .utf8)!)
            data.append("\r\n".data(using: .utf8)!)
        }

        var body = Data()
        appendField("name", name, to: &body)
        appendField("phoneNumber", phone, to: &body)
        appendField("country", country, to: &body)
        appendField("city", city, to: &body)
        appendBool("hasPhoto", hasPhoto, to: &body)
        appendBool("hasPets", hasPets, to: &body)
        // file part: field name must be "image" per backend
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"avatar.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        // end
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        request.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if (200..<300).contains(http.statusCode) {
            return try JSONDecoder().decode(AppUser.self, from: data)
        } else {
            let serverMsg = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw APIClient.APIError.http(status: http.statusCode, message: serverMsg)
        }
    }
}

