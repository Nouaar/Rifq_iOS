//
//  MedicalHistoryView.swift
//  vet.tn
//
//  Created by Mac on 5/11/2025.
//

import Foundation
//
//  MedicalHistoryView.swift
//  vet.tn
//

import SwiftUI

// MARK: - View

struct MedicalHistoryView: View {
    // Pass the pet to show name/emoji/breed/age text in header
    let pet: Pet

    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {

                    // Top bar
                    TopBar(
                        title: "Medical History",
                        onNotifications: {},
                        onSettings: {}
                    )

                    // Pet header
                    PetHeader(pet: pet)
                        .padding(.horizontal, 16)

                    // Timeline
                    SectionTitle("Timeline")
                        .padding(.horizontal, 16)

                    VStack(spacing: 10) {
                        ForEach(timelineMock) { item in
                            TimelineRow(item: item)
                        }
                    }
                    .padding(.horizontal, 16)

                    // Current Medications
                    SectionTitle("Current Medications")
                        .padding(.horizontal, 16)

                    VStack(spacing: 10) {
                        ForEach(medicationsMock) { med in
                            MedicationCard(med: med)
                        }
                    }
                    .padding(.horizontal, 16)

                    // Allergies & Conditions
                    SectionTitle("Allergies & Conditions")
                        .padding(.horizontal, 16)

                    VStack(spacing: 10) {
                        InfoListCard(
                            title: "Known Allergies",
                            items: [
                                "Chicken",
                                "Dairy products",
                                "Beef"
                            ],
                            icon: "exclamationmark.triangle.fill",
                            iconTint: .orange
                        )

                        InfoListCard(
                            title: "Chronic Conditions",
                            items: [
                                "Recurring otitis",
                                "Sensitive skin",
                                "Mild arthritis"
                            ],
                            icon: "stethoscope",
                            iconTint: .vetCanyon
                        )
                    }
                    .padding(.horizontal, 16)

                    // Vaccinations
                    SectionTitle("Vaccinations")
                        .padding(.horizontal, 16)

                    VStack(spacing: 10) {
                        ForEach(vaccinesMock) { vax in
                            VaccinationRow(vax: vax)
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer(minLength: 24)
                }
                .padding(.bottom, 24)
            }
        }
    }
}

// MARK: - Components

private struct PetHeader: View {
    let pet: Pet

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.vetCanyon.opacity(0.22))
                    .frame(width: 88, height: 88)
                Text(pet.emoji)
                    .font(.system(size: 40))
            }

            VStack(spacing: 2) {
                Text("\(pet.name)'s Medical History")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.vetTitle)
                Text("\(pet.breed) • \(ageText(from: pet))")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.vetSubtitle)
            }
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color.vetCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.vetStroke, lineWidth: 1)
        )
    }

    private func ageText(from pet: Pet) -> String {
        // If you already have pet.ageText, just return that.
        // This fallback infers from sample weight text if needed.
        // Replace with your real age string if available.
        return "3 years old"
    }
}

private struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color.vetSubtitle)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TimelineRow: View {
    let item: TimelineItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Dot + date
            VStack(spacing: 6) {
                Circle()
                    .fill(Color.vetCanyon)
                    .frame(width: 8, height: 8)
                Spacer()
            }
            .frame(width: 14)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.date)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.vetSubtitle)

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: item.icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.vetCanyon)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.vetTitle)
                        if let subtitle = item.subtitle {
                            Text(subtitle)
                                .font(.system(size: 12))
                                .foregroundStyle(Color.vetSubtitle)
                        }
                    }
                    Spacer()
                }
            }
            .padding(12)
            .background(Color.vetCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.vetStroke, lineWidth: 1)
            )
        }
    }
}

