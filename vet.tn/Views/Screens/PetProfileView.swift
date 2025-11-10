//
//  PetProfileView.swift
//  vet.tn
//
//  Created by Mac on 5/11/2025.
//

import Foundation
//
//  PetProfileView.swift
//  vet.tn
//

import SwiftUI

struct PetProfileView: View {
    let pet: Pet

    @State private var showEdit = false

    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // MARK: - Header
                    TopBar(title: pet.name)

                    VStack(spacing: 8) {
                        Text(pet.emoji)
                            .font(.system(size: 60))
                            .padding(.top, 8)

                        Text(pet.name)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.vetTitle)

                        Text("\(pet.breed) • \(pet.ageText)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.vetSubtitle)
                    }

                    // MARK: - Stats Section
                    VStack(spacing: 12) {

                        // Navigate to MedicalHistoryView when tapped
                        NavigationLink {
                            MedicalHistoryView(pet: pet)
                        } label: {
                            Text("MEDICAL HISTORY")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.vetCanyon)
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.vetCanyon, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain) // keep it flat and elegant

                        HStack(spacing: 16) {
                            StatBox(title: "Weight", value: "\(pet.weight)")
                            StatBox(title: "Height", value: "\(pet.height)")
                        }
                    }
                    .padding(.horizontal, 16)

                    // MARK: - Basic Info
                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle("Basic Info")

                        InfoRow(label: "Date of Birth", value: pet.birthDateFormatted)
                        InfoRow(label: "Breed", value: pet.breed)
                        InfoRow(label: "Color", value: pet.color)
                        InfoRow(label: "Microchip ID", value: pet.microchip)
                    }
                    .padding(.horizontal, 16)

                    // MARK: - Health Status
                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle("Health Status")

                        HealthCard(
                            icon: "checkmark.circle.fill",
                            text: "All Vaccinations Up-to-date",
                            color: .green
                        )

                        if let med = pet.activeMedication {
                            HealthCard(
                                icon: "exclamationmark.triangle.fill",
                                text: "Medication Active (\(med))",
                                color: .orange
                            )
                        }
                    }
                    .padding(.horizontal, 16)

                    // MARK: - Edit Button
                    Button {
                        showEdit.toggle()
                    } label: {
                        Label("EDIT PET INFO", systemImage: "pencil")
                            .font(.system(size: 15, weight: .bold))
                            .frame(maxWidth: .infinity, minHeight: 50)
                    }
                    .foregroundStyle(Color.vetCanyon)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.vetCanyon, lineWidth: 1.4)
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showEdit) {
            EditPetView(pet: pet)
        }
        .preference(key: TabBarHiddenPreferenceKey.self, value: false)
    }

    // MARK: - Subviews

    private func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(Color.vetSubtitle)
    }
}

// MARK: - Components

struct StatBox: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.vetCanyon)
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.vetSubtitle)
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .background(Color.vetCardBackground)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.vetStroke, lineWidth: 1))
        .cornerRadius(12)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.vetTitle)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.vetCanyon)
        }
        .padding(12)
        .background(Color.vetCardBackground)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.vetStroke, lineWidth: 1))
        .cornerRadius(12)
    }
}

struct HealthCard: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.vetTitle)
            Spacer()
        }
        .padding(12)
        .background(Color.vetCardBackground)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.4), lineWidth: 1))
        .cornerRadius(12)
    }
}

// MARK: - Model

struct PetProfileData: Identifiable {
    let id = UUID()
    let name: String
    let breed: String
    let color: String
    let emoji: String
    let birthDate: Date
    let weight: String
    let height: String
    let microchip: String
    let activeMedication: String?

    var ageText: String {
        let years = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        return "\(years) year\(years > 1 ? "s" : "") old"
    }

    var birthDateFormatted: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: birthDate)
    }
}

// MARK: - Edit Pet Sheet Placeholder

struct EditPetView: View {
    let pet: Pet
    var body: some View {
        VStack(spacing: 12) {
            Text("Edit \(pet.name)’s Info")
                .font(.title3.bold())
            Text("(Coming Soon 🐾)")
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.vetBackground.ignoresSafeArea())
    }
}

// MARK: - Preview

#Preview("Pet Profile") {
    NavigationStack {
        PetProfileView(
            pet: Pet(
                name: "Max",
                breed: "Doberman",
                emoji: "🐕",
                medsCount: 1,
                weight: "2.8 kg"
              
            )
        )
        .environmentObject(ThemeStore()) // ✅ inject ThemeStore for colors
    }
}


#Preview("Pet Profile – Dark") {
    NavigationStack {
        PetProfileView(pet: .init(
            name: "Max",
            breed: "Doberman",
            emoji: "🐕",
            medsCount: 1,
            weight: "2.8 kg"
        ))
        .environmentObject(ThemeStore())
        .preferredColorScheme(.dark)
    }
}
