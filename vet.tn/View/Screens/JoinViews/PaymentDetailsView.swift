//
//  PaymentDetailsView.swift
//  vet.tn
//

import SwiftUI

struct PaymentDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    let role: ProfessionalRole
    let subscriptionPrice: Double
    
    @State private var cardNumber = ""
    @State private var cardholderName = ""
    @State private var expirationDate = ""
    @State private var cvv = ""
    @State private var showForm = false
    
    @FocusState private var focusedField: PaymentField?
    
    enum PaymentField: Hashable {
        case cardNumber, cardholder, expiration, cvv
    }
    
    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()
            
            // Background paw prints decoration
            ZStack {
                ForEach(0..<6, id: \.self) { index in
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color.vetCanyon.opacity(0.1))
                        .offset(
                            x: CGFloat.random(in: -150...150),
                            y: CGFloat(200 + index * 100)
                        )
                }
            }
            .allowsHitTesting(false)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Top Bar
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.vetTitle)
                                .frame(width: 32, height: 32)
                                .background(Color.vetCardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.vetStroke, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.vetTitle)
                                .frame(width: 32, height: 32)
                                .background(Color.vetCardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.vetStroke, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Payment Details")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.vetTitle)
                        
                        HStack {
                            Text("$\(String(format: "%.1f", subscriptionPrice))/month")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.vetCanyon)
                            
                            Text("•")
                                .foregroundColor(.vetSubtitle)
                            
                            Text("Become a Professional")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.vetTitle)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    
                    // Card Display
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("CARD")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Spacer()
                            
                            Button {
                                // Info action
                            } label: {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Text(cardNumber.isEmpty ? "•••• •••• •••• ••••" : cardNumber)
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .tracking(2)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("CARDHOLDER")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text(cardholderName.isEmpty ? "CARDHOLDER NAME" : cardholderName.uppercased())
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("EXPIRES")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text(expirationDate.isEmpty ? "MM/YY" : expirationDate)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(hex: "#6B46C1"),
                                Color(hex: "#8B5CF6")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .padding(.horizontal, 16)
                    
                    // Payment Input Forms
                    VStack(spacing: 16) {
                        // Card Number
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Card Number")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.vetTitle)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 16))
                                    .foregroundColor(.vetSubtitle)
                                
                                TextField("Card Number", text: $cardNumber)
                                    .font(.system(size: 16, design: .monospaced))
                                    .foregroundColor(.vetTitle)
                                    .keyboardType(.numberPad)
                                    .focused($focusedField, equals: .cardNumber)
                                    .onChange(of: cardNumber) { oldValue, newValue in
                                        // Format card number with spaces every 4 digits
                                        let formatted = newValue.filter { $0.isNumber }
                                        let grouped = formatted.enumerated().map { index, char in
                                            index > 0 && index % 4 == 0 ? " \(char)" : String(char)
                                        }.joined()
                                        if grouped != newValue {
                                            cardNumber = grouped
                                        }
                                    }
                                
                                if !cardNumber.isEmpty && cardNumber.filter({ $0.isNumber }).count >= 16 {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(14)
                            .background(Color.vetInputBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(focusedField == .cardNumber ? Color.vetCanyon : Color.vetStroke, lineWidth: focusedField == .cardNumber ? 2 : 1)
                            )
                            .cornerRadius(14)
                        }
                        
                        // Cardholder Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Cardholder Name")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.vetTitle)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.vetSubtitle)
                                
                                TextField("Cardholder Name", text: $cardholderName)
                                    .font(.system(size: 16))
                                    .foregroundColor(.vetTitle)
                                    .textInputAutocapitalization(.characters)
                                    .focused($focusedField, equals: .cardholder)
                                
                                if !cardholderName.isEmpty {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(14)
                            .background(Color.vetInputBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(focusedField == .cardholder ? Color.vetCanyon : Color.vetStroke, lineWidth: focusedField == .cardholder ? 2 : 1)
                            )
                            .cornerRadius(14)
                        }
                        
                        // Expiration Date and CVV
                        HStack(spacing: 12) {
                            // Expiration Date
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Expiration Date")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.vetTitle)
                                
                                HStack(spacing: 12) {
                                    TextField("MM/YY", text: $expirationDate)
                                        .font(.system(size: 16, design: .monospaced))
                                        .foregroundColor(.vetTitle)
                                        .keyboardType(.numberPad)
                                        .focused($focusedField, equals: .expiration)
                                        .onChange(of: expirationDate) { oldValue, newValue in
                                            // Format expiration date as MM/YY
                                            let digits = newValue.filter { $0.isNumber }
                                            if digits.count <= 2 {
                                                expirationDate = digits
                                            } else if digits.count <= 4 {
                                                let index = digits.index(digits.startIndex, offsetBy: 2)
                                                expirationDate = String(digits[..<index]) + "/" + String(digits[index...])
                                            } else {
                                                let index = digits.index(digits.startIndex, offsetBy: 2)
                                                expirationDate = String(digits[..<index]) + "/" + String(digits[index..<digits.index(index, offsetBy: 2)])
                                            }
                                        }
                                    
                                    if !expirationDate.isEmpty && expirationDate.count >= 5 {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding(14)
                                .background(Color.vetInputBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(focusedField == .expiration ? Color.vetCanyon : Color.vetStroke, lineWidth: focusedField == .expiration ? 2 : 1)
                                )
                                .cornerRadius(14)
                            }
                            
                            // CVV
                            VStack(alignment: .leading, spacing: 8) {
                                Text("CVV")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.vetTitle)
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.vetSubtitle)
                                    
                                    SecureField("•••", text: $cvv)
                                        .font(.system(size: 16, design: .monospaced))
                                        .foregroundColor(.vetTitle)
                                        .keyboardType(.numberPad)
                                        .focused($focusedField, equals: .cvv)
                                        .onChange(of: cvv) { oldValue, newValue in
                                            // Limit CVV to 3-4 digits
                                            let digits = newValue.filter { $0.isNumber }
                                            if digits.count <= 4 {
                                                cvv = digits
                                            } else {
                                                cvv = String(digits.prefix(4))
                                            }
                                        }
                                    
                                    if !cvv.isEmpty && cvv.count >= 3 {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding(14)
                                .background(Color.vetInputBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(focusedField == .cvv ? Color.vetCanyon : Color.vetStroke, lineWidth: focusedField == .cvv ? 2 : 1)
                                )
                                .cornerRadius(14)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Subscription Features
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.square.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                            
                            Text("Connect with pet owners via chat")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.vetTitle)
                        }
                        
                        // Security Info
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                            
                            Text("Your payment information is secure and encrypted.")
                                .font(.system(size: 13))
                                .foregroundColor(.vetSubtitle)
                        }
                        .padding(12)
                        .background(Color.blue.opacity(0.1))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.3), lineWidth: 1))
                        .cornerRadius(12)
                        
                        // Subscription Price
                        HStack {
                            Text("Monthly Subscription")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.vetTitle)
                            
                            Spacer()
                            
                            Text("$\(String(format: "%.1f", subscriptionPrice))/month")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.vetCanyon)
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Pay Button
                    Button {
                        showForm = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                            
                            Text("Pay $\(String(format: "%.1f", subscriptionPrice))/month")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.vetCanyon)
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showForm) {
            if role == .veterinarian {
                JoinVetView()
            } else {
                JoinPetSitterView()
            }
        }
    }
}

// MARK: - Previews

#Preview("Payment Details – Light") {
    let store: ThemeStore = { let s = ThemeStore(); s.selection = .light; return s }()
    return NavigationStack {
        PaymentDetailsView(
            role: .veterinarian,
            subscriptionPrice: 30.0
        )
        .environmentObject(store)
        .preferredColorScheme(.light)
    }
}

#Preview("Payment Details – Dark") {
    let store: ThemeStore = { let s = ThemeStore(); s.selection = .dark; return s }()
    return NavigationStack {
        PaymentDetailsView(
            role: .petSitter,
            subscriptionPrice: 30.0
        )
        .environmentObject(store)
        .preferredColorScheme(.dark)
    }
}

