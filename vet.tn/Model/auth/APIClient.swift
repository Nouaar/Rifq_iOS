// APIClient.swift

import Foundation

final class APIClient {
    // Default app API (non-auth)
    static let shared = APIClient(baseKey: "API_BASE_URL")
    // Dedicated client for authentication endpoints
    static let auth   = APIClient(baseKey: "AUTH_BASE_URL", fallbackKey: "API_BASE_URL")

    private let baseURL: URL
    private let session: URLSession
    
    // Token refresh state management
    private let refreshLock = NSLock()
    private var refreshTask: Task<AuthTokens?, Never>?
    
    // SessionManager reference for token refresh
    weak var sessionManager: SessionManager?
    
    // Shared refresh state across all instances
    private static var isRefreshing = false
    private static let sharedRefreshLock = NSLock()
    private static var sharedRefreshTask: Task<AuthTokens?, Never>?

    // baseKey is the Info.plist key that contains the base URL string.
    // If it's missing, we optionally fall back to fallbackKey.
    init(baseKey: String, fallbackKey: String? = nil, session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            // Allow longer time for AI requests that may be rate-limited (can take 60+ seconds)
            config.timeoutIntervalForRequest = 200 // Increased for AI rate-limited requests
            config.timeoutIntervalForResource = 240 // Increased for AI rate-limited requests
            config.waitsForConnectivity = true
            self.session = URLSession(configuration: config)
        }

        func url(from key: String) -> URL? {
            guard let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String,
                  let url = URL(string: raw) else { return nil }
            return url
        }

