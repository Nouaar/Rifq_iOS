//
//  MyBookingsView.swift
//  vet.tn
//

import SwiftUI

struct MyBookingsView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = BookingViewModel()
    
    @State private var selectedRole: BookingRole = .owner
    @State private var selectedStatus: BookingStatus? = nil
    @State private var selectedBooking: Booking?
    
    private var availableRoles: [BookingRole] {
        var roles: [BookingRole] = [.owner]
        // Only show "As Provider" if user has subscription
        if hasSubscription {
            roles.append(.provider)
        }
        return roles
    }
    
    private var hasSubscription: Bool {
        guard let subscription = session.user?.subscription else { return false }
        // User has subscription if it exists and hasn't truly expired (effectiveStatus is not canceled)
        let effectiveStatus = subscription.effectiveStatus
        return effectiveStatus != .none && effectiveStatus != .canceled && !subscription.id.isEmpty
    }
    
    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Filters
                VStack(spacing: 12) {
                    // Role Filter
                    VStack(alignment: .leading, spacing: 8) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(availableRoles, id: \.self) { role in
                                    FilterChip(
                                        title: role.displayName,
                                        isSelected: selectedRole == role,
                                        action: {
                                            selectedRole = role
                                            Task {
                                                await viewModel.loadBookings(role: role.rawValue)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        
                        // Show description for selected role
                        Text(selectedRole.description)
                            .font(.system(size: 12))
                            .foregroundColor(.vetSubtitle)
                            .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 12)
                    
                    // Status Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterChip(
                                title: "All",
                                isSelected: selectedStatus == nil,
                                action: {
                                    selectedStatus = nil
                                }
                            )
                            
                            ForEach([BookingStatus.pending, .accepted, .rejected, .completed], id: \.self) { status in
                                FilterChip(
                                    title: status.displayName,
                                    isSelected: selectedStatus == status,
                                    action: {
                                        selectedStatus = status
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 12)
                }
                .background(Color.vetCardBackground)
                .overlay(
                    Rectangle()
                        .fill(Color.vetStroke.opacity(0.3))
                        .frame(height: 1),
                    alignment: .bottom
                )
                
                // Bookings List
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredBookings.isEmpty {
                    // Show different empty state for provider if no subscription
                    if selectedRole == .provider && !hasSubscription {
                        EmptyProviderBookingsView()
                    } else {
                        EmptyBookingsView()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredBookings) { booking in
                                BookingRow(booking: booking, currentUserId: session.user?.id ?? "")
                                    .onTapGesture {
                                        selectedBooking = booking
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                }
            }
        }
        .navigationTitle("My Bookings")
        .navigationBarTitleDisplayMode(.large)
        .task {
            viewModel.setSessionManager(session)
            await viewModel.loadBookings(role: selectedRole.rawValue)
        }
        .refreshable {
            await viewModel.loadBookings(role: selectedRole.rawValue)
        }
        .sheet(item: $selectedBooking) { booking in
            BookingDetailSheet(
                booking: booking,
                onBookingUpdated: {
                    // Refresh bookings list after update
                    Task {
                        await viewModel.loadBookings(role: selectedRole.rawValue)
                    }
                }
            )
        }
    }
    
    private var filteredBookings: [Booking] {
        var bookings = viewModel.bookings
        
        // Filter by status if selected
        if let status = selectedStatus {
            if status == .completed {
                // Completed means: accepted status AND date has expired
                bookings = bookings.filter { booking in
                    guard booking.status == .accepted else { return false }
                    guard let dateTime = parseDate(booking.dateTime) else { return false }
                    return dateTime < Date()
                }
            } else {
                bookings = bookings.filter { $0.status == status }
            }
        }
        
        return bookings
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString)
    }
}

// MARK: - Booking Role

enum BookingRole: String, CaseIterable {
    case owner = "owner"
    case provider = "provider"
    
    var displayName: String {
        switch self {
        case .owner:
            return "As Owner"
        case .provider:
            return "As Provider"
        }
    }
    
    var description: String {
        switch self {
        case .owner:
            return "Bookings you made (when you booked a vet or sitter)"
        case .provider:
            return "Bookings you received (if you're subscribed as vet or sitter)"
        }
    }
}

// MARK: - Booking Status Extension

extension BookingStatus {
    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .accepted:
            return "Accepted"
        case .rejected:
            return "Rejected"
        case .completed:
            return "Completed"
        case .cancelled:
            return "Cancelled"
        }
    }
    
    var color: Color {
        switch self {
        case .pending:
            return .orange
        case .accepted:
            return .green
        case .rejected:
            return .red
        case .completed:
            return .blue
        case .cancelled:
            return .gray
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : .vetTitle)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.vetCanyon : Color.vetCardBackground)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color.vetStroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Booking Row

