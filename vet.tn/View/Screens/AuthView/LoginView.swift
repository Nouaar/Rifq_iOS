//
//  LoginView.swift
//  vet.tn
//

import SwiftUI
import GoogleSignInSwift

struct LoginView: View {
    @EnvironmentObject private var session: SessionManager

    @State private var email = ""
    @State private var password = ""
    @State private var isSecure = true
    @State private var isSubmitting = false
    @FocusState private var focused: Field?

    // Added: route to email verification when needed (Google unverified, or email login 403)
    @State private var isVerifying = false
    @State private var showSignup = false

    @StateObject private var googleVM = GoogleAuthViewModel()

    enum Field { case email, password }

    // MARK: - Validation
    private var trimmedEmail: String { email.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedPassword: String { password.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var isEmailValid: Bool {
        let t = trimmedEmail
        guard t.contains("@"), t.contains(".") else { return false }
        return t.count >= 5
    }
    private var isPasswordValid: Bool { trimmedPassword.count >= 6 }
    private var canSignIn: Bool { isEmailValid && isPasswordValid && !isSubmitting }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vetBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    TopBar(title: "RifQ")

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 22) {
                            paws.padding(.top, 36)

                            Text("vet.tn")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.vetTitle)

                            Text("Pet Healthcare Platform")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.vetSubtitle)

                            // MARK: Inputs + validation
                            VStack(spacing: 6) {
                                emailField
                                if !email.isEmpty && !isEmailValid {
                                    Text("Please enter a valid email address.")
                                        .font(.vetSmallFont())
                                        .foregroundStyle(.red.opacity(0.85))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 4)
                                }

