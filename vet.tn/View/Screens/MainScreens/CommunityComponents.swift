//
//  CommunityComponents.swift
//  vet.tn
//
//  Community UI components - Reaction picker, comment views, etc.

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Reaction Type Enum

enum ReactionType: String, CaseIterable {
    case like = "like"
    case love = "love"
    case haha = "haha"
    case angry = "angry"
    case cry = "cry"
    
    var emoji: String {
        switch self {
        case .like: return "👍"
        case .love: return "❤️"
        case .haha: return "😂"
        case .angry: return "😠"
        case .cry: return "😢"
        }
    }
    
    var label: String {
        switch self {
        case .like: return "Like"
        case .love: return "Love"
        case .haha: return "Haha"
        case .angry: return "Angry"
        case .cry: return "Cry"
        }
    }
}

// MARK: - Reaction Picker

struct ReactionPicker: View {
    let onReactionSelected: (ReactionType) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(ReactionType.allCases, id: \.self) { reaction in
                Button {
                    onReactionSelected(reaction)
                } label: {
                    Text(reaction.emoji)
                        .font(.system(size: 28))
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.95))
        .cornerRadius(28)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        .padding(16)
    }
}

// MARK: - Reaction Button

struct ReactionButton: View {
    let currentReaction: String?
    let onClick: () -> Void
    
    private var displayEmoji: String {
        guard let reaction = currentReaction,
              let reactionType = ReactionType(rawValue: reaction) else {
            return "👍"
        }
        return reactionType.emoji
    }
    
    private var displayLabel: String {
        guard let reaction = currentReaction,
              let reactionType = ReactionType(rawValue: reaction) else {
            return "Like"
        }
        return reactionType.label
    }
    
    private var isActive: Bool {
        currentReaction != nil
    }
    
    var body: some View {
        Button {
            onClick()
        } label: {
            HStack(spacing: 4) {
                Text(displayEmoji)
                    .font(.system(size: 20))
                Text(displayLabel)
                    .font(.system(size: 14, weight: isActive ? .bold : .regular))
            }
            .foregroundColor(isActive ? Color.orange : Color.primary.opacity(0.6))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reaction Count Display

struct ReactionCountView: View {
    let emoji: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 2) {
            Text(emoji)
                .font(.system(size: 14))
            Text("\(count)")
                .font(.system(size: 12))
                .foregroundColor(Color.primary.opacity(0.7))
        }
    }
}
