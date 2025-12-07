//
//  SubscriptionManager.swift
//  vet.tn
//

import Foundation
import Combine

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var subscription: Subscription?
    @Published var showExpirationAlert = false
    @Published var expirationMessage: String?
    
    private var checkTimer: Timer?
    private let subscriptionService = SubscriptionService.shared
    private var lastAlertShownDate: Date?
    private let alertCooldownInterval: TimeInterval = 3600 // Don't show same alert more than once per hour
    
    private init() {
        startPeriodicCheck()
    }
    
    // MARK: - Periodic Subscription Check
    /// Starts periodic checking of subscription status
    func startPeriodicCheck() {
        // Check every 30 minutes (more frequent for expiration alerts)
        checkTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            // Timer will be handled by MainTabView with access token
        }
    }
    
    /// Stops periodic checking
    func stopPeriodicCheck() {
        checkTimer?.invalidate()
        checkTimer = nil
    }
    
    // MARK: - Check Subscription Status
    /// Checks subscription status and shows alerts if needed
    func checkSubscriptionStatus(accessToken: String? = nil) async {
        // If no access token provided, we can't check
        // This should be called from SessionManager with the token
        guard let token = accessToken else { return }
        
        do {
            let sub = try await subscriptionService.getSubscription(accessToken: token)
            subscription = sub
            
            // Check if subscription will renew soon (Scenario 4 - reminder)
            if sub.status == .active && sub.willRenewSoon {
                if let days = sub.daysUntilRenewal {
                    // Only show alert if we haven't shown it recently (cooldown)
                    let now = Date()
                    if let lastAlert = lastAlertShownDate {
                        let timeSinceLastAlert = now.timeIntervalSince(lastAlert)
                        if timeSinceLastAlert < alertCooldownInterval {
                            return // Still in cooldown period
                        }
                    }
                    
                    expirationMessage = "Your subscription will renew in \(days) day\(days == 1 ? "" : "s")."
                    showExpirationAlert = true
                    lastAlertShownDate = now
                }
            }
            
            // Check if subscription is in grace period (Scenario 3 - payment failed)
            if sub.status == .gracePeriod {
                // Show grace period alert regardless of cooldown
                expirationMessage = "Your payment failed. Please update your payment method to avoid service interruption."
                showExpirationAlert = true
                lastAlertShownDate = Date()
            }
        } catch {
            #if DEBUG
            print("⚠️ Failed to check subscription status: \(error)")
            #endif
        }
    }
    
    // MARK: - Refresh Subscription
    /// Refreshes subscription data
    func refreshSubscription(accessToken: String) async {
        await checkSubscriptionStatus(accessToken: accessToken)
    }
}

