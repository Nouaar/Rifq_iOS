//
//  AIService.swift
//  vet.tn
//
//  Service for calling backend AI endpoints for tips, recommendations, and reminders
//

import Foundation

// MARK: - AI Response Models

struct AITipsResponse: Decodable {
    let tips: [AITip]
    
    struct AITip: Decodable {
        let emoji: String
        let title: String
        let detail: String
    }
}

struct AIRecommendationsResponse: Decodable {
    let recommendations: [AIRecommendation]
    
    struct AIRecommendation: Decodable {
        let title: String
        let detail: String
        let type: String
        let suggestedDate: String?
    }
}

struct AIRemindersResponse: Decodable {
    let reminders: [AIReminder]
    
    struct AIReminder: Decodable {
        let icon: String
        let title: String
        let detail: String
        let date: String
        let tint: String
    }
}

struct AIStatusResponse: Decodable {
    let status: String
    let pills: [AIStatusPill]
    let summary: String
    
    struct AIStatusPill: Decodable {
        let text: String
        let bg: String
        let fg: String
    }
}

// MARK: - AI Service

final class AIService {
    static let shared = AIService()
    
    private let api = APIClient.auth
    
    private init() {}
    
    // MARK: - Get Tips
    
    func getTips(petId: String, accessToken: String) async throws -> AITipsResponse {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        return try await api.request(
            "GET",
            path: "/ai/pets/\(petId)/tips",
            headers: headers,
            responseType: AITipsResponse.self,
            timeout: 180, // Increased timeout for rate-limited requests (can take 60+ seconds)
            retries: 0 // Don't retry - backend handles retries internally
        )
    }
    
    // MARK: - Get Recommendations
    
    func getRecommendations(petId: String, accessToken: String) async throws -> AIRecommendationsResponse {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        return try await api.request(
            "GET",
            path: "/ai/pets/\(petId)/recommendations",
            headers: headers,
            responseType: AIRecommendationsResponse.self,
            timeout: 180, // Increased timeout for rate-limited requests
            retries: 0
        )
    }
    
    // MARK: - Get Reminders
    
    func getReminders(petId: String, accessToken: String) async throws -> AIRemindersResponse {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        return try await api.request(
            "GET",
            path: "/ai/pets/\(petId)/reminders",
            headers: headers,
            responseType: AIRemindersResponse.self,
            timeout: 180, // Increased timeout for rate-limited requests
            retries: 0
        )
    }
    
    // MARK: - Get Status
    
    func getStatus(petId: String, accessToken: String) async throws -> AIStatusResponse {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        return try await api.request(
            "GET",
            path: "/ai/pets/\(petId)/status",
            headers: headers,
            responseType: AIStatusResponse.self,
            timeout: 180, // Increased timeout for rate-limited requests
            retries: 0
        )
    }
}

