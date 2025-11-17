//
//  NotificationsView.swift
//  vet.tn
//

import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = NotificationViewModel()
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var selectedBooking: Booking?
    @State private var showBookingDetail = false
    
    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Notifications")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.vetTitle)
                    
                    Spacer()
                    
                    if viewModel.unreadCount > 0 {
                        Button {
                            Task {
                                await viewModel.markAllAsRead()
                                // Explicitly update unread count to update badge immediately
                                await viewModel.updateUnreadCount()
                                // Also update NotificationManager to sync badge
                                await notificationManager.updateUnreadCount()
                            }
                        } label: {
                            Text("Mark all read")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.vetCanyon)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.vetSand)
                .overlay(
                    Rectangle()
                        .fill(Color.vetStroke.opacity(0.4))
                        .frame(height: 1),
                    alignment: .bottom
                )
                
                // Notifications list
                ScrollView {
                    if viewModel.isLoading && viewModel.notifications.isEmpty {
                        ProgressView()
                            .padding()
                    } else if viewModel.notifications.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "bell.slash")
                                .font(.system(size: 48))
                                .foregroundColor(.vetSubtitle.opacity(0.5))
                            Text("No notifications")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.vetTitle)
                            Text("You'll see booking requests and updates here")
                                .font(.system(size: 14))
                                .foregroundColor(.vetSubtitle)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.notifications) { notification in
                                NotificationRow(notification: notification) {
                                    // Handle notification tap
                                    Task { @MainActor in
                                        #if DEBUG
                                        print("🔔 Notification tapped - ID: \(notification.id), Type: \(notification.type), Read: \(notification.read)")
                                        #endif
                                        
                                        // Mark as read if unread
                                        if !notification.read {
                                            await viewModel.markAsRead(notificationId: notification.id)
                                            // Explicitly update unread count to update badge immediately
                                            await viewModel.updateUnreadCount()
                                            // Also update NotificationManager to sync badge
                                            await notificationManager.updateUnreadCount()
                                        }
                                        
                                        // If notification has a booking, show booking details
                                        if let bookingId = notification.bookingId {
                                            #if DEBUG
                                            print("📅 Notification has bookingId: \(bookingId)")
                                            #endif
                                            
                                            // Use existing booking if available, otherwise fetch it
                                            if let booking = notification.booking {
                                                #if DEBUG
                                                print("✅ Using existing booking: \(booking.id)")
                                                #endif
                                                selectedBooking = booking
                                                #if DEBUG
                                                print("📋 Set selectedBooking to: \(selectedBooking?.id ?? "nil")")
                                                #endif
                                            } else {
                                                #if DEBUG
                                                print("📥 Fetching booking with ID: \(bookingId)")
                                                #endif
                                                // Fetch booking by ID
                                                await fetchAndShowBooking(bookingId: bookingId)
                                            }
                                        } else {
                                            #if DEBUG
                                            print("ℹ️ Notification tapped but no bookingId - type: \(notification.type)")
                                            #endif
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.setSessionManager(session)
            await viewModel.loadNotifications()
        }
        .refreshable {
            await viewModel.loadNotifications()
        }
        .sheet(item: $selectedBooking) { booking in
            #if DEBUG
            let _ = print("📱 Sheet presenting for booking: \(booking.id)")
            #endif
            BookingDetailView(booking: booking)
                .environmentObject(session)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .onDisappear {
                    // Reload notifications after booking action
                    Task {
                        await viewModel.loadNotifications()
                    }
                }
        }
    }
    
    @MainActor
    private func fetchAndShowBooking(bookingId: String) async {
        guard let accessToken = session.tokens?.accessToken else {
            #if DEBUG
            print("❌ No access token available")
            #endif
            return
        }
        
        let bookingService = BookingService.shared
        do {
            let booking = try await bookingService.getBooking(bookingId: bookingId, accessToken: accessToken)
            #if DEBUG
            print("✅ Successfully fetched booking: \(booking.id)")
            #endif
            selectedBooking = booking
            #if DEBUG
            print("📋 selectedBooking set to: \(selectedBooking?.id ?? "nil")")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to fetch booking: \(error)")
            #endif
        }
    }
}

// MARK: - Notification Row

private struct NotificationRow: View {
    let notification: AppNotification
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 12) {
                // Icon based on notification type
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor)
                        .frame(width: 44, height: 44)
                    Image(systemName: iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(notification.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.vetTitle)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if !notification.read {
                            Circle()
                                .fill(Color.vetCanyon)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Text(notification.message)
                        .font(.system(size: 13))
                        .foregroundColor(.vetSubtitle)
                        .lineLimit(2)
                    
                    if let createdAt = notification.createdAt {
                        Text(formatTime(createdAt))
                            .font(.system(size: 11))
                            .foregroundColor(.vetSubtitle.opacity(0.7))
                            .padding(.top, 2)
                    }
                }
            }
            .padding(12)
            .background(notification.read ? Color.vetCardBackground : Color.vetCanyon.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.vetStroke.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var iconName: String {
        switch notification.type {
        case "booking_request":
            return "calendar.badge.plus"
        case "booking_accepted":
            return "checkmark.circle.fill"
        case "booking_rejected":
            return "xmark.circle.fill"
        case "message":
            return "message.fill"
        default:
            return "bell.fill"
        }
    }
    
    private var iconColor: Color {
        switch notification.type {
        case "booking_request":
            return .blue
        case "booking_accepted":
            return .green
        case "booking_rejected":
            return .red
        case "message":
            return .vetCanyon
        default:
            return .vetTitle
        }
    }
    
    private var iconBackgroundColor: Color {
        iconColor.opacity(0.15)
    }
    
    private func formatTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString) else {
            return dateString
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            let diff = now.timeIntervalSince(date)
            if diff < 60 {
                return "Just now"
            } else if diff < 3600 {
                let minutes = Int(diff / 60)
                return "\(minutes)m ago"
            } else {
                let hours = Int(diff / 3600)
                return "\(hours)h ago"
            }
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            return dateFormatter.string(from: date)
        }
    }
}

