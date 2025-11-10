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

    @State private var step: Step = .petInfo
    @Namespace private var ns

    @State private var draft = PetDraft() // holds form state
    @State private var saved = false

    enum Step: Int, CaseIterable { case petInfo, medical, review }

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
                            // TODO: integrate with backend here
                            saved = true
                        } label: {
                            Text("Save Pet Profile")
                                .font(.system(size: 15, weight: .bold))
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .foregroundStyle(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.vetCanyon)
                                )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
        .alert("🐾 Pet added successfully!", isPresented: $saved) {
            Button("OK", role: .cancel) { }
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
                                if let data = try? await new.loadTransferable(type: Data.self),
                                   let down = downsampleJPEGData(data, maxPixel: 800, quality: 0.85) {
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
                // Downsample côté UIKit aussi
                let target = CGSize(width: 800, height: 800)
                let down = ui.downsampledJPEGData(maxPixel: max(target.width, target.height), quality: 0.85)
                if let down, let small = UIImage(data: down) {
                    pickedImage = Image(uiImage: small)
                    draft.photoData = down
                } else if let data = ui.jpegData(compressionQuality: 0.85) {
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

    var body: some View {
        VStack(spacing: 16) {
            DisclosureGroup(isExpanded: $expand) {
                VStack(spacing: 10) {
                    PetField(icon: "syringe", placeholder: "Vaccinations (e.g. Rabies 10/2024)", text: $draft.vaccinations)
                    PetField(icon: "exclamationmark.triangle.fill", placeholder: "Allergies (• chicken, • dairy…)", text: $draft.allergies)
                    PetField(icon: "stethoscope", placeholder: "Chronic conditions", text: $draft.conditions)
                    PetField(icon: "pills.fill", placeholder: "Current medication + dosage", text: $draft.medications)
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

            HStack {
                Text("Optional — you can fill this later")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.vetSubtitle)
                Spacer()
            }
        }
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
