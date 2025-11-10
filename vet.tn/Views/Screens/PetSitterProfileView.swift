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
    @State private var showBooking = false

    let sitter: PetSitter

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
            BookingSheet(sitter: sitter)
                .presentationDetents([.height(360), .large])
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
    @Environment(\.dismiss) private var dismiss
    @State private var selectedService = 0
    @State private var date = Date()

    var body: some View {
        NavigationView {
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

                Spacer()

                Button {
                    // TODO: integrate with real booking flow
                    dismiss()
                } label: {
                    Text("Confirm Booking")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.vetCanyon))
                }
            }
            .padding(16)
            .background(Color.vetBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }.foregroundColor(.vetCanyon)
                }
            }
        }
    }
}

// MARK: - Models (local to this screen)

struct PetSitter: Identifiable {
    let id = UUID()
    let displayName: String
    let emoji: String
    let about: String
    let priceAtHome: String
    let priceVisit: String
    let rating: Double
    let reviews: [Review]

    // mock
    static var mock: PetSitter {
        .init(
            displayName: "Fatima Ben Youssef",
            emoji: "🧑‍🦰",
            about: "Experienced pet sitter with 5+ years of experience. Specialized in caring for dogs and cats. Offers at-home sitting, walking, and feeding services.",
            priceAtHome: "€25/day",
            priceVisit: "€15",
            rating: 4.9,
            reviews: [
                .init(author: "Jean Dupont", stars: 5.0, text: "Excellent care! My dog was so happy!"),
                .init(author: "Marie Santos", stars: 4.5, text: "Very professional and trustworthy!")
            ]
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
