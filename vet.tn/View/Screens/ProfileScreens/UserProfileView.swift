//
//  UserProfileView.swift
//  vet.tn
//
//  User profile view for viewing other users' profiles

import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss
    
    let userId: String
    let userName: String?
    let userAvatarUrl: String?
    let userRole: String?
    
    @State private var showChat = false
    
    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Top Bar
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.vetCanyon)
                                .frame(width: 44, height: 44)
                        }
                        
                        Spacer()
                        
                        Text("Profile")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.vetTitle)
                        
                        Spacer()
                        
                        // Invisible spacer to balance the layout
                        Color.clear
                            .frame(width: 44, height: 44)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    // Profile Card
                    VStack(spacing: 16) {
                        // Avatar
                        AsyncImage(url: URL(string: userAvatarUrl ?? "")) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Circle()
                                .fill(Color.vetCanyon.opacity(0.2))
                                .overlay(
                                    Text((userName ?? "?").prefix(1).uppercased())
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.vetCanyon)
                                )
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        
                        // Name
                        VStack(spacing: 4) {
                            Text(userName ?? "Unknown User")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.vetTitle)
                            
                            // Role badge
                            if let role = userRole {
                                HStack(spacing: 4) {
                                    Image(systemName: getRoleIcon(role))
                                        .font(.system(size: 12))
                                    Text(getRoleDisplay(role))
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.vetCanyon)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.vetCanyon.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        
                        // Send Message Button
                        Button {
                            showChat = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "message.fill")
                                    .font(.system(size: 16))
                                Text("Send Message")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.vetCanyon)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.top, 8)
                    }
                    .padding(24)
                    .background(Color.vetCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 16)
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showChat) {
            ChatView(
                recipientId: userId,
                recipientName: userName ?? "User",
                recipientAvatarUrl: userAvatarUrl
            )
            .environmentObject(session)
        }
    }
    
    private func getRoleIcon(_ role: String) -> String {
        switch role.lowercased() {
        case "veterinarian", "vet":
            return "cross.case.fill"
        case "pet-sitter", "sitter", "petsitter":
            return "pawprint.fill"
        default:
            return "person.fill"
        }
    }
    
    private func getRoleDisplay(_ role: String) -> String {
        switch role.lowercased() {
        case "veterinarian", "vet":
            return "Veterinarian"
        case "pet-sitter", "sitter", "petsitter":
            return "Pet Sitter"
        default:
            return "Pet Owner"
        }
    }
}
