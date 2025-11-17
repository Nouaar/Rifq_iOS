//
//  ChatService.swift
//  vet.tn
//

import Foundation

final class ChatService {
    static let shared = ChatService()
    
    private let api = APIClient.auth
    
    private init() {}
    
    // MARK: - Get All Conversations
    
    func getConversations(accessToken: String) async throws -> [Conversation] {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        return try await api.request(
            "GET",
            path: "/messages/conversations",
            headers: headers,
            responseType: [Conversation].self,
            timeout: 30,
            retries: 1
        )
    }
    
    // MARK: - Get or Create Conversation
    
    func getOrCreateConversation(participantId: String, accessToken: String) async throws -> Conversation {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        let body = CreateConversationRequest(participantId: participantId)
        return try await api.request(
            "POST",
            path: "/messages/conversations",
            headers: headers,
            body: body,
            responseType: Conversation.self,
            timeout: 30,
            retries: 1
        )
    }
    
    // MARK: - Get Messages for Conversation
    
    func getMessages(conversationId: String, accessToken: String) async throws -> [ChatMessage] {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        return try await api.request(
            "GET",
            path: "/messages/conversations/\(conversationId)",
            headers: headers,
            responseType: [ChatMessage].self,
            timeout: 30,
            retries: 1
        )
    }
    
    // MARK: - Send Message
    
    func sendMessage(recipientId: String, content: String, conversationId: String?, accessToken: String) async throws -> ChatMessage {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        let body = CreateMessageRequest(recipientId: recipientId, content: content, conversationId: conversationId)
        return try await api.request(
            "POST",
            path: "/messages",
            headers: headers,
            body: body,
            responseType: ChatMessage.self,
            timeout: 30,
            retries: 1
        )
    }
    
    // MARK: - Send Audio Message (Multipart)
    
    func sendAudioMessage(recipientId: String, content: String, conversationId: String?, audioURL: URL, accessToken: String) async throws -> ChatMessage {
        guard let audioData = try? Data(contentsOf: audioURL) else {
            throw NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to read audio file"])
        }
        
        func url(from key: String) -> URL? {
            guard let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String,
                  let url = URL(string: raw) else { return nil }
            return url
        }
        let base = url(from: "AUTH_BASE_URL") ?? url(from: "API_BASE_URL")
        guard var url = base else {
            throw NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing AUTH_BASE_URL/API_BASE_URL in Info.plist"])
        }
        url.append(path: "/messages")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        var body = Data()
        
        // Add form fields
        func appendField(_ name: String, _ value: String?, to data: inout Data) {
            guard let value = value else { return }
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        appendField("recipientId", recipientId, to: &body)
        appendField("content", content, to: &body)
        if let conversationId = conversationId {
            appendField("conversationId", conversationId, to: &body)
        }
        
        // Add audio file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ChatService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        return try JSONDecoder().decode(ChatMessage.self, from: data)
    }
    
    // MARK: - Update Message
    
    func updateMessage(messageId: String, content: String, accessToken: String) async throws -> ChatMessage {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        struct UpdateMessageRequest: Encodable {
            let content: String
        }
        let body = UpdateMessageRequest(content: content)
        return try await api.request(
            "PATCH",
            path: "/messages/\(messageId)",
            headers: headers,
            body: body,
            responseType: ChatMessage.self,
            timeout: 30,
            retries: 1
        )
    }
    
    // MARK: - Delete Message
    
    func deleteMessage(messageId: String, accessToken: String) async throws -> ChatMessage {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        return try await api.request(
            "DELETE",
            path: "/messages/\(messageId)",
            headers: headers,
            responseType: ChatMessage.self,
            timeout: 30,
            retries: 1
        )
    }
    
    // MARK: - Mark Messages as Read
    
    func markAsRead(conversationId: String, accessToken: String) async throws {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        _ = try await api.request(
            "POST",
            path: "/messages/conversations/\(conversationId)/read",
            headers: headers,
            body: APIClient.Empty(),
            responseType: APIClient.Empty.self,
            timeout: 25,
            retries: 1
        )
    }
    
    // MARK: - Delete Conversation
    
    func deleteConversation(conversationId: String, accessToken: String) async throws {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        _ = try await api.request(
            "DELETE",
            path: "/messages/conversations/\(conversationId)",
            headers: headers,
            body: nil,
            responseType: APIClient.Empty.self,
            timeout: 30,
            retries: 1
        )
    }
}
