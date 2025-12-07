//
//  SubscriptionService.swift
//  vet.tn
//

import Foundation

final class SubscriptionService {
    static let shared = SubscriptionService()
    
    private let api = APIClient.auth
    private let subscriptionPrice: Double = 30.0 // $30/month
    
    private init() {}
    
    // MARK: - Create Subscription
    /// Creates a subscription for the user (vet or sitter)
    func createSubscription(role: String, accessToken: String) async throws -> SubscriptionResponse {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        
        let body = CreateSubscriptionRequest(role: role, paymentMethodId: nil)
        
        return try await api.request(
            "POST",
            path: "/subscriptions",
            headers: headers,
            body: body,
            responseType: SubscriptionResponse.self,
            timeout: 30,
            retries: 1
        )
    }
    
    // MARK: - Get User Subscription
    /// Gets the current user's subscription
    func getSubscription(accessToken: String) async throws -> Subscription {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        
        do {
            let subscription = try await api.request(
                "GET",
                path: "/subscriptions/me",
                headers: headers,
                responseType: Subscription.self,
                timeout: 25,
                retries: 1
            )
            
            #if DEBUG
            print("✅ Successfully decoded subscription: status=\(subscription.status.rawValue), id=\(subscription.id)")
            #endif
            
            return subscription
        } catch {
            // If the response is empty or invalid, return a "none" subscription
            if let decodingError = error as? DecodingError {
                #if DEBUG
                print("⚠️ Subscription response decoding error: \(decodingError)")
                #endif
                // Return a default "none" subscription
                return Subscription(
                    id: "",
                    userId: "",
                    role: "owner",
                    status: .none,
                    stripeSubscriptionId: nil,
                    stripeCustomerId: nil,
                    currentPeriodStart: nil,
                    currentPeriodEnd: nil,
                    cancelAtPeriodEnd: nil,
                    createdAt: nil,
                    updatedAt: nil
                )
            }
            throw error
        }
    }
    
    // MARK: - Cancel Subscription
    /// Cancels the user's subscription (at period end)
    func cancelSubscription(accessToken: String) async throws -> CancelSubscriptionResponse {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        
        return try await api.request(
            "POST",
            path: "/subscriptions/cancel",
            headers: headers,
            body: APIClient.Empty(),
            responseType: CancelSubscriptionResponse.self,
            timeout: 25,
            retries: 1
        )
    }
    
    // MARK: - Reactivate Subscription
    /// Reactivates a canceled subscription
    func reactivateSubscription(accessToken: String) async throws -> Subscription {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        
        return try await api.request(
            "POST",
            path: "/subscriptions/reactivate",
            headers: headers,
            body: APIClient.Empty(),
            responseType: Subscription.self,
            timeout: 25,
            retries: 1
        )
    }
    
    // MARK: - Renew Subscription
    /// Renews/extends an active or expires soon subscription
    func renewSubscription(accessToken: String) async throws -> Subscription {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        
        return try await api.request(
            "POST",
            path: "/subscriptions/renew",
            headers: headers,
            body: APIClient.Empty(),
            responseType: Subscription.self,
            timeout: 25,
            retries: 1
        )
    }
    
    // MARK: - Resend Subscription Verification Code
    /// Resends verification code for subscription confirmation
    func resendSubscriptionVerification(accessToken: String) async throws -> MessageResponse {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        
        return try await api.request(
            "POST",
            path: "/subscriptions/resend-verification",
            headers: headers,
            body: APIClient.Empty(),
            responseType: MessageResponse.self,
            timeout: 25,
            retries: 1
        )
    }
    
    // MARK: - Verify Subscription
    /// Verifies subscription with code to activate it
    func verifySubscription(code: String, accessToken: String) async throws -> Subscription {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        
        struct VerifySubscriptionBody: Codable {
            let code: String
        }
        
        let response = try await api.request(
            "POST",
            path: "/subscriptions/verify-email",
            headers: headers,
            body: VerifySubscriptionBody(code: code),
            responseType: VerifySubscriptionResponse.self,
            timeout: 25,
            retries: 1
        )
        
        return response.subscription
    }
    
    // MARK: - Check Subscription Status
    /// Checks if subscription is active and valid
    func checkSubscriptionStatus(_ subscription: Subscription) -> (isActive: Bool, daysUntilRenewal: Int?, willRenewSoon: Bool) {
        let isActive = subscription.isActive
        let daysUntilRenewal = subscription.daysUntilRenewal
        let willRenewSoon = subscription.willRenewSoon
        
        return (isActive, daysUntilRenewal, willRenewSoon)
    }
}

