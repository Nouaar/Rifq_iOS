//
//  BookingService.swift
//  vet.tn
//

import Foundation

final class BookingService {
    static let shared = BookingService()
    
    private let api = APIClient.auth
    
    private init() {}
    
    func createBooking(_ request: CreateBookingRequest, accessToken: String) async throws -> Booking {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        return try await api.request(
            "POST",
            path: "/bookings",
            headers: headers,
            body: request,
            responseType: Booking.self,
            timeout: 30,
            retries: 0
        )
    }
    
    func getBookings(role: String? = nil, accessToken: String) async throws -> [Booking] {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        var path = "/bookings"
        if let role = role {
            path += "?role=\(role)"
        }
        return try await api.request(
            "GET",
            path: path,
            headers: headers,
            body: nil,
            responseType: [Booking].self,
            timeout: 25,
            retries: 1
        )
    }
    
    func getBooking(bookingId: String, accessToken: String) async throws -> Booking {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        return try await api.request(
            "GET",
            path: "/bookings/\(bookingId)",
            headers: headers,
            body: nil,
            responseType: Booking.self,
            timeout: 25,
            retries: 1
        )
    }
    
    func updateBooking(bookingId: String, request: UpdateBookingRequest, accessToken: String) async throws -> Booking {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        return try await api.request(
            "PUT",
            path: "/bookings/\(bookingId)",
            headers: headers,
            body: request,
            responseType: Booking.self,
            timeout: 30,
            retries: 0
        )
    }
    
    func deleteBooking(bookingId: String, accessToken: String) async throws {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        _ = try await api.request(
            "DELETE",
            path: "/bookings/\(bookingId)",
            headers: headers,
            body: nil,
            responseType: APIClient.Empty.self,
            timeout: 25,
            retries: 1
        )
    }
}

