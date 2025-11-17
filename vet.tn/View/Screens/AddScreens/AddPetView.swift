//
//  AddPetFlowView.swift
//  vet.tn
//
//  Created by Mac on 6/11/2025.
//

import Foundation
import SwiftUI
import UIKit
import PhotosUI

// MARK: - Flow

struct AddPetFlowView: View {
    @EnvironmentObject private var theme: ThemeStore
    @EnvironmentObject private var session: SessionManager

    @StateObject private var petViewModel = PetViewModel()

    @State private var step: Step = .petInfo
    @Namespace private var ns

    @State private var draft = PetDraft() // holds form state
    @State private var saved = false
    @State private var isSaving = false
    @State private var saveError: String?

    enum Step: Int, CaseIterable { case petInfo, medical, review }
    
    // PetViewModel will be initialized in onAppear with the session from environment

    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                TopBar(title: "Add New Pet")

                // Step indicator
                StepHeader(step: step)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                // Animated content (each is full-screen scrollable)
                ZStack {
                    switch step {
                    case .petInfo:
                        ScrollView(showsIndicators: false) {
                            PetInfoStep(draft: $draft)
                                .matchedGeometryEffect(id: "card", in: ns)
                                .padding(.horizontal, 16)
                                .padding(.top, 10)
                                .padding(.bottom, 24)
                        }
                        .transition(.move(edge: .leading).combined(with: .opacity))

                    case .medical:
                        ScrollView(showsIndicators: false) {
                            MedicalInfoStep(draft: $draft)
                                .matchedGeometryEffect(id: "card", in: ns)
                                .padding(.horizontal, 16)
                                .padding(.top, 10)
                                .padding(.bottom, 24)
                        }
                        .transition(.asymmetric(insertion: .move(edge: .trailing),
                                                removal: .move(edge: .leading)).combined(with: .opacity))

                    case .review:
                        ScrollView(showsIndicators: false) {
                            ReviewStep(draft: draft)
                                .matchedGeometryEffect(id: "card", in: ns)
                                .padding(.horizontal, 16)
                                .padding(.top, 10)
                                .padding(.bottom, 24)
                        }
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.28), value: step)

