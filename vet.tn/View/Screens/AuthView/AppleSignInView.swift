//
//  AppleSignInView.swift
//  vet.tn
//
//  Created by Mac on 7/11/2025.
//

import Foundation
import SwiftUI
import AuthenticationServices

// UIKit wrapper for ASAuthorizationAppleIDButton
struct AppleSignInButtonView: UIViewRepresentable {
    @Binding var isLoading: Bool
    var onTap: () -> Void

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        button.cornerRadius = 12
        button.addTarget(context.coordinator, action: #selector(Coordinator.buttonTapped), for: .touchUpInside)
        context.coordinator.onTap = onTap
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
        uiView.isEnabled = !isLoading
        context.coordinator.onTap = onTap
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }

    class Coordinator: NSObject {
        var onTap: () -> Void

        init(onTap: @escaping () -> Void) {
            self.onTap = onTap
        }

        @objc func buttonTapped() {
            onTap()
        }
    }
}

// SwiftUI view that uses the ViewModel
struct AppleSignInButton: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var vm = AppleAuthViewModel()
    var source: AppleAuthViewModel.Source = .login

    var body: some View {
        VStack(spacing: 8) {
            AppleSignInButtonView(isLoading: $vm.isLoading) {
                vm.signIn(session: session, source: source)
            }
            .frame(height: 48)
            
            if vm.isLoading {
                ProgressView()
                    .padding(.top, 6)
            }
            
            if let err = vm.errorMessage {
                Text(err)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

