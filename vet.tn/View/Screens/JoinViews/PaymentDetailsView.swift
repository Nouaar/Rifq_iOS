//
//  PaymentDetailsView.swift
//  vet.tn
//

import SwiftUI
import StripePaymentSheet

struct PaymentDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager
    let role: ProfessionalRole
    let subscriptionPrice: Double
    
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @State private var paymentSheet: PaymentSheet?
    
    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Top Bar
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.vetTitle)
                                .frame(width: 32, height: 32)
                                .background(Color.vetCardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.vetStroke, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.vetTitle)
                                .frame(width: 32, height: 32)
                                .background(Color.vetCardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.vetStroke, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Complete Your Subscription")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.vetTitle)
                        
                        HStack {
                            Text("$\(String(format: "%.1f", subscriptionPrice))/month")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.vetCanyon)
                            
                            Text("•")
                                .foregroundColor(.vetSubtitle)
                            
                            Text(role.title)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.vetTitle)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    
                    // Subscription Benefits
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What You'll Get")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.vetTitle)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            BenefitRow(icon: "map.fill", text: "Appear in discover list and map")
                            BenefitRow(icon: "calendar.badge.clock", text: "Receive booking requests from pet owners")
                            BenefitRow(icon: "calendar", text: "Manage your schedule and appointments")
                            BenefitRow(icon: "person.text.rectangle", text: "Build your professional profile")
                            BenefitRow(icon: "message.fill", text: "Connect with pet owners via chat")
                        }
                        .padding(16)
                        .background(Color.vetCardBackground)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.vetStroke, lineWidth: 1))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 16)
                    
                    // Security Info
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Secure Payment")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.green)
                            
                            Text("Your payment is processed securely by Stripe. We never store your card details.")
                                .font(.system(size: 13))
                                .foregroundColor(.vetSubtitle)
                        }
                    }
                    .padding(16)
                    .background(Color.green.opacity(0.1))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.3), lineWidth: 1))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    
                    // Error Message
                    if let error = errorMessage {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.red)
                            
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.3), lineWidth: 1))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                    }
                    
                    // Pay Button
                    Button {
                        Task {
                            await createSubscriptionAndPay()
                        }
                    } label: {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity, minHeight: 56)
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16, weight: .bold))
                                
                                Text("Pay $\(String(format: "%.1f", subscriptionPrice))/month")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 56)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isProcessing ? Color.vetCanyon.opacity(0.6) : Color.vetCanyon)
                    )
                    .disabled(isProcessing)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showSuccess) {
            SubscriptionManagementView()
        }
    }
    
    // MARK: - Create Subscription and Handle Payment
    
    @MainActor
    private func createSubscriptionAndPay() async {
        isProcessing = true
        errorMessage = nil
        
        guard let accessToken = session.tokens?.accessToken else {
            errorMessage = "Please log in to subscribe"
            isProcessing = false
            return
        }
        
        do {
            let subscriptionService = SubscriptionService.shared
            
            // Step 1: Create subscription on backend (returns clientSecret)
            let response = try await subscriptionService.createSubscription(
                role: role.rawValue,
                accessToken: accessToken
            )
            
            guard let clientSecret = response.clientSecret else {
                // No payment required (test mode or already paid)
                showSuccess = true
                isProcessing = false
                return
            }
            
            // Step 2: Present Stripe PaymentSheet
            var configuration = PaymentSheet.Configuration()
            configuration.merchantDisplayName = "Rifq"
            configuration.returnURL = "rifq://stripe-redirect"
            configuration.allowsDelayedPaymentMethods = false
            
            print("🔑 Creating PaymentSheet with clientSecret: \(clientSecret.prefix(20))...")
            print("🔑 Stripe publishable key set: \(StripeAPI.defaultPublishableKey != nil)")
            
            let paymentSheet = PaymentSheet(
                paymentIntentClientSecret: clientSecret,
                configuration: configuration
            )
            
            // Present the payment sheet
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                errorMessage = "Unable to present payment sheet"
                isProcessing = false
                return
            }
            
            // Get the topmost view controller to present from
            var topController = window.rootViewController
            while let presentedController = topController?.presentedViewController {
                topController = presentedController
            }
            
            guard let presentingController = topController else {
                errorMessage = "Unable to find presenting view controller"
                isProcessing = false
                return
            }
            
            // Add small delay to ensure view hierarchy is ready
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            paymentSheet.present(from: presentingController) { result in
                Task { @MainActor in
                    await handlePaymentResult(result)
                }
            }
            
        } catch {
            if let apiError = error as? APIClient.APIError {
                if case .http(let status, let message) = apiError {
                    errorMessage = message.isEmpty ? "Failed to create subscription" : message
                } else {
                    errorMessage = "Failed to create subscription"
                }
            } else {
                errorMessage = error.localizedDescription
            }
            isProcessing = false
        }
    }
    
    // MARK: - Handle Payment Result
    
    @MainActor
    private func handlePaymentResult(_ result: PaymentSheetResult) async {
        switch result {
        case .completed:
            // Payment succeeded - webhook will activate subscription
            // Navigate to subscription management
            showSuccess = true
            
        case .canceled:
            // User canceled payment
            errorMessage = "Payment cancelled. You can try again or the subscription will remain pending."
            
        case .failed(let error):
            // Payment failed
            errorMessage = "Payment failed: \(error.localizedDescription)"
        }
        
        isProcessing = false
    }
}

// MARK: - Benefit Row

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.green)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.vetTitle)
            
            Spacer()
        }
    }
}
// MARK: - Previews

#Preview("Payment Details – Light") {
    let store: ThemeStore = { let s = ThemeStore(); s.selection = .light; return s }()
    return NavigationStack {
        PaymentDetailsView(
            role: .veterinarian,
            subscriptionPrice: 30.0
        )
        .environmentObject(store)
        .environmentObject(SessionManager())
        .preferredColorScheme(.light)
    }
}

#Preview("Payment Details – Dark") {
    let store: ThemeStore = { let s = ThemeStore(); s.selection = .dark; return s }()
    return NavigationStack {
        PaymentDetailsView(
            role: .petSitter,
            subscriptionPrice: 30.0
        )
        .environmentObject(store)
        .environmentObject(SessionManager())
        .preferredColorScheme(.dark)
    }
}


