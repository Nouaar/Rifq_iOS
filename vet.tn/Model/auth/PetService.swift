//
//  PetService.swift
//  vet.tn
//
//  Created by Mac on 7/11/2025.
//

import Foundation

/// Service for managing pet-related API operations.
///
/// The `PetService` handles all pet-related backend communication including
/// creating, reading, updating, and deleting pets.
///
/// ## Usage
///
/// ```swift
/// let petService = PetService.shared
/// let pets = try await petService.getPetsForOwner(ownerId: "user123", accessToken: "token")
/// ```
final class PetService {
    static let shared = PetService()
    
    // Use auth client since pets endpoints are on the same server as auth
    private let api = APIClient.auth
    
    private init() {}
    
    // MARK: - Create Pet
    
    /// Creates a new pet for the specified owner.
    ///
    /// - Parameters:
    ///   - ownerId: The ID of the pet owner
    ///   - request: The pet creation request containing pet details
    ///   - accessToken: The authentication token
    ///
    /// - Returns: The created `Pet` object
    ///
    /// - Throws: An error if the creation fails
    func createPet(ownerId: String, request: CreatePetRequest, accessToken: String) async throws -> Pet {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        return try await api.request(
            "POST",
            path: "/pets/owner/\(ownerId)",
            headers: headers,
            body: request,
            responseType: Pet.self,
            timeout: 30,
            retries: 0
        )
    }
    
    // MARK: - Get All Pets for Owner
    
    /// Retrieves all pets for a specific owner.
    ///
    /// - Parameters:
    ///   - ownerId: The ID of the pet owner
    ///   - accessToken: The authentication token
    ///
    /// - Returns: An array of `Pet` objects belonging to the owner
    ///
    /// - Throws: An error if the request fails
    func getPetsForOwner(ownerId: String, accessToken: String) async throws -> [Pet] {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        return try await api.request(
            "GET",
            path: "/pets/owner/\(ownerId)",
            headers: headers,
            responseType: [Pet].self,
            timeout: 25,
            retries: 1
        )
    }
    
    // MARK: - Get Single Pet
    
    func getPet(petId: String, accessToken: String) async throws -> Pet {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        return try await api.request(
            "GET",
            path: "/pets/\(petId)",
            headers: headers,
            responseType: Pet.self,
            timeout: 25,
            retries: 1
        )
    }
    
    // MARK: - Update Pet
    
    func updatePet(petId: String, request: UpdatePetRequest, accessToken: String) async throws -> Pet {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        return try await api.request(
            "PUT",
            path: "/pets/\(petId)",
            headers: headers,
            body: request,
            responseType: Pet.self,
            timeout: 30,
            retries: 0
        )
    }
    
    // MARK: - Delete Pet
    
    func deletePet(ownerId: String, petId: String, accessToken: String) async throws {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        // DELETE endpoint returns empty body (200 OK with no content)
        _ = try await api.request(
            "DELETE",
            path: "/pets/\(ownerId)/\(petId)",
            headers: headers,
            responseType: APIClient.Empty.self,
            timeout: 25,
            retries: 0
        )
    }
}

