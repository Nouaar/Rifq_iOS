//
//  NotificationModels.swift
//  vet.tn
//

import Foundation

struct AppNotification: Codable, Identifiable {
    let id: String
    let recipientId: String
    let senderId: String
    let type: String
    let title: String
    let message: String
    let bookingId: String?
    let messageRefId: String?
    let read: Bool
    let readAt: String?
    let createdAt: String?
    let metadata: NotificationMetadata?
    
    // Populated fields (optional)
    let sender: BookingUser?
    let booking: Booking?
    
    enum CodingKeys: String, CodingKey {
        case id
        case _id
        case recipientId
        case recipient
        case senderId
        case sender
        case type
        case title
        case message
        case bookingId
        case booking
        case messageRefId
        case messageRef
        case read
        case readAt
        case createdAt
        case created
        case metadata
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
        
        // Handle recipientId
        if let recipientId = try? c.decode(String.self, forKey: .recipientId) {
            self.recipientId = recipientId
        } else if let recipient = try? c.decode(BookingUser.self, forKey: .recipient) {
            self.recipientId = recipient.id
        } else {
            self.recipientId = ""
        }
        
        // Prepare local holders for populated fields
        var decodedSender: BookingUser? = nil
        var decodedBooking: Booking? = nil
        
        // Handle senderId (can be string or object)
        if let senderId = try? c.decode(String.self, forKey: .senderId) {
            self.senderId = senderId
        } else if let sender = try? c.decode(BookingUser.self, forKey: .sender) {
            self.senderId = sender.id
            decodedSender = sender
        } else {
            self.senderId = ""
        }
        
        self.type = (try? c.decode(String.self, forKey: .type)) ?? ""
        self.title = (try? c.decode(String.self, forKey: .title)) ?? ""
        self.message = (try? c.decode(String.self, forKey: .message)) ?? ""
        
        // Handle bookingId (can be string or object)
        if let bookingId = try? c.decode(String.self, forKey: .bookingId) {
            self.bookingId = bookingId
        } else if let booking = try? c.decode(Booking.self, forKey: .booking) {
            self.bookingId = booking.id
            decodedBooking = booking
        } else {
            self.bookingId = nil
        }
        
        // Handle messageRefId
        if let messageRefId = try? c.decode(String.self, forKey: .messageRefId) {
            self.messageRefId = messageRefId
        } else if let messageRef = try? c.decode(String.self, forKey: .messageRef) {
            self.messageRefId = messageRef
        } else {
            self.messageRefId = nil
        }
        
        self.read = (try? c.decode(Bool.self, forKey: .read)) ?? false
        self.readAt = try? c.decode(String.self, forKey: .readAt)
        
        // Handle createdAt
        if let createdAt = try? c.decode(String.self, forKey: .createdAt) {
            self.createdAt = createdAt
        } else if let created = try? c.decode(String.self, forKey: .created) {
            self.createdAt = created
        } else {
            self.createdAt = nil
        }
        
        self.metadata = try? c.decode(NotificationMetadata.self, forKey: .metadata)
        
        // Assign populated fields exactly once
        self.sender = decodedSender
        self.booking = decodedBooking
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(recipientId, forKey: .recipientId)
        try c.encode(senderId, forKey: .senderId)
        try c.encode(type, forKey: .type)
        try c.encode(title, forKey: .title)
        try c.encode(message, forKey: .message)
        if let bookingId = bookingId {
            try c.encode(bookingId, forKey: .bookingId)
        }
        if let messageRefId = messageRefId {
            try c.encode(messageRefId, forKey: .messageRefId)
        }
        try c.encode(read, forKey: .read)
        if let readAt = readAt {
            try c.encode(readAt, forKey: .readAt)
        }
        if let createdAt = createdAt {
            try c.encode(createdAt, forKey: .createdAt)
        }
        if let metadata = metadata {
            try c.encode(metadata, forKey: .metadata)
        }
        // Note: We don't encode populated fields (sender, booking) as they're read-only from server
    }
}

struct NotificationMetadata: Codable {
    let bookingId: String?
    let serviceType: String?
    let dateTime: String?
    let rejectionReason: String?
    
    enum CodingKeys: String, CodingKey {
        case bookingId
        case serviceType
        case dateTime
        case rejectionReason
    }
}

struct NotificationCountResponse: Codable {
    let count: Int
}