                // Bottom bar (Back / Next / Save)
                HStack(spacing: 10) {
                    if step != .petInfo {
                        Button {
                            withAnimation { goBack() }
                        } label: {
                            Text("Back")
                                .font(.system(size: 15, weight: .semibold))
                                .frame(maxWidth: .infinity, minHeight: 48)
                        }
                        .foregroundStyle(Color.vetCanyon)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.vetCanyon, lineWidth: 2)
                        )
                    }

                    if step != .review {
                        Button {
                            withAnimation { goNext() }
                        } label: {
                            Text("Next")
                                .font(.system(size: 15, weight: .bold))
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .foregroundStyle(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(canPressNext ? Color.vetCanyon : Color.vetCanyon.opacity(0.35))
                                )
                        }
                        .disabled(!canPressNext)
                    } else {
                        Button {
                            Task {
                                await savePet()
                            }
                        } label: {
                            Text(isSaving ? "Saving..." : "Save Pet Profile")
                                .font(.system(size: 15, weight: .bold))
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .foregroundStyle(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(isSaving ? Color.vetCanyon.opacity(0.6) : Color.vetCanyon)
                                )
                        }
                        .disabled(isSaving)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
        .alert("🐾 Pet added successfully!", isPresented: $saved) {
            Button("OK", role: .cancel) {
                // Dismiss the view after successful save
                // The parent view will refresh pets automatically
            }
        }
        .alert("Error", isPresented: .constant(saveError != nil)) {
            Button("OK") { saveError = nil }
        } message: {
            if let error = saveError {
                Text(error)
            }
        }
        .onAppear {
            // Set session reference for PetViewModel
            petViewModel.sessionManager = session
        }
    }
    
    private func savePet() async {
        isSaving = true
        saveError = nil
        
        // Convert PetDraft to CreatePetRequest
        let weight = Double(draft.weight.replacingOccurrences(of: ",", with: "."))
        let height = Double(draft.height.replacingOccurrences(of: ",", with: "."))
        
        // Calculate age from birthDate
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year, .month], from: draft.birthDate, to: Date())
        let age = Double(ageComponents.year ?? 0) + (Double(ageComponents.month ?? 0) / 12.0)
        
        // Parse medical history
        let vaccinations = draft.vaccinations.isEmpty ? nil : draft.vaccinations.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        
        // Combine allergies and conditions (allergies stored as "Allergy: [name]")
        var allConditions: [String] = []
        if !draft.allergies.isEmpty && !draft.allergies.lowercased().contains("none") {
            let allergies = draft.allergies.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            allConditions.append(contentsOf: allergies.map { "Allergy: \($0)" })
        }
        if !draft.conditions.isEmpty {
            let conditions = draft.conditions.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            allConditions.append(contentsOf: conditions)
        }
        let chronicConditions = allConditions.isEmpty ? nil : allConditions
        
        // Parse medications (format: "name: dosage" or just "name")
        // Backend requires dosage to be non-empty, so we filter out medications without dosage
        let medications: [Medication]? = draft.medications.isEmpty ? nil : draft.medications.components(separatedBy: ",").compactMap { medStr in
            let trimmed = medStr.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return nil }
            let parts = trimmed.components(separatedBy: ":")
            if parts.count >= 2 {
                let name = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let dosage = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                // Only include if both name and dosage are non-empty
                if name.isEmpty || dosage.isEmpty {
                    return nil
                }
                return Medication(name: name, dosage: dosage)
            } else {
                // If no dosage provided, skip this medication (backend requires dosage)
                return nil
            }
        }
        
        // Only include medicalHistory if there's at least one valid medication or other data
        let hasValidMedicalHistory = (medications?.isEmpty == false) || 
                                     (vaccinations?.isEmpty == false) || 
                                     (chronicConditions?.isEmpty == false)
        
        // Convert photo to base64 if available, but limit size to avoid 413 errors
        // Base64 increases size by ~33%, so we limit raw data to ~500KB (base64 will be ~650KB)
        let maxPhotoSize = 500 * 1024 // 500KB
        var finalPhotoData: Data? = draft.photoData
        let photo: String?
        
        if let data = finalPhotoData {
            if data.count > maxPhotoSize {
                // If still too large, try compressing further
                if let uiImage = UIImage(data: data),
                   let compressed = uiImage.jpegData(compressionQuality: 0.5),
                   compressed.count <= maxPhotoSize {
                    finalPhotoData = compressed
                    draft.photoData = compressed
                } else {
                    // Skip photo if still too large to avoid 413 error
                    #if DEBUG
                    print("⚠️ Photo too large (\(data.count) bytes), skipping to avoid 413 error")
                    #endif
                    finalPhotoData = nil
                }
            }
            
            // Encode to base64 if we have valid data
            if let data = finalPhotoData, data.count <= maxPhotoSize {
                photo = data.base64EncodedString()
            } else {
                photo = nil
            }
        } else {
            photo = nil
        }
        
        let request = CreatePetRequest(
            name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
            species: draft.type,
            breed: draft.breed.isEmpty ? nil : draft.breed,
            age: age > 0 ? age : nil, // Don't send age if it's 0 (might cause validation issues)
            gender: draft.gender,
            color: nil, // Not in draft yet
            weight: weight,
            height: height,
            photo: photo,
            microchipId: draft.microchip.isEmpty ? nil : draft.microchip,
            medicalHistory: hasValidMedicalHistory ? MedicalHistoryRequest(
                vaccinations: vaccinations,
                chronicConditions: chronicConditions,
                currentMedications: medications
            ) : nil
        )
        
        let success = await petViewModel.createPet(request)
        
        await MainActor.run {
            isSaving = false
            if success {
                saved = true
            } else {
                saveError = petViewModel.error ?? "Failed to save pet. Please try again."
            }
        }
    }

    private var canPressNext: Bool {
        switch step {
        case .petInfo: return draft.isPetInfoValid
        case .medical: return true          // Medical is optional
        case .review:  return true
        }
    }

    private func goNext() {
        switch step {
        case .petInfo: step = .medical
        case .medical: step = .review
        case .review:  break
        }
    }

    private func goBack() {
        switch step {
        case .petInfo: break
        case .medical: step = .petInfo
        case .review:  step = .medical
        }
    }
}

