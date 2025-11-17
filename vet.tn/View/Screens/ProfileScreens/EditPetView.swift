//
//  EditPetView.swift
//  vet.tn
//
//  Created by Mac on 7/11/2025.
//

import SwiftUI
import PhotosUI

struct EditPetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager
    @StateObject private var petViewModel = PetViewModel()
    
    let pet: Pet
    
    @State private var name: String = ""
    @State private var breed: String = ""
    @State private var species: String = "Dog"
    @State private var gender: String = "Male"
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var microchip: String = ""
    @State private var color: String = ""
    @State private var age: Double = 0
    
    // Medical History
    @State private var vaccinations: String = ""
    @State private var chronicConditions: String = ""
    @State private var medications: String = ""
    
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var showSuccessAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.vetBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Pet Info Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Pet Information")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.vetTitle)
                            
                            VStack(spacing: 12) {
                                PetTextField(title: "Name", text: $name, icon: "pawprint.fill")
                                PetTextField(title: "Breed", text: $breed, icon: "leaf.fill")
                                
                                PetPickerField(title: "Species", selection: $species, options: ["Dog", "Cat", "Bird", "Other"])
                                
                                PetSegmentField(title: "Gender", selection: $gender, options: ["Male", "Female"])
                                
                                HStack(spacing: 12) {
                                    PetTextField(title: "Weight (kg)", text: $weight, icon: "scalemass.fill")
                                        .keyboardType(.decimalPad)
                                    PetTextField(title: "Height (cm)", text: $height, icon: "ruler.fill")
                                        .keyboardType(.decimalPad)
                                }
                                
                                PetTextField(title: "Color", text: $color, icon: "paintpalette.fill")
                                PetTextField(title: "Microchip ID", text: $microchip, icon: "barcode.viewfinder")
                            }
                        }
                        .padding()
                        .background(Color.vetCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.vetStroke, lineWidth: 1))
                        
                        // Medical History Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Medical History")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.vetTitle)
                            
                            VStack(spacing: 12) {
                                PetTextField(
                                    title: "Vaccinations (comma-separated)",
                                    text: $vaccinations,
                                    icon: "syringe"
                                )
                                
                                PetTextField(
                                    title: "Chronic Conditions (comma-separated)",
                                    text: $chronicConditions,
                                    icon: "stethoscope"
                                )
                                
                                PetTextField(
                                    title: "Medications (format: Name: Dosage)",
                                    text: $medications,
                                    icon: "pills.fill"
                                )
                            }
                        }
                        .padding()
                        .background(Color.vetCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.vetStroke, lineWidth: 1))
                        
                        if let error = saveError {
                            Text(error)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.9))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                        Button {
                            Task {
                                await savePet()
                            }
                        } label: {
                            Text(isSaving ? "Saving..." : "Save Changes")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(isSaving ? Color.vetCanyon.opacity(0.6) : Color.vetCanyon)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isSaving || !canSave)
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.vetCanyon)
                }
            }
            .overlay {
                if isSaving {
                    ProgressView("Saving…")
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .alert("Pet updated successfully!", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            }
            .onAppear {
                petViewModel.sessionManager = session
                loadPetData()
            }
        }
    }
    
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !species.isEmpty
    }
    
    private func loadPetData() {
        name = pet.name
        breed = pet.breed ?? ""
        species = pet.species.capitalized
        gender = pet.gender ?? "Male"
        weight = pet.weight != nil ? String(format: "%.1f", pet.weight!) : ""
        height = pet.height != nil ? String(format: "%.1f", pet.height!) : ""
        microchip = pet.microchipId ?? ""
        color = pet.color ?? ""
        age = pet.age ?? 0
        
        // Load medical history
        if let history = pet.medicalHistory {
            vaccinations = history.vaccinations?.joined(separator: ", ") ?? ""
            chronicConditions = history.chronicConditions?.joined(separator: ", ") ?? ""
            medications = history.currentMedications?.map { "\($0.name): \($0.dosage)" }.joined(separator: ", ") ?? ""
        }
    }
    
    private func savePet() async {
        isSaving = true
        saveError = nil
        
        let weightValue = Double(weight.replacingOccurrences(of: ",", with: "."))
        let heightValue = Double(height.replacingOccurrences(of: ",", with: "."))
        
        // Parse medical history
        let vaccinationsArray = vaccinations.isEmpty ? nil : vaccinations.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let conditionsArray = chronicConditions.isEmpty ? nil : chronicConditions.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        
        let medicationsArray: [Medication]? = medications.isEmpty ? nil : medications.components(separatedBy: ",").compactMap { medStr in
            let trimmed = medStr.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return nil }
            let parts = trimmed.components(separatedBy: ":")
            if parts.count >= 2 {
                let name = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let dosage = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                if name.isEmpty || dosage.isEmpty { return nil }
                return Medication(name: name, dosage: dosage)
            }
            return nil
        }
        
        let request = UpdatePetRequest(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            species: species.lowercased(),
            breed: breed.isEmpty ? nil : breed,
            age: age > 0 ? age : nil,
            gender: gender,
            color: color.isEmpty ? nil : color,
            weight: weightValue,
            height: heightValue,
            photo: pet.photo,
            microchipId: microchip.isEmpty ? nil : microchip,
            medicalHistory: MedicalHistoryRequest(
                vaccinations: vaccinationsArray,
                chronicConditions: conditionsArray,
                currentMedications: medicationsArray
            )
        )
        
        let success = await petViewModel.updatePet(petId: pet.id, request: request)
        
        await MainActor.run {
            isSaving = false
            if success {
                // Refresh the pet data
                Task {
                    await petViewModel.refreshPet(petId: pet.id)
                }
                showSuccessAlert = true
            } else {
                saveError = petViewModel.error ?? "Failed to update pet. Please try again."
            }
        }
    }
}

// MARK: - Reusable Components

private struct PetTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.vetSubtitle)
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(.vetSubtitle)
                    .frame(width: 20)
                TextField("", text: $text)
                    .foregroundColor(.vetTitle)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.vetInputBackground)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.vetStroke, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

private struct PetPickerField: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.vetSubtitle)
            HStack(spacing: 10) {
                Image(systemName: "list.bullet")
                    .foregroundColor(.vetSubtitle)
                    .frame(width: 20)
                Picker(title, selection: $selection) {
                    ForEach(options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .tint(.vetCanyon)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.vetInputBackground)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.vetStroke, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

private struct PetSegmentField: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.vetSubtitle)
            HStack(spacing: 10) {
                ForEach(options, id: \.self) { option in
                    Button {
                        selection = option
                    } label: {
                        Text(option)
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selection == option ? Color.vetCanyon.opacity(0.18) : Color.vetCardBackground)
                            .foregroundColor(selection == option ? .vetCanyon : .vetTitle)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(selection == option ? Color.vetCanyon : Color.vetStroke, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    EditPetView(
        pet: Pet(
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
            medicalHistory: nil
        )
    )
    .environmentObject(SessionManager())
}

