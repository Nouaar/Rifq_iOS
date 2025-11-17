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
    
    // MARK: - ViewModel
    @StateObject private var viewModel = SitterListViewModel()
    
    // MARK: - Navigation
    @State private var selectedSitter: PetSitter? = nil
    
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
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if viewModel.sitters.isEmpty && viewModel.error == nil {
                            Text("No pet sitters available")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.vetSubtitle)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if let error = viewModel.error {
                            Text("Error: \(error)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            ForEach(viewModel.sitters) { sitter in
                                SitterCardView(sitter: sitter) {
                                    selectedSitter = mapToPetSitter(sitter)
                                }
                                .padding(.horizontal, 18)
                            }
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
        .task {
            await viewModel.loadSitters()
        }
        .refreshable {
            await viewModel.loadSitters()
        }
        .navigationDestination(item: $selectedSitter) { sitter in
            PetSitterProfileView(sitter: sitter, sitterUserId: sitter.userId)
        }
    }
    
    // MARK: - Helpers
    
    private func mapToPetSitter(_ availableSitter: AvailableSitter) -> PetSitter {
        // Map AvailableSitter to PetSitter model
        // Extract data from appUser if available, otherwise use defaults
        let displayName = availableSitter.name
        let about = availableSitter.description.isEmpty 
            ? "Professional pet sitter with experience caring for various pets."
            : availableSitter.description
        
        // For now, use default pricing since AppUser doesn't have hourlyRate
        // You can extend this when hourlyRate is available in AppUser
        let priceAtHome = "Contact for pricing"
        let priceVisit = "Contact for pricing"
        
        // Default rating and reviews
        let rating = availableSitter.rating
        let reviews: [Review] = [] // Empty for now, can be populated from backend
        
        // Create PetSitter with userId from AvailableSitter
        return PetSitter(
            id: UUID(),
            displayName: displayName,
            emoji: availableSitter.emoji,
            about: about,
            priceAtHome: priceAtHome,
            priceVisit: priceVisit,
            rating: rating,
            reviews: reviews,
            userId: availableSitter.userId
        )
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
    let id: String // Changed from UUID to String to use user id
    let name: String
    let service: String
    let description: String
    let rating: Double
    let emoji: String
    let tint: Color
    let userId: String? // Optional user ID for navigation
    let appUser: AppUser? // Optional full user data
}

// MARK: - Card view

struct SitterCardView: View {
    let sitter: AvailableSitter
    let onViewProfile: () -> Void
    
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
                onViewProfile()
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
