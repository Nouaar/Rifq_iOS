//
//  ChatModels.swift
//  vet.tn
//

import Foundation

// MARK: - Helper Models

private struct SenderObject: Codable {
    let id: String
    let _id: String?
    let email: String?
    let name: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case _id
        case email
        case name
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let id = try? c.decode(String.self, forKey: .id) {
            self.id = id
        } else if let id = try? c.decode(String.self, forKey: ._id) {
            self.id = id
        } else {
            self.id = ""
        }
        self._id = try? c.decode(String.self, forKey: ._id)
        self.email = try? c.decode(String.self, forKey: .email)
        self.name = try? c.decode(String.self, forKey: .name)
    }
}

// MARK: - Message Model

struct ChatMessage: Codable, Identifiable {
    let id: String
    let conversationId: String
    let senderId: String
    let recipientId: String
    let content: String
    let createdAt: String
    let readAt: String?
    let isDeleted: Bool?
    let editedAt: String?
    let audioURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case _id
        case conversationId
        case conversation
        case senderId
        case sender
        case recipientId
        case recipient
        case content
        case text
        case message
        case createdAt
        case created
        case readAt
        case read
        case isDeleted
        case deleted
        case editedAt
        case audioURL
        case audio_url
    }
    
    init(
        id: String,
        conversationId: String,
        senderId: String,
        recipientId: String,
        content: String,
        createdAt: String,
        readAt: String? = nil,
        isDeleted: Bool? = nil,
        editedAt: String? = nil,
        audioURL: String? = nil
    ) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.recipientId = recipientId
        self.content = content
        self.createdAt = createdAt
        self.readAt = readAt
        self.isDeleted = isDeleted
        self.editedAt = editedAt
        self.audioURL = audioURL
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle id
        if let id = try? c.decode(String.self, forKey: .id) {
            self.id = id
        } else if let id = try? c.decode(String.self, forKey: ._id) {
            self.id = id
        } else {
            throw DecodingError.keyNotFound(CodingKeys.id, .init(codingPath: decoder.codingPath, debugDescription: "Missing id/_id"))
        }
        
        // Handle conversationId
        if let convId = try? c.decode(String.self, forKey: .conversationId) {
            self.conversationId = convId
        } else if let convId = try? c.decode(String.self, forKey: .conversation) {
            self.conversationId = convId
        } else {
            self.conversationId = ""
        }
        
        // Handle senderId
        if let sender = try? c.decode(String.self, forKey: .senderId) {
            self.senderId = sender
        } else if let sender = try? c.decode(String.self, forKey: .sender) {
            self.senderId = sender
        } else if let senderObj = try? c.decode(SenderObject.self, forKey: .sender) {
            // If sender is an object, extract the _id
            self.senderId = senderObj.id
        } else {
            self.senderId = ""
        }
        
        // Handle recipientId
        if let recipient = try? c.decode(String.self, forKey: .recipientId) {
            self.recipientId = recipient
        } else if let recipient = try? c.decode(String.self, forKey: .recipient) {
            self.recipientId = recipient
        } else {
            self.recipientId = ""
        }
        
        // Handle content
        if let content = try? c.decode(String.self, forKey: .content) {
            self.content = content
        } else if let text = try? c.decode(String.self, forKey: .text) {
            self.content = text
        } else if let message = try? c.decode(String.self, forKey: .message) {
            self.content = message
        } else {
            self.content = ""
        }
        
        // Handle createdAt
        if let created = try? c.decode(String.self, forKey: .createdAt) {
            self.createdAt = created
        } else if let created = try? c.decode(String.self, forKey: .created) {
            self.createdAt = created
        } else {
            self.createdAt = ""
        }
        
        // Handle readAt
        if let readAt = try? c.decode(String.self, forKey: .readAt) {
            self.readAt = readAt
        } else {
            self.readAt = try? c.decode(String.self, forKey: .read)
        }
        
        // Handle isDeleted
        if let deleted = try? c.decode(Bool.self, forKey: .isDeleted) {
            self.isDeleted = deleted
        } else if let deleted = try? c.decode(Bool.self, forKey: .deleted) {
            self.isDeleted = deleted
        } else {
            self.isDeleted = nil
        }
        
        // Handle editedAt
        self.editedAt = try? c.decode(String.self, forKey: .editedAt)
        
        // Handle audioURL
        if let audioURL = try? c.decode(String.self, forKey: .audioURL) {
            self.audioURL = audioURL
        } else {
            self.audioURL = try? c.decode(String.self, forKey: .audio_url)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(conversationId, forKey: .conversationId)
        try c.encode(senderId, forKey: .senderId)
        try c.encode(recipientId, forKey: .recipientId)
        try c.encode(content, forKey: .content)
        try c.encode(createdAt, forKey: .createdAt)
        if let readAt = readAt {
            try c.encode(readAt, forKey: .readAt)
        }
        if let isDeleted = isDeleted {
            try c.encode(isDeleted, forKey: .isDeleted)
        }
        if let editedAt = editedAt {
            try c.encode(editedAt, forKey: .editedAt)
        }
        if let audioURL = audioURL {
            try c.encode(audioURL, forKey: .audioURL)
        }
    }
}

