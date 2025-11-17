//
//  EmailVerificationView.swift
//  vet.tn
//

import SwiftUI
import Combine

struct EmailVerificationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager

    @State private var code: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusedIndex: Int?

    // Email-based
    let email: String
    // If true, we will trigger resend automatically on appear (useful after signup timeout)
    // NOTE: Disabled for now while testing backend email sending.
    var autoResendOnAppear: Bool = false
    // If true, this is from a conversion flow (vet/sitter), so we should dismiss instead of showing MainTabView
    var isFromConversion: Bool = false

    // MARK: - Resend cooldown (disabled for now)
    // private let resendCooldown: Int = 30

    // Navigation
    @State private var isVerified = false

    // UI state
    @State private var isSubmitting = false
    // @State private var isResending = false
    @State private var localError: String?
    @State private var infoMessage: String?

    // Resend timer (disabled for now)
    // @State private var secondsLeft: Int = 30
    // @State private var canResend: Bool = false
    // private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Always resolve the email from session first, falling back to the initializer
    private var resolvedEmail: String {
        let base = session.pendingEmail ?? session.user?.email ?? email
        return base.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()

            VStack(spacing: 22) {
                // Top bar with Back (outlined gray)
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Text("Back")
                            .font(.vetSmallFont())
                            .foregroundStyle(Color.vetSubtitle)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.vetSubtitle, lineWidth: 1)
                            )
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Spacer(minLength: 20)

                Text("Verify your email")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.vetTitle)

                Text("We sent a 6-digit code to:")
                    .foregroundStyle(Color.vetSubtitle)

                Text(resolvedEmail.isEmpty ? "—" : resolvedEmail)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.vetCanyon)
                    .textSelection(.enabled)

                // Code inputs
                HStack(spacing: 12) {
                    ForEach(0..<6, id: \.self) { i in
                        TextField("", text: $code[i])
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .focused($focusedIndex, equals: i)
                            .frame(width: 45, height: 55)
                            .background(Color.vetInputBackground)
                            .foregroundStyle(Color.vetTitle)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.vetStroke))
                            .cornerRadius(10)
                            .onChange(of: code[i]) { newValue in
                                // Keep only last digit
                                let filtered = newValue.filter(\.isNumber)
                                if filtered.count > 1 {
                                    code[i] = String(filtered.last!)
                                } else {
                                    code[i] = filtered
                                }
                                // Auto-advance/back
                                if !code[i].isEmpty && i < 5 {
                                    focusedIndex = i + 1
                                } else if code[i].isEmpty && i > 0 {
                                    focusedIndex = i - 1
                                }
                                clearErrors()
                            }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 6)

                // Info / Error
                if let info = infoMessage, !info.isEmpty {
                    Text(info)
                        .foregroundColor(.green)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                if let err = localError ?? session.lastError, !err.isEmpty {
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
                        Text(isSubmitting ? "VERIFYING..." : "CONFIRM")
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
        .onAppear {
            focusedIndex = 0
        }
        .fullScreenCover(isPresented: $isVerified) {
            MainTabView()
        }
    }

    private var isCodeComplete: Bool {
        code.joined().count == 6
    }

    private func clearErrors() {
        localError = nil
        infoMessage = nil
        session.lastError = nil
    }

    private func submitCode() async {
        guard isCodeComplete, !isSubmitting else { return }
        clearErrors()

        let emailToUse = resolvedEmail.lowercased()
        guard !emailToUse.isEmpty else {
            localError = "Missing email for verification."
            return
        }

        isSubmitting = true
        let joined = code.joined()

        let ok = await session.verifyEmail(email: emailToUse, code: joined)
        isSubmitting = false

        if ok {
            // After successful verification, user data is already refreshed in SessionManager.verifyEmail
            if isFromConversion {
                // For conversion flow, just dismiss to go back to previous screen
                // The role is already updated in the session
                dismiss()
            } else {
                // For initial signup flow, show MainTabView via fullScreenCover
            isVerified = true
            }
        } else {
            localError = session.lastError ?? "Verification failed. Please try again."
        }
    }
}

// MARK: - Previews
#Preview("Email Verification – Light") {
    let store: ThemeStore = { let s = ThemeStore(); s.selection = .light; return s }()
    return EmailVerificationView(email: "user@example.com")
        .environmentObject(store)
        .environmentObject(SessionManager())
        .preferredColorScheme(.light)
}

#Preview("Email Verification – Dark") {
    let store: ThemeStore = { let s = ThemeStore(); s.selection = .dark; return s }()
    return EmailVerificationView(email: "user@example.com")
        .environmentObject(store)
        .environmentObject(SessionManager())
        .preferredColorScheme(.dark)
}

