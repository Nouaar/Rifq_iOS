//
//  PetService.swift
//  vet.tn
//
//  Created by Mac on 7/11/2025.
//

import Foundation

final class PetService {
    static let shared = PetService()
    
    // Use auth client since pets endpoints are on the same server as auth
    private let api = APIClient.auth
    
    private init() {}
    
    // MARK: - Create Pet
    
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

