//
//  GoogleSignInView.swift
//  vet.tn
//
//  Created by Mac on 7/11/2025.
//

import Foundation
import SwiftUI
import GoogleSignIn

struct GoogleSignInView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var vm = GoogleAuthViewModel()

    var body: some View {
        VStack(spacing: 16) {
            // Custom button to avoid dependency on GoogleSignInSwift's View (which might be unavailable)
            Button {
                vm.signIn(session: session)
            } label: {
                HStack(spacing: 12) {
                    // Simple G logo placeholder; replace with an asset if desired
                    Image(systemName: "g.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.red)
                    Text("Sign in with Google")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                )
            }

            if vm.isLoading { ProgressView() }

            if let email = vm.userEmail {
                Text("Signed in as \(email)")
                    .font(.footnote)
            }

            if let err = vm.errorMessage {
                Text(err)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}
