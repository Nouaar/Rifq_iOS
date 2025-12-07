//
//  MapViewModel.swift
//  vet.tn
//

import Foundation
import Combine
import CoreLocation

@MainActor
final class MapViewModel: ObservableObject {
    @Published var vetLocations: [VetLocation] = []
    @Published var sitterLocations: [SitterLocation] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let vetSitterService = VetSitterService.shared
    
    func loadLocations() async {
        isLoading = true
        error = nil
        
        async let vetsTask = vetSitterService.getAllVets()
        async let sittersTask = vetSitterService.getAllSitters()
        
        do {
            let vets = try await vetsTask
            let sitters = try await sittersTask
            
            // Filter and map vets with valid locations and active subscriptions
            vetLocations = vets.compactMap { vet in
                guard let lat = vet.latitude,
                      let lon = vet.longitude,
                      lat != 0.0 || lon != 0.0 else {
                    return nil
                }
                
                // Only show vets with active subscriptions (Scenario 1 & 2)
                if let subscription = vet.subscription {
                    guard subscription.shouldAppearOnMap else {
                        return nil
                    }
                } else {
                    // No subscription means they shouldn't appear
                    return nil
                }
                
                return VetLocation(
                    id: vet.id,
                    name: vet.name ?? vet.email.components(separatedBy: "@").first ?? "Veterinarian",
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    address: extractAddress(from: vet),
                    isAvailable: vet.isVerified ?? false,
                    userId: vet.id,
                    appUser: vet
                )
            }
            
            // Filter and map sitters with valid locations and active subscriptions
            sitterLocations = sitters.compactMap { sitter in
                guard let lat = sitter.latitude,
                      let lon = sitter.longitude,
                      lat != 0.0 || lon != 0.0 else {
                    return nil
                }
                
                // Only show sitters with active subscriptions (Scenario 1 & 2)
                if let subscription = sitter.subscription {
                    guard subscription.shouldAppearOnMap else {
                        return nil
                    }
                } else {
                    // No subscription means they shouldn't appear
                    return nil
                }
                
                return SitterLocation(
                    id: sitter.id,
                    name: sitter.name ?? sitter.email.components(separatedBy: "@").first ?? "Pet Sitter",
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    address: extractAddress(from: sitter),
                    isAvailable: sitter.isVerified ?? false,
                    userId: sitter.id,
                    appUser: sitter
                )
            }
            
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            #if DEBUG
            print("❌ Failed to load locations: \(error)")
            #endif
        }
    }
    
    private func extractAddress(from user: AppUser) -> String {
        var parts: [String] = []
        
        if let city = user.city, !city.isEmpty {
            parts.append(city)
        }
        
        if let country = user.country, !country.isEmpty {
            parts.append(country)
        }
        
        if parts.isEmpty {
            // Fallback to email domain or coordinates
            return user.email.components(separatedBy: "@").last ?? "Unknown location"
        }
        
        return parts.joined(separator: ", ")
    }
}

// MARK: - Location Models

struct VetLocation: Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let address: String
    let isAvailable: Bool
    let userId: String
    let appUser: AppUser // Store full user data for profile navigation
}

struct SitterLocation: Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let address: String
    let isAvailable: Bool
    let userId: String
    let appUser: AppUser // Store full user data for profile navigation
}