// MARK: - Booking Detail View

private struct BookingDetailView: View {
    let booking: Booking
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss
    @State private var showRejectAlert = false
    @State private var rejectionReason = ""
    @State private var isProcessing = false
    
    private let bookingService = BookingService.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Booking Request")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.vetTitle)
                        
                        StatusBadge(status: booking.status)
                    }
                    
                    Divider()
                    
                    // Booking details
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(label: "Service", value: booking.serviceType)
                        DetailRow(label: "Date & Time", value: formatDateTime(booking.dateTime))
                        
                        if let description = booking.description, !description.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Notes")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.vetSubtitle)
                                Text(description)
                                    .font(.system(size: 14))
                                    .foregroundColor(.vetTitle)
                            }
                        }
                        
                        if let pet = booking.pet {
                            DetailRow(label: "Pet", value: "\(pet.name ?? "Unknown") (\(pet.species ?? ""))")
                        }
                    }
                    
                    // Customer info
                    if let owner = booking.owner {
                        Divider()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Customer")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.vetTitle)
                            Text(owner.name ?? owner.email ?? "Unknown")
                                .font(.system(size: 14))
                                .foregroundColor(.vetSubtitle)
                        }
                    }
                    
                    // Action buttons (only show for pending bookings if user is provider)
                    if booking.status == .pending,
                       booking.providerId == session.user?.id {
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
                    
                    // Rejection reason if rejected
                    if booking.status == .rejected, let reason = booking.rejectionReason {
                        Divider()
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Rejection Reason")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.vetSubtitle)
                            Text(reason)
                                .font(.system(size: 14))
                                .foregroundColor(.vetTitle)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.vetBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }.foregroundColor(.vetCanyon)
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
            .alert("Booking Accepted", isPresented: .constant(false)) {
                // Success handled via dismiss
            } message: {
                Text("The booking has been accepted.")
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
            _ = try await bookingService.updateBooking(
                bookingId: booking.id,
                request: request,
                accessToken: accessToken
            )
            dismiss()
        } catch {
            #if DEBUG
            print("❌ Failed to accept booking: \(error)")
            #endif
        }
        
        isProcessing = false
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
            _ = try await bookingService.updateBooking(
                bookingId: booking.id,
                request: request,
                accessToken: accessToken
            )
            rejectionReason = ""
            dismiss()
        } catch {
            #if DEBUG
            print("❌ Failed to reject booking: \(error)")
            #endif
        }
        
        isProcessing = false
    }
    
    private func formatDateTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString) else {
            return dateString
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
}

private struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.vetSubtitle)
            Spacer()
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.vetTitle)
        }
    }
}

private struct StatusBadge: View {
    let status: BookingStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.system(size: 12, weight: .bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(statusColor.opacity(0.15))
            .foregroundColor(statusColor)
            .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch status {
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

