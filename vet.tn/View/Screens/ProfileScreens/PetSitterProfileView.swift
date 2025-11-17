//
//  PetSitterProfileView.swift
//  vet.tn
//
//  Created by Mac on 6/11/2025.
//

import Foundation
//
//  PetSitterProfileView.swift
//  vet.tn
//

import SwiftUI

struct PetSitterProfileView: View {
    @EnvironmentObject private var theme: ThemeStore
    @EnvironmentObject private var session: SessionManager
    @State private var showBooking = false
    @State private var showChat = false

    let sitter: PetSitter
    var sitterUserId: String? = nil // User ID for messaging

    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {

                    // Top bar
                    TopBar(title: sitter.displayName)

                    // Header card
                    VStack(spacing: 12) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(Color.vetCanyon.opacity(0.18))
                                .frame(width: 86, height: 86)
                            Text(sitter.emoji)
                                .font(.system(size: 38))
                        }

                        VStack(spacing: 2) {
                            Text(sitter.displayName)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.vetTitle)
                            Text("Professional Pet Sitter")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.vetSubtitle)
                        }

                        // Rating + reviews
                        HStack(spacing: 8) {
                            StarRating(rating: sitter.rating)
                            PillSmall(text: String(format: "%.1f", sitter.rating),
                                      icon: "star.fill",
                                      fg: .vetCanyon,
                                      bg: Color.vetCanyon.opacity(0.14))
                            PillSmall(text: "\(sitter.reviews.count) reviews",
                                      icon: "text.bubble.fill",
                                      fg: .vetTitle,
                                      bg: Color.vetInputBackground)
                        }
                        .padding(.top, 2)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(Color.vetCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.vetStroke.opacity(0.3), lineWidth: 1))
                    .padding(.horizontal, 16)

                    // About
                    SectionBox(title: "About") {
                        Text(sitter.about)
                            .font(.system(size: 14))
                            .foregroundColor(.vetTitle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Services & Pricing
                    SectionBox(title: "Services & Pricing") {
                        VStack(spacing: 10) {
                            ServiceRow(title: "At Home", price: sitter.priceAtHome)
                            ServiceRow(title: "Visit",   price: sitter.priceVisit)
                        }
                    }

                    // Recent Reviews
                    SectionBox(title: "Recent Reviews") {
                        VStack(spacing: 10) {
                            ForEach(sitter.reviews.prefix(2)) { r in
                                ReviewCard(review: r)
                            }
                        }
                    }

                    // Contact Button - Show if we have a userId and it's not the current user
                    if let userId = sitterUserId ?? sitter.userId, session.user?.id != userId {
                        Button {
                            showChat = true
                        } label: {
                            HStack {
                                Image(systemName: "message.fill")
                                Text("CONTACT")
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.blue)
                            )
                        }
                        .padding(.horizontal, 16)
                        .buttonStyle(.plain)
                    }

                    // CTA
                    Button {
                        showBooking = true
                    } label: {
                        Text("BOOK NOW")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.vetCanyon)
                            )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)
            }
        }
        .sheet(isPresented: $showBooking) {
            BookingSheet(sitter: sitter, sitterUserId: sitterUserId ?? sitter.userId)
                .presentationDetents([.height(480), .large])
        }
        .sheet(isPresented: $showChat) {
            if let userId = sitterUserId ?? sitter.userId {
                NavigationStack {
                    ChatView(
                        recipientId: userId,
                        recipientName: sitter.displayName,
                        recipientAvatarUrl: nil
                    )
                }
            }
        }
    }
}

// MARK: - Components

private struct SectionBox<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.vetTitle)

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.vetCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.vetStroke.opacity(0.3), lineWidth: 1))
        .padding(.horizontal, 16)
    }
}

private struct PillSmall: View {
    let text: String
    let icon: String
    let fg: Color
    let bg: Color
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 11, weight: .semibold))
            Text(text).font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(fg)
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(bg)
        .clipShape(Capsule())
    }
}

private struct StarRating: View {
    let rating: Double // 0...5
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { i in
                let filled = rating >= Double(i + 1) - 0.25
                Image(systemName: filled ? "star.fill" : "star")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.vetCanyon)
            }
        }
    }
}