        if let url = url(from: baseKey) {
            self.baseURL = url
        } else if let fb = fallbackKey, let url = url(from: fb) {
            self.baseURL = url
            #if DEBUG
            print("⚠️ \(baseKey) missing; falling back to \(fb): \(url.absoluteString)")
            #endif
        } else {
            #if DEBUG
            // Fail fast in DEBUG so you notice missing config
            fatalError("Missing Info.plist base URL keys: \(baseKey) (and fallback: \(fallbackKey ?? "nil"))")
            #else
            // Last-resort fallback in Release to avoid crash
            let fallback = URL(string: "http://localhost:3000")!
            self.baseURL = fallback
            print("⚠️ Missing base URL keys. Falling back to \(fallback.absoluteString)")
            #endif
        }
    }

    struct Empty: Codable {}

    func request<T: Decodable>(
        _ method: String,
        path: String,
        headers: [String: String] = [:],
        body: Encodable? = nil,
        responseType: T.Type = T.self,
        timeout: TimeInterval? = nil,
        retries: Int = 1,
        retryDelay: TimeInterval = 0.75,
        skipAutoRefresh: Bool = false
    ) async throws -> T {
        // Parse path and query string separately
        let pathComponents = path.split(separator: "?", maxSplits: 1)
        let pathOnly = String(pathComponents[0]).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        var url = baseURL
        url.append(path: pathOnly)
        
        // Handle query string if present
        if pathComponents.count > 1 {
            let queryString = String(pathComponents[1])
            if var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                components.query = queryString
                if let finalURL = components.url {
                    url = finalURL
                }
            }
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        headers.forEach { req.setValue($1, forHTTPHeaderField: $0) }

        if let body {
            let data = try JSONEncoder().encode(AnyEncodable(body))
            req.httpBody = data
        }

        req.timeoutInterval = timeout ?? 20

        #if DEBUG
        print("➡️ \(method) \(url.absoluteString)")
        if let body = req.httpBody, let s = String(data: body, encoding: .utf8) {
            print("   Body: \(s)")
        }
        #endif

        var attempt = 0
        while true {
            do {
                let (data, resp) = try await session.data(for: req)
                guard let http = resp as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }

                #if DEBUG
                print("⬅️ \(http.statusCode) \(url.absoluteString)")
                if let s = String(data: data, encoding: .utf8) {
                    print("   Resp: \(s)")
                }
                #endif

                if (200..<300).contains(http.statusCode) {
                    // Handle empty response body (common for DELETE requests)
                    if data.isEmpty {
                        // If expecting Empty type, return it without decoding
                        if T.self == APIClient.Empty.self {
                            return APIClient.Empty() as! T
                        }
                        // For other types with empty body, this will likely fail decoding
                        // but we'll let it throw naturally
                    }
                    // If expecting Empty type and body is not empty, still try to decode
                    if T.self == APIClient.Empty.self {
                        return APIClient.Empty() as! T
                    }
                    return try JSONDecoder().decode(T.self, from: data)
                } else if http.statusCode == 401 {
                    // Handle 401 Unauthorized - try to refresh token
                    // Skip auto-refresh if explicitly requested or if this is a refresh endpoint
                    if skipAutoRefresh || path.contains("/auth/refresh") || path.contains("/refresh") {
                        let serverMsg = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
                        throw APIError.http(status: http.statusCode, message: serverMsg)
                    }
                    
                    // Prevent infinite retry loops (max 1 retry after refresh)
                    if attempt >= 2 {
                        // Already tried refreshing, don't retry again
                        let serverMsg = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
                        throw APIError.http(status: http.statusCode, message: serverMsg)
                    }
                    
                    // Try to refresh token
                    if let newTokens = await refreshTokenIfNeeded() {
                        // Update request with new token
                        var newHeaders = headers
                        // Replace or add authorization header with new token
                        newHeaders["Authorization"] = "Bearer \(newTokens.accessToken)"
                        
                        // Rebuild request with new token
                        var newReq = URLRequest(url: url)
                        newReq.httpMethod = method
                        newReq.setValue("application/json", forHTTPHeaderField: "Accept")
                        if body != nil {
                            newReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        }
                        newHeaders.forEach { newReq.setValue($1, forHTTPHeaderField: $0) }
                        
                        if let body {
                            let data = try JSONEncoder().encode(AnyEncodable(body))
                            newReq.httpBody = data
                        }
                        
                        req = newReq
                        attempt += 1
                        continue // Retry with new token
                    } else {
                        // Refresh failed - tokens are invalid
                        let serverMsg = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
                        throw APIError.http(status: http.statusCode, message: serverMsg)
                    }
                } else {
                    if shouldRetry(statusCode: http.statusCode), attempt < retries {
                        attempt += 1
                        try await Task.sleep(nanoseconds: UInt64(retryDelay * pow(2, Double(attempt - 1)) * 1_000_000_000))
                        continue
                    }
                    let serverMsg = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
                    throw APIError.http(status: http.statusCode, message: serverMsg)
                }
            } catch {
                if isTransient(error), attempt < retries {
                    attempt += 1
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * pow(2, Double(attempt - 1)) * 1_000_000_000))
                    continue
                }
                throw error
            }
        }
    }

    private func shouldRetry(statusCode: Int) -> Bool {
        return statusCode == 502 || statusCode == 503 || statusCode == 504
    }

    private func isTransient(_ error: Error) -> Bool {
        if let urlErr = error as? URLError {
            switch urlErr.code {
            case .timedOut, .cannotFindHost, .cannotConnectToHost, .networkConnectionLost, .dnsLookupFailed:
                return true
            default:
                return false
            }
        }
        return false
    }

    enum APIError: Error, LocalizedError {
        case http(status: Int, message: String)
        var errorDescription: String? {
            switch self {
            case .http(_, let message): return message
            }
        }
    }

    private struct AnyEncodable: Encodable {
        private let encodeFunc: (Encoder) throws -> Void
        init(_ wrapped: Encodable) {
            self.encodeFunc = wrapped.encode
        }
        func encode(to encoder: Encoder) throws { try encodeFunc(encoder) }
    }
    
    // MARK: - Token Refresh
    
    /// Sets the SessionManager reference for automatic token refresh
    func setSessionManager(_ manager: SessionManager) {
        self.sessionManager = manager
    }
    
    /// Refreshes the access token using refresh token
    /// Uses lock to prevent concurrent refresh attempts
    private func refreshTokenIfNeeded() async -> AuthTokens? {
        // Use shared lock to prevent concurrent refreshes across all APIClient instances
        APIClient.sharedRefreshLock.lock()
        
        // Check if already refreshing
        if let existingTask = APIClient.sharedRefreshTask {
            APIClient.sharedRefreshLock.unlock()
            // Wait for existing refresh to complete
            return await existingTask.value
        }
        
        // Check if we have a session manager and refresh token
        guard let sessionManager = sessionManager ?? APIClient.auth.sessionManager,
              let refreshToken = sessionManager.tokens?.refreshToken else {
            #if DEBUG
            print("⚠️ Cannot refresh token: no session manager or refresh token")
            #endif
            APIClient.sharedRefreshLock.unlock()
            return nil
        }
        
        // Create new refresh task
        let task = Task<AuthTokens?, Never> {
            do {
                #if DEBUG
                print("🔄 Refreshing access token...")
                #endif
                
                // Call refresh endpoint directly (bypassing automatic refresh to avoid infinite loop)
                // Create a temporary APIClient without session manager for refresh call
                let refreshClient = APIClient(baseKey: "AUTH_BASE_URL", fallbackKey: "API_BASE_URL")
                // Don't set session manager on refresh client to prevent recursion
                
                struct RefreshBody: Encodable { let refreshToken: String }
                let refreshHeaders = ["Authorization": "Bearer \(refreshToken)"]
                
                let newTokens = try await refreshClient.request(
                    "POST",
                    path: "/auth/refresh",
                    headers: refreshHeaders,
                    body: RefreshBody(refreshToken: refreshToken),
                    responseType: AuthTokens.self,
                    timeout: 40,
                    retries: 0, // Don't retry refresh endpoint
                    retryDelay: 0.8,
                    skipAutoRefresh: true // Don't try to refresh the refresh endpoint
                )
                
                // Update session manager with new tokens and persist
                await MainActor.run {
                    sessionManager.updateTokens(newTokens)
                    
                    // Refresh user data to ensure session is up to date
                    Task {
                        await sessionManager.refreshUserData()
                    }
                }
                
                #if DEBUG
                print("✅ Token refresh successful")
                #endif
                
                return newTokens
            } catch {
                #if DEBUG
                print("❌ Token refresh failed: \(error)")
                #endif
                
                // Refresh failed - clear tokens
                await MainActor.run {
                    Task {
                        await sessionManager.logout()
                    }
                }
                
                return nil
            }
        }
        
        APIClient.sharedRefreshTask = task
        APIClient.sharedRefreshLock.unlock()
        
        let result = await task.value
        
        APIClient.sharedRefreshLock.lock()
        APIClient.sharedRefreshTask = nil
        APIClient.sharedRefreshLock.unlock()
        
        return result
    }
}
