//
//  MedicalHistoryView.swift
//  vet.tn
//
//  Created by Mac on 5/11/2025.
//

import SwiftUI

// MARK: - View

struct MedicalHistoryView: View {
    let pet: Pet

    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Top bar
                    TopBar(
                        title: "Medical History"
                    )

                    // Pet header card
                    PetHeaderCard(pet: pet)
                        .padding(.horizontal, 16)

                    // Quick Stats
                    QuickStatsSection(pet: pet)
                        .padding(.horizontal, 16)

                    // Current Medications
                    if let meds = pet.medicalHistory?.currentMedications, !meds.isEmpty {
                        MedicationsSection(medications: meds)
                            .padding(.horizontal, 16)
                    }

                    // Vaccinations
                    if let vaccines = pet.medicalHistory?.vaccinations, !vaccines.isEmpty {
                        VaccinationsSection(vaccinations: vaccines)
                            .padding(.horizontal, 16)
                    }

                    // Chronic Conditions
                    if let conditions = pet.medicalHistory?.chronicConditions, !conditions.isEmpty {
                        ConditionsSection(conditions: conditions)
                            .padding(.horizontal, 16)
                    }

                    // Empty State
                    if isEmpty {
                        EmptyMedicalHistoryView()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 40)
                    }

                    Spacer(minLength: 24)
                }
                .padding(.bottom, 24)
            }
        }
    }
    
    private var isEmpty: Bool {
        let hasMeds = !(pet.medicalHistory?.currentMedications?.isEmpty ?? true)
        let hasVaccines = !(pet.medicalHistory?.vaccinations?.isEmpty ?? true)
        let hasConditions = !(pet.medicalHistory?.chronicConditions?.isEmpty ?? true)
        return !hasMeds && !hasVaccines && !hasConditions
    }
}

// MARK: - Pet Header Card

// MARK: - Helper for pet header photo

@ViewBuilder
private func petHeaderPhotoView(photoString: String, emoji: String) -> some View {
    // Check if it's a URL
    if photoString.hasPrefix("http://") || photoString.hasPrefix("https://"),
       let photoURL = URL(string: photoString) {
        AsyncImage(url: photoURL) { phase in
            switch phase {
            case .empty:
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.vetCanyon.opacity(0.2), Color.vetCanyon.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    ProgressView()
                }
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.vetStroke.opacity(0.3), lineWidth: 2))
            case .failure:
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.vetCanyon.opacity(0.2), Color.vetCanyon.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    Text(emoji)
                        .font(.system(size: 50))
                }
            @unknown default:
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.vetCanyon.opacity(0.2), Color.vetCanyon.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    Text(emoji)
                        .font(.system(size: 50))
                }
            }
        }
    } else if let base64String = extractBase64String(from: photoString),
              let imageData = Data(base64Encoded: base64String),
              let uiImage = UIImage(data: imageData) {
        Image(uiImage: uiImage)
            .resizable()
            .scaledToFill()
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.vetStroke.opacity(0.3), lineWidth: 2))
    } else {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.vetCanyon.opacity(0.2), Color.vetCanyon.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
            Text(emoji)
                .font(.system(size: 50))
        }
    }
}

private func extractBase64String(from photoString: String) -> String? {
    if photoString.hasPrefix("data:image") {
        if let commaIndex = photoString.firstIndex(of: ",") {
            return String(photoString[photoString.index(after: commaIndex)...])
        } else {
            return photoString
        }
    } else {
        return photoString
    }
}

private struct PetHeaderCard: View {
    let pet: Pet

    var body: some View {
        VStack(spacing: 16) {
            // Display photo if available, otherwise show emoji with gradient background
            if let photoString = pet.photo, !photoString.isEmpty {
                petHeaderPhotoView(photoString: photoString, emoji: pet.emoji)
            } else {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.vetCanyon.opacity(0.2), Color.vetCanyon.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    Text(pet.emoji)
                        .font(.system(size: 50))
                }
            }

            VStack(spacing: 6) {
                Text("\(pet.name)'s Medical History")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.vetTitle)
                
                Text("\(pet.breed ?? "Unknown") • \(pet.ageText)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.vetSubtitle)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.vetCardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [Color.vetCanyon.opacity(0.3), Color.vetCanyon.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Quick Stats Section

private struct QuickStatsSection: View {
    let pet: Pet
    
    var body: some View {
        HStack(spacing: 12) {
            StatCard(
                icon: "syringe.fill",
                title: "Vaccinations",
                value: "\(pet.medicalHistory?.vaccinations?.count ?? 0)",
                color: .green
            )
            
            StatCard(
                icon: "pills.fill",
                title: "Medications",
                value: "\(pet.medicalHistory?.currentMedications?.count ?? 0)",
                color: .orange
            )
            
            StatCard(
                icon: "stethoscope",
                title: "Conditions",
                value: "\(pet.medicalHistory?.chronicConditions?.count ?? 0)",
                color: .vetCanyon
            )
        }
    }
}

private struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.vetTitle)
            
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.vetSubtitle)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.vetCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.vetStroke.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Medications Section

private struct MedicationsSection: View {
    let medications: [Medication]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "pills.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.orange)
                
