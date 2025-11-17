//
//  ConfirmResetCodeView.swift
//  vet.tn
//

import SwiftUI

struct ConfirmResetCodeView: View {
    @Environment(\.dismiss) private var dismiss

    let email: String

    @State private var code: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusedIndex: Int?
    @State private var navigateToReset = false

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var joinedCode: String {
        code.joined()
    }

    private var isCodeComplete: Bool {
        joinedCode.count == 6
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vetBackground.ignoresSafeArea()

                VStack(spacing: 20) {
                    TopBar(title: "Enter Code")

                    Text("Enter the 6-digit code we sent to:")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.vetSubtitle)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Text(trimmedEmail)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.vetCanyon)

                    HStack(spacing: 12) {
                        ForEach(0..<6, id: \.self) { i in
                            TextField("", text: $code[i])
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .focused($focusedIndex, equals: i)
                                .frame(width: 45, height: 55)
                                .background(Color.vetInputBackground)
                                .foregroundStyle(Color.vetTitle)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.vetStroke, lineWidth: 1)
                                )
                                .cornerRadius(10)
                                .onChange(of: code[i]) { newValue in
                                    let filtered = newValue.filter(\.isNumber)
                                    if filtered.count > 1 {
                                        code[i] = String(filtered.last!)
                                    } else {
                                        code[i] = filtered
                                    }
                                    if !code[i].isEmpty && i < 5 {
                                        focusedIndex = i + 1
                                    } else if code[i].isEmpty && i > 0 {
                                        focusedIndex = i - 1
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 40)

                    Button {
                        navigateToReset = true
                    } label: {
                        Text("CONTINUE")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity, minHeight: 56)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(isCodeComplete ? Color.vetCanyon : Color.vetCanyon.opacity(0.4))
                    )
                    .foregroundColor(.white)
                    .disabled(!isCodeComplete)
                    .padding(.horizontal, 24)

                    Spacer()
                }

                NavigationLink(
                    destination: ResetPasswordView(email: trimmedEmail, code: joinedCode),
                    isActive: $navigateToReset
                ) {
                    EmptyView()
                }
                .hidden()
            }
        }
        .onAppear {
            focusedIndex = 0
        }
    }
}


