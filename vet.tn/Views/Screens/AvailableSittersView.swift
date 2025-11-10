//
//  AvailableSittersView.swift
//  vet.tn
//
//  Created by Mac on 4/11/2025.
//

import Foundation
//  AvailableSittersView.swift
//  vet.tn
//
//  Created by Mac on 4/11/2025.
//

import SwiftUI

struct AvailableSittersView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let sitters: [AvailableSitter] = [
        .init(
            name: "Fatima Ben Youssef",
            service: "At home • €25/day",
            description: "Experienced with dogs & cats",
            rating: 4.9,
            emoji: "🧑‍🍼",
            tint: Color.vetCanyon.opacity(0.25)
        ),
        .init(
            name: "Ahmed Hamza",
            service: "Walking • €20",
            description: "Professional dog walker",
            rating: 4.7,
            emoji: "🧑‍🍼",
            tint: Color.vetCanyon.opacity(0.25)
        ),
        .init(
            name: "Saida Mansour",
            service: "At home • €25/day",
            description: "Cat specialist",
            rating: 4.8,
            emoji: "🧑‍🍼",
            tint: Color.vetCanyon.opacity(0.25)
        )
    ]
    
    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // Section title
                    Text("Available Sitters")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.vetTitle)
                        .padding(.horizontal, 18)
                        .padding(.top, 6)
                    
                    VStack(spacing: 14) {
                        ForEach(sitters) { sitter in
                            SitterCardView(sitter: sitter)
                                .padding(.horizontal, 18)
                        }
                    }
                    .padding(.bottom, 24)
                }
                .padding(.top, 8)
            }
        }
        // Navigation bar with native iOS back button
        .navigationTitle("Available Sitters")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                headerBadge("bell.fill")
                headerBadge("gearshape.fill")
            }
        }
    }
    
    // MARK: - Header badge
    
    private func headerBadge(_ system: String) -> some View {
        Image(systemName: system)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.vetTitle)
            .frame(width: 32, height: 32)
            .background(Color.vetCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.vetStroke))
    }
}

// MARK: - Model

struct AvailableSitter: Identifiable {
    let id = UUID()
    let name: String
    let service: String
    let description: String
    let rating: Double
    let emoji: String
    let tint: Color
}

// MARK: - Card view

struct SitterCardView: View {
    let sitter: AvailableSitter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(sitter.tint)
                        .frame(width: 44, height: 44)
                    Text(sitter.emoji)
                        .font(.system(size: 22))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(sitter.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.vetTitle)
                    
                    Text(sitter.service)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.vetSubtitle)
                    
                    Text(sitter.description)
                        .font(.system(size: 12))
                        .foregroundColor(.vetSubtitle)
                }
                
                Spacer()
                
                // Rating badge
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text(String(format: "%.1f", sitter.rating))
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            
            // Button
            Button {
                // TODO: go to sitter profile
            } label: {
                Text("VIEW PROFILE")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.vetCanyon)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            
        }
        .padding(14)
        .background(Color.vetCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.vetStroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview("Available Sitters") {
    NavigationStack {
        AvailableSittersView()
            .environment(\.colorScheme, .light)
    }
}
