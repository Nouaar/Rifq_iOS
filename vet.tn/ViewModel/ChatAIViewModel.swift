import Foundation
import SwiftUI
import Combine

@MainActor
final class ChatAIViewModel: ObservableObject {
    @Published var messages: [ChatMsg] = []
    @Published var isLoading: Bool = false  
    @Published var errorMessage: String?

    var sessionManager: SessionManager?

    init() {
        messages = [
            .init(role: .assistant, text: "👋 Hi! I'm your AI vet assistant. I can help answer questions about your pet's health, nutrition, behavior, and general care. How can I help you today?")
        ]
    }



    func sendMessage(userMessage: String, imageBase64: String? = nil) async {
        var conversationHistory: String? = nil
        
        let userContent: String
        if let imageBase64 = imageBase64, !imageBase64.isEmpty {
            if userMessage.isEmpty {
                userContent = "analyse this image"
            } else {
                userContent = "\(userMessage)\n[photo attached]"
            }
        } else {
            userContent = userMessage
        }
        
        defer {
            isLoading = false
        }
        
        do {
            errorMessage = nil
            
            let userMsg = ChatMsg(role: .user, text: userContent, image: nil)
            messages.append(userMsg)
            
            isLoading = true 
            
            conversationHistory = messages
                .suffix(10)
                .map { msg in
                    if msg.role == .user {
                        return "User: \(msg.text)"
                    } else {
                        return "Assistant: \(msg.text)"
                    }
                }
                .joined(separator: "\n")
            
            if conversationHistory?.isEmpty ?? true {
                conversationHistory = nil
            }
            
            let messageForRequest = userContent.isEmpty ? "analyse this image" : userContent
            
            if let imageBase64 = imageBase64, !imageBase64.isEmpty {
                do {
                    let pureBase64 = imageBase64.contains(",") ? String(imageBase64.split(separator: ",").last ?? "") : imageBase64
                    guard let imageData = Data(base64Encoded: pureBase64) else {
                        throw NSError(domain: "ChatAIViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
                    }
                    
                    _ = try await sendMultipart(message: messageForRequest, context: conversationHistory, imageData: imageData)
                } catch ChatError.payloadTooLarge {
                    _ = try await sendJSON(message: messageForRequest, imageBase64: imageBase64, context: conversationHistory)
                } catch {
                    _ = try await sendJSON(message: messageForRequest, imageBase64: imageBase64, context: conversationHistory)
                }
            } else {
                _ = try await sendJSON(message: messageForRequest, imageBase64: nil, context: conversationHistory)
            }

            
            do {
                try await withTimeout(seconds: 30) {
                    await self.fetchHistory(setLoading: false)
                }
            } catch {
                print("⚠️ fetchHistory failed after sending message: \(error.localizedDescription)")
            }
            
        } catch {
            if let httpError = error as? ChatError,
               case .serverError(let status, _) = httpError,
               status == 413,
               let imageBase64 = imageBase64,
               !imageBase64.isEmpty {
                print("⚠️ Image too large (413). Retrying without image.")
                do {
                    let retryRequest = ChatbotMessageRequest(
                        message: userContent.isEmpty ? "analyse this image" : userContent,
                        context: conversationHistory,
                        image: nil
                    )
                    
                    _ = try await APIClient.shared.request(
                        "POST",
                        path: "/chatbot/message",
                        headers: sessionManager?.authorizedHeaders() ?? [:],
                        body: retryRequest,
                        responseType: ChatbotResponse.self,
                        timeout: 120, 
                        retries: 0
                    )
                    
                
                    await fetchHistory(setLoading: false)
                    errorMessage = nil
                } catch {
                    let retryError = error
                    let errorMsg: String
                    if let urlError = retryError as? URLError {
                        switch urlError.code {
                        case .timedOut:
                            errorMsg = "Request timed out. The AI is taking longer than expected. Please try again."
                        case .notConnectedToInternet:
                            errorMsg = "No internet connection. Please check your network."
                        case .cannotConnectToHost:
                            errorMsg = "Cannot connect to server. Please try again later."
                        default:
                            errorMsg = "Failed to get AI response: \(retryError.localizedDescription)"
                        }
                    } else {
                        errorMsg = "Failed to get AI response: \(retryError.localizedDescription)"
                    }
                    errorMessage = errorMsg
                    messages.append(.init(role: .assistant, text: "I'm sorry, I'm having trouble connecting right now. Please try again."))
                    print("❌ Chatbot retry error: \(errorMsg)")
                }
            } else {
                let errorMsg: String
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .timedOut:
                        errorMsg = "Request timed out. The AI is taking longer than expected. Please try again."
                    case .notConnectedToInternet:
                        errorMsg = "No internet connection. Please check your network."
                    case .cannotConnectToHost:
                        errorMsg = "Cannot connect to server. Please try again later."
                    default:
                        errorMsg = "Failed to get AI response: \(error.localizedDescription)"
                    }
                } else {
                    errorMsg = "Failed to get AI response: \(error.localizedDescription)"
                }
                errorMessage = errorMsg
                messages.append(.init(role: .assistant, text: "I'm sorry, I'm having trouble connecting right now. Please try again."))
                print("❌ Chatbot error: \(errorMsg)")
            }
        }
    }

    func fetchHistory(limit: Int = 50, offset: Int = 0, setLoading: Bool = true) async {
        
        defer {
            if setLoading {
                isLoading = false  
            }
        }
        
        do {
            if setLoading {
                isLoading = true  
            }
            errorMessage = nil

            guard let sessionManager = sessionManager else {
                return
            }
            
            let headers = sessionManager.authorizedHeaders()
            
            func getBaseURL() -> URL {
                if let raw = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
                   let url = URL(string: raw) {
                    return url
                }
                return URL(string: "https://rifq.onrender.com")!
            }
            
            let baseURL = getBaseURL()
            var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
            urlComponents.path = "/chatbot/history"
            urlComponents.queryItems = [
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "offset", value: "\(offset)")
            ]
            
            guard let url = urlComponents.url else {
                throw NSError(domain: "ChatAIViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
            request.timeoutInterval = 30 
            
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30
            config.timeoutIntervalForResource = 45
            let session = URLSession(configuration: config)
            
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw NSError(domain: "ChatAIViewModel", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
            
            let wrapper = try JSONDecoder().decode(HistoryWrapper.self, from: data)
            
            var mapped: [ChatMsg] = []
            for item in wrapper.messages {
            let role: ChatMsg.Role
            switch item.role.lowercased() {
            case "assistant": role = .assistant
                case "user": role = .user
                default: role = .assistant
            }

            var img: UIImage? = nil
            if let urlStr = item.imageUrl, let url = URL(string: urlStr) {
                    do {
                        let data = try await withTimeout(seconds: 10) {
                            try await self.fetchData(from: url)
                        }
                        img = UIImage(data: data)
                    } catch {
                        print("⚠️ Failed to load image: \(error.localizedDescription)")
                    }
                }
                
                mapped.append(ChatMsg(role: role, text: item.content, image: img))
            }
            
            if !mapped.isEmpty {
                let previousCount = messages.count
                messages = mapped
                print("✅ Fetched \(mapped.count) messages from history (was \(previousCount))")
            } else {
                print("⚠️ fetchHistory returned empty messages array - keeping existing messages")
            }
        } catch {
            print("⚠️ Failed fetching history: \(error.localizedDescription)")
            
            if let urlError = error as? URLError {
                print("⚠️ URLError: \(urlError.localizedDescription), code: \(urlError.code.rawValue)")
                if urlError.code == .timedOut {
                    print("⚠️ fetchHistory timed out - this may cause loading to hang")
                }
            } else if let nsError = error as NSError? {
                print("⚠️ NSError: \(nsError.localizedDescription), domain: \(nsError.domain), code: \(nsError.code)")
            }
        }
    }

    func clearHistoryServer() async {
        defer {
            isLoading = false  
        }
        
        do {
            isLoading = true  
            errorMessage = nil
            
            guard let sessionManager = sessionManager else {
                return
            }
            
            let headers = sessionManager.authorizedHeaders()
            
            let response = try await APIClient.shared.request(
                "DELETE",
                path: "/chatbot/history",
                headers: headers,
                body: nil,
                responseType: APIClient.Empty.self,
                timeout: 30,
                retries: 0
            )
            
            messages = [
                .init(role: .assistant, text: "Chat cleared. How can I help you today?")
            ]
            errorMessage = nil
        } catch {
            errorMessage = "Failed to clear history: \(error.localizedDescription)"
        }
    }


    private func sendJSON(message: String, imageBase64: String?, context: String?) async throws {
        guard let sessionManager = sessionManager else {
            throw NSError(domain: "ChatAIViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Session manager not available"])
        }
        
        let headers = sessionManager.authorizedHeaders()
        guard !headers.isEmpty, headers["Authorization"] != nil else {
            throw NSError(domain: "ChatAIViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Authentication required"])
        }
        
        let request = ChatbotMessageRequest(
            message: message,
            context: context,
            image: imageBase64
        )


        _ = try await APIClient.shared.request(
            "POST",
            path: "/chatbot/message",
            headers: headers,
            body: request,
            responseType: ChatbotResponse.self,
            timeout: 120, 
            retries: 0
        )
        
        print("✅ Chatbot message sent successfully")
    }

    private func sendMultipart(message: String, context: String?, imageData: Data) async throws {
        guard let sessionManager = sessionManager else {
            throw NSError(domain: "ChatAIViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Session manager not available"])
        }
        
        guard let authHeader = sessionManager.authorizedHeaders()["Authorization"] else {
            throw NSError(domain: "ChatAIViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Authentication required"])
        }

        func url(from key: String) -> URL? {
            guard let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String,
                  let url = URL(string: raw) else { return nil }
            return url
        }
        let base = url(from: "AUTH_BASE_URL") ?? url(from: "API_BASE_URL")
        guard var url = base else {
            throw NSError(domain: "ChatAIViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing AUTH_BASE_URL/API_BASE_URL in Info.plist"])
        }
        url.append(path: "/chatbot/message")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120 
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue(authHeader, forHTTPHeaderField: "Authorization")

        var body = Data()

        func appendField(_ name: String, _ value: String?, to data: inout Data) {
            guard let value = value else { return }
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(value)\r\n".data(using: .utf8)!)
        }

        appendField("message", message, to: &body)
        appendField("context", context, to: &body)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body


        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 180
        config.waitsForConnectivity = true
        let session = URLSession(configuration: config)
        
        let (data, urlResponse) = try await session.data(for: request)
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw NSError(domain: "ChatAIViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 413 {
                throw ChatError.payloadTooLarge
            }
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ChatError.serverError(status: httpResponse.statusCode, body: errorMessage)
        }
        

        _ = try JSONDecoder().decode(ChatbotResponse.self, from: data)
        print("✅ Chatbot multipart message sent successfully")
    }


    private func compressImageData(from image: UIImage, maxKB: Int) -> Data? {
        let maxBytes = maxKB * 1024
        var quality: CGFloat = 0.9
        let minQuality: CGFloat = 0.2
        while quality >= minQuality {
            if let data = image.jpegData(compressionQuality: quality), data.count <= maxBytes {
                return data
            }
            quality -= 0.15
        }

        let targetSize = CGSize(width: 1024, height: 1024)
        let scaled = image.scaled(to: targetSize)
        return scaled.jpegData(compressionQuality: 0.6)
    }

    private func fetchData(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = 10 
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        let session = URLSession(configuration: config)
        
        let (data, resp) = try await session.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw URLError(.timedOut)
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    // MARK: - Context building

    private func buildConversationContext(limit: Int = 10) -> String? {
        // Ignore top system message and keep the latest exchanges
        let recent = messages
            .filter { $0.role != .system }
            .suffix(limit)

        guard !recent.isEmpty else { return nil }

        let lines = recent.map { msg -> String in
            let roleLabel: String
            switch msg.role {
            case .assistant: roleLabel = "Assistant"
            case .user: roleLabel = "User"
            case .system: roleLabel = "System"
            }

            if msg.image != nil {
                return "\(roleLabel): \(msg.text) [Image attached]"
            } else {
                return "\(roleLabel): \(msg.text)"
            }
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - Support types

extension ChatAIViewModel {
    struct HistoryWrapper: Codable {
        let messages: [HistoryItem]
        let total: Int
    }

    struct HistoryItem: Codable {
        let _id: String?
        let role: String
        // server field containing text
        let content: String
        let imageUrl: String?
        let imagePrompt: String?
        let createdAt: String
        let updatedAt: String?
        
        var id: String? { _id }
    }

    struct ChatbotMessageRequest: Encodable {
        let message: String
        let context: String?
        let image: String?
    }

    struct ChatbotResponse: Codable {
        let response: String
        let timestamp: String
    }

    enum ChatError: Error {
        case payloadTooLarge
        case serverError(status: Int, body: String)
    }
}

// MARK: - UIImage helpers

private extension UIImage {
    func scaled(to targetSize: CGSize) -> UIImage {
        let aspectWidth = targetSize.width / size.width
        let aspectHeight = targetSize.height / size.height
        let aspectRatio = min(aspectWidth, aspectHeight)

        let newSize = CGSize(width: size.width * aspectRatio, height: size.height * aspectRatio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - ChatMsg model

struct ChatMsg: Identifiable {
    enum Role { case user, assistant, system }
    let id = UUID()
    let role: Role
    let text: String
    let image: UIImage?

    init(role: Role, text: String, image: UIImage? = nil) {
        self.role = role
        self.text = text
        self.image = image
    }
}

