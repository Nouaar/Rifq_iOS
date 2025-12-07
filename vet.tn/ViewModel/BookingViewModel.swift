//
//  BookingViewModel.swift
//  vet.tn
//

import Foundation
import Combine

@MainActor
class BookingViewModel: ObservableObject {
    @Published var bookings: [Booking] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    weak var sessionManager: SessionManager?
    private let bookingService = BookingService.shared
    
    func setSessionManager(_ session: SessionManager) {
        self.sessionManager = session
    }
    
    func loadBookings(role: String? = nil) async {
        guard let accessToken = sessionManager?.tokens?.accessToken else {
            errorMessage = "Please log in to view bookings"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedBookings = try await bookingService.getBookings(role: role, accessToken: accessToken)
            bookings = fetchedBookings
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("❌ Failed to load bookings: \(error)")
            #endif
        }
        
        isLoading = false
    }
}

