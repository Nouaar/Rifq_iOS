//  FindVetView.swift
//  vet.tn
//

import SwiftUI

struct FindVetView: View {
    // MARK: - Sort / Filters
    enum Sort: Hashable { case specialty, distance, allDay }
    @State private var activeSort: Sort = .specialty
    @State private var showOnlyOpen: Bool = false

    // MARK: - Selection for navigation
    @State private var selectedProfile: VetProfile? = nil

    // MARK: - Mock data
    @State private var vets: [VetCard] = [
        .init(
            name: "Dr. Ahmed Ben Ali",
            specialties: ["Surgery", "Dermatology"],
            rating: 4.8, reviews: 128,
            distanceKm: 2.3,
            is247: true, isOpen: true,
            tint: Color(hex: 0xF3B27A), emoji: "🧑‍⚕️"
        ),
        .init(
            name: "Dr. Soumaya El Aloui",
            specialties: ["General", "Emergency"],
            rating: 4.9, reviews: 247,
            distanceKm: 1.8,
            is247: false, isOpen: true,
            tint: Color(hex: 0xE8C48E), emoji: "🧑‍⚕️"
        ),
        .init(
            name: "Dr. Karim Miled",
            specialties: ["Orthopedics"],
            rating: 4.6, reviews: 89,
            distanceKm: 5.2,
            is247: false, isOpen: true,
            tint: Color(hex: 0xB7E08E), emoji: "🧑‍⚕️"
        )
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vetBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        // Title
                        Text("Find a Vet")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.vetTitle)
                            .padding(.horizontal, 16)
                            .padding(.top, 6)

                        // Sort chips + open filter
                        HStack(spacing: 8) {
                            SortChip(title: "Specialty", isActive: activeSort == .specialty) { activeSort = .specialty }
                            SortChip(title: "Distance",  isActive: activeSort == .distance ) { activeSort = .distance  }
                            SortChip(title: "24/7",      isActive: activeSort == .allDay   ) { activeSort = .allDay    }

                            Spacer(minLength: 8)

                            // Show only open vets
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) { showOnlyOpen.toggle() }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: showOnlyOpen ? "checkmark.circle.fill" : "circle")
                                    Text("Open")
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(showOnlyOpen ? Color.green.opacity(0.12) : Color.vetCardBackground)
                                .foregroundStyle(showOnlyOpen ? Color.green.darker() : Color.vetTitle)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(showOnlyOpen ? Color.green : Color.vetStroke, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)

                        // Vet list
                        VStack(spacing: 10) {
                            ForEach(filteredAndSorted(vets)) { vet in
                                Button {
                                    selectedProfile = mapToProfile(vet)
                                } label: {
                                    VetListRow(vet: vet)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Find a Vet")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selectedProfile) { profile in
                VetProfileView(vet: profile)
            }
        }
    }

    // MARK: - Helpers

    private func filteredAndSorted(_ items: [VetCard]) -> [VetCard] {
        var res = items
        switch activeSort {
        case .specialty:
            res = res.sorted { $0.name < $1.name }
        case .distance:
            res = res.sorted { $0.distanceKm < $1.distanceKm }
        case .allDay:
            res = res.sorted { ($0.is247 ? 0 : 1, $0.distanceKm) < ($1.is247 ? 0 : 1, $1.distanceKm) }
        }
        if showOnlyOpen { res = res.filter { $0.isOpen } }
        return res
    }

    private func mapToProfile(_ v: VetCard) -> VetProfile {
        VetProfile(
            name: v.name,
            role: v.specialties.first.map { "\($0) Specialist" } ?? "Veterinary Specialist",
            emoji: v.emoji,
            rating: v.rating,
            reviews: v.reviews,
            is24_7: v.is247,
            about: "Experienced vet specialized in \(v.specialties.joined(separator: ", ")). Offering high-quality and caring medical services for your pets.",
            services: [
                .init(label: "Cabinet",   price: "35€"),
                .init(label: "Home Visit",price: "60€"),
                .init(label: "Video Call",price: "25€")
            ],
            hours: [
                "Mon–Sat: 9:00 AM – 6:00 PM",
                "Sun: 10:00 AM – 4:00 PM",
                v.is247 ? "24/7 Emergency Available" : "Emergency by appointment"
            ]
        )
    }
}

// MARK: - Row

struct VetListRow: View {
    let vet: VetCard

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(vet.tint.opacity(0.35))
                    .frame(width: 44, height: 44)
                Text(vet.emoji)
                    .font(.system(size: 22))
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(vet.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.vetTitle)

                HStack(spacing: 6) {
                    Text(vet.specialties.joined(separator: ", "))
                    Text("• \(String(format: "%.1f", vet.rating))★")
                    Text("(\(vet.reviews))")
                }
                .foregroundColor(.vetSubtitle)
                .font(.system(size: 12))

                HStack(spacing: 8) {
                    Label("\(String(format: "%.1f", vet.distanceKm)) km", systemImage: "mappin.and.ellipse")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.vetCanyon)

                    StatusPill(
                        text: vet.isOpen ? "Open" : "Closed",
                        bg: vet.isOpen ? Color.green.opacity(0.12) : Color.red.opacity(0.12),
                        fg: vet.isOpen ? Color.green.darker() : Color.red
                    )

                    if vet.is247 {
                        StatusPill(
                            text: "24/7",
                            bg: Color.vetCanyon.opacity(0.14),
                            fg: Color.vetCanyon
                        )
                    }
                }
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
        .background(Color.vetCardBackground) // ✅ Supports Dark/Light
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.vetStroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Small components

struct SortChip: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isActive ? .vetCanyon : .vetTitle)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isActive ? Color.vetCanyon.opacity(0.14) : Color.vetCardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isActive ? Color.vetCanyon : Color.vetStroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pill renamed to avoid conflicts
private struct StatusPill: View {
    let text: String
    let bg: Color
    let fg: Color
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(fg)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(bg)
            .clipShape(Capsule())
    }
}

// MARK: - Model

struct VetCard: Identifiable {
    let id = UUID()
    let name: String
    let specialties: [String]
    let rating: Double
    let reviews: Int
    let distanceKm: Double
    let is247: Bool
    let isOpen: Bool
    let tint: Color
    let emoji: String
}

// MARK: - Utils

private extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Preview

#Preview {
    FindVetView()
        .preferredColorScheme(.dark) // test dark mode
}
