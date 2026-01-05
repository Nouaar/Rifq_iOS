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
    @State private var successMessage: String?
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
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text("Error")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.red)
                            }
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundColor(.red.opacity(0.9))
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
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
            Button("No", role: .cancel) { }
            Button("Yes") {
                Task {
                    await reactivateSubscription()
                }
            }
        } message: {
            if let subscription = subscription,
               let periodEnd = subscription.currentPeriodEnd {
                let effectiveStatus = subscription.effectiveStatus
                if effectiveStatus == .expiresSoon {
                    Text("Your subscription will expire on \(formatDate(periodEnd)). Do you want to reactivate it? It will continue to renew automatically after the current period ends.")
                } else {
                    Text("Do you want to reactivate your subscription? It will continue to renew automatically.")
                }
            } else {
                Text("Do you want to reactivate your subscription? It will continue to renew automatically.")
            }
        }
        .alert("Subscription Reminder", isPresented: $showExpirationAlert) {
            Button("View Details") {
                // Navigate to subscription management
                Task {
                    await loadSubscription()
                }
            }
            Button("Later", role: .cancel) { }
        } message: {
            if let days = subscription?.daysUntilRenewal {
                Text("Your subscription will renew in \(days) day\(days == 1 ? "" : "s").")
            } else {
                Text("Your subscription will renew soon.")
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
                    statusBadge(subscription.effectiveStatus)
                }
                
                let effectiveStatus = subscription.effectiveStatus
                if effectiveStatus == .active || effectiveStatus == .expiresSoon || subscription.status == .pending || subscription.status == .gracePeriod {
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
                            
                            if effectiveStatus == .expiresSoon {
                                if let days = subscription.daysUntilRenewal, days > 0 {
                                    Text("Expires in \(days) day\(days == 1 ? "" : "s")")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.orange)
                                } else {
                                    Text("Expires soon")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.orange)
                                }
                            } else if subscription.cancelAtPeriodEnd == true {
                                Text("Cancels at period end")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.orange)
                            } else if let days = subscription.daysUntilRenewal {
                                if days > 0 {
                                    Text("Renews in \(days) day\(days == 1 ? "" : "s")")
                                        .font(.system(size: 13))
                                        .foregroundStyle(subscription.willRenewSoon ? Color.orange : Color.vetSubtitle)
                                } else {
                                    Text("Renewing today")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.orange)
                                }
                            }
                            
                            // Show status-specific messages
                            if subscription.status == .pending {
                                Text("Payment is being processed")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.blue)
                            } else if subscription.status == .gracePeriod {
                                Text("Payment failed - update your payment method")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.red)
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
            let effectiveStatus = subscription.effectiveStatus
            if effectiveStatus == .active {
                // Active subscription - show cancel button
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
            } else if effectiveStatus == .expiresSoon {
                // Subscription is scheduled to cancel but date hasn't expired - can reactivate
                VStack(spacing: 12) {
                    if let periodEnd = subscription.currentPeriodEnd {
                        Text("Your subscription will expire on \(formatDate(periodEnd)). You can reactivate it to continue.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.vetSubtitle)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    } else {
                        Text("Your subscription is scheduled to cancel. You can reactivate it to continue.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.vetSubtitle)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    
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
                }
            } else if effectiveStatus == .canceled {
                // Subscription is truly canceled (date has expired) - must create new subscription
                // User needs to choose role again (vet or sitter)
                VStack(spacing: 12) {
                    if let periodEnd = subscription.currentPeriodEnd {
                        Text("Your subscription expired on \(formatDate(periodEnd)). Create a new subscription to continue.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.vetSubtitle)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    } else {
                        Text("Your subscription has been canceled. Create a new subscription to continue.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.vetSubtitle)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    
                    NavigationLink(destination: JoinTeamView()) {
                        Text("Subscribe Again")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color.vetCanyon)
                            .foregroundStyle(Color.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                }
            } else if subscription.status == .pending {
                // Show payment processing message for PENDING status
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.orange)
                            Text("⏳ Payment Processing")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.orange)
                        }
                        
                        Text("Your payment is being processed. Your subscription will activate automatically once payment is confirmed.")
                            .font(.system(size: 14))
                            .foregroundColor(.vetSubtitle)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Refresh button to check if webhook has activated the subscription
                    Button {
                        Task {
                            await loadSubscription()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16))
                            Text("Refresh Status")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.vetCanyon)
                        .cornerRadius(12)
                    }
                    .disabled(isProcessing)
                    
                    // Manual activation button for testing/localhost
                    Button {
                        Task {
                            await activatePendingSubscription()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 16))
                            Text("Manually Activate Subscription")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.vetCanyon)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.vetCanyon, lineWidth: 2)
                        )
                    }
                    .disabled(isProcessing)
                }
                .padding(.horizontal, 16)
            } else if subscription.status == .gracePeriod {
                // Show update payment method button for grace period
                Button {
                    // Navigate to payment details update
                    // This would typically open Stripe payment sheet or payment details view
                    Task {
                        // For now, we'll try to refresh subscription to see if payment succeeded
                        await loadSubscription()
                    }
                } label: {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity, minHeight: 50)
                    } else {
                        Text("Update Payment Method")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 50)
                    }
                }
                .background(Color.orange)
                .foregroundStyle(Color.white)
                .cornerRadius(12)
                .disabled(isProcessing)
                .padding(.horizontal, 16)
                
                Text("Your payment failed. Please update your payment method to avoid service interruption.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            } else if subscription.status == .canceled {
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
        VStack(spacing: 24) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.vetCanyon)
            
            Text("Become a Professional")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.vetTitle)
            
            Text("Subscribe to unlock premium features, get a verified badge, and choose to become a Veterinarian or Pet Sitter.")
                .font(.system(size: 14))
                .foregroundStyle(Color.vetSubtitle)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            VStack(alignment: .leading, spacing: 12) {
                benefitRow(icon: "checkmark.circle.fill", text: "Verified Badge")
                benefitRow(icon: "checkmark.circle.fill", text: "Professional Profile")
                benefitRow(icon: "checkmark.circle.fill", text: "Appear in Discover")
                benefitRow(icon: "checkmark.circle.fill", text: "Receive Bookings")
                benefitRow(icon: "checkmark.circle.fill", text: "Manage Schedule")
            }
            .padding(.horizontal, 32)
            
            Text("$30/month")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Color.vetCanyon)
            
            // Subscribe button
            Button {
                Task {
                    await createPremiumSubscription()
                }
            } label: {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity, minHeight: 56)
                } else {
                    Text("Subscribe Now")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(Color.vetCanyon)
                        .foregroundStyle(Color.white)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 32)
        }
        .padding(.top, 40)
        .onAppear {
            #if DEBUG
            print("📱 noSubscriptionView appeared")
            #endif
        }
    }
    
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.green)
                .font(.system(size: 16))
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(Color.vetTitle)
            Spacer()
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
        case .gracePeriod:
            return ("Payment Failed", .orange)
        case .expiresSoon:
            return ("Expires Soon", .orange)
        case .canceled:
            return ("Canceled", .red)
        case .pending:
            return ("Pending", .blue)
        case .pendingVerification:
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
            
            // Check if subscription will renew soon (reminder)
            if sub.willRenewSoon && sub.status == .active {
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
    private func activatePendingSubscription() async {
        isProcessing = true
        errorMessage = nil
        
        guard let accessToken = session.tokens?.accessToken else {
            errorMessage = "Please log in to activate subscription"
            isProcessing = false
            return
        }
        
        do {
            let subscriptionService = SubscriptionService.shared
            let sub = try await subscriptionService.activatePendingSubscription(accessToken: accessToken)
            
            subscription = sub
            successMessage = "Subscription activated successfully!"
            
            // Refresh user data
            await session.refreshUserData()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isProcessing = false
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
        
        // Preserve current role before canceling (in case backend changes it immediately)
        let currentRole = session.user?.role
        let currentSubscription = subscription
        
        let subscriptionService = SubscriptionService.shared
        
        do {
            let response = try await subscriptionService.cancelSubscription(accessToken: accessToken)
            subscription = response.subscription
            
            // If subscription date hasn't expired, preserve the professional role
            // The mergedUser function will handle this, but we ensure subscription has the role
            if let sub = subscription,
               let periodEnd = sub.currentPeriodEnd,
               periodEnd > Date() {
                // Date hasn't expired - subscription should keep professional role
                // The SessionManager's mergedUser will preserve it based on effectiveStatus
            }
            
            // Refresh user data - mergedUser will preserve role if subscription is expiresSoon
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
        
        guard let accessToken = session.tokens?.accessToken else {
            errorMessage = "Please log in to reactivate subscription"
            isProcessing = false
            return
        }
        
        guard let currentSubscription = subscription else {
            errorMessage = "Subscription not found"
            isProcessing = false
            return
        }
        
        let subscriptionService = SubscriptionService.shared
        let effectiveStatus = currentSubscription.effectiveStatus
        
        // If the subscription is truly expired (date has passed), we can't reactivate
        if effectiveStatus == .canceled {
            errorMessage = "Your subscription has expired. Please create a new subscription."
            isProcessing = false
            return
        }
        
        // If effective status is expiresSoon but backend status is CANCELED,
        // the backend won't allow reactivation. We need to create a new subscription instead.
        if effectiveStatus == .expiresSoon && currentSubscription.status == .canceled {
            // Check if date hasn't expired - if so, create new subscription
            if let periodEnd = currentSubscription.currentPeriodEnd, periodEnd > Date() {
                // Date hasn't expired, but backend says CANCELED - create new subscription
                do {
                    guard let currentRole = session.user?.role?.lowercased(),
                          (currentRole == "vet" || currentRole == "sitter") else {
                        errorMessage = "Unable to determine subscription role. Please ensure you have a vet or sitter role."
                        isProcessing = false
                        return
                    }
                    
                    let response = try await subscriptionService.createSubscription(role: currentRole, accessToken: accessToken)
                    subscription = response.subscription
                    await session.refreshUserData()
                } catch {
                    if let apiError = error as? APIClient.APIError {
                        if case .http(let status, let message) = apiError {
                            if status == 409 {
                                errorMessage = "You already have an active subscription. Please refresh the page."
                            } else {
                                errorMessage = parseErrorMessage(message)
                            }
                        } else {
                            errorMessage = error.localizedDescription
                        }
                    } else {
                        errorMessage = error.localizedDescription
                    }
                }
                isProcessing = false
                return
            }
        }
        
        // Try to reactivate normally
        do {
            subscription = try await subscriptionService.reactivateSubscription(accessToken: accessToken)
            
            // Refresh user data
            await session.refreshUserData()
        } catch {
            // If reactivation fails with "Cannot reactivate expired or canceled subscription"
            // and the date hasn't expired, try creating a new subscription
            if case APIClient.APIError.http(let status, let message) = error {
                if status == 400 && message.contains("Cannot reactivate expired or canceled subscription") {
                    // Check if date hasn't expired
                    if let periodEnd = currentSubscription.currentPeriodEnd, periodEnd > Date() {
                        // Date hasn't expired, but backend won't reactivate - create new subscription
                        do {
                            guard let currentRole = session.user?.role?.lowercased(),
                                  (currentRole == "vet" || currentRole == "sitter") else {
                                errorMessage = "Unable to determine subscription role. Please ensure you have a vet or sitter role."
                                isProcessing = false
                                return
                            }
                            
                            let response = try await subscriptionService.createSubscription(role: currentRole, accessToken: accessToken)
                            subscription = response.subscription
                            await session.refreshUserData()
                        } catch {
                            if let apiError = error as? APIClient.APIError {
                                if case .http(let createStatus, let createMessage) = apiError {
                                    if createStatus == 409 {
                                        errorMessage = "You already have an active subscription. Please refresh the page."
                                    } else {
                                        errorMessage = parseErrorMessage(createMessage)
                                    }
                                } else {
                                    errorMessage = error.localizedDescription
                                }
                            } else {
                                errorMessage = error.localizedDescription
                            }
                        }
                        isProcessing = false
                        return
                    } else {
                        // Date has expired - show error
                        errorMessage = "Your subscription has expired. Please create a new subscription."
                    }
                } else if status == 401 {
                    await session.refreshTokensIfPossible()
                    if let refreshedToken = session.tokens?.accessToken {
                        do {
                            subscription = try await subscriptionService.reactivateSubscription(accessToken: refreshedToken)
                            await session.refreshUserData()
                        } catch {
                            // Parse error message for better user feedback
                            if case APIClient.APIError.http(let retryStatus, let retryMessage) = error {
                                errorMessage = parseErrorMessage(retryMessage)
                            } else {
                                errorMessage = error.localizedDescription
                            }
                        }
                    } else {
                        errorMessage = "Please log in again to reactivate subscription"
                    }
                } else {
                    // Parse error message for better user feedback
                    errorMessage = parseErrorMessage(message)
                }
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        isProcessing = false
    }
    
    /// Parses error message from API response to extract user-friendly message
    private func parseErrorMessage(_ message: String) -> String {
        // Try to parse JSON error message
        if let data = message.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let errorMessage = json["message"] as? String {
            return errorMessage
        }
        // If not JSON, return as is
        return message
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
            
            // Determine which endpoint to use based on subscription status
            if currentSub.status == .canceled || currentSub.status == .none {
                // For canceled or no subscription, create a new one
                guard let currentRole = session.user?.role?.lowercased(),
                      (currentRole == "vet" || currentRole == "sitter") else {
                    errorMessage = "Unable to determine subscription role. Please ensure you have a vet or sitter role."
                    isProcessing = false
                    return
                }
                let response = try await subscriptionService.createSubscription(role: currentRole, accessToken: accessToken)
                subscription = response.subscription
            } else if currentSub.status == .active {
                // For active subscriptions, use renew endpoint (extends by 1 month)
                subscription = try await subscriptionService.renewSubscription(accessToken: accessToken)
            } else {
                // For other statuses (pending, gracePeriod, etc.), try to create new
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
            // Parse error message for better user feedback
            if let apiError = error as? APIClient.APIError {
                if case .http(let status, let message) = apiError {
                    if status == 409 {
                        errorMessage = "You already have an active subscription. If it's scheduled to cancel, use the 'Reactivate' button instead."
                    } else {
                        errorMessage = parseErrorMessage(message)
                    }
                } else {
                    errorMessage = error.localizedDescription
                }
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        isProcessing = false
    }
    
    @MainActor
    private func createPremiumSubscription() async {
        isProcessing = true
        errorMessage = nil
        
        guard let accessToken = session.tokens?.accessToken else {
            errorMessage = "Please log in to subscribe"
            isProcessing = false
            return
        }
        
        let subscriptionService = SubscriptionService.shared
        
        do {
            // Create subscription with "premium" role (user will choose vet/sitter later)
            let response = try await subscriptionService.createSubscription(role: "premium", accessToken: accessToken)
            subscription = response.subscription
            
            // Refresh user data
            await session.refreshUserData()
            
            successMessage = "Subscription created! You can now choose your professional role below."
        } catch {
            if let apiError = error as? APIClient.APIError {
                if case .http(let status, let message) = apiError {
                    if status == 409 {
                        errorMessage = "You already have a subscription. Please refresh."
                    } else {
                        errorMessage = parseErrorMessage(message)
                    }
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