struct BookingRow: View {
    let booking: Booking
    let currentUserId: String
    
    var isOwner: Bool {
        booking.ownerId == currentUserId
    }
    
    var otherParty: BookingUser? {
        isOwner ? booking.provider : booking.owner
    }
    
    var displayStatus: BookingStatus {
        // If booking is accepted and date has expired, show as completed
        if booking.status == .accepted,
           let dateTime = parseDate(booking.dateTime),
           dateTime < Date() {
            return .completed
        }
        return booking.status
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isOwner ? "Service Provider" : "Pet Owner")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.vetSubtitle)
                    
                    Text(otherParty?.name ?? otherParty?.email ?? "Unknown")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.vetTitle)
                }
                
                Spacer()
                
                StatusBadge(status: displayStatus)
            }
            
            Divider()
                .background(Color.vetStroke.opacity(0.3))
            
            // Details
            VStack(alignment: .leading, spacing: 8) {
                BookingDetailRow(
                    icon: "calendar",
                    title: "Service",
                    value: booking.serviceType.capitalized
                )
                
                if let dateTime = parseDate(booking.dateTime) {
                    BookingDetailRow(
                        icon: "clock",
                        title: "Date & Time",
                        value: formatDateTime(dateTime)
                    )
                }
                
                if let pet = booking.pet {
                    BookingDetailRow(
                        icon: "pawprint.fill",
                        title: "Pet",
                        value: pet.name ?? "Unknown"
                    )
                }
                
                if let price = booking.price {
                    BookingDetailRow(
                        icon: "dollarsign.circle.fill",
                        title: "Price",
                        value: String(format: "%.2f TND", price)
                    )
                }
            }
        }
        .padding(16)
        .background(Color.vetCardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.vetStroke, lineWidth: 1)
        )
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Booking Detail Row

struct BookingDetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.vetSubtitle)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.vetSubtitle)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.vetTitle)
        }
    }
}


// MARK: - Empty State

struct EmptyBookingsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(.vetSubtitle.opacity(0.5))
            
            Text("No Bookings")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.vetTitle)
            
            Text("You don't have any bookings yet")
                .font(.system(size: 14))
                .foregroundColor(.vetSubtitle)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyProviderBookingsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 48))
                .foregroundColor(.vetSubtitle.opacity(0.5))
            
            Text("No Active Subscription")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.vetTitle)
            
            Text("Subscribe as a vet or pet sitter to receive booking requests")
                .font(.system(size: 14))
                .foregroundColor(.vetSubtitle)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Booking Detail Sheet

struct BookingDetailSheet: View {
    let booking: Booking
    let onBookingUpdated: () -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager
    
    @State private var showRejectAlert = false
    @State private var rejectionReason = ""
    @State private var isProcessing = false
    @State private var currentBooking: Booking
    
    private let bookingService = BookingService.shared
    
    init(booking: Booking, onBookingUpdated: @escaping () -> Void) {
        self.booking = booking
        self.onBookingUpdated = onBookingUpdated
        self._currentBooking = State(initialValue: booking)
    }
    
    var displayStatus: BookingStatus {
        // If booking is accepted and date has expired, show as completed
        if currentBooking.status == .accepted,
           let dateTime = parseDate(currentBooking.dateTime),
           dateTime < Date() {
            return .completed
        }
        return currentBooking.status
    }
    
    var canAcceptOrReject: Bool {
        // Provider can accept/reject if: booking is pending AND date hasn't expired AND user is the provider
        guard currentBooking.status == .pending,
              currentBooking.providerId == session.user?.id else { return false }
        
        // Check if date hasn't expired
        if let dateTime = parseDate(currentBooking.dateTime) {
            return dateTime >= Date()
        }
        return true // If we can't parse date, allow action
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Status
                    HStack {
                        Text("Status")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.vetTitle)
                        
                        Spacer()
                        
                        StatusBadge(status: displayStatus)
                    }
                    .padding(16)
                    .background(Color.vetCardBackground)
                    .cornerRadius(12)
                    
                    // Service Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Service Details")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.vetTitle)
                        
                        DetailItem(label: "Service Type", value: currentBooking.serviceType.capitalized)
                        DetailItem(label: "Provider Type", value: currentBooking.providerType.capitalized)
                        
                        if let description = currentBooking.description {
                            DetailItem(label: "Description", value: description)
                        }
                        
