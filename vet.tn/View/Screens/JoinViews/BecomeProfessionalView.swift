//
//  BecomeProfessionalView.swift
//  vet.tn
//

import SwiftUI

enum ProfessionalRole: String, CaseIterable {
    case veterinarian = "vet"
    case petSitter = "sitter"
    
    var title: String {
        switch self {
        case .veterinarian: return "Veterinarian"
        case .petSitter: return "Pet Sitter"
        }
    }
    
    var description: String {
        switch self {
        case .veterinarian: return "Provide medical care and consultations for pets"
        case .petSitter: return "Offer pet sitting, walking, and care services"
        }
    }
    
    var icon: String {
        switch self {
        case .veterinarian: return "star.fill"
        case .petSitter: return "heart.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .veterinarian: return .blue
        case .petSitter: return .green
        }
    }
}

struct BecomeProfessionalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRole: ProfessionalRole? = nil
    @State private var showPaymentDetails = false
    
    private let subscriptionPrice = 30.0
    private let benefits = [
        "Appear in discover list and map",
        "Receive booking requests from pet owners",
        "Manage your schedule and appointments",
        "Build your professional profile",
        "Connect with pet owners via chat"
    ]
    
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
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    
                    // Header Section
                    VStack(spacing: 16) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.vetCanyon)
                        
                        Text("Join as a Professional")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.vetTitle)
                        
                        Text("Get discovered by pet owners and start receiving booking requests")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.vetSubtitle)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 8)
                    
                    // Choose Your Role Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Choose Your Role")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.vetTitle)
                            .padding(.horizontal, 16)
                        
                        VStack(spacing: 12) {
                            ForEach(ProfessionalRole.allCases, id: \.self) { role in
                                RoleSelectionCard(
                                    role: role,
                                    isSelected: selectedRole == role
                                ) {
                                    selectedRole = role
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Subscription Benefits Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Subscription Benefits")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.vetTitle)
                            .padding(.horizontal, 16)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(benefits, id: \.self) { benefit in
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.green)
                                    
                                    Text(benefit)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.vetTitle)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.vetCardBackground)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.vetStroke, lineWidth: 1))
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                        
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
                        .padding(.horizontal, 16)
                    }
                    
                    // Email Verification Info
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Email Verification Required")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.blue)
                            
                            Text("After subscribing, you'll receive a verification code via email to activate your subscription.")
                                .font(.system(size: 13))
                                .foregroundColor(.vetSubtitle)
                        }
                    }
                    .padding(16)
                    .background(Color.blue.opacity(0.1))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.3), lineWidth: 1))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    
                    // Subscribe Now Button
                    Button {
                        if selectedRole != nil {
                            showPaymentDetails = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                            
                            Text("Subscribe Now")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedRole != nil ? Color.vetCanyon : Color.vetCanyon.opacity(0.5))
                        )
                    }
                    .disabled(selectedRole == nil)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showPaymentDetails) {
            if let role = selectedRole {
                PaymentDetailsView(
                    role: role,
                    subscriptionPrice: subscriptionPrice
                )
            }
        }
    }
}

// MARK: - Role Selection Card

struct RoleSelectionCard: View {
    let role: ProfessionalRole
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(role.iconColor.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: role.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(role.iconColor)
                }
                
                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(role.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.vetTitle)
                    
                    Text(role.description)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.vetSubtitle)
                }
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.vetCanyon)
                } else {
                    Circle()
                        .stroke(Color.vetStroke, lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.vetCanyon.opacity(0.1) : Color.vetCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.vetCanyon : Color.vetStroke, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Become Professional – Light") {
    let store: ThemeStore = { let s = ThemeStore(); s.selection = .light; return s }()
    return NavigationStack {
        BecomeProfessionalView()
            .environmentObject(store)
            .preferredColorScheme(.light)
    }
}

#Preview("Become Professional – Dark") {
    let store: ThemeStore = { let s = ThemeStore(); s.selection = .dark; return s }()
    return NavigationStack {
        BecomeProfessionalView()
            .environmentObject(store)
            .preferredColorScheme(.dark)
    }
}

