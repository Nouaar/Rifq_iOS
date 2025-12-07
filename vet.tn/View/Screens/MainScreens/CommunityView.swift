//
//  CommunityView.swift
//  vet.tn
//
//  Community/Messages view - matches Android ConversationsListScreen
//  This is the community feature where users can chat with vets and pet sitters

import SwiftUI

struct CommunityView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager

    var body: some View {
        ConversationsListView()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.vetCanyon)
                }
            }
    }
}

#Preview("CommunityView") {
    NavigationStack {
        CommunityView()
            .environmentObject(ThemeStore())
            .environmentObject(SessionManager())
    }
}