                        if let dateTime = parseDate(currentBooking.dateTime) {
                            DetailItem(label: "Date & Time", value: formatDateTime(dateTime))
                        }
                        
                        if let duration = currentBooking.duration {
                            DetailItem(label: "Duration", value: "\(duration) minutes")
                        }
                        
                        if let price = currentBooking.price {
                            DetailItem(label: "Price", value: String(format: "%.2f TND", price))
                        }
                    }
                    .padding(16)
                    .background(Color.vetCardBackground)
                    .cornerRadius(12)
                    
                    // Parties
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Parties")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.vetTitle)
                        
                        if let owner = currentBooking.owner {
                            DetailItem(label: "Owner", value: owner.name ?? owner.email ?? "Unknown")
                        }
                        
                        if let provider = currentBooking.provider {
                            DetailItem(label: "Provider", value: provider.name ?? provider.email ?? "Unknown")
                        }
                        
                        if let pet = currentBooking.pet {
                            DetailItem(label: "Pet", value: pet.name ?? "Unknown")
                        }
                    }
                    .padding(16)
                    .background(Color.vetCardBackground)
                    .cornerRadius(12)
                    
                    // Rejection/Cancellation Info
                    if currentBooking.status == .rejected, let reason = currentBooking.rejectionReason {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Rejection Reason")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.red)
                            
                            Text(reason)
                                .font(.system(size: 14))
                                .foregroundColor(.vetSubtitle)
                        }
                        .padding(16)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    if currentBooking.status == .cancelled, let reason = currentBooking.cancellationReason {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Cancellation Reason")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                            
                            Text(reason)
                                .font(.system(size: 14))
                                .foregroundColor(.vetSubtitle)
                        }
                        .padding(16)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Accept/Reject buttons for provider on pending bookings
                    if canAcceptOrReject {
                        VStack(spacing: 12) {
                            Divider()
                            
                            HStack(spacing: 12) {
                                Button {
                                    Task {
                                        await acceptBooking()
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("ACCEPT")
                                    }
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .background(Color.green)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .disabled(isProcessing)
                                
                                Button {
                                    showRejectAlert = true
                                } label: {
                                    HStack {
                                        Image(systemName: "xmark.circle.fill")
                                        Text("REJECT")
                                    }
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .background(Color.red)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .disabled(isProcessing)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.vetBackground.ignoresSafeArea())
            .navigationTitle("Booking Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.vetTitle)
                    }
                }
            }
            .alert("Reject Booking", isPresented: $showRejectAlert) {
                TextField("Reason (optional)", text: $rejectionReason)
                Button("Cancel", role: .cancel) {
                    rejectionReason = ""
                }
                Button("Reject", role: .destructive) {
                    Task {
                        await rejectBooking()
                    }
                }
            } message: {
                Text("Please provide a reason for rejecting this booking (optional).")
            }
        }
    }
    
    @MainActor
    private func acceptBooking() async {
        guard let accessToken = session.tokens?.accessToken else { return }
        
        isProcessing = true
        
        let request = UpdateBookingRequest(
            status: "accepted",
            rejectionReason: nil,
            cancellationReason: nil
        )
        
        do {
            let updatedBooking = try await bookingService.updateBooking(
                bookingId: currentBooking.id,
                request: request,
                accessToken: accessToken
            )
            // Update local state immediately
            currentBooking = updatedBooking
            // Refresh the bookings list
            onBookingUpdated()
            // Dismiss after a short delay to show the updated status
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            dismiss()
        } catch {
            #if DEBUG
            print("❌ Failed to accept booking: \(error)")
            #endif
            isProcessing = false
        }
    }
    
    @MainActor
    private func rejectBooking() async {
        guard let accessToken = session.tokens?.accessToken else { return }
        
        isProcessing = true
        
        let request = UpdateBookingRequest(
            status: "rejected",
            rejectionReason: rejectionReason.isEmpty ? nil : rejectionReason,
            cancellationReason: nil
        )
        
        do {
            let updatedBooking = try await bookingService.updateBooking(
                bookingId: currentBooking.id,
                request: request,
                accessToken: accessToken
            )
            // Update local state immediately
            currentBooking = updatedBooking
            // Refresh the bookings list
            onBookingUpdated()
            rejectionReason = ""
            // Dismiss after a short delay to show the updated status
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            dismiss()
        } catch {
            #if DEBUG
            print("❌ Failed to reject booking: \(error)")
            #endif
            isProcessing = false
        }
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DetailItem: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.vetSubtitle)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.vetTitle)
        }
    }
}

#Preview {
    MyBookingsView()
        .environmentObject(SessionManager())
}