// MARK: - Step header

private struct StepHeader: View {
    let step: AddPetFlowView.Step

    var body: some View {
        HStack(spacing: 10) {
            StepPill(title: "Pet Info",   isActive: step == .petInfo || step == .medical || step == .review)
            Image(systemName: "chevron.right").foregroundStyle(Color.vetSubtitle)
            StepPill(title: "Medical",    isActive: step == .medical || step == .review)
            Image(systemName: "chevron.right").foregroundStyle(Color.vetSubtitle)
            StepPill(title: "Review",     isActive: step == .review)
            Spacer()
        }
    }
}

private struct StepPill: View {
    let title: String
    let isActive: Bool
    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .bold))
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(isActive ? Color.vetCanyon.opacity(0.18) : Color.vetCardBackground)
            .foregroundStyle(isActive ? Color.vetCanyon : Color.vetTitle)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isActive ? Color.vetCanyon : Color.vetStroke, lineWidth: 1)
            )
    }
}

// MARK: - STEP 1: Pet Info

private struct PetInfoStep: View {
    @Binding var draft: PetDraft

    @State private var pickerItem: PhotosPickerItem?
    @State private var pickedImage: Image?

    @State private var showImageSheet = false
    @State private var useCamera = false

    var body: some View {
        VStack(spacing: 16) {
            // Photo
            VStack(spacing: 10) {
                if let img = pickedImage {
                    img.resizable().scaledToFill()
                        .frame(width: 110, height: 110).clipShape(Circle())
                        .overlay(Circle().stroke(Color.vetStroke, lineWidth: 1))
                } else {
                    Circle()
                        .fill(Color.vetCanyon.opacity(0.18))
                        .frame(width: 110, height: 110)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Color.vetCanyon)
                        )
                }

                HStack(spacing: 14) {
                    // Caméra – iOS 13+
                    Button {
                        useCamera = true
                        showImageSheet = true
                    } label: {
                        Label("Take Photo", systemImage: "camera")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.vetCanyon)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.vetCardBackground)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.vetCanyon, lineWidth: 1))

                    // Import photo – iOS 16+: PhotosPicker, sinon fallback UIKit
                    if #available(iOS 16.0, *) {
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            Label("Import Photo", systemImage: "photo.on.rectangle")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.vetCanyon)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.vetCardBackground)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.vetCanyon, lineWidth: 1))
                        }
                        .onChange(of: pickerItem) { new in
                            guard let new else { return }
                            Task.detached(priority: .userInitiated) {
                                // Chargement + downsample hors MainActor
                                // Reduce size more aggressively to avoid 413 errors
                                if let data = try? await new.loadTransferable(type: Data.self),
                                   let down = downsampleJPEGData(data, maxPixel: 400, quality: 0.7) {
                                    await MainActor.run {
                                        draft.photoData = down
                                        if let ui = UIImage(data: down) {
                                            pickedImage = Image(uiImage: ui)
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        Button {
                            useCamera = false
                            showImageSheet = true
                        } label: {
                            Label("Import Photo", systemImage: "photo.on.rectangle")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.vetCanyon)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.vetCardBackground)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.vetCanyon, lineWidth: 1))
                    }
                }
            }

            PetSectionBox(title: "Pet Information") {
                PetField(icon: "pawprint.fill", placeholder: "Name", text: $draft.name)
                PetPickerField(title: "Type", selection: $draft.type, options: PetDraft.types)
                PetField(icon: "leaf.fill", placeholder: "Breed", text: $draft.breed)
                PetSegment(title: "Gender", selection: $draft.gender, options: ["Male", "Female"])
                PetDateField(title: "Date of Birth", date: $draft.birthDate)
                PetField(icon: "scalemass.fill", placeholder: "Weight (kg)", text: $draft.weight)
                    .keyboardType(.decimalPad)
                PetField(icon: "ruler.fill", placeholder: "Height (cm)", text: $draft.height)
                    .keyboardType(.decimalPad)
                PetField(icon: "barcode.viewfinder", placeholder: "Microchip ID (optional)", text: $draft.microchip)
            }

            HStack {
                Text(draft.isPetInfoValid ? "Looks good ✅" : "Please complete required fields")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(draft.isPetInfoValid ? .green : .red)
                Spacer()
            }
        }
        .sheet(isPresented: $showImageSheet) {
            ImagePicker(source: useCamera ? .camera : .photoLibrary) { uiImage in
                guard let ui = uiImage else { return }
                // Downsample more aggressively to avoid 413 errors (400px max, 0.7 quality)
                let down = ui.downsampledJPEGData(maxPixel: 400, quality: 0.7)
                if let down, let small = UIImage(data: down) {
                    pickedImage = Image(uiImage: small)
                    draft.photoData = down
                } else if let data = ui.jpegData(compressionQuality: 0.7) {
                    // Fallback: compress without downsampling if downsampling fails
                    pickedImage = Image(uiImage: ui)
                    draft.photoData = data
                }
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - STEP 2: Medical Info

private struct MedicalInfoStep: View {
    @Binding var draft: PetDraft
    @State private var expand = true
    @State private var selectedVaccinations: Set<String> = []
    @State private var customVaccination: String = ""
    @State private var selectedAllergies: Set<String> = []
    @State private var customAllergy: String = ""
    @State private var medications: [MedicationEntry] = []
    
    struct MedicationEntry: Identifiable, Equatable {
        let id = UUID()
        var name: String = ""
        var dosage: String = ""
        
        static func == (lhs: MedicationEntry, rhs: MedicationEntry) -> Bool {
            lhs.id == rhs.id && lhs.name == rhs.name && lhs.dosage == rhs.dosage
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            DisclosureGroup(isExpanded: $expand) {
                VStack(spacing: 20) {
                    // Vaccinations Section
                    VaccinationsSection(
                        species: draft.type,
                        selectedVaccinations: $selectedVaccinations,
                        customVaccination: $customVaccination
                    )
                    
                    // Allergies Section
                    AllergiesSection(
                        selectedAllergies: $selectedAllergies,
                        customAllergy: $customAllergy
                    )
                    
                    // Chronic Conditions
                    PetField(icon: "stethoscope", placeholder: "Chronic conditions (comma-separated)", text: $draft.conditions)
                    
                    // Medications Section
                    MedicationsSection(medications: $medications)
                }
                .padding(.top, 6)
            } label: {
                HStack {
                    Text("Medical Info")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.vetTitle)
                    Spacer()
                    Image(systemName: expand ? "chevron.up" : "chevron.down")
                        .foregroundStyle(Color.vetSubtitle)
                }
            }
            .padding()
            .background(Color.vetCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.vetStroke.opacity(0.3)))
            .onChange(of: selectedVaccinations) { _ in updateDraft() }
            .onChange(of: customVaccination) { _ in updateDraft() }
            .onChange(of: selectedAllergies) { _ in updateDraft() }
            .onChange(of: customAllergy) { _ in updateDraft() }
            .onChange(of: medications) { _ in updateDraft() }

            HStack {
                Text("Optional — you can fill this later")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.vetSubtitle)
                Spacer()
            }
        }
    }
    
    private func updateDraft() {
        // Update vaccinations
        var allVaccinations = Array(selectedVaccinations)
        if !customVaccination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            allVaccinations.append(customVaccination.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        draft.vaccinations = allVaccinations.joined(separator: ", ")
        
        // Update allergies
        var allAllergies = Array(selectedAllergies)
        if !customAllergy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            allAllergies.append(customAllergy.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        draft.allergies = allAllergies.joined(separator: ", ")
        
        // Update medications
        let validMeds = medications.filter { !$0.name.isEmpty && !$0.dosage.isEmpty }
        draft.medications = validMeds.map { "\($0.name): \($0.dosage)" }.joined(separator: ", ")
    }
}

// MARK: - Vaccinations Section

private struct VaccinationsSection: View {
    let species: String
    @Binding var selectedVaccinations: Set<String>
    @Binding var customVaccination: String
    
    private var suggestedVaccinations: [String] {
        switch species.lowercased() {
        case "dog":
            return ["Rabies", "DHPP (Distemper, Hepatitis, Parvovirus, Parainfluenza)", "Bordetella", "Leptospirosis", "Lyme Disease", "Canine Influenza"]
        case "cat":
            return ["Rabies", "FVRCP (Feline Viral Rhinotracheitis, Calicivirus, Panleukopenia)", "FeLV (Feline Leukemia)", "FIP (Feline Infectious Peritonitis)"]
        case "bird":
            return ["Polyomavirus", "Pacheco's Disease", "Psittacosis"]
        default:
            return ["Rabies", "Core Vaccinations"]
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "syringe")
                    .foregroundStyle(Color.vetCanyon)
                Text("Vaccinations")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.vetTitle)
                Spacer()
            }
            
            // Suggested vaccinations with checkboxes
            VStack(alignment: .leading, spacing: 10) {
                ForEach(suggestedVaccinations, id: \.self) { vaccine in
                    HStack {
                        Button {
                            if selectedVaccinations.contains(vaccine) {
                                selectedVaccinations.remove(vaccine)
                            } else {
                                selectedVaccinations.insert(vaccine)
                            }
                        } label: {
                            Image(systemName: selectedVaccinations.contains(vaccine) ? "checkmark.square.fill" : "square")
                                .foregroundStyle(selectedVaccinations.contains(vaccine) ? Color.vetCanyon : Color.vetSubtitle)
                                .font(.system(size: 20))
                        }
                        .buttonStyle(.plain)
                        
                        Text(vaccine)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.vetTitle)
                        
                        Spacer()
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.vetInputBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Custom vaccination input
            HStack {
                Text("Or add custom:")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.vetSubtitle)
                Spacer()
            }
            .padding(.top, 4)
            
            PetField(icon: "plus.circle", placeholder: "Add custom vaccination", text: $customVaccination)
        }
    }
}

