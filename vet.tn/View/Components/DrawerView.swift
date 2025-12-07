//
//  DrawerView.swift
//  vet.tn
//

import SwiftUI

struct DrawerView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showMessages = false
    @State private var showCommunity = false
    @State private var showMyPosts = false
    @State private var showSubscription = false
    @State private var showBookings = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Menu")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.vetTitle)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.vetTitle)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 24)
            
            // Menu Items
            ScrollView {
                VStack(spacing: 0) {
                    // Messages
                    DrawerMenuItem(
                        icon: "message.fill",
                        title: "Messages",
                        action: {
                            showMessages = true
                        }
                    )
                    
                    // Community
                    DrawerMenuItem(
                        icon: "person.3.fill",
                        title: "Community",
                        action: {
                            showCommunity = true
                        }
                    )
                    
                    // My Posts
                    DrawerMenuItem(
                        icon: "photo.on.rectangle.angled",
                        title: "My Posts",
                        action: {
                            showMyPosts = true
                        }
                    )
                    
                    // Manage Subscription (only if user has subscription)
                    if hasSubscription {
                        DrawerMenuItem(
                            icon: "creditcard.fill",
                            title: "Manage Subscription",
                            action: {
                                showSubscription = true
                            }
                        )
                    }
                    
                    // My Bookings
                    DrawerMenuItem(
                        icon: "calendar.badge.checkmark",
                        title: "My Bookings",
                        action: {
                            showBookings = true
                        }
                    )
                }
            }
            
            Spacer()
        }
        .background(Color.vetBackground.ignoresSafeArea())
        .fullScreenCover(isPresented: $showMessages) {
            NavigationStack {
                ConversationsListView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                showMessages = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.vetTitle)
                            }
                        }
                    }
            }
            .environmentObject(session)
        }
        .fullScreenCover(isPresented: $showBookings) {
            NavigationStack {
                MyBookingsView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                showBookings = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.vetTitle)
                            }
                        }
                    }
            }
            .environmentObject(session)
        }
        .fullScreenCover(isPresented: $showCommunity) {
            NavigationStack {
                CommunityFeedView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                showCommunity = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.vetTitle)
                            }
                        }
                    }
            }
            .environmentObject(session)
        }
        .fullScreenCover(isPresented: $showMyPosts) {
            NavigationStack {
                MyPostsView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                showMyPosts = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.vetTitle)
                            }
                        }
                    }
            }
            .environmentObject(session)
        }
        .sheet(isPresented: $showSubscription) {
            NavigationStack {
                SubscriptionManagementView()
            }
            .environmentObject(session)
        }
    }
    
    private var hasSubscription: Bool {
        guard let subscription = session.user?.subscription else { return false }
        // User has subscription if it exists and hasn't truly expired (effectiveStatus is not canceled)
        let effectiveStatus = subscription.effectiveStatus
        return effectiveStatus != .none && effectiveStatus != .canceled && !subscription.id.isEmpty
    }
}

// MARK: - Drawer Menu Item

struct DrawerMenuItem: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.vetCanyon.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.vetCanyon)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.vetTitle)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.vetSubtitle)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.vetSubtitle)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.vetCardBackground)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(
            Rectangle()
                .fill(Color.vetStroke.opacity(0.3))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}


#Preview {
    DrawerView()
        .environmentObject(SessionManager())
}

