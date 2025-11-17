//
//  VetSitterService.swift
//  vet.tn
//
//  Created by Mac on 13/11/2025.
//

import Foundation

// MARK: - Request DTOs

struct CreateVetRequest: Codable {
    let email: String
    let name: String
    let password: String
    let phoneNumber: String?
    let licenseNumber: String
    let clinicName: String
    let clinicAddress: String
    let specializations: [String]?
    let yearsOfExperience: Int?
    let latitude: Double?
    let longitude: Double?
    let bio: String?
}

struct UpdateVetRequest: Codable {
    let email: String?
    let name: String?
    let phoneNumber: String?
    let licenseNumber: String?
    let clinicName: String?
    let clinicAddress: String?
    let specializations: [String]?
    let yearsOfExperience: Int?
    let latitude: Double?
    let longitude: Double?
    let bio: String?
}

struct CreateSitterRequest: Codable {
    let email: String
    let name: String
    let password: String
    let phoneNumber: String?
    let hourlyRate: Double
    let sitterAddress: String
    let services: [String]?
    let yearsOfExperience: Int?
    let availableWeekends: Bool?
    let canHostPets: Bool?
    let availability: [String]? // ISO date strings
    let latitude: Double?
    let longitude: Double?
    let bio: String?
}

struct UpdateSitterRequest: Codable {
    let email: String?
    let name: String?
    let phoneNumber: String?
    let hourlyRate: Double?
    let sitterAddress: String?
    let services: [String]?
    let yearsOfExperience: Int?
    let availableWeekends: Bool?
    let canHostPets: Bool?
    let availability: [String]?
    let latitude: Double?
    let longitude: Double?
    let bio: String?
}

// MARK: - Vet Sitter Service

final class VetSitterService {
    static let shared = VetSitterService()
    
    // Use auth client since these endpoints are on the same server
    private let api = APIClient.auth
    
    private init() {}
    
    // MARK: - Veterinarian Methods
    
    /// Create a new veterinarian account
    func createVet(_ request: CreateVetRequest) async throws -> AppUser {
        return try await api.request(
            "POST",
            path: "/veterinarians/register",
            body: request,
            responseType: AppUser.self,
            timeout: 30,
            retries: 0
        )
    }
    
    /// Convert existing user to veterinarian
    func convertUserToVet(userId: String, licenseNumber: String, clinicName: String, clinicAddress: String, specializations: [String]?, yearsOfExperience: Int?, latitude: Double?, longitude: Double?, bio: String?, accessToken: String) async throws -> AppUser {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        
        struct ConvertVetBody: Codable {
            let licenseNumber: String
            let clinicName: String
            let clinicAddress: String
            let specializations: [String]?
            let yearsOfExperience: Int?
            let latitude: Double?
            let longitude: Double?
            let bio: String?
        }
        
        let body = ConvertVetBody(
            licenseNumber: licenseNumber,
            clinicName: clinicName,
            clinicAddress: clinicAddress,
            specializations: specializations,
            yearsOfExperience: yearsOfExperience,
            latitude: latitude,
            longitude: longitude,
            bio: bio
        )
        
        return try await api.request(
            "POST",
            path: "/veterinarians/convert/\(userId)",
            headers: headers,
            body: body,
            responseType: AppUser.self,
            timeout: 30,
            retries: 0
        )
    }
    
    /// Update veterinarian profile
    func updateVet(vetId: String, request: UpdateVetRequest, accessToken: String) async throws -> AppUser {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        return try await api.request(
            "PUT",
            path: "/veterinarians/\(vetId)",
            headers: headers,
            body: request,
            responseType: AppUser.self,
            timeout: 30,
            retries: 0
        )
    }
    
    /// Get all veterinarians
    func getAllVets() async throws -> [AppUser] {
        return try await api.request(
            "GET",
            path: "/veterinarians",
            responseType: [AppUser].self,
            timeout: 25,
            retries: 1
        )
    }
    
    /// Get single veterinarian
    func getVet(vetId: String) async throws -> AppUser {
        return try await api.request(
            "GET",
            path: "/veterinarians/\(vetId)",
            responseType: AppUser.self,
            timeout: 25,
            retries: 1
        )
    }
    
    // MARK: - Pet Sitter Methods
    
    /// Create a new pet sitter account
    func createSitter(_ request: CreateSitterRequest) async throws -> AppUser {
        return try await api.request(
            "POST",
            path: "/pet-sitters/register",
            body: request,
            responseType: AppUser.self,
            timeout: 30,
            retries: 0
        )
    }
    
    /// Convert existing user to pet sitter
    func convertUserToSitter(userId: String, hourlyRate: Double, sitterAddress: String, services: [String]?, yearsOfExperience: Int?, availableWeekends: Bool?, canHostPets: Bool?, availability: [String]?, latitude: Double?, longitude: Double?, bio: String?, accessToken: String) async throws -> AppUser {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        
        struct ConvertSitterBody: Codable {
            let hourlyRate: Double
            let sitterAddress: String
            let services: [String]?
            let yearsOfExperience: Int?
            let availableWeekends: Bool?
            let canHostPets: Bool?
            let availability: [String]?
            let latitude: Double?
            let longitude: Double?
            let bio: String?
        }
        
        let body = ConvertSitterBody(
            hourlyRate: hourlyRate,
            sitterAddress: sitterAddress,
            services: services,
            yearsOfExperience: yearsOfExperience,
            availableWeekends: availableWeekends,
            canHostPets: canHostPets,
            availability: availability,
            latitude: latitude,
            longitude: longitude,
            bio: bio
        )
        
        return try await api.request(
            "POST",
            path: "/pet-sitters/convert/\(userId)",
            headers: headers,
            body: body,
            responseType: AppUser.self,
            timeout: 30,
            retries: 0
        )
    }
    
    /// Update pet sitter profile
    func updateSitter(sitterId: String, request: UpdateSitterRequest, accessToken: String) async throws -> AppUser {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        return try await api.request(
            "PUT",
            path: "/pet-sitters/\(sitterId)",
            headers: headers,
            body: request,
            responseType: AppUser.self,
            timeout: 30,
            retries: 0
        )
    }
    
    /// Get all pet sitters
    func getAllSitters() async throws -> [AppUser] {
        return try await api.request(
            "GET",
            path: "/pet-sitters",
            responseType: [AppUser].self,
            timeout: 25,
            retries: 1
        )
    }
    
    /// Get single pet sitter
    func getSitter(sitterId: String) async throws -> AppUser {
        return try await api.request(
            "GET",
            path: "/pet-sitters/\(sitterId)",
            responseType: AppUser.self,
            timeout: 25,
            retries: 1
        )
    }
}


