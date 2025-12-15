//
//  StripeService.swift
//  vet.tn
//

import Foundation
import StripePaymentSheet

final class StripeService {
    static let shared = StripeService()
    
    private let publishableKey: String
    
    private init() {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "STRIPE_PUBLISHABLE_KEY") as? String else {
            fatalError("STRIPE_PUBLISHABLE_KEY not found in Info.plist")
        }
        self.publishableKey = key
        StripeAPI.defaultPublishableKey = publishableKey
        print("✅ Stripe initialized with key: \(publishableKey.prefix(20))...")
    }
}