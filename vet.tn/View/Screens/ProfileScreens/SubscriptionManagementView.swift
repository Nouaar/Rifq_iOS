//
//  SubscriptionManagementView.swift
//  vet.tn
//

import SwiftUI

struct SubscriptionManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager
    
    @State private var subscription: Subscription?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showCancelConfirmation = false
    @State private var showReactivateConfirmation = false
    @State private var isProcessing = false
    @State private var showExpirationAlert = false
    
    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Custom header with close button
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.vetTitle)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Text("Subscription Management")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.vetTitle)
                        
                        Spacer()
                        
                        // Invisible button for balance
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.clear)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
                    
                    if isLoading {
                        ProgressView()
                            .padding(.top, 40)
                    } else {
                        // Show subscription details if status is not "none" and id is not empty
                        if let subscription = subscription,
                           subscription.status != .none,
                           !subscription.id.isEmpty {
                            subscriptionDetailsView(subscription: subscription)
                        } else {
                            noSubscriptionView
                        }
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(.horizontal, 16)
                    }
                }
            }
        }
        .task {
            await loadSubscription()
        }
        .onChange(of: subscription) { oldValue, newValue in
            #if DEBUG
            print("📱 Subscription changed: old=\(oldValue?.status.rawValue ?? "nil"), new=\(newValue?.status.rawValue ?? "nil")")
            #endif
        }
        .onChange(of: isLoading) { oldValue, newValue in
            #if DEBUG
            print("📱 Loading state changed: \(oldValue) -> \(newValue)")
            #endif
        }
        .alert("Cancel Subscription", isPresented: $showCancelConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm", role: .destructive) {
                Task {
                    await cancelSubscription()
                }
            }
        } message: {
            Text("Your subscription will remain active until the end of the current billing period. After that, your role will be downgraded to owner and you will no longer appear in discover lists.")
        }
        .alert("Reactivate Subscription", isPresented: $showReactivateConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm") {
                Task {
                    await reactivateSubscription()
                }
            }
        } message: {
            Text("Your subscription will be reactivated and will continue to renew automatically.")
        }
        .alert("Subscription Expiring Soon", isPresented: $showExpirationAlert) {
            Button("Renew Now") {
                // Navigate to payment/renewal
                Task {
                    await renewSubscription()
                }
            }
            Button("Later", role: .cancel) { }
        } message: {
            if let days = subscription?.daysUntilExpiration {
                Text("Your subscription expires in \(days) day\(days == 1 ? "" : "s"). Renew now to continue your service.")
            } else {
                Text("Your subscription is about to expire. Renew now to continue your service.")
            }
        }
    }
    
    private func subscriptionDetailsView(subscription: Subscription) -> some View {
        VStack(spacing: 20) {
            // Status Card
            VStack(spacing: 12) {
                HStack {
                    Text("Status")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.vetTitle)
                    Spacer()
                    statusBadge(subscription.status)
                }
                
                if subscription.status == .active || subscription.status == .expiresSoon {
                    if let endDate = subscription.currentPeriodEnd {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Period")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.vetSubtitle)
                            
                            if let startDate = subscription.currentPeriodStart {
                                Text("\(formatDate(startDate)) - \(formatDate(endDate))")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color.vetTitle)
                            }
                            
                            if subscription.cancelAtPeriodEnd == true {
                                Text("Cancels at period end")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.orange)
                            } else if let days = subscription.daysUntilExpiration {
                                if days > 0 {
                                    if subscription.status == .expiresSoon {
                                        Text("Expires in \(days) day\(days == 1 ? "" : "s")")
                                            .font(.system(size: 13))
                                            .foregroundStyle(Color.orange)
                                    } else {
                                        Text("Renews in \(days) day\(days == 1 ? "" : "s")")
                                            .font(.system(size: 13))
                                            .foregroundStyle(subscription.willExpireSoon ? Color.orange : Color.vetSubtitle)
                                    }
                                } else {
                                    Text("Expired")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.red)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(16)
            .background(Color.vetCardBackground)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.vetStroke, lineWidth: 1))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            
            // Role Info
            VStack(alignment: .leading, spacing: 8) {
                Text("Subscription Type")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.vetSubtitle)
                Text(subscription.role.capitalized)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.vetTitle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.vetCardBackground)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.vetStroke, lineWidth: 1))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            
            // Actions
            if subscription.status == .active {
                if subscription.cancelAtPeriodEnd == true {
                    Button {
                        showReactivateConfirmation = true
                    } label: {
                        Text("Reactivate Subscription")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color.vetCanyon)
                            .foregroundStyle(Color.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                } else {
                    Button {
                        showCancelConfirmation = true
                    } label: {
                        Text("Cancel Subscription")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color.red.opacity(0.1))
                            .foregroundStyle(Color.red)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                }
                
                // Don't show "Renew" button if subscription is active and not scheduled to cancel
                // It will auto-renew automatically
            } else if subscription.status == .expiresSoon {
                // Show renew button for expires soon status
                Button {
                    Task {
                        await renewSubscription()
                    }
                } label: {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity, minHeight: 50)
                    } else {
                        Text("Renew Subscription")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 50)
                    }
                }
                .background(Color.orange)
                .foregroundStyle(Color.white)
                .cornerRadius(12)
                .disabled(isProcessing)
                .padding(.horizontal, 16)
                
                // Also show cancel button
                Button {
                    showCancelConfirmation = true
                } label: {
                    Text("Cancel Subscription")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.red.opacity(0.1))
                        .foregroundStyle(Color.red)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 16)
            } else if subscription.status == .expired || subscription.status == .canceled {
                Button {
                    Task {
                        await renewSubscription()
                    }
                } label: {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity, minHeight: 50)
                    } else {
                        Text("Renew Subscription")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 50)
                    }
                }
                .background(Color.vetCanyon)
                .foregroundStyle(Color.white)
                .cornerRadius(12)
                .disabled(isProcessing)
                .padding(.horizontal, 16)
            }
        }
        .padding(.top, 20)
    }
    
    private var noSubscriptionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard")
                .font(.system(size: 48))
                .foregroundStyle(Color.vetSubtitle)
            
            Text("No Active Subscription")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.vetTitle)
            
            Text("Subscribe to become a vet or pet sitter and appear in discover lists.")
                .font(.system(size: 14))
                .foregroundStyle(Color.vetSubtitle)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 60)
        .onAppear {
            #if DEBUG
            print("📱 noSubscriptionView appeared")
            #endif
        }
    }
    
    private func statusBadge(_ status: SubscriptionStatus) -> some View {
        let (text, color) = statusInfo(status)
        return Text(text)
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .cornerRadius(8)
    }
    
    private func statusInfo(_ status: SubscriptionStatus) -> (String, Color) {
        switch status {
        case .active:
            return ("Active", .green)
        case .expiresSoon:
            return ("Expires Soon", .orange)
        case .canceled:
            return ("Paused", .orange)
        case .expired:
            return ("Expired", .red)
        case .pending:
            return ("Pending", .blue)
        case .none:
            return ("None", .gray)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    @MainActor
    private func loadSubscription() async {
        isLoading = true
        errorMessage = nil
        
        guard let accessToken = session.tokens?.accessToken else {
            errorMessage = "Please log in to view subscription"
            isLoading = false
            return
        }
        
        do {
            let subscriptionService = SubscriptionService.shared
            let sub = try await subscriptionService.getSubscription(accessToken: accessToken)
            
            #if DEBUG
            print("✅ Loaded subscription: status=\(sub.status.rawValue), id=\(sub.id.isEmpty ? "empty" : sub.id)")
            #endif
            
            // Always set subscription, even if it's "none" status
            subscription = sub
            #if DEBUG
            print("📱 Subscription state updated: status=\(sub.status.rawValue), willShowDetails=\(sub.status != .none && !sub.id.isEmpty)")
            #endif
            
            // Check if subscription is expiring soon
            if sub.willExpireSoon && sub.status == .active {
                showExpirationAlert = true
            }
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("❌ Failed to load subscription: \(error)")
            #endif
            // Set subscription to nil so we show "No Active Subscription"
            subscription = nil
        }
        
        isLoading = false
    }
    
    @MainActor
    private func cancelSubscription() async {
        isProcessing = true
        errorMessage = nil
        
        guard var accessToken = session.tokens?.accessToken else {
            errorMessage = "Please log in to cancel subscription"
            isProcessing = false
            return
        }
        
        let subscriptionService = SubscriptionService.shared
        
        do {
            let response = try await subscriptionService.cancelSubscription(accessToken: accessToken)
            subscription = response.subscription
            
            // Refresh user data to update role if needed
            await session.refreshUserData()
        } catch {
            // If we get a 401, try refreshing token and retry once
            if case APIClient.APIError.http(let status, _) = error, status == 401 {
                await session.refreshTokensIfPossible()
                if let refreshedToken = session.tokens?.accessToken {
                    do {
                        let response = try await subscriptionService.cancelSubscription(accessToken: refreshedToken)
                        subscription = response.subscription
                        await session.refreshUserData()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                } else {
                    errorMessage = "Please log in again to cancel subscription"
                }
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        isProcessing = false
    }
    
    @MainActor
    private func reactivateSubscription() async {
        isProcessing = true
        errorMessage = nil
        
        guard var accessToken = session.tokens?.accessToken else {
            errorMessage = "Please log in to reactivate subscription"
            isProcessing = false
            return
        }
        
        let subscriptionService = SubscriptionService.shared
        
        do {
            subscription = try await subscriptionService.reactivateSubscription(accessToken: accessToken)
            
            // Refresh user data
            await session.refreshUserData()
        } catch {
            // If we get a 401, try refreshing token and retry once
            if case APIClient.APIError.http(let status, _) = error, status == 401 {
                await session.refreshTokensIfPossible()
                if let refreshedToken = session.tokens?.accessToken {
                    do {
                        subscription = try await subscriptionService.reactivateSubscription(accessToken: refreshedToken)
                        await session.refreshUserData()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                } else {
                    errorMessage = "Please log in again to reactivate subscription"
                }
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        isProcessing = false
    }
    
    @MainActor
    private func renewSubscription() async {
        isProcessing = true
        errorMessage = nil
        
        guard let accessToken = session.tokens?.accessToken else {
            errorMessage = "Please log in to renew subscription"
            isProcessing = false
            return
        }
        
        do {
            let subscriptionService = SubscriptionService.shared
            
            // Check current subscription status
            let currentSub = try await subscriptionService.getSubscription(accessToken: accessToken)
            
            // If subscription is scheduled to cancel, reactivate it
            if (currentSub.status == .active || currentSub.status == .expiresSoon) && currentSub.cancelAtPeriodEnd == true {
                subscription = try await subscriptionService.reactivateSubscription(accessToken: accessToken)
            }
            // If subscription is expires soon or active, extend/renew it
            else if currentSub.status == .expiresSoon || currentSub.status == .active {
                subscription = try await subscriptionService.renewSubscription(accessToken: accessToken)
            }
            // If subscription is expired or canceled, create a new one
            else if currentSub.status == .expired || currentSub.status == .canceled {
                guard let currentRole = session.user?.role?.lowercased(),
                      (currentRole == "vet" || currentRole == "sitter") else {
                    errorMessage = "Unable to determine subscription role"
                    isProcessing = false
                    return
                }
                let response = try await subscriptionService.createSubscription(role: currentRole, accessToken: accessToken)
                subscription = response.subscription
            }
            
            // Refresh user data
            await session.refreshUserData()
        } catch {
            // Handle 409 conflict (subscription already exists)
            if let apiError = error as? APIClient.APIError {
                if case .http(let status, let message) = apiError, status == 409 {
                    errorMessage = "You already have an active subscription. If it's scheduled to cancel, use the 'Reactivate' button instead."
                } else {
                    errorMessage = error.localizedDescription
                }
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        isProcessing = false
    }
}

#Preview {
    SubscriptionManagementView()
        .environmentObject(SessionManager())
        .environmentObject(ThemeStore())
}

