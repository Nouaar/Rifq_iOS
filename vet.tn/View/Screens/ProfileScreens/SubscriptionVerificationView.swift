//
//  SubscriptionVerificationView.swift
//  vet.tn
//
//  View for verifying subscription with code

import SwiftUI

struct SubscriptionVerificationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager
    
    let subscription: Subscription?
    
    @State private var code: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusedIndex: Int?
    
    @State private var isSubmitting = false
    @State private var localError: String?
    @State private var isVerified = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.vetBackground.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.vetCanyon)
                        
                        Text("Confirm Subscription")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.vetTitle)
                        
                        Text("Enter the 6-digit code sent to your email to activate your subscription")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.vetSubtitle)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    // Code input fields
                    HStack(spacing: 12) {
                        ForEach(0..<6, id: \.self) { index in
                            TextField("", text: $code[index])
                                .keyboardType(.numberPad)
                                .textContentType(.oneTimeCode)
                                .frame(width: 50, height: 60)
                                .background(Color.vetCardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(focusedIndex == index ? Color.vetCanyon : Color.vetStroke, lineWidth: 2)
                                )
                                .font(.system(size: 24, weight: .bold))
                                .multilineTextAlignment(.center)
                                .focused($focusedIndex, equals: index)
                                .onChange(of: code[index]) { oldValue, newValue in
                                    // Only allow digits
                                    let filtered = newValue.filter { $0.isNumber }
                                    if filtered != newValue {
                                        code[index] = filtered
                                    }
                                    
                                    // Move to next field
                                    if !filtered.isEmpty && index < 5 {
                                        focusedIndex = index + 1
                                    }
                                    
                                    // Auto-submit when all fields are filled
                                    if isCodeComplete {
                                        Task {
                                            await submitCode()
                                        }
                                    }
                                }
                                .onChange(of: focusedIndex) { oldValue, newValue in
                                    if newValue == index && code[index].isEmpty {
                                        // Clear field when focused if empty
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    if let err = localError, !err.isEmpty {
                        Text(err)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    Button {
                        Task { await submitCode() }
                    } label: {
                        ZStack {
                            Text(isSubmitting ? "CONFIRMING..." : "CONFIRM")
                                .font(.system(size: 16, weight: .bold))
                                .opacity(isSubmitting ? 0.001 : 1)
                            if isSubmitting {
                                ProgressView().tint(.white)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 56)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(isCodeComplete ? Color.vetCanyon : Color.vetCanyon.opacity(0.4))
                    )
                    .foregroundColor(.white)
                    .disabled(!isCodeComplete || isSubmitting)
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.vetTitle)
                    }
                }
            }
        }
        .onAppear {
            focusedIndex = 0
        }
        .onChange(of: isVerified) { oldValue, newValue in
            if newValue {
                dismiss()
            }
        }
    }
    
    private var isCodeComplete: Bool {
        code.joined().count == 6
    }
    
    private func clearErrors() {
        localError = nil
        session.lastError = nil
    }
    
    private func submitCode() async {
        guard isCodeComplete, !isSubmitting else { return }
        clearErrors()
        
        guard let accessToken = session.tokens?.accessToken else {
            localError = "Please log in to confirm subscription"
            return
        }
        
        isSubmitting = true
        let joined = code.joined()
        
        do {
            let subscriptionService = SubscriptionService.shared
            let verifiedSubscription = try await subscriptionService.verifySubscription(code: joined, accessToken: accessToken)
            
            #if DEBUG
            print("✅ Subscription verified successfully: status=\(verifiedSubscription.status.rawValue)")
            #endif
            
            // Refresh user data to get updated subscription and role
            await session.refreshUserData()
            
            // Small delay to show success before dismissing
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            isVerified = true
        } catch {
            #if DEBUG
            print("❌ Subscription verification failed: \(error)")
            #endif
            
            if let apiError = error as? APIClient.APIError {
                if case .http(let status, let message) = apiError {
                    switch status {
                    case 400, 401:
                        localError = message.isEmpty ? "Invalid confirmation code. Please try again." : message
                    case 404:
                        localError = "Verification endpoint not found. Please contact support."
                    default:
                        localError = message.isEmpty ? "Could not confirm subscription. Please try again." : message
                    }
                } else {
                    localError = "Could not confirm subscription. Please try again."
                }
            } else if let decodingError = error as? DecodingError {
                localError = "Invalid response from server. Please try again."
                #if DEBUG
                print("Decoding error: \(decodingError)")
                #endif
            } else {
                localError = error.localizedDescription
            }
        }
        
        isSubmitting = false
    }
}

#Preview {
    SubscriptionVerificationView(subscription: nil)
        .environmentObject(SessionManager())
        .environmentObject(ThemeStore())
}

