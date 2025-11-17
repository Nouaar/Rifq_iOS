//
//  BookingModels.swift
//  vet.tn
//

import Foundation

struct Booking: Codable, Identifiable {
    let id: String
    let ownerId: String
    let providerId: String
    let providerType: String // "vet" or "sitter"
    let petId: String?
    let serviceType: String
    let description: String?
    let dateTime: String // ISO date string
    let duration: Int?
    let price: Double?
    let status: BookingStatus
    let rejectionReason: String?
    let completedAt: String?
    let cancelledAt: String?
    let cancellationReason: String?
    let createdAt: String?
    let updatedAt: String?
    
    // Populated fields (optional, may be present in response)
    let owner: BookingUser?
    let provider: BookingUser?
    let pet: BookingPet?
    
    enum CodingKeys: String, CodingKey {
        case id
        case _id
        case ownerId
        case owner
        case providerId
        case provider
        case providerType
        case petId
        case pet
        case serviceType
        case description
        case dateTime
        case duration
        case price
        case status
        case rejectionReason
        case completedAt
        case cancelledAt
        case cancellationReason
        case createdAt
        case updatedAt
        case created
        case updated
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
        
        // Decode ownerId / owner into locals, then assign once
        let decodedOwnerId: String
        let decodedOwner: BookingUser?
        if let ownerId = try? c.decode(String.self, forKey: .ownerId) {
            decodedOwnerId = ownerId
            decodedOwner = nil
        } else if let owner = try? c.decode(BookingUser.self, forKey: .owner) {
            decodedOwnerId = owner.id
            decodedOwner = owner
        } else {
            decodedOwnerId = ""
            decodedOwner = nil
        }
        self.ownerId = decodedOwnerId
        self.owner = decodedOwner
        
        // Decode providerId / provider into locals, then assign once
        let decodedProviderId: String
        let decodedProvider: BookingUser?
        if let providerId = try? c.decode(String.self, forKey: .providerId) {
            decodedProviderId = providerId
            decodedProvider = nil
        } else if let provider = try? c.decode(BookingUser.self, forKey: .provider) {
            decodedProviderId = provider.id
            decodedProvider = provider
        } else {
            decodedProviderId = ""
            decodedProvider = nil
        }
        self.providerId = decodedProviderId
        self.provider = decodedProvider
        
        self.providerType = try c.decode(String.self, forKey: .providerType)
        self.petId = try? c.decode(String.self, forKey: .petId)
        self.serviceType = try c.decode(String.self, forKey: .serviceType)
        self.description = try? c.decode(String.self, forKey: .description)
        
        // Handle dateTime
        if let dateTime = try? c.decode(String.self, forKey: .dateTime) {
            self.dateTime = dateTime
        } else {
            self.dateTime = ""
        }
        
        self.duration = try? c.decode(Int.self, forKey: .duration)
        self.price = try? c.decode(Double.self, forKey: .price)
        
        // Handle status
        if let statusStr = try? c.decode(String.self, forKey: .status) {
            self.status = BookingStatus(rawValue: statusStr) ?? .pending
        } else {
            self.status = .pending
        }
        
        self.rejectionReason = try? c.decode(String.self, forKey: .rejectionReason)
        
        if let completedAt = try? c.decode(String.self, forKey: .completedAt) {
            self.completedAt = completedAt
        } else {
            self.completedAt = nil
        }
        
        if let cancelledAt = try? c.decode(String.self, forKey: .cancelledAt) {
            self.cancelledAt = cancelledAt
        } else {
            self.cancelledAt = nil
        }
        
        self.cancellationReason = try? c.decode(String.self, forKey: .cancellationReason)
        
        // Handle createdAt
        if let createdAt = try? c.decode(String.self, forKey: .createdAt) {
            self.createdAt = createdAt
        } else if let created = try? c.decode(String.self, forKey: .created) {
            self.createdAt = created
        } else {
            self.createdAt = nil
        }
        
