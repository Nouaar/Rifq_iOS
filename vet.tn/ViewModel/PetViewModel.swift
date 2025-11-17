//
//  PetViewModel.swift
//  vet.tn
//
//  Created by Mac on 7/11/2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class PetViewModel: ObservableObject {
    @Published var pets: [Pet] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private let petService = PetService.shared
    weak var sessionManager: SessionManager?
    private var loadTask: Task<Void, Never>?
    
    init(sessionManager: SessionManager? = nil) {
        self.sessionManager = sessionManager
    }
    
    // MARK: - Load Pets
    
    func loadPets() async {
        // Cancel any existing load task to prevent multiple simultaneous calls
        loadTask?.cancel()
        
        // If already loading AND we have pets, return early to prevent duplicate calls
        // But if pets array is empty, we should always load (view was recreated)
        if isLoading && !pets.isEmpty {
            return
        }
        
        guard let session = sessionManager,
              let userId = session.user?.id,
              let accessToken = session.tokens?.accessToken else {
            error = "Not authenticated"
            return
        }
        
        // Set loading state immediately to prevent concurrent calls
        isLoading = true
        error = nil
        
        // Create a new task and store it
        loadTask = Task { @MainActor in
            defer {
                isLoading = false
            }
            
            do {
                // Check if task was cancelled
                try Task.checkCancellation()
                
                let loadedPets = try await petService.getPetsForOwner(ownerId: userId, accessToken: accessToken)
                
                // Check again if task was cancelled before updating state
                try Task.checkCancellation()
                
                #if DEBUG
                print("✅ Loaded \(loadedPets.count) pets: \(loadedPets.map { $0.name })")
                for pet in loadedPets {
                    if let photo = pet.photo {
                        print("📸 Pet '\(pet.name)' has photo: \(photo.prefix(50))...")
                    } else {
                        print("⚠️ Pet '\(pet.name)' has no photo field")
                    }
                }
                #endif
                
                pets = loadedPets
            } catch is CancellationError {
                // Task was cancelled, don't update state
                // isLoading is set to false in defer
            } catch let error as URLError where error.code == .cancelled {
                // URL request was cancelled (e.g., by cancelling previous task)
                // This is expected behavior, so we ignore it silently
                // isLoading is set to false in defer
            } catch {
                // Only log and set error for actual failures, not cancellations
                // Check if it's a cancellation error (NSURLErrorDomain code -999)
                let nsError = error as NSError
                if nsError.domain == "NSURLErrorDomain" && nsError.code == -999 {
                    // This is a cancelled request, ignore silently
                    return
                }
                
                self.error = error.localizedDescription
                #if DEBUG
                print("❌ Failed to load pets: \(error)")
                #endif
            }
        }
        
        await loadTask?.value
    }
    
    // MARK: - Create Pet
    
    func createPet(_ request: CreatePetRequest) async -> Bool {
        guard let session = sessionManager,
              let userId = session.user?.id,
              let accessToken = session.tokens?.accessToken else {
            error = "Not authenticated"
            return false
        }
        
        isLoading = true
        error = nil
        
        #if DEBUG
        if let photo = request.photo {
            print("📤 Sending pet with photo (base64 length: \(photo.count) chars)")
        } else {
            print("📤 Sending pet without photo")
        }
        #endif
        
        do {
            let newPet = try await petService.createPet(
                ownerId: userId,
                request: request,
                accessToken: accessToken
            )
            
            #if DEBUG
            if let photo = newPet.photo {
                print("✅ Pet created with photo: \(photo.prefix(50))...")
            } else {
                print("⚠️ Pet created but backend did not return photo field")
            }
            #endif
            
            // Reload all pets to ensure we have the latest data from server
            await loadPets()
            
            // Update hasPets flag in session
            await updateHasPetsFlag()
            
            return true
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            #if DEBUG
            print("❌ Failed to create pet: \(error)")
            #endif
            return false
        }
    }
    
    // MARK: - Update Pet
    
    func updatePet(petId: String, request: UpdatePetRequest) async -> Bool {
        guard let session = sessionManager,
              let accessToken = session.tokens?.accessToken else {
            error = "Not authenticated"
            return false
        }
        
        isLoading = true
        error = nil
        
        do {
            let updatedPet = try await petService.updatePet(
                petId: petId,
                request: request,
                accessToken: accessToken
            )
            
            // Update local array
            if let index = pets.firstIndex(where: { $0.id == petId }) {
                pets[index] = updatedPet
            }
            
            isLoading = false
            return true
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            #if DEBUG
            print("❌ Failed to update pet: \(error)")
            #endif
            return false
        }
    }
    
    // MARK: - Delete Pet
    
    func deletePet(petId: String) async -> Bool {
        guard let session = sessionManager,
              let userId = session.user?.id,
              let accessToken = session.tokens?.accessToken else {
            error = "Not authenticated"
            return false
        }
        
        isLoading = true
        error = nil
        
        do {
            try await petService.deletePet(
                ownerId: userId,
                petId: petId,
                accessToken: accessToken
            )
            
            // Remove from local array
            pets.removeAll { $0.id == petId }
            isLoading = false
            
            // Update hasPets flag in session
            await updateHasPetsFlag()
            
            return true
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            #if DEBUG
            print("❌ Failed to delete pet: \(error)")
            #endif
            return false
        }
    }
    
    // MARK: - Refresh Single Pet
    
    func refreshPet(petId: String) async {
        guard let session = sessionManager,
              let accessToken = session.tokens?.accessToken else {
            return
        }
        
        do {
            let refreshed = try await petService.getPet(petId: petId, accessToken: accessToken)
            if let index = pets.firstIndex(where: { $0.id == petId }) {
                pets[index] = refreshed
            }
        } catch {
            #if DEBUG
            print("⚠️ Failed to refresh pet: \(error)")
            #endif
        }
    }
    
    // MARK: - Helper
    
    private func updateHasPetsFlag() async {
        guard let session = sessionManager else { return }
        let hasPets = !pets.isEmpty
        // Get current user values to preserve them
        let current = session.user
        _ = await session.updateProfile(
            name: current?.name,
            phone: current?.phone,
            country: current?.country,
            city: current?.city,
            hasPhoto: current?.hasPhoto == true,
            hasPets: hasPets
        )
    }
}

