//
//  SubscriptionModels.swift
//  vet.tn
//

import Foundation

// MARK: - Subscription Status
enum SubscriptionStatus: String, Codable, Equatable {
    case active = "active"
    case pendingVerification = "pending_verification" // After payment, before email verification
    case canceled = "canceled" // Subscription canceled (at end of period)
    case expiresSoon = "expires_soon" // Subscription will expire soon (scheduled to cancel)
    case gracePeriod = "grace_period" // Payment failed, Stripe retrying
    case pending = "pending" // Generic pending state (if needed)
    case none = "none" // No subscription
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
    
    /// Returns true if subscription is active and user should have professional role
    /// Includes expiresSoon status - user keeps role until subscription is truly canceled (date expired)
    var isActive: Bool {
        let effective = effectiveStatus
        return effective == .active || effective == .expiresSoon
    }
    
    /// Returns true if user should appear on map/discover page
    /// Only active subscriptions should appear (not expiresSoon)
    var shouldAppearOnMap: Bool {
        effectiveStatus == .active
    }
    
    /// Returns true if subscription is in a state that allows professional role
    /// (active, expiresSoon, or pending verification - user paid but hasn't verified email yet)
    /// User keeps professional role until subscription is truly canceled (date expired)
    var hasProfessionalAccess: Bool {
        let effective = effectiveStatus
        return effective == .active || effective == .expiresSoon || status == .pendingVerification
    }
    
    /// Days until next renewal (for active subscriptions) or expiration
    var daysUntilRenewal: Int? {
        guard let endDate = currentPeriodEnd else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: endDate)
        return components.day
    }
    
    /// Returns true if subscription will renew soon (within 7 days)
    /// This is not a status - just a reminder for active subscriptions
    var willRenewSoon: Bool {
        guard status == .active, let days = daysUntilRenewal else { return false }
        return days <= 7 && days > 0 // Within 7 days
    }
    
    /// Returns true if subscription is scheduled to cancel at period end
    var isScheduledToCancel: Bool {
        cancelAtPeriodEnd == true && status == .active
    }
    
    /// Returns the effective status based on cancelAtPeriodEnd and expiration date
    /// If user canceled but date hasn't expired, status is "expires_soon"
    /// Only after expiration should it be "canceled"
    var effectiveStatus: SubscriptionStatus {
        // If subscription is scheduled to cancel at period end
        if cancelAtPeriodEnd == true {
            // Check if the expiration date has passed
            if let periodEnd = currentPeriodEnd {
                if periodEnd > Date() {
                    // Date hasn't expired yet - show as "expires_soon"
                    return .expiresSoon
                } else {
                    // Date has expired - show as "canceled"
                    return .canceled
                }
            } else {
                // No expiration date, but scheduled to cancel - treat as expires_soon
                return .expiresSoon
            }
        }
        
        // If backend says canceled and cancelAtPeriodEnd is false, subscription was immediately canceled
        // Return the actual status (canceled) - don't convert to expires_soon
        if status == .canceled && cancelAtPeriodEnd == false {
            return .canceled
        }
        
        // If backend says canceled but cancelAtPeriodEnd is true or nil, check date
        if status == .canceled {
            if let periodEnd = currentPeriodEnd {
                if periodEnd > Date() {
                    // Date hasn't expired yet - show as "expires_soon" (can reactivate)
                    return .expiresSoon
                } else {
                    // Date has expired - show as "canceled" (must create new)
                    return .canceled
                }
            }
        }
        
        // Otherwise, use the actual status from backend
        return status
    }
    
    /// Returns true if subscription can be reactivated (expires_soon and date hasn't expired)
    var canReactivate: Bool {
        return effectiveStatus == .expiresSoon
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

// MARK: - Verify Subscription Response
struct VerifySubscriptionResponse: Codable {
    let success: Bool?
    let message: String?
    let subscription: Subscription
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case subscription
    }
}