                                passwordField
                                    .padding(.top, 8)
                                if !password.isEmpty && !isPasswordValid {
                                    Text("Password must be at least 6 characters.")
                                        .font(.vetSmallFont())
                                        .foregroundStyle(.red.opacity(0.85))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 4)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                            // MARK: Sign in button
                            Button {
                                Task { await doSignIn() }
                            } label: {
                                ZStack {
                                    Text(isSubmitting ? "SIGNING IN..." : "SIGN IN")
                                        .font(.system(size: 16, weight: .bold))
                                        .kerning(0.8)
                                        .opacity(isSubmitting ? 0.001 : 1)
                                        .frame(maxWidth: .infinity, minHeight: 56)

                                    if isSubmitting {
                                        ProgressView()
                                            .tint(.white)
                                    }
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(canSignIn ? Color.vetCanyon : Color.vetCanyon.opacity(0.4))
                            )
                            .foregroundColor(.white)
                            .disabled(!canSignIn)
                            .padding(.horizontal, 20)
                            .padding(.top, 4)

                            if let err = session.lastError, !err.isEmpty {
                                Text(err)
                                    .foregroundColor(.red)
                                    .font(.vetSmallFont())
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }

                            // Links
                            HStack(spacing: 8) {
                                NavigationLink(destination: SignupView()) {
                                    Text("Sign Up")
                                        .foregroundColor(.vetCanyon)
                                        .fontWeight(.semibold)
                                }
                                Text("|")
                                    .foregroundColor(.vetCanyon.opacity(0.6))
                                NavigationLink(destination: ForgotPasswordView()) {
                                    Text("Forgot password?")
                                        .foregroundColor(.vetCanyon)
                                        .fontWeight(.semibold)
                                }
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .padding(.top, 6)

                            Divider().padding(.horizontal, 20)

                            // MARK: - Google branded button (outlined on light)
                            GoogleSignInButton(
                                scheme: .light,
                                style: .wide,
                                state: googleVM.isLoading ? .disabled : .normal
                            ) {
                                googleVM.signIn(session: session)
                            }
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 2)

                            if googleVM.isLoading { ProgressView().padding(.top, 6) }

                            if let err = googleVM.errorMessage {
                                Text(err)
                                    .foregroundColor(.red)
                                    .font(.vetSmallFont())
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }

                            if let email = session.user?.email {
                                Text("Signed in as \(email)")
                                    .font(.vetSmallFont())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            // Navigate to verification if required
            .onChange(of: session.requiresEmailVerification) { needs in
                if needs && session.isAuthenticated {
                    isVerifying = true
                } else if needs && !session.isAuthenticated {
                    // User needs verification but not authenticated yet
                    isVerifying = true
                }
            }
            // Navigate to signup if email doesn't exist
            .onChange(of: session.shouldNavigateToSignup) { shouldNavigate in
                if shouldNavigate {
                    // Show error dialog first, then navigate to signup
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showSignup = true
                        // Reset the flag
                        session.shouldNavigateToSignup = false
                    }
                }
            }
            .fullScreenCover(isPresented: $isVerifying) {
                EmailVerificationView(
                    email: session.pendingEmail ?? session.user?.email ?? trimmedEmail
                )
            }
            .fullScreenCover(isPresented: $showSignup) {
                SignupView()
            }
        }
        .onChange(of: email) { _ in session.lastError = nil }
        .onChange(of: password) { _ in session.lastError = nil }
    }

    // MARK: - Actions

    private func doSignIn() async {
        guard canSignIn else { return }
        isSubmitting = true
        session.lastError = nil
        let e = trimmedEmail
        let p = trimmedPassword
        await session.signIn(email: e, password: p)
        isSubmitting = false
        if session.requiresEmailVerification {
            // If backend said verify first (e.g., 403), show verification
            isVerifying = true
        } else if session.isAuthenticated {
            hideKeyboard()
        }
    }

    // MARK: - Subviews

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
                .focused($focused, equals: .email)
                .submitLabel(.next)
                .onSubmit { focused = .password }
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(Color.vetInputBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(borderColor(valid: isEmailValid, touched: !email.isEmpty),
                        lineWidth: 1)
        )
        .cornerRadius(14)
        .animation(.easeInOut(duration: 0.18), value: isEmailValid)
        .animation(.easeInOut(duration: 0.18), value: email.isEmpty)
    }

    private var passwordField: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .foregroundStyle(Color.vetSubtitle)

            Group {
                if isSecure {
                    SecureField("Password (min 6)", text: $password)
                        .onSubmit { Task { await doSignIn() } }
                } else {
                    TextField("Password (min 6)", text: $password)
                        .onSubmit { Task { await doSignIn() } }
                }
            }
            .textContentType(.password)
            .foregroundStyle(Color.vetTitle)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .focused($focused, equals: .password)
            .submitLabel(.done)

            Button { isSecure.toggle() } label: {
                Image(systemName: isSecure ? "eye.slash" : "eye")
                    .foregroundStyle(Color.vetSubtitle)
            }
            .accessibilityLabel(isSecure ? "Show password" : "Hide password")
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(Color.vetInputBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(borderColor(valid: isPasswordValid, touched: !password.isEmpty),
                        lineWidth: 1)
        )
        .cornerRadius(14)
        .animation(.easeInOut(duration: 0.18), value: isPasswordValid)
        .animation(.easeInOut(duration: 0.18), value: password.isEmpty)
    }

    private func borderColor(valid: Bool, touched: Bool) -> Color {
        if !touched { return Color.vetStroke }
        return valid ? Color.green.opacity(0.75) : Color.red.opacity(0.75)
    }

    private func hideKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
        #endif
    }
}

// MARK: - Previews

#Preview("LoginView – Light") {
    let store: ThemeStore = { let s = ThemeStore(); s.selection = .light; return s }()
    return LoginView()
        .environmentObject(store)
        .environmentObject(SessionManager())
        .preferredColorScheme(.light)
}

#Preview("LoginView – Dark") {
    let store: ThemeStore = { let s = ThemeStore(); s.selection = .dark; return s }()
    return LoginView()
        .environmentObject(store)
        .environmentObject(SessionManager())
        .preferredColorScheme(.dark)
}