        // Handle updatedAt
        if let updatedAt = try? c.decode(String.self, forKey: .updatedAt) {
            self.updatedAt = updatedAt
        } else if let updated = try? c.decode(String.self, forKey: .updated) {
            self.updatedAt = updated
        } else {
            self.updatedAt = nil
        }
        
        // Handle populated pet (assign once)
        self.pet = try? c.decode(BookingPet.self, forKey: .pet)
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(ownerId, forKey: .ownerId)
        try c.encode(providerId, forKey: .providerId)
        try c.encode(providerType, forKey: .providerType)
        if let petId = petId {
            try c.encode(petId, forKey: .petId)
        }
        try c.encode(serviceType, forKey: .serviceType)
        if let description = description {
            try c.encode(description, forKey: .description)
        }
        try c.encode(dateTime, forKey: .dateTime)
        if let duration = duration {
            try c.encode(duration, forKey: .duration)
        }
        if let price = price {
            try c.encode(price, forKey: .price)
        }
        try c.encode(status.rawValue, forKey: .status)
        if let rejectionReason = rejectionReason {
            try c.encode(rejectionReason, forKey: .rejectionReason)
        }
        if let completedAt = completedAt {
            try c.encode(completedAt, forKey: .completedAt)
        }
        if let cancelledAt = cancelledAt {
            try c.encode(cancelledAt, forKey: .cancelledAt)
        }
        if let cancellationReason = cancellationReason {
            try c.encode(cancellationReason, forKey: .cancellationReason)
        }
        if let createdAt = createdAt {
            try c.encode(createdAt, forKey: .createdAt)
        }
        if let updatedAt = updatedAt {
            try c.encode(updatedAt, forKey: .updatedAt)
        }
        // Note: We don't encode populated fields (owner, provider, pet) as they're read-only from server
    }
}

enum BookingStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case rejected = "rejected"
    case completed = "completed"
    case cancelled = "cancelled"
}

struct BookingUser: Codable {
    let id: String
    let name: String?
    let email: String?
    let profileImage: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case _id
        case name
        case email
        case profileImage
        case avatarUrl
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        
        if let id = try? c.decode(String.self, forKey: .id) {
            self.id = id
        } else if let id = try? c.decode(String.self, forKey: ._id) {
            self.id = id
        } else {
            throw DecodingError.keyNotFound(CodingKeys.id, .init(codingPath: decoder.codingPath, debugDescription: "Missing id/_id"))
        }
        
        self.name = try? c.decode(String.self, forKey: .name)
        self.email = try? c.decode(String.self, forKey: .email)
        
        if let profileImage = try? c.decode(String.self, forKey: .profileImage) {
            self.profileImage = profileImage
        } else {
            self.profileImage = try? c.decode(String.self, forKey: .avatarUrl)
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
        if let profileImage = profileImage {
            try c.encode(profileImage, forKey: .profileImage)
        }
    }
}

struct BookingPet: Codable {
    let id: String
    let name: String?
    let species: String?
    let breed: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case _id
        case name
        case species
        case breed
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        
        if let id = try? c.decode(String.self, forKey: .id) {
            self.id = id
        } else if let id = try? c.decode(String.self, forKey: ._id) {
            self.id = id
        } else {
            throw DecodingError.keyNotFound(CodingKeys.id, .init(codingPath: decoder.codingPath, debugDescription: "Missing id/_id"))
        }
        
        self.name = try? c.decode(String.self, forKey: .name)
        self.species = try? c.decode(String.self, forKey: .species)
        self.breed = try? c.decode(String.self, forKey: .breed)
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        if let name = name {
            try c.encode(name, forKey: .name)
        }
        if let species = species {
            try c.encode(species, forKey: .species)
        }
        if let breed = breed {
            try c.encode(breed, forKey: .breed)
        }
    }
}

struct CreateBookingRequest: Codable {
    let providerId: String
    let providerType: String // "vet" or "sitter"
    let petId: String?
    let serviceType: String
    let description: String?
    let dateTime: String // ISO date string
    let duration: Int?
    let price: Double?
}

struct UpdateBookingRequest: Codable {
    let status: String?
    let rejectionReason: String?
    let cancellationReason: String?
}
