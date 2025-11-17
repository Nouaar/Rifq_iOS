//
//  SignupView.swift
//  vet.tn
//

import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager

    // Inputs
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSecurePass = true
    @State private var isSecureConfirm = true
    
    @StateObject private var googleVM = GoogleAuthViewModel()
    @State private var isGoogleSignedUp = false

    // Navigation flags
    @State private var isVerifying = false
    @State private var arrivedFromTimeout = false
    @State private var showLogin = false

    // Submission
    @State private var isSubmitting = false

    // Focus management
    @FocusState private var focused: Field?
    enum Field { case name, email, password, confirm }

    // MARK: - Validation
    private var isNameValid: Bool { fullName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 }
    private var isEmailValid: Bool {
        let t = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.contains("@"), t.contains(".") else { return false }
        return t.count >= 5
    }
    private var isPasswordValid: Bool { password.count >= 6 }
    private var isConfirmValid: Bool { !confirmPassword.isEmpty && confirmPassword == password }
    private var canRegister: Bool { isNameValid && isEmailValid && isPasswordValid && isConfirmValid }

    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()

            VStack(spacing: 26) {
                Spacer(minLength: 40)

                paws

                Text("Create Account")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.vetTitle)

                Text("Join the Pet Healthcare community 🐾")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.vetSubtitle)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                // Inputs + validation
                VStack(spacing: 8) {
                    inputRow(icon: "person.fill") {
                        TextField("Full Name", text: $fullName)
                            .foregroundStyle(Color.vetTitle)
                            .textContentType(.name)
                            .autocorrectionDisabled(true)
                            .focused($focused, equals: .name)
                            .submitLabel(.next)
                            .onSubmit { focused = .email }
                            .onChange(of: fullName) { _ in session.lastError = nil }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(borderColor(valid: isNameValid, touched: !fullName.isEmpty), lineWidth: 1)
                    )
                    if !fullName.isEmpty && !isNameValid {
                        helper("Please enter your full name.")
                    }

                    inputRow(icon: "envelope.fill") {
                        TextField("Email", text: $email)
                            .foregroundStyle(Color.vetTitle)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .textContentType(.emailAddress)
                            .focused($focused, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focused = .password }
                            .onChange(of: email) { _ in session.lastError = nil }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(borderColor(valid: isEmailValid, touched: !email.isEmpty), lineWidth: 1)
                    )
                    if !email.isEmpty && !isEmailValid {
                        helper("Please enter a valid email address.")
                    }

                    inputRow(icon: "lock.fill") {
                        Group {
                            if isSecurePass {
                                SecureField("Password (min 6)", text: $password)
                            } else {
                                TextField("Password (min 6)", text: $password)
                            }
                        }
                        .foregroundStyle(Color.vetTitle)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .textContentType(.newPassword)
                        .focused($focused, equals: .password)
                        .submitLabel(.next)
                        .onSubmit { focused = .confirm }

                        Button { isSecurePass.toggle() } label: {
                            Image(systemName: isSecurePass ? "eye.slash" : "eye")
                                .foregroundStyle(Color.vetSubtitle)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(borderColor(valid: isPasswordValid, touched: !password.isEmpty), lineWidth: 1)
                    )
                    .onChange(of: password) { _ in session.lastError = nil }
                    if !password.isEmpty && !isPasswordValid {
                        helper("Password must be at least 6 characters.")
                    }

                    inputRow(icon: "checkmark.shield.fill") {
                        Group {
                            if isSecureConfirm {
                                SecureField("Confirm Password", text: $confirmPassword)
                            } else {
                                TextField("Confirm Password", text: $confirmPassword)
                            }
                        }
                        .foregroundStyle(Color.vetTitle)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .textContentType(.newPassword)
                        .focused($focused, equals: .confirm)
                        .submitLabel(.done)
                        .onSubmit { tryRegister() }

                        Button { isSecureConfirm.toggle() } label: {
                            Image(systemName: isSecureConfirm ? "eye.slash" : "eye")
                                .foregroundStyle(Color.vetSubtitle)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(borderColor(valid: isConfirmValid, touched: !confirmPassword.isEmpty), lineWidth: 1)
                    )
                    .onChange(of: confirmPassword) { _ in session.lastError = nil }
                    if !confirmPassword.isEmpty && !isConfirmValid {
                        helper("Passwords do not match.")
                    }
                }
                .padding(.horizontal, 24)

                // CTA
                Button {
                    hideKeyboard()
                    tryRegister()
                } label: {
                    ZStack {
                        Text(isSubmitting ? "CREATING..." : "CREATE ACCOUNT")
                            .font(.system(size: 16, weight: .bold))
                            .opacity(isSubmitting ? 0.001 : 1)
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 56)
                }
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(canRegister ? Color.vetCanyon : Color.vetCanyon.opacity(0.4))
                )
                .foregroundColor(.white)
                .disabled(!canRegister || isSubmitting)
                .padding(.horizontal, 24)
                .padding(.top, 10)

                // Error from session
                if let err = session.lastError, !err.isEmpty {
                    Text(err)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Back to login
                HStack(spacing: 6) {
                    Text("Already have an account?")
                        .foregroundColor(.vetSubtitle)
                    Button("Sign In") { dismiss() }
                        .foregroundColor(.vetCanyon)
                        .fontWeight(.semibold)
                }
                .padding(.top, 4)

                Divider().padding(.horizontal, 30)

                // MARK: - Google (treat as Continue with Google)
                Button {
                    googleVM.signIn(session: session, source: .signup)
                } label: {
                    Text("CONTINUE WITH GOOGLE")
                        .font(.system(size: 16, weight: .bold))
                        .kerning(0.8)
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.vetCanyon, lineWidth: 2)
                )
                .foregroundColor(.vetCanyon)
                .padding(.horizontal, 24)

                // Loading + messages
                if googleVM.isLoading {
                    ProgressView().padding(.top, 6)
                }
                if let info = googleVM.infoMessage {
                    Text(info)
                        .foregroundColor(.green)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                if let err = googleVM.errorMessage {
                    Text(err)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer(minLength: 40)
            }
        }
        // React to Google success — attach to a concrete container (the ZStack)
        .onChange(of: googleVM.userEmail) { newEmail in
            if newEmail != nil {
                isGoogleSignedUp = true
            }
        }
        // Navigate to verification
        .fullScreenCover(isPresented: $isVerifying) {
            EmailVerificationView(
                email: session.pendingEmail ?? email.trimmingCharacters(in: .whitespacesAndNewlines),
                autoResendOnAppear: arrivedFromTimeout
            )
        }
        // Navigate to login if email already exists
        .onChange(of: session.shouldNavigateToLogin) { shouldNavigate in
            if shouldNavigate {
                // Show error dialog first, then dismiss to login
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Reset the flag
                    session.shouldNavigateToLogin = false
                    dismiss()
                }
            }
        }
        // Navigate to verification if required
        .onChange(of: session.requiresEmailVerification) { needsVerification in
            if needsVerification && session.isAuthenticated {
                isVerifying = true
            }
        }
        // Navigate to main tab if authenticated
        .onChange(of: session.isAuthenticated) { isAuth in
            if isAuth && !session.requiresEmailVerification {
                // User is authenticated and verified, navigate to main tab
                // This will be handled by parent view
            }
        }
    }

    // MARK: - Actions

    private func tryRegister() {
        guard canRegister, !isSubmitting else { return }
        session.lastError = nil
        isSubmitting = true
        arrivedFromTimeout = false

        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let pwd = password

        Task {
            // Pass role "owner" by default
            let ok = await session.signUp(name: trimmedName, email: trimmedEmail, password: pwd)
            isSubmitting = false
            if ok {
                isVerifying = true
            } else {
                // If we hit the typical cold-start timeout message, still push to verification
                if let msg = session.lastError?.lowercased(),
                   msg.contains("taking too long") || msg.contains("timed out") {
                    arrivedFromTimeout = true
                    isVerifying = true
                }
            }
        }
    }

    // MARK: - Reusable UI

    private func inputRow<Content: View>(icon: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Color.vetSubtitle)
            content()
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(Color.vetInputBackground)
        .cornerRadius(14)
    }

    private func helper(_ text: String) -> some View {
        Text(text)
            .font(.vetSmallFont())
            .foregroundStyle(Color.red.opacity(0.85))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 6)
    }

    private func borderColor(valid: Bool, touched: Bool) -> Color {
        if !touched { return Color.vetStroke }
        return valid ? Color.green.opacity(0.75) : Color.red.opacity(0.75)
    }

    private var paws: some View {
        ZStack {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 44))
                .foregroundColor(.black.opacity(0.7))
                .rotationEffect(.degrees(-18))
                .offset(x: -12, y: -8)

            Image(systemName: "pawprint.fill")
                .font(.system(size: 44))
                .foregroundColor(.black.opacity(0.7))
                .rotationEffect(.degrees(18))
                .offset(x: 18, y: 12)
        }
        .padding(15)
    }

    private func hideKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
        #endif
    }
}