                Text("Current Medications")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.vetTitle)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(medications, id: \.name) { med in
                    MedicationCard(medication: med)
                }
            }
        }
    }
}

private struct MedicationCard: View {
    let medication: Medication
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "pills.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.orange)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(medication.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.vetTitle)
                
                Text("Dosage: \(medication.dosage)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.vetSubtitle)
            }
            
            Spacer()
            
            // Status indicator
            Circle()
                .fill(Color.orange)
                .frame(width: 8, height: 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.vetCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1.5)
        )
        .shadow(color: Color.orange.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Vaccinations Section

private struct VaccinationsSection: View {
    let vaccinations: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "syringe.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.green)
                
                Text("Vaccinations")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.vetTitle)
                
                Spacer()
            }
            
            VStack(spacing: 10) {
                ForEach(vaccinations, id: \.self) { vaccine in
                    VaccinationCard(vaccine: vaccine)
                }
            }
        }
    }
}

private struct VaccinationCard: View {
    let vaccine: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "syringe.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.green)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(vaccine)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.vetTitle)
                
                Text("Up to date")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.green)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.vetCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.2), lineWidth: 1.5)
        )
        .shadow(color: Color.green.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Conditions Section

private struct ConditionsSection: View {
    let conditions: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "stethoscope")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.vetCanyon)
                
                Text("Chronic Conditions")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.vetTitle)
                
                Spacer()
            }
            
            VStack(spacing: 10) {
                ForEach(conditions, id: \.self) { condition in
                    ConditionCard(condition: condition)
                }
            }
        }
    }
}

private struct ConditionCard: View {
    let condition: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.vetCanyon.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "stethoscope")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.vetCanyon)
            }
            
            // Content
            Text(condition)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.vetTitle)
            
            Spacer()
            
            // Info icon
            Image(systemName: "info.circle")
                .font(.system(size: 20))
                .foregroundColor(.vetSubtitle)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.vetCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.vetCanyon.opacity(0.2), lineWidth: 1.5)
        )
        .shadow(color: Color.vetCanyon.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Empty State

private struct EmptyMedicalHistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.vetCanyon.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.vetSubtitle)
            }
            
            Text("No Medical Records")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.vetTitle)
            
            Text("Medical history will appear here once records are added")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.vetSubtitle)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Preview

#Preview("Medical History – Light") {
    let pet = Pet(
        id: "1",
        name: "Max",
        species: "dog",
        breed: "Doberman",
        age: 3.0,
        gender: "Male",
        color: "Black & Tan",
        weight: 28.5,
        height: 70.0,
        photo: nil,
        microchipId: "123456789",
        owner: nil,
        medicalHistory: MedicalHistory(
            id: nil,
            vaccinations: ["Rabies", "DHPP", "Bordetella"],
            chronicConditions: ["Recurring otitis", "Sensitive skin"],
            currentMedications: [
                Medication(name: "Amoxicillin", dosage: "500mg twice daily"),
                Medication(name: "Heartworm Prevention", dosage: "Monthly chewable")
            ]
        )
    )
    return NavigationStack {
        MedicalHistoryView(pet: pet)
            .environmentObject(ThemeStore())
            .preferredColorScheme(.light)
    }
}

#Preview("Medical History – Dark") {
    let pet = Pet(
        id: "1",
        name: "Max",
        species: "dog",
        breed: "Doberman",
        age: 3.0,
        gender: "Male",
        color: "Black & Tan",
        weight: 28.5,
        height: 70.0,
        photo: nil,
        microchipId: "123456789",
        owner: nil,
        medicalHistory: MedicalHistory(
            id: nil,
            vaccinations: ["Rabies", "DHPP"],
            chronicConditions: ["Recurring otitis"],
            currentMedications: [Medication(name: "Amoxicillin", dosage: "500mg 2× per day")]
        )
    )
    return NavigationStack {
        MedicalHistoryView(pet: pet)
            .environmentObject(ThemeStore())
            .preferredColorScheme(.dark)
    }
}