// MARK: - Allergies Section

private struct AllergiesSection: View {
    @Binding var selectedAllergies: Set<String>
    @Binding var customAllergy: String
    
    private let commonAllergies = ["Chicken", "Beef", "Dairy", "Wheat", "Soy", "Eggs", "Fish", "Corn"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.orange)
                Text("Allergies")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.vetTitle)
                Spacer()
            }
            
            // Suggested allergies with checkboxes
            VStack(alignment: .leading, spacing: 10) {
                // "None" button
                Button {
                    if selectedAllergies.contains("None") {
                        selectedAllergies.removeAll()
                    } else {
                        selectedAllergies.removeAll()
                        selectedAllergies.insert("None")
                    }
                } label: {
                    HStack {
                        Image(systemName: selectedAllergies.contains("None") ? "checkmark.square.fill" : "square")
                            .foregroundStyle(selectedAllergies.contains("None") ? Color.vetCanyon : Color.vetSubtitle)
                            .font(.system(size: 20))
                        
                        Text("None")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.vetTitle)
                        
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                
                Divider()
                    .padding(.vertical, 4)
                
                // Common allergies
                ForEach(commonAllergies, id: \.self) { allergy in
                    HStack {
                        Button {
                            if selectedAllergies.contains("None") {
                                selectedAllergies.remove("None")
                            }
                            if selectedAllergies.contains(allergy) {
                                selectedAllergies.remove(allergy)
                            } else {
                                selectedAllergies.insert(allergy)
                            }
                        } label: {
                            Image(systemName: selectedAllergies.contains(allergy) ? "checkmark.square.fill" : "square")
                                .foregroundStyle(selectedAllergies.contains(allergy) ? Color.vetCanyon : Color.vetSubtitle)
                                .font(.system(size: 20))
                        }
                        .buttonStyle(.plain)
                        .disabled(selectedAllergies.contains("None"))
                        
                        Text(allergy)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(selectedAllergies.contains("None") ? Color.vetSubtitle.opacity(0.5) : Color.vetTitle)
                        
                        Spacer()
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.vetInputBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Custom allergy input
            HStack {
                Text("Or add custom:")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.vetSubtitle)
                Spacer()
            }
            .padding(.top, 4)
            
            PetField(icon: "plus.circle", placeholder: "Add custom allergy", text: $customAllergy)
                .disabled(selectedAllergies.contains("None"))
        }
    }
}

