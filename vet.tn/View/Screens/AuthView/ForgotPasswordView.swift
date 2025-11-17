//
//  ForgotPasswordView.swift
//  vet.tn
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager

    @State private var email: String = ""
    @State private var isSubmitting = false
    @State private var infoMessage: String?
    @State private var errorMessage: String?
    @FocusState private var isEmailFocused: Bool

    // Navigation to code confirmation
    @State private var navigateToCode = false

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isEmailValid: Bool {
        let t = trimmedEmail
        return t.contains("@") && t.contains(".") && t.count >= 5
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vetBackground.ignoresSafeArea()

                VStack(spacing: 20) {
                    TopBar(title: "Forgot Password")

                    Text("Enter your email and we’ll send you a code to reset your password.")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.vetSubtitle)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    emailField
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    if let info = infoMessage {
                        Text(info)
                            .font(.vetSmallFont())
                            .foregroundStyle(.green)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    if let err = errorMessage {
                        Text(err)
                            .font(.vetSmallFont())
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    Button {
                        Task { await sendResetCode() }
                    } label: {
                        ZStack {
                            Text(isSubmitting ? "SENDING..." : "SEND CODE")
                                .font(.system(size: 16, weight: .bold))
                                .kerning(0.8)
                                .opacity(isSubmitting ? 0.001 : 1)
                                .frame(maxWidth: .infinity, minHeight: 56)

                            if isSubmitting {
                                ProgressView().tint(.white)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(isEmailValid ? Color.vetCanyon : Color.vetCanyon.opacity(0.4))
                    )
                    .foregroundColor(.white)
                    .disabled(!isEmailValid || isSubmitting)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

                    Spacer()
                }
            }
        }
        .onChange(of: email) { _ in
            errorMessage = nil
            infoMessage = nil
        }
        .background(
            NavigationLink(
                destination: ConfirmResetCodeView(email: trimmedEmail),
                isActive: $navigateToCode
            ) {
                EmptyView()
            }
            .hidden()
        )
    }

    private var emailField: some View {
        HStack(spacing: 10) {
            Image(systemName: "envelope.fill")
                .foregroundStyle(Color.vetSubtitle)

            TextField("Email", text: $email)
                .foregroundStyle(Color.vetTitle)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .focused($isEmailFocused)
                .submitLabel(.done)
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(Color.vetInputBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isEmailValid || email.isEmpty ? Color.vetStroke : Color.red.opacity(0.75),
                        lineWidth: 1)
        )
        .cornerRadius(14)
        .animation(.easeInOut(duration: 0.18), value: isEmailValid)
    }

    private func sendResetCode() async {
        guard isEmailValid, !isSubmitting else { return }
        isSubmitting = true
        errorMessage = nil
        infoMessage = nil

        do {
            let resp = try await session.forgotPassword(email: trimmedEmail)
            await MainActor.run {
                infoMessage = resp.message
                // Navigate to code entry screen once email is accepted
                navigateToCode = true
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }

        isSubmitting = false
    }
}


