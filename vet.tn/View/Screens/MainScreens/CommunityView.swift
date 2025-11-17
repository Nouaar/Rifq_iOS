//
//  CommunityView.swift
//  vet.tn
//

import SwiftUI

struct CommunityView: View {
    @Environment(\.dismiss) private var dismiss

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
    }
}

