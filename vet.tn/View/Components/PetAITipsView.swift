//
//  PetAITipsView.swift
//  vet.tn
//
//  Example view showing how to use AI tips in your app
//

import SwiftUI

struct PetAITipsView: View {
    let pet: Pet
    @StateObject private var aiViewModel = PetAIViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AI CARE TIPS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.vetSubtitle)
                
                Spacer()
                
                Button {
                    Task {
                        await aiViewModel.generateTips(for: pet)
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundColor(.vetCanyon)
                }
            }
            
            if aiViewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let error = aiViewModel.error {
                Text("Error: \(error)")
                    .font(.system(size: 13))
                    .foregroundColor(.red)
                    .padding()
            } else if aiViewModel.tips.isEmpty {
                Button {
                    Task {
                        await aiViewModel.generateTips(for: pet)
                    }
                } label: {
                    Text("Generate Tips")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.vetCanyon)
                        .cornerRadius(8)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(aiViewModel.tips.enumerated()), id: \.offset) { index, tip in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.vetCanyon)
                            
                            Text(tip)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.vetTitle)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
            }
        }
        .padding()
        .background(Color.vetCardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.vetStroke.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            if aiViewModel.tips.isEmpty {
                Task {
                    await aiViewModel.generateTips(for: pet)
                }
            }
        }
    }
}

#Preview {
    PetAITipsView(
        pet: Pet(
            id: "1",
            name: "Max",
            species: "dog",
            breed: "Doberman",
            age: 3.0,
            gender: "Male",
            color: nil,
            weight: 28.5,
            height: nil,
            photo: nil,
            microchipId: nil,
            owner: nil,
            medicalHistory: MedicalHistory(
                id: nil,
                vaccinations: ["Rabies", "DHPP"],
                chronicConditions: nil,
                currentMedications: [Medication(name: "Heartworm Prevention", dosage: "Monthly")]
            )
        )
    )
    .padding()
    .background(Color.vetBackground)
}