private struct ServiceRow: View {
    let title: String
    let price: String
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.vetTitle)
            Spacer()
            Text(price)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.vetCanyon)
        }
        .padding(12)
        .background(Color.vetInputBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct ReviewCard: View {
    let review: Review
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(review.author)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.vetTitle)
                Spacer()
                StarRating(rating: review.stars)
            }
            Text(review.text)
                .font(.system(size: 14))
                .foregroundColor(.vetSubtitle)
        }
        .padding(12)
        .background(Color.vetInputBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct BookingSheet: View {
    let sitter: PetSitter
    let sitterUserId: String?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager
    @State private var selectedService = 0
    @State private var date = Date()
    @State private var description = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    
    private let bookingService = BookingService.shared
    
    private var serviceType: String {
        selectedService == 0 ? "At Home" : "Visit"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Book with \(sitter.displayName)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.vetTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Picker("Service", selection: $selectedService) {
                        Text("At Home – \(sitter.priceAtHome)").tag(0)
                        Text("Visit – \(sitter.priceVisit)").tag(1)
                    }
                    .pickerStyle(.segmented)

                    DatePicker("Date & time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .tint(.vetCanyon)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Additional Notes (Optional)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.vetTitle)
                        TextEditor(text: $description)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color.vetInputBackground)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.vetStroke, lineWidth: 1))
                            .cornerRadius(12)
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }

                    Button {
                        Task {
                            await createBooking()
                        }
                    } label: {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity, minHeight: 48)
                        } else {
                            Text("Confirm Booking")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 48)
                        }
                    }
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.vetCanyon))
                    .disabled(isSubmitting || sitterUserId == nil)
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
            .alert("Booking Request Sent!", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your booking request has been sent. The pet sitter will be notified and can accept or reject it.")
            }
        }
    }
    
    @MainActor
    private func createBooking() async {
        guard let sitterUserId = sitterUserId,
              let accessToken = session.tokens?.accessToken else {
            errorMessage = "Unable to create booking. Please try again."
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let request = CreateBookingRequest(
            providerId: sitterUserId,
            providerType: "sitter",
            petId: nil, // Can be extended to select a pet
            serviceType: serviceType,
            description: description.isEmpty ? nil : description,
            dateTime: dateFormatter.string(from: date),
            duration: nil,
            price: nil
        )
        
        do {
            _ = try await bookingService.createBooking(request, accessToken: accessToken)
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("❌ Failed to create booking: \(error)")
            #endif
        }
        
        isSubmitting = false
    }
}

// MARK: - Models (local to this screen)

struct PetSitter: Identifiable, Hashable {
    let id: UUID
    let displayName: String
    let emoji: String
    let about: String
    let priceAtHome: String
    let priceVisit: String
    let rating: Double
    let reviews: [Review]
    let userId: String? // User ID for messaging
    
    // Make hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PetSitter, rhs: PetSitter) -> Bool {
        lhs.id == rhs.id
    }

    // mock
    static var mock: PetSitter {
        .init(
            id: UUID(),
            displayName: "Fatima Ben Youssef",
            emoji: "🧑‍🦰",
            about: "Experienced pet sitter with 5+ years of experience. Specialized in caring for dogs and cats. Offers at-home sitting, walking, and feeding services.",
            priceAtHome: "€25/day",
            priceVisit: "€15",
            rating: 4.9,
            reviews: [
                .init(author: "Jean Dupont", stars: 5.0, text: "Excellent care! My dog was so happy!"),
                .init(author: "Marie Santos", stars: 4.5, text: "Very professional and trustworthy!")
            ],
            userId: nil
        )
    }
}

struct Review: Identifiable {
    let id = UUID()
    let author: String
    let stars: Double
    let text: String
}

// MARK: - Preview

#Preview("Pet Sitter Profile – Light") {
    NavigationStack {
        PetSitterProfileView(sitter: .mock)
            .environmentObject(ThemeStore())
            .preferredColorScheme(.light)
    }
}

#Preview("Pet Sitter Profile – Dark") {
    NavigationStack {
        PetSitterProfileView(sitter: .mock)
            .environmentObject(ThemeStore())
            .preferredColorScheme(.dark)
    }
}
