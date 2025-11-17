//
//  NotificationService.swift
//  vet.tn
//

import Foundation

final class NotificationService {
    static let shared = NotificationService()
    
    private let api = APIClient.auth
    
    private init() {}
    
    func getNotifications(unreadOnly: Bool = false, accessToken: String) async throws -> [AppNotification] {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        var path = "/notifications"
        if unreadOnly {
            path += "?unreadOnly=true"
        }
        return try await api.request(
            "GET",
            path: path,
            headers: headers,
            body: nil,
            responseType: [AppNotification].self,
            timeout: 25,
            retries: 1
        )
    }
    
    func getUnreadCount(accessToken: String) async throws -> Int {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        let response = try await api.request(
            "GET",
            path: "/notifications/count/unread",
            headers: headers,
            body: nil,
            responseType: NotificationCountResponse.self,
            timeout: 25,
            retries: 1
        )
        return response.count
    }
    
    func markAsRead(notificationId: String, accessToken: String) async throws -> AppNotification {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        return try await api.request(
            "POST",
            path: "/notifications/\(notificationId)/read",
            headers: headers,
            body: nil,
            responseType: AppNotification.self,
            timeout: 25,
            retries: 1
        )
    }
    
    func markAllAsRead(accessToken: String) async throws {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        _ = try await api.request(
            "POST",
            path: "/notifications/read-all",
            headers: headers,
            body: nil,
            responseType: APIClient.Empty.self,
            timeout: 25,
            retries: 1
        )
    }
    
    func deleteNotification(notificationId: String, accessToken: String) async throws {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        _ = try await api.request(
            "DELETE",
            path: "/notifications/\(notificationId)",
            headers: headers,
            body: nil,
            responseType: APIClient.Empty.self,
            timeout: 25,
            retries: 1
        )
    }
}