// MARK: - Medications Section

private struct MedicationsSection: View {
    @Binding var medications: [MedicalInfoStep.MedicationEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "pills.fill")
                    .foregroundStyle(Color.vetCanyon)
                Text("Current Medications")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.vetTitle)
                Spacer()
                
                Button {
                    medications.append(MedicalInfoStep.MedicationEntry())
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.vetCanyon)
                }
                .buttonStyle(.plain)
            }
            
            if medications.isEmpty {
                Text("No medications added. Tap + to add one.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.vetSubtitle)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(medications.indices, id: \.self) { index in
                        MedicationEntryRow(
                            medication: $medications[index],
                            onDelete: {
                                medications.remove(at: index)
                            }
                        )
                    }
                }
            }
        }
    }
}

private struct MedicationEntryRow: View {
    @Binding var medication: MedicalInfoStep.MedicationEntry
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Medication \(medication.id.uuidString.prefix(4))")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.vetSubtitle)
                Spacer()
                
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.red)
                }
                .buttonStyle(.plain)
            }
            
            PetField(icon: "pills.fill", placeholder: "Medication name", text: $medication.name)
            PetField(icon: "scalemass.fill", placeholder: "Dosage (e.g., 500mg twice daily)", text: $medication.dosage)
        }
        .padding(12)
        .background(Color.vetInputBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.vetStroke, lineWidth: 1))
    }
}

