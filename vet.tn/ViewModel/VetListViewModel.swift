//
//  VetListViewModel.swift
//  vet.tn
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class VetListViewModel: ObservableObject {
    @Published var vets: [VetCard] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private let vetSitterService = VetSitterService.shared
    
    func loadVets() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            let appUsers = try await vetSitterService.getAllVets()
            // Filter to only show vets with active subscriptions
            let activeVets = appUsers.filter { user in
                guard let subscription = user.subscription else { return false }
                return subscription.shouldAppearOnMap
            }
            vets = activeVets.map { mapToVetCard($0) }
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            print("❌ Failed to load vets: \(error)")
            #endif
        }
        
        isLoading = false
    }
    
    private func mapToVetCard(_ user: AppUser) -> VetCard {
        // Extract specializations from user data if available
        // For now, we'll use placeholder data since AppUser doesn't have all fields
        // You may need to extend AppUser or create a separate Vet model
        
        let specialties: [String]
        // If backend returns specializations in AppUser, use them
        // Otherwise, use default based on role
        specialties = ["General Practice"] // Default, can be extended
        
        // Use random distance for now (in a real app, calculate from user location)
        let distanceKm = Double.random(in: 1.0...10.0)
        
        // Default rating (would come from reviews/ratings system)
        let rating = 4.5
        
        // Default reviews count
        let reviews = 0
        
        // Determine if open (would need availability data)
        let isOpen = true
        let is247 = false
        
        // Use name or email as display name
        let displayName = user.name ?? user.email.components(separatedBy: "@").first ?? "Veterinarian"
        
        // Use clinic name from user if available, or default
        let vetName = displayName
        
        return VetCard(
            id: user.id,
            name: vetName,
            specialties: specialties,
            rating: rating,
            reviews: reviews,
            distanceKm: distanceKm,
            is247: is247,
            isOpen: isOpen,
            tint: Color.vetCanyon.opacity(0.3),
            emoji: "🧑‍⚕️",
            userId: user.id,
            appUser: user
        )
    }
}