// MARK: - Conversation Model

struct Conversation: Codable, Identifiable {
    let id: String
    let participantIds: [String]
    let lastMessage: ChatMessage?
    let lastMessageAt: String?
    let unreadCount: Int?
    let participants: [ConversationParticipant]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case _id
        case participantIds
        case participants
        case lastMessage
        case lastMessageAt
        case updatedAt
        case unreadCount
    }
    
    init(
        id: String,
        participantIds: [String],
        lastMessage: ChatMessage? = nil,
        lastMessageAt: String? = nil,
        unreadCount: Int? = nil,
        participants: [ConversationParticipant]? = nil
    ) {
        self.id = id
        self.participantIds = participantIds
        self.lastMessage = lastMessage
        self.lastMessageAt = lastMessageAt
        self.unreadCount = unreadCount
        self.participants = participants
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle id
        if let id = try? c.decode(String.self, forKey: .id) {
            self.id = id
        } else if let id = try? c.decode(String.self, forKey: ._id) {
            self.id = id
        } else {
            throw DecodingError.keyNotFound(CodingKeys.id, .init(codingPath: decoder.codingPath, debugDescription: "Missing id/_id"))
        }
        
        // Handle participantIds
        if let ids = try? c.decode([String].self, forKey: .participantIds) {
            self.participantIds = ids
        } else if let participants = try? c.decode([ConversationParticipant].self, forKey: .participants) {
            self.participantIds = participants.map { $0.id }
        } else {
            self.participantIds = []
        }
        
        self.lastMessage = try? c.decode(ChatMessage.self, forKey: .lastMessage)
        
        if let lastAt = try? c.decode(String.self, forKey: .lastMessageAt) {
            self.lastMessageAt = lastAt
        } else {
            self.lastMessageAt = try? c.decode(String.self, forKey: .updatedAt)
        }
        
        self.unreadCount = try? c.decode(Int.self, forKey: .unreadCount) ?? 0
        self.participants = try? c.decode([ConversationParticipant].self, forKey: .participants)
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(participantIds, forKey: .participantIds)
        if let lastMessage = lastMessage {
            try c.encode(lastMessage, forKey: .lastMessage)
        }
        if let lastMessageAt = lastMessageAt {
            try c.encode(lastMessageAt, forKey: .lastMessageAt)
        }
        if let unreadCount = unreadCount {
            try c.encode(unreadCount, forKey: .unreadCount)
        }
        if let participants = participants {
            try c.encode(participants, forKey: .participants)
        }
    }
}

struct ConversationParticipant: Codable {
    let id: String
    let name: String?
    let email: String?
    let avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case _id
        case name
        case email
        case avatarUrl
        case profileImage
        case avatar
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        
        if let id = try? c.decode(String.self, forKey: .id) {
            self.id = id
        } else if let id = try? c.decode(String.self, forKey: ._id) {
            self.id = id
        } else {
            self.id = ""
        }
        
        self.name = try? c.decode(String.self, forKey: .name)
        self.email = try? c.decode(String.self, forKey: .email)
        
        if let avatar = try? c.decode(String.self, forKey: .avatarUrl) {
            self.avatarUrl = avatar
        } else if let profile = try? c.decode(String.self, forKey: .profileImage) {
            self.avatarUrl = profile
        } else {
            self.avatarUrl = try? c.decode(String.self, forKey: .avatar)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        if let name = name {
            try c.encode(name, forKey: .name)
        }
        if let email = email {
            try c.encode(email, forKey: .email)
        }
        if let avatarUrl = avatarUrl {
            try c.encode(avatarUrl, forKey: .avatarUrl)
        }
    }
}

// MARK: - Create Message Request

struct CreateMessageRequest: Encodable {
    let recipientId: String
    let content: String
    let conversationId: String?
}

// MARK: - Create Conversation Request

struct CreateConversationRequest: Encodable {
    let participantId: String
}