private struct MedicationCard: View {
    let med: Medication

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Capsule()
                    .fill(Color.clear)
                    .frame(width: 4, height: 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.vetCanyon, lineWidth: 2)
                    )
                Text(med.name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.vetTitle)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                if let dosage = med.dosage {
                    Text("Dosage: \(dosage)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.vetSubtitle)
                }
                if let frequency = med.frequency {
                    Text("For: \(frequency)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.vetSubtitle)
                }
                if let started = med.started {
                    Text("Started: \(started)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.vetSubtitle)
                }
            }
        }
        .padding(12)
        .background(Color.vetCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.vetStroke, lineWidth: 1)
        )
    }
}

private struct InfoListCard: View {
    let title: String
    let items: [String]
    let icon: String
    let iconTint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(iconTint)
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.vetTitle)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                ForEach(items, id: \.self) { it in
                    HStack(spacing: 6) {
                        Text("•")
                            .foregroundStyle(Color.vetSubtitle)
                        Text(it)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.vetSubtitle)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.vetCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.vetStroke, lineWidth: 1)
        )
    }
}

private struct VaccinationRow: View {
    let vax: Vaccination

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "pencil.and.list.clipboard")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.vetCanyon)

            VStack(alignment: .leading, spacing: 2) {
                Text(vax.name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.vetTitle)
                Text(vax.doctor)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.vetSubtitle)
            }

            Spacer()

            Text(vax.date)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.vetSubtitle)
        }
        .padding(12)
        .background(Color.vetCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.vetStroke, lineWidth: 1)
        )
    }
}

// MARK: - Models (simple UI models for the view)

private struct TimelineItem: Identifiable {
    let id = UUID()
    let date: String
    let icon: String
    let title: String
    let subtitle: String?
}

private struct Medication: Identifiable {
    let id = UUID()
    let name: String
    let dosage: String?
    let frequency: String?
    let started: String?
}

private struct Vaccination: Identifiable {
    let id = UUID()
    let name: String
    let doctor: String
    let date: String
}

// MARK: - Mock Data

private let timelineMock: [TimelineItem] = [
    .init(date: "OCT 10, 2024",
          icon: "syringe",
          title: "Rabies Vaccination",
          subtitle: "Administered by Dr. Ahmed Ben Ali"),
    .init(date: "SEP 25, 2024",
          icon: "stethoscope",
          title: "Consultation",
          subtitle: "Bacterial otitis diagnosis – Dr. Ahmed"),
    .init(date: "SEP 20, 2024",
          icon: "doc.text.magnifyingglass",
          title: "Lab Results",
          subtitle: "Blood work analysis – All normal"),
    .init(date: "AUG 15, 2024",
          icon: "pills.fill",
          title: "Medication",
          subtitle: "Started Amoxicilline treatment")
]

private let medicationsMock: [Medication] = [
    .init(name: "Amoxicilline 500mg",
          dosage: "500mg 2× per day",
          frequency: nil,
          started: "Sep 15, 2024"),
    .init(name: "Ear Drops (Otimax)",
          dosage: nil,
          frequency: "Apply 3× daily — For: Otitis treatment",
          started: nil)
]

private let vaccinesMock: [Vaccination] = [
    .init(name: "DHCP",  doctor: "Dr. Ahmed Ben Ali", date: "12/2023"),
    .init(name: "Rabies", doctor: "Dr. Ahmed Ben Ali", date: "10/2024")
]

// MARK: - Previews

#Preview("Medical History – Light") {
    let pet = Pet(name: "Max", breed: "Doberman", emoji: "🐕", medsCount: 1, weight: "2.8 kg")
    return NavigationStack {
        MedicalHistoryView(pet: pet)
            .environmentObject(ThemeStore())
            .preferredColorScheme(.light)
    }
}

#Preview("Medical History – Dark") {
    let pet = Pet(name: "Max", breed: "Doberman", emoji: "🐕", medsCount: 1, weight: "2.8 kg")
    return NavigationStack {
        MedicalHistoryView(pet: pet)
            .environmentObject(ThemeStore())
            .preferredColorScheme(.dark)
    }
}
