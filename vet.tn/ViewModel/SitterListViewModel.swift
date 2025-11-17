//
//  SitterListViewModel.swift
//  vet.tn
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class SitterListViewModel: ObservableObject {
    @Published var sitters: [AvailableSitter] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private let vetSitterService = VetSitterService.shared
    
    func loadSitters() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            let appUsers = try await vetSitterService.getAllSitters()
            sitters = appUsers.map { mapToSitter($0) }
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            print("❌ Failed to load sitters: \(error)")
            #endif
        }
        
        isLoading = false
    }
    
    private func mapToSitter(_ user: AppUser) -> AvailableSitter {
        // Use name or email as display name
        let displayName = user.name ?? user.email.components(separatedBy: "@").first ?? "Pet Sitter"
        
        // Build service description from available data
        // For now, use placeholder since AppUser doesn't have hourlyRate
        let service = "Pet Sitting Services"
        
        // Build description from location or default
        let location = [user.city, user.country]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        
        let description = location.isEmpty 
            ? "Professional pet sitter" 
            : "Experienced pet sitter in \(location)"
        
        // Default rating (would come from reviews/ratings system)
        let rating = 4.5
        
        return AvailableSitter(
            id: user.id,
            name: displayName,
            service: service,
            description: description,
            rating: rating,
            emoji: "🧑‍🍼",
            tint: Color.vetCanyon.opacity(0.25),
            userId: user.id,
            appUser: user
        )
    }
}

