//
//  SubscriptionModels.swift
//  vet.tn
//

import Foundation

// MARK: - Subscription Status
enum SubscriptionStatus: String, Codable, Equatable {
    case active = "active"
    case expiresSoon = "expires_soon"
    case canceled = "canceled"
    case expired = "expired"
    case pending = "pending"
    case none = "none"
}

// MARK: - Subscription Model
struct Subscription: Codable, Equatable {
    let id: String
    let userId: String
    let role: String // "vet" or "sitter"
    let status: SubscriptionStatus
    let stripeSubscriptionId: String?
    let stripeCustomerId: String?
    let currentPeriodStart: Date?
    let currentPeriodEnd: Date?
    let cancelAtPeriodEnd: Bool?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case role
        case status
        case stripeSubscriptionId
        case stripeCustomerId
        case currentPeriodStart
        case currentPeriodEnd
        case cancelAtPeriodEnd
        case createdAt
        case updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Allow empty id for "none" status subscriptions
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        role = try container.decode(String.self, forKey: .role)
        status = try container.decode(SubscriptionStatus.self, forKey: .status)
        stripeSubscriptionId = try? container.decode(String.self, forKey: .stripeSubscriptionId)
        stripeCustomerId = try? container.decode(String.self, forKey: .stripeCustomerId)
        cancelAtPeriodEnd = try? container.decode(Bool.self, forKey: .cancelAtPeriodEnd)
        
        // Handle date decoding
        if let dateString = try? container.decode(String.self, forKey: .currentPeriodStart) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            currentPeriodStart = formatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString)
        } else {
            currentPeriodStart = nil
        }
        
        if let dateString = try? container.decode(String.self, forKey: .currentPeriodEnd) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            currentPeriodEnd = formatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString)
        } else {
            currentPeriodEnd = nil
        }
        
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            createdAt = formatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString)
        } else {
            createdAt = nil
        }
        
        if let dateString = try? container.decode(String.self, forKey: .updatedAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            updatedAt = formatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString)
        } else {
            updatedAt = nil
        }
    }
    
    // Manual initializer for creating default subscriptions
    init(
        id: String,
        userId: String,
        role: String,
        status: SubscriptionStatus,
        stripeSubscriptionId: String? = nil,
        stripeCustomerId: String? = nil,
        currentPeriodStart: Date? = nil,
        currentPeriodEnd: Date? = nil,
        cancelAtPeriodEnd: Bool? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.role = role
        self.status = status
        self.stripeSubscriptionId = stripeSubscriptionId
        self.stripeCustomerId = stripeCustomerId
        self.currentPeriodStart = currentPeriodStart
        self.currentPeriodEnd = currentPeriodEnd
        self.cancelAtPeriodEnd = cancelAtPeriodEnd
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var isActive: Bool {
        status == .active && !isExpired
    }
    
    var isExpired: Bool {
        guard let endDate = currentPeriodEnd else { return true }
        return endDate < Date()
    }
    
    var daysUntilExpiration: Int? {
        guard let endDate = currentPeriodEnd else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: endDate)
        return components.day
    }
    
    var willExpireSoon: Bool {
        guard let days = daysUntilExpiration else { return false }
        return days <= 7 && days > 0 // Within 7 days
    }
    
    // Equatable conformance
    static func == (lhs: Subscription, rhs: Subscription) -> Bool {
        return lhs.id == rhs.id &&
               lhs.userId == rhs.userId &&
               lhs.role == rhs.role &&
               lhs.status == rhs.status &&
               lhs.stripeSubscriptionId == rhs.stripeSubscriptionId &&
               lhs.stripeCustomerId == rhs.stripeCustomerId &&
               lhs.currentPeriodStart == rhs.currentPeriodStart &&
               lhs.currentPeriodEnd == rhs.currentPeriodEnd &&
               lhs.cancelAtPeriodEnd == rhs.cancelAtPeriodEnd
    }
}

// MARK: - Create Subscription Request
struct CreateSubscriptionRequest: Codable {
    let role: String // "vet" or "sitter"
    let paymentMethodId: String? // Stripe payment method ID (optional for test mode)
}

// MARK: - Subscription Response
struct SubscriptionResponse: Codable {
    let subscription: Subscription
    let clientSecret: String? // For Stripe PaymentSheet
    let message: String?
}

// MARK: - Cancel Subscription Response
struct CancelSubscriptionResponse: Codable {
    let subscription: Subscription
    let message: String?
}

