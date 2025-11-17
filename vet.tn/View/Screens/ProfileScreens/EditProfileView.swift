//
//  EditProfileView.swift
//  vet.tn
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var country: String = ""
    @State private var city: String = ""
    @State private var hasPhoto: Bool = false
    @State private var hasPets: Bool = false
    @State private var hasLoaded = false

    @State private var pickerItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    // New: simple saving state and error banner
    @State private var isSaving = false
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let err = saveError {
                        Text(err)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal, 20)
                    }

                    profileSection
                    contactSection
                    petsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
            }
            .disabled(isSaving)
            .overlay {
                if isSaving {
                    ProgressView("Saving…")
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .background(Color.vetBackground.ignoresSafeArea())
            .navigationTitle("Complete Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        session.shouldPresentEditProfile = false
                        dismiss()
                    }
                    .foregroundColor(.vetSubtitle)
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.vetCanyon)
                    .disabled(!canSave || isSaving)
                }
            }
            .onAppear {
                if !hasLoaded {
                    seedInitialValues()
                    hasLoaded = true
                }
            }
            .onChange(of: pickerItem) { _ in
                Task { await loadSelectedImage() }
            }
        }
    }

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Profile Details")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.vetTitle)

            VStack(spacing: 12) {
                avatarPicker

                TextField("Full name", text: $name)
                    .textContentType(.name)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color.vetInputBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.vetStroke, lineWidth: 1)
                    )
            }
            .padding(16)
            .background(Color.vetCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.vetStroke.opacity(0.4), lineWidth: 1)
            )
        }
    }

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Contact Information")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.vetTitle)

            VStack(spacing: 12) {
                TextField("Phone number", text: $phone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color.vetInputBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.vetStroke, lineWidth: 1)
                    )

                TextField("Country", text: $country)
                    .textContentType(.countryName)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color.vetInputBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.vetStroke, lineWidth: 1)
                    )

                TextField("City", text: $city)
                    .textContentType(.addressCity)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color.vetInputBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.vetStroke, lineWidth: 1)
                    )
            }
            .padding(16)
            .background(Color.vetCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.vetStroke.opacity(0.4), lineWidth: 1)
            )
        }
    }

    private var petsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Pet Information")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.vetTitle)

            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $hasPets) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("I’ve added my pets")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.vetTitle)
                        Text("Let us know if you already listed your pets in the app.")
                            .font(.system(size: 12))
                            .foregroundColor(.vetSubtitle)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .vetCanyon))
                .padding(.horizontal, 4)
            }
            .padding(16)
            .background(Color.vetCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.vetStroke.opacity(0.4), lineWidth: 1)
            )
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func seedInitialValues() {
        name = session.user?.name ?? ""
        phone = session.user?.phone ?? ""
        country = session.user?.country ?? ""
        city = session.user?.city ?? ""
        let backendHasPhoto = session.user?.hasPhoto ?? !(session.user?.avatarUrl?.isEmpty ?? true)
        hasPhoto = backendHasPhoto
        hasPets = session.user?.hasPets ?? !(session.user?.pets?.isEmpty ?? true)
    }

    private func save() {
        saveError = nil
        isSaving = true
        Task {
            let ok = await session.updateProfile(
                name: name,
                phone: phone,
                country: country,
                city: city,
                hasPhoto: hasPhoto || selectedImage != nil,
                hasPets: hasPets,
                image: selectedImage
            )
            await MainActor.run {
                isSaving = false
                if ok {
                    session.shouldPresentEditProfile = false
                    dismiss()
                } else {
                    // Show an error if server update failed (local fallback may have updated UI)
                    saveError = "Could not save to server. Please check your connection and try again."
                }
            }
        }
    }

    private var avatarPicker: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.vetCardBackground)
                    .frame(width: 96, height: 96)
                    .overlay(
                        Circle()
                            .stroke(Color.vetStroke, lineWidth: 1)
                    )

                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 92, height: 92)
                        .clipShape(Circle())
                } else if let urlString = session.user?.avatarUrl,
                          let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 92, height: 92)
                                .clipShape(Circle())
                        case .failure:
                            Image(systemName: "person.fill")
                                .font(.system(size: 36, weight: .medium))
                                .foregroundColor(.vetCanyon)
                        @unknown default:
                            Image(systemName: "person.fill")
                                .font(.system(size: 36, weight: .medium))
                                .foregroundColor(.vetCanyon)
                        }
                    }
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.vetCanyon)
                }
            }

            HStack(spacing: 12) {
                PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                    Label("Import Photo", systemImage: "photo.on.rectangle.angled")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.vetCardBackground)
                        .foregroundColor(.vetCanyon)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.vetCanyon, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                if selectedImage != nil || (session.user?.avatarUrl?.isEmpty == false) {
                    Button {
                        selectedImage = nil
                        hasPhoto = false
                    } label: {
                        Label("Remove", systemImage: "trash")
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.12))
                            .foregroundColor(.red)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func loadSelectedImage() async {
        guard let item = pickerItem else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    self.selectedImage = image
                    self.hasPhoto = true
                }
            }
        } catch {
            #if DEBUG
            print("Failed to load selected image: \(error)")
            #endif
        }

        await MainActor.run {
            pickerItem = nil
        }
    }
}

#Preview("EditProfileView") {
    EditProfileView()
        .environmentObject(SessionManager())
}

