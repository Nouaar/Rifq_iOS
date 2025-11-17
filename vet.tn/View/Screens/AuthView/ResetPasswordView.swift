//
//  ResetPasswordView.swift
//  vet.tn
//

import SwiftUI

struct ResetPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager

    let email: String
    let code: String
    @State private var newPassword: String = ""
    @State private var isSubmitting = false
    @State private var infoMessage: String?
    @State private var errorMessage: String?
    @FocusState private var isPasswordFocused: Bool

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var isPasswordValid: Bool {
        newPassword.trimmingCharacters(in: .whitespacesAndNewlines).count >= 6
    }

    private var canSubmit: Bool {
        isPasswordValid && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vetBackground.ignoresSafeArea()

                VStack(spacing: 20) {
                    TopBar(title: "Reset Password")

                    Text("Choose a new password for:")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.vetSubtitle)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Text(trimmedEmail)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.vetCanyon)

                    passwordField
                    .padding(.horizontal, 20)

                    if let info = infoMessage {
                        Text(info)
                            .font(.vetSmallFont())
                            .foregroundStyle(.green)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    if let err = errorMessage ?? session.lastError, !err.isEmpty {
                        Text(err)
                            .font(.vetSmallFont())
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    Button {
                        Task { await submitReset() }
                    } label: {
                        ZStack {
                            Text(isSubmitting ? "CHANGING..." : "CHANGE PASSWORD")
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
                            .fill(canSubmit ? Color.vetCanyon : Color.vetCanyon.opacity(0.4))
                    )
                    .foregroundColor(.white)
                    .disabled(!canSubmit)
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
        }
        .onChange(of: newPassword) { _ in
            clearErrors()
        }
    }

    private var passwordField: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .foregroundStyle(Color.vetSubtitle)

            SecureField("New password (min 6)", text: $newPassword)
                .foregroundStyle(Color.vetTitle)
                .focused($isPasswordFocused)
                .submitLabel(.done)
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(Color.vetInputBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isPasswordValid || newPassword.isEmpty ? Color.vetStroke : Color.red.opacity(0.75),
                        lineWidth: 1)
        )
        .cornerRadius(14)
    }

    private func clearErrors() {
        errorMessage = nil
        infoMessage = nil
        session.lastError = nil
    }

    private func submitReset() async {
        guard canSubmit else { return }
        isSubmitting = true
        clearErrors()

        let ok = await session.resetPassword(
            email: trimmedEmail,
            code: code.trimmingCharacters(in: .whitespacesAndNewlines),
            newPassword: newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        await MainActor.run {
            isSubmitting = false
            if ok {
                infoMessage = "Password changed. You can now sign in with your new password."
                // Optionally auto-dismiss after a small delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    dismiss()
                }
            } else {
                errorMessage = session.lastError ?? "Could not reset password. Please try again."
            }
        }
    }
}