// MARK: - STEP 3: Review

private struct ReviewStep: View {
    let draft: PetDraft
    var body: some View {
        VStack(spacing: 14) {
            PetSectionBox(title: "Summary") {
                SummaryRow("Name", draft.name)
                SummaryRow("Type", draft.type)
                SummaryRow("Breed", draft.breed)
                SummaryRow("Gender", draft.gender)
                SummaryRow("Date of Birth", draft.birthDate.formatted(date: .abbreviated, time: .omitted))
                SummaryRow("Weight", draft.weight.isEmpty ? "-" : "\(draft.weight) kg")
                SummaryRow("Height", draft.height.isEmpty ? "-" : "\(draft.height) cm")
                SummaryRow("Microchip", draft.microchip.isEmpty ? "-" : draft.microchip)
            }

            PetSectionBox(title: "Medical") {
                SummaryRow("Vaccinations", draft.vaccinations.ifEmpty("-"))
                SummaryRow("Allergies", draft.allergies.ifEmpty("-"))
                SummaryRow("Conditions", draft.conditions.ifEmpty("-"))
                SummaryRow("Medications", draft.medications.ifEmpty("-"))
            }

            Spacer(minLength: 40)
        }
    }

    private func SummaryRow(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).foregroundStyle(Color.vetTitle)
            Spacer()
            Text(v).foregroundStyle(Color.vetSubtitle)
        }
        .font(.system(size: 15))
        .padding(10)
        .background(Color.vetInputBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Draft model

private struct PetDraft {
    var photoData: Data? = nil

    var name: String = ""
    var type: String = "Dog"
    var breed: String = ""
    var gender: String = "Male"
    var birthDate: Date = Date()
    var weight: String = ""
    var height: String = ""
    var microchip: String = ""

    var vaccinations: String = ""
    var allergies: String = ""
    var conditions: String = ""
    var medications: String = ""

    static let types = ["Dog", "Cat", "Bird", "Other"]

    // required: name, type, gender, birthDate, weight, height (numeric-ish)
    var isPetInfoValid: Bool {
        let okName = name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
        let okWeight = Double(weight.replacingOccurrences(of: ",", with: ".")) != nil
        let okHeight = Double(height.replacingOccurrences(of: ",", with: ".")) != nil
        return okName && !type.isEmpty && !gender.isEmpty && okWeight && okHeight
    }
}

// MARK: - Reusable UI (namespaced to avoid collisions)

private struct PetSectionBox<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.vetTitle)
            VStack(spacing: 8) { content }
        }
        .padding()
        .background(Color.vetCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.vetStroke.opacity(0.3)))
    }
}

