//
//  VetProfileView.swift
//  vet.tn
//
//  Created by Mac on 6/11/2025.
//

import Foundation
//  VetProfileView.swift
//  vet.tn

import SwiftUI

// MARK: - Model

struct VetProfile: Identifiable, Hashable {
    let id: UUID
    let name: String
    let role: String
    let emoji: String        // you can replace with an image later
    let rating: Double
    let reviews: Int
    let is24_7: Bool
    let about: String
    let services: [Service]  // e.g. [("Cabinet","35€"), ("Home Visit","60€")]
    let hours: [String]      // lines to show under Hours
    let vetUserId: String?   // User ID for messaging

    struct Service: Hashable {
        let label: String
        let price: String
    }
    
    init(
        name: String,
        role: String,
        emoji: String,
        rating: Double,
        reviews: Int,
        is24_7: Bool,
        about: String,
        services: [Service],
        hours: [String],
        vetUserId: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.role = role
        self.emoji = emoji
        self.rating = rating
        self.reviews = reviews
        self.is24_7 = is24_7
        self.about = about
        self.services = services
        self.hours = hours
        self.vetUserId = vetUserId
    }
}

// MARK: - View

struct VetProfileView: View {
    let vet: VetProfile
    var onBook: (() -> Void)? = nil
    var vetUserId: String? = nil // User ID for messaging
    
    @State private var showChat = false
    @State private var showBooking = false
    @EnvironmentObject private var session: SessionManager

    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {

                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.vetCanyon.opacity(0.25))
                                .frame(width: 92, height: 92)
                            Text(vet.emoji)
                                .font(.system(size: 40))
                        }

                        Text(vet.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.vetTitle)

                        Text(vet.role)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.vetSubtitle)

                        HStack(spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                Text(String(format: "%.1f", vet.rating))
                            }
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Color.vetCardBackground)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.vetStroke, lineWidth: 1))

                            HStack(spacing: 6) {
                                Image(systemName: "text.badge.star")
                                Text("\(vet.reviews) reviews")
                            }
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Color.vetCardBackground)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.vetStroke, lineWidth: 1))

                            if vet.is24_7 {
                                HStack(spacing: 6) {
                                    Image(systemName: "bolt.fill")
                                    Text("24/7")
                                }
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(Color.vetCanyon.opacity(0.18))
                                .foregroundStyle(Color.vetCanyon)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.vetCanyon, lineWidth: 1))
                            }
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.vetTitle)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)

                    // About
                    SectionCard(title: "About") {
                        Text(vet.about)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.vetTitle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Services & Pricing
                    SectionCard(title: "Services & Pricing") {
                        VStack(spacing: 10) {
                            ForEach(vet.services, id: \.self) { s in
                                HStack {
                                    Text(s.label)
                                    Spacer()
                                    Text(s.price)
                                        .foregroundStyle(Color.vetCanyon)
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.vetTitle)

                                if s != vet.services.last {
                                    Divider().overlay(Color.vetStroke)
                                }
                            }
                        }
                    }

                    // Hours
                    SectionCard(title: "Hours") {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(vet.hours, id: \.self) { line in
                                Text(line)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.vetTitle)
                            }
                        }
                    }

                    // Contact Button - Show if we have a userId and it's not the current user
                    if let vetUserId = vetUserId ?? vet.vetUserId, session.user?.id != vetUserId {
                        Button {
                            showChat = true
                        } label: {
                            HStack {
                                Image(systemName: "message.fill")
                                Text("CONTACT")
                            }
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }

                    // Book CTA
                    Button {
                        showBooking = true
                    } label: {
                        Text("BOOK APPOINTMENT")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Color.vetCanyon)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(vet.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                headerBadge("bell.fill")
                headerBadge("gearshape.fill")
            }
        }
        .sheet(isPresented: $showChat) {
            if let vetUserId = vetUserId ?? vet.vetUserId {
                NavigationStack {
                    ChatView(
                        recipientId: vetUserId,
                        recipientName: vet.name,
                        recipientAvatarUrl: nil
                    )
                }
            }
        }
        .sheet(isPresented: $showBooking) {
            VetBookingSheet(vet: vet, vetUserId: vetUserId ?? vet.vetUserId)
                .presentationDetents([.height(480), .large])
        }
    }

    private func headerBadge(_ system: String) -> some View {
        Image(systemName: system)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.vetTitle)
            .frame(width: 32, height: 32)
            .background(Color.vetCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.vetStroke))
    }
}

// MARK: - Vet Booking Sheet

private struct VetBookingSheet: View {
    let vet: VetProfile
    let vetUserId: String?
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
        guard selectedService < vet.services.count else { return "Cabinet" }
        return vet.services[selectedService].label
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Book with \(vet.name)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.vetTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if !vet.services.isEmpty {
                        Picker("Service", selection: $selectedService) {
                            ForEach(Array(vet.services.enumerated()), id: \.offset) { index, service in
                                Text("\(service.label) – \(service.price)").tag(index)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

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
                    .disabled(isSubmitting || vetUserId == nil)
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
                Text("Your booking request has been sent. The veterinarian will be notified and can accept or reject it.")
            }
        }
    }
    
    @MainActor
    private func createBooking() async {
        guard let vetUserId = vetUserId,
              let accessToken = session.tokens?.accessToken else {
            errorMessage = "Unable to create booking. Please try again."
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let request = CreateBookingRequest(
            providerId: vetUserId,
            providerType: "vet",
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

// MARK: - Section Card

private struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.vetTitle)
            content
        }
        .padding()
        .background(Color.vetCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.vetStroke))
    }
}

// MARK: - Preview

#Preview("Vet Profile – Light") {
    NavigationStack {
        VetProfileView(
            vet: .init(
                name: "Dr. Ahmed",
                role: "Veterinary Specialist",
                emoji: "🧑‍⚕️",
                rating: 4.8,
                reviews: 120,
                is24_7: true,
                about: "Veterinarian with 10+ years of experience in surgery and dermatology. Specialized in treating complex cases.",
                services: [
                    .init(label: "Cabinet",   price: "35€"),
                    .init(label: "Home Visit",price: "60€"),
                    .init(label: "Video Call",price: "25€")
                ],
                hours: [
                    "Mon–Sat: 9:00 AM – 6:00 PM",
                    "Sun: 10:00 AM – 4:00 PM",
                    "24/7 Emergency Available"
                ]
            )
        )
        .preferredColorScheme(.light)
    }
}

#Preview("Vet Profile – Dark") {
    NavigationStack {
        VetProfileView(
            vet: .init(
                name: "Dr. Ahmed",
                role: "Veterinary Specialist",
                emoji: "🧑‍⚕️",
                rating: 4.8,
                reviews: 120,
                is24_7: true,
                about: "Veterinarian with 10+ years of experience in surgery and dermatology. Specialized in treating complex cases.",
                services: [
                    .init(label: "Cabinet",   price: "35€"),
                    .init(label: "Home Visit",price: "60€"),
                    .init(label: "Video Call",price: "25€")
                ],
                hours: [
                    "Mon–Sat: 9:00 AM – 6:00 PM",
                    "Sun: 10:00 AM – 4:00 PM",
                    "24/7 Emergency Available"
                ]
            )
        )
        .preferredColorScheme(.dark)
    }
}
