//
//  PaymentView.swift
//  vet.tn
//

import SwiftUI

struct PaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager
    
    let role: String // "vet" or "sitter"
    let onPaymentSuccess: () -> Void
    
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    
    private let subscriptionPrice = 30.0
    
    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    TopBar(title: "Subscription Payment")
                    
                    // Header
                    VStack(spacing: 12) {
                        Text("Join as \(role.capitalized)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color.vetTitle)
                        
                        Text("Subscribe to become a \(role == "vet" ? "Veterinarian" : "Pet Sitter")")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.vetSubtitle)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Pricing Card
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Text("Monthly Subscription")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.vetTitle)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("$")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(Color.vetCanyon)
                                Text("\(Int(subscriptionPrice))")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundStyle(Color.vetCanyon)
                                Text("/month")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(Color.vetSubtitle)
                            }
                        }
                        
                        Divider()
                            .background(Color.vetStroke)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            benefitRow(icon: "checkmark.circle.fill", text: "Appear in discover list")
                            benefitRow(icon: "checkmark.circle.fill", text: "Visible on map")
                            benefitRow(icon: "checkmark.circle.fill", text: "Receive bookings")
                            benefitRow(icon: "checkmark.circle.fill", text: "Manage your profile")
                            benefitRow(icon: "checkmark.circle.fill", text: "Cancel anytime")
                        }
                    }
                    .padding(20)
                    .background(Color.vetCardBackground)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.vetStroke, lineWidth: 1))
                    .cornerRadius(16)
                    .padding(.horizontal, 16)
                    
                    // Payment Info (Test Mode)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(Color.blue)
                            Text("Test Mode")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.vetTitle)
                        }
                        
                        Text("This is a test payment. No real charges will be made.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.vetSubtitle)
                    }
                    .padding(12)
                    .background(Color.blue.opacity(0.1))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.3), lineWidth: 1))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    
                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(.horizontal, 16)
                    }
                    
                    // Payment Button
                    Button {
                        Task {
                            await processPayment()
                        }
                    } label: {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity, minHeight: 56)
                        } else {
                            Text("Subscribe for $\(Int(subscriptionPrice))/month")
                                .font(.system(size: 16, weight: .bold))
                                .frame(maxWidth: .infinity, minHeight: 56)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(isProcessing ? Color.vetCanyon.opacity(0.6) : Color.vetCanyon)
                    )
                    .foregroundStyle(Color.white)
                    .disabled(isProcessing)
                    .padding(.horizontal, 16)
                    
                    // Terms
                    Text("By subscribing, you agree to our Terms of Service and Privacy Policy. Subscription will auto-renew unless canceled.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.vetSubtitle)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                }
            }
        }
        .alert("Payment Successful", isPresented: $showSuccess) {
            Button("Continue") {
                onPaymentSuccess()
            }
        } message: {
            Text("Your subscription has been created. Please verify your email to activate your account.")
        }
    }
    
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.vetCanyon)
                .font(.system(size: 16))
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(Color.vetTitle)
            Spacer()
        }
    }
    
    @MainActor
    private func processPayment() async {
        isProcessing = true
        errorMessage = nil
        
        guard let accessToken = session.tokens?.accessToken else {
            errorMessage = "Please log in to continue"
            isProcessing = false
            return
        }
        
        do {
            let subscriptionService = SubscriptionService.shared
            let response = try await subscriptionService.createSubscription(role: role, accessToken: accessToken)
            
            // In test mode, we'll simulate successful payment
            // In production, you would use Stripe PaymentSheet here with response.clientSecret
            
            // For now, assume payment is successful after creating subscription
            // The backend should handle the actual Stripe payment processing
            
            // Wait a moment to simulate payment processing
            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("❌ Payment failed: \(error)")
            #endif
        }
        
        isProcessing = false
    }
}

#Preview {
    PaymentView(role: "vet") {
        print("Payment success")
    }
    .environmentObject(SessionManager())
    .environmentObject(ThemeStore())
}