private struct PetField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(Color.vetSubtitle)
            TextField(placeholder, text: $text)
                .foregroundStyle(Color.vetTitle)
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(Color.vetInputBackground)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.vetStroke, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct PetPickerField: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "list.bullet").foregroundStyle(Color.vetSubtitle)
            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { Text($0) }
            }
            .tint(Color.vetCanyon)
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(Color.vetInputBackground)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.vetStroke, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct PetSegment: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.vetSubtitle)
            HStack(spacing: 10) {
                ForEach(options, id: \.self) { opt in
                    Button {
                        selection = opt
                    } label: {
                        Text(opt)
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(selection == opt ? Color.vetCanyon.opacity(0.18) : Color.vetCardBackground)
                            .foregroundStyle(selection == opt ? Color.vetCanyon : Color.vetTitle)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(selection == opt ? Color.vetCanyon : Color.vetStroke, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.vetInputBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.vetStroke, lineWidth: 1))
    }
}

private struct PetDateField: View {
    let title: String
    @Binding var date: Date
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar").foregroundStyle(Color.vetSubtitle)
            DatePicker(title, selection: $date, displayedComponents: .date)
                .tint(Color.vetCanyon)
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(Color.vetInputBackground)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.vetStroke, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Camera / Library Image Picker (UIKit)

private struct ImagePicker: UIViewControllerRepresentable {
    enum Source { case camera, photoLibrary }
    let source: Source
    let onPick: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = (source == .camera && UIImagePickerController.isSourceTypeAvailable(.camera))
            ? .camera : .photoLibrary
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onPick: (UIImage?) -> Void
        init(onPick: @escaping (UIImage?) -> Void) { self.onPick = onPick }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
            onPick(image)
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onPick(nil)
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Downsampling helpers (perf)

/// Downsample un JPEG/PNG `Data` vers une taille max (pixels) et recompresse en JPEG.
func downsampleJPEGData(_ data: Data, maxPixel: CGFloat, quality: CGFloat) -> Data? {
    guard let src = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
    let opts: [NSString: Any] = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceThumbnailMaxPixelSize: maxPixel,
        kCGImageSourceCreateThumbnailWithTransform: true
    ]
    guard let cgImg = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary) else { return nil }
    let ui = UIImage(cgImage: cgImg)
    return ui.jpegData(compressionQuality: quality)
}

private extension UIImage {
    /// Downsample puis encode JPEG en Data
    func downsampledJPEGData(maxPixel: CGFloat, quality: CGFloat) -> Data? {
        guard let data = self.jpegData(compressionQuality: 1.0) else { return nil }
        return downsampleJPEGData(data, maxPixel: maxPixel, quality: quality)
    }
}

// MARK: - Helpers

private extension String {
    func ifEmpty(_ alt: String) -> String { isEmpty ? alt : self }
}

// MARK: - Preview

#Preview("Add Pet – Light") {
    NavigationStack {
        AddPetFlowView()
            .environmentObject(ThemeStore())
            .preferredColorScheme(.light)
    }
}

#Preview("Add Pet – Dark") {
    NavigationStack {
        AddPetFlowView()
            .environmentObject(ThemeStore())
            .preferredColorScheme(.dark)
    }
}
