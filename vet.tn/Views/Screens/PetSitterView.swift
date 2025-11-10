//  PetSitterView.swift
//  vet.tn

import SwiftUI

struct PetSitterView: View {
    // MARK: - State
    @State private var fromDate = Date()
    @State private var toDate = Date().addingTimeInterval(24*60*60)
    @State private var selectedService: ServiceType = .atHome
    @State private var goAvailableSitters = false
    @State private var routeSitter: SitterCard? = nil      // ← tap a row to navigate

    private let sitters: [SitterCard] = [
        .init(name: "Fatima Ben Youssef", rating: 4.9, reviews: 12, tint: Color.vetCanyon.opacity(0.25), emoji: "🧑‍🍼"),
        .init(name: "Ahmed Hamza",        rating: 4.7, reviews: 8,  tint: Color.vetCanyon.opacity(0.25), emoji: "🧑‍🍼")
    ]

    // MARK: - Body
    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {

                    // Title
                    Text("Find Pet Sitter")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.vetTitle)
                        .padding(.top, 6)

                    // Dates
                    VStack(spacing: 12) {
                        LabeledField(title: "FROM DATE") {
                            DatePicker("", selection: $fromDate, displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        LabeledField(title: "TO DATE") {
                            DatePicker("", selection: $toDate, in: fromDate..., displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    // Service type
                    VStack(alignment: .leading, spacing: 10) {
                        Text("SERVICE TYPE")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.vetSubtitle)

                        VStack(spacing: 10) {
                            RadioRow(title: "At Home",    price: "€25/day", isOn: selectedService == .atHome)    { selectedService = .atHome }
                            RadioRow(title: "Visit Only", price: "€15",     isOn: selectedService == .visitOnly) { selectedService = .visitOnly }
                            RadioRow(title: "Walking",    price: "€20",     isOn: selectedService == .walking)   { selectedService = .walking }
                        }
                    }

                    // Search button -> Available sitters
                    Button {
                        goAvailableSitters = true
                    } label: {
                        Text("SEARCH SITTERS")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.vetCanyon)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    // Recent sitters
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Sitters")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.vetTitle)

                        VStack(spacing: 12) {
                            ForEach(sitters) { s in
                                Button {
                                    routeSitter = s                // ← triggers navigation
                                } label: {
                                    SitterRow(sitter: s)
                                        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
        }
        // Nav bar
        .navigationTitle("Pet Sitter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                headerBadge("bell.fill")
                headerBadge("gearshape.fill")
            }
        }

        // Available sitters screen
        .navigationDestination(isPresented: $goAvailableSitters) {
            AvailableSittersView()
                .navigationBarBackButtonHidden(false)
        }

        // Row -> Profile screen
        .navigationDestination(item: $routeSitter) { sitter in
            // If you already have PetSitterProfileView(sitter: …),
            // replace the next line with your own destination.
            LocalPetSitterProfileView(sitter: sitter)
        }
    }

    // MARK: - Small helpers
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

// MARK: - Models
private enum ServiceType { case atHome, visitOnly, walking }

private struct SitterCard: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let rating: Double
    let reviews: Int
    let tint: Color
    let emoji: String
}

// MARK: - Pieces

private struct LabeledField<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.vetSubtitle)

            content
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color.vetInputBackground)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.vetStroke))
                .cornerRadius(12)
        }
    }
}

private struct RadioRow: View {
    let title: String
    let price: String
    let isOn: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(isOn ? Color.blue : Color.vetStroke, lineWidth: 2)
                        .frame(width: 20, height: 20)
                    if isOn {
                        Circle().fill(Color.blue).frame(width: 10, height: 10)
                    }
                }

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.vetTitle)

                Spacer()

                Text(price)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.vetSubtitle)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.vetCanyon.opacity(0.6), lineWidth: 1)
                    )
            }
            .padding(12)
            .background(Color.vetCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isOn ? Color.vetCanyon : Color.vetStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct SitterRow: View {
    let sitter: SitterCard

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(sitter.tint)
                    .frame(width: 44, height: 44)
                Text(sitter.emoji).font(.system(size: 22))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(sitter.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.vetTitle)

                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text(String(format: "%.1f", sitter.rating))
                    Text("(\(sitter.reviews) reviews)")
                }
                .foregroundColor(.vetSubtitle)
                .font(.system(size: 12))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.vetTitle.opacity(0.8))
                .padding(8)
                .background(
                    Circle().fill(Color.vetCardBackground)
                        .overlay(Circle().stroke(Color.vetStroke, lineWidth: 1))
                )
        }
        .padding(12)
        .background(Color.vetCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.vetStroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Local profile screen (no external deps)
private struct LocalPetSitterProfileView: View {
    let sitter: SitterCard

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
                                .frame(width: 84, height: 84)
                            Text(sitter.emoji).font(.system(size: 36))
                        }
                        Text(sitter.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.vetTitle)

                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                            Text(String(format: "%.1f", sitter.rating))
                            Text("• \(sitter.reviews) reviews")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.vetSubtitle)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    // About
                    SectionCard(title: "About") {
                        Text("Experienced pet sitter with 5+ years of experience. Specialized in caring for dogs and cats. Offers at-home sitting, walking, and quick visits.")
                            .font(.system(size: 14))
                            .foregroundColor(.vetTitle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Services & Pricing
                    SectionCard(title: "Services & Pricing") {
                        HStack {
                            Text("At Home")
                            Spacer()
                            Text("€25/day")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.vetTitle)

                        Divider().overlay(Color.vetStroke)

                        HStack {
                            Text("Visit")
                            Spacer()
                            Text("€15")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.vetTitle)
                    }

                    // Reviews (sample)
                    SectionCard(title: "Recent Reviews") {
                        ReviewRow(author: "Jean Dupont",  text: "Excellent care! My dog was so happy!", stars: 5)
                        ReviewRow(author: "Marie Santos", text: "Very professional and trustworthy!",  stars: 4)
                    }

                    Button {
                        // book action
                    } label: {
                        Text("BOOK NOW")
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
        .navigationTitle("Pet Sitter")
        .navigationBarTitleDisplayMode(.inline)
    }

    private struct SectionCard<Content: View>: View {
        let title: String
        @ViewBuilder var content: Content
        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.vetTitle)
                content
            }
            .padding()
            .background(Color.vetCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.vetStroke))
        }
    }

    private struct ReviewRow: View {
        let author: String
        let text: String
        let stars: Int
        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    ForEach(0..<stars, id: \.self) { _ in
                        Image(systemName: "star.fill")
                    }
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.yellow)

                Text(author)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.vetTitle)

                Text(text)
                    .font(.system(size: 13))
                    .foregroundColor(.vetSubtitle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Color.vetInputBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - Preview
#Preview("Pet Sitter") {
    NavigationStack {
        PetSitterView()
            .environment(\.colorScheme, .light)
    }
}
