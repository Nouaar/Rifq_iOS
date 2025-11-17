// APIClient.swift

import Foundation

final class APIClient {
    // Default app API (non-auth)
    static let shared = APIClient(baseKey: "API_BASE_URL")
    // Dedicated client for authentication endpoints
    static let auth   = APIClient(baseKey: "AUTH_BASE_URL", fallbackKey: "API_BASE_URL")

    private let baseURL: URL
    private let session: URLSession

    // baseKey is the Info.plist key that contains the base URL string.
    // If it's missing, we optionally fall back to fallbackKey.
    init(baseKey: String, fallbackKey: String? = nil, session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            // Allow longer time for first-hit cold starts on hosted backends (e.g., Render)
            config.timeoutIntervalForRequest = 40
            config.timeoutIntervalForResource = 60
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
            let fallback = URL(string: "https://rifq.onrender.com")!
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
        retryDelay: TimeInterval = 0.75
    ) async throws -> T {
        var url = baseURL
        url.append(path: path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))

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
}
