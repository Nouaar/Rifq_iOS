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
import EventKit

struct PetProfileView: View {
    let pet: Pet
    @StateObject private var petViewModel = PetViewModel()
    @EnvironmentObject private var session: SessionManager

    @State private var showEdit = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var deleteError: String?
    @State private var currentPet: Pet
    @Environment(\.dismiss) private var dismiss
    
    init(pet: Pet) {
        self.pet = pet
        _currentPet = State(initialValue: pet)
    }

    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // MARK: - Header
                    TopBar(title: currentPet.name)

                    VStack(spacing: 8) {
                        // Display photo if available, otherwise show emoji
                        if let photoString = currentPet.photo, !photoString.isEmpty {
                            petPhotoView(photoString: photoString)
                                .padding(.top, 8)
                        } else {
                            Text(currentPet.emoji)
                                .font(.system(size: 60))
                                .padding(.top, 8)
                        }

                        Text(currentPet.name)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.vetTitle)

                        Text("\(currentPet.breed ?? "Unknown") • \(currentPet.ageText)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.vetSubtitle)
                    }

                    // MARK: - Stats Section
                    VStack(spacing: 12) {

                        // Navigate to MedicalHistoryView when tapped
                        NavigationLink {
                            MedicalHistoryView(pet: currentPet)
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
                            StatBox(title: "Weight", value: currentPet.weightText)
                            StatBox(title: "Height", value: currentPet.heightText)
                        }
                    }
                    .padding(.horizontal, 16)

                    // MARK: - Basic Info
                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle("Basic Info")

                        InfoRow(label: "Age", value: currentPet.ageText)
                        InfoRow(label: "Breed", value: currentPet.breed ?? "—")
                        InfoRow(label: "Color", value: currentPet.color ?? "—")
                        InfoRow(label: "Microchip ID", value: currentPet.microchipId ?? "—")
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

                        if let meds = currentPet.medicalHistory?.currentMedications, !meds.isEmpty {
                            ForEach(meds, id: \.name) { med in
                            HealthCard(
                                icon: "exclamationmark.triangle.fill",
                                    text: "\(med.name) - \(med.dosage)",
                                color: .orange
                            )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // MARK: - Calendar Section
                    PetCalendarSection(pet: currentPet)
                        .padding(.horizontal, 16)

                    // MARK: - Action Buttons
                    VStack(spacing: 12) {
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
                        
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            Label("DELETE PET", systemImage: "trash")
                                .font(.system(size: 15, weight: .bold))
                                .frame(maxWidth: .infinity, minHeight: 50)
                        }
                        .foregroundStyle(Color.red)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.red, lineWidth: 1.4)
                        )
                        .disabled(isDeleting)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showEdit, onDismiss: {
            // Refresh pet data after editing
            Task {
                await refreshPet()
            }
        }) {
            EditPetView(pet: currentPet)
        }
        .onAppear {
            petViewModel.sessionManager = session
        }
        .alert("Delete Pet", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deletePet()
                }
            }
        } message: {
            Text("Are you sure you want to delete \(currentPet.name)? This action cannot be undone.")
        }
        .alert("Error", isPresented: .constant(deleteError != nil)) {
            Button("OK") { deleteError = nil }
        } message: {
            if let error = deleteError {
                Text(error)
            }
        }
        .overlay {
            if isDeleting {
                ProgressView("Deleting…")
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .preference(key: TabBarHiddenPreferenceKey.self, value: false)
    }

    // MARK: - Subviews
    
    @ViewBuilder
    private func petPhotoView(photoString: String) -> some View {
        // Check if it's a URL
        if photoString.hasPrefix("http://") || photoString.hasPrefix("https://"),
           let photoURL = URL(string: photoString) {
            AsyncImage(url: photoURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 100, height: 100)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.vetStroke, lineWidth: 2))
                case .failure:
                    Text(currentPet.emoji)
                        .font(.system(size: 60))
                @unknown default:
                    Text(currentPet.emoji)
                        .font(.system(size: 60))
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
                .overlay(Circle().stroke(Color.vetStroke, lineWidth: 2))
        } else {
            // Fallback to emoji if base64 decode fails
            Text(currentPet.emoji)
                .font(.system(size: 60))
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
    
    private func refreshPet() async {
        await petViewModel.refreshPet(petId: currentPet.id)
        // Update currentPet from the refreshed list
        if let refreshed = petViewModel.pets.first(where: { $0.id == currentPet.id }) {
            await MainActor.run {
                currentPet = refreshed
            }
        } else {
            // If not in list, fetch directly
            guard let session = petViewModel.sessionManager,
                  let accessToken = session.tokens?.accessToken else {
                return
            }
            do {
                let refreshed = try await PetService.shared.getPet(petId: currentPet.id, accessToken: accessToken)
                await MainActor.run {
                    currentPet = refreshed
                }
            } catch {
                #if DEBUG
                print("⚠️ Failed to refresh pet: \(error)")
                #endif
            }
        }
    }

    private func deletePet() async {
        isDeleting = true
        deleteError = nil
        
        let success = await petViewModel.deletePet(petId: currentPet.id)
        
        await MainActor.run {
            isDeleting = false
            if success {
                dismiss()
            } else {
                deleteError = petViewModel.error ?? "Failed to delete pet. Please try again."
            }
        }
    }

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

// MARK: - Pet Calendar Section

struct PetCalendarSection: View {
    let pet: Pet
    @StateObject private var calendarManager = CalendarManager()
    @State private var showFullCalendar = false
    @State private var showAddEventSheet = false
    @State private var selectedEventType: CalendarEventType = .appointment
    @State private var refreshID = UUID()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CALENDAR")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.vetSubtitle)
                
                Spacer()
                
                Button {
                    showFullCalendar = true
                } label: {
                    Text("View All")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.vetCanyon)
                }
            }
            
            if calendarManager.authorizationStatus == .notDetermined || calendarManager.authorizationStatus == .denied {
                authorizationPrompt
            } else {
                calendarContent
            }
        }
        .id(refreshID)
        .onAppear {
            Task {
                if calendarManager.authorizationStatus != .authorized {
                    _ = await calendarManager.requestAccess()
                }
                await calendarManager.loadEvents(for: pet.id)
            }
        }
        .sheet(isPresented: $showFullCalendar) {
            NavigationStack {
                CalendarView(tabSelection: .constant(.myPets), useSystemNavBar: true, pet: pet)
            }
        }
        .sheet(isPresented: $showAddEventSheet) {
            AddCalendarEventView(
                pet: pet,
                eventType: selectedEventType,
                calendarManager: calendarManager
            )
            .onDisappear {
                // Reload events when sheet is dismissed
                Task {
                    await calendarManager.loadEvents(for: pet.id)
                }
            }
        }
    }
    
    private var authorizationPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 30))
                .foregroundColor(.vetSubtitle)
            
            Text("Enable calendar access to track appointments, medications, and vaccinations")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.vetSubtitle)
                .multilineTextAlignment(.center)
            
            Button {
                Task { @MainActor in
                    print("🔵 Requesting calendar access...")
                    let granted = await calendarManager.requestAccess()
                    print("🔵 Access granted: \(granted)")
                    
                    // Force a refresh of the authorization status
                    calendarManager.checkAuthorizationStatus()
                    print("🔵 Authorization status: \(calendarManager.authorizationStatus.rawValue)")
                    
                    // Force view refresh
                    refreshID = UUID()
                    
                    if granted && calendarManager.authorizationStatus == .authorized {
                        print("🔵 Loading events...")
                        await calendarManager.loadEvents(for: pet.id)
                    }
                }
            } label: {
                Text("Enable Calendar")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.vetCanyon)
                    .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.vetCardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.vetStroke.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var calendarContent: some View {
        VStack(spacing: 12) {
            // Quick Add Buttons
            HStack(spacing: 8) {
                QuickAddButton(type: .medication, icon: "pills.fill", color: .orange) {
                    selectedEventType = .medication
                    showAddEventSheet = true
                }
                
                QuickAddButton(type: .vaccination, icon: "syringe.fill", color: .green) {
                    selectedEventType = .vaccination
                    showAddEventSheet = true
                }
                
                QuickAddButton(type: .appointment, icon: "calendar.badge.clock", color: .blue) {
                    selectedEventType = .appointment
                    showAddEventSheet = true
                }
                
                QuickAddButton(type: .reminder, icon: "bell.fill", color: .purple) {
                    selectedEventType = .reminder
                    showAddEventSheet = true
                }
            }
            
            // Upcoming Events
            if calendarManager.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                let upcomingEvents = calendarManager.events
                    .filter { $0.date >= Date() }
                    .sorted { $0.date < $1.date }
                    .prefix(3)
                
                if upcomingEvents.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 24))
                            .foregroundColor(.vetSubtitle)
                        Text("No upcoming events")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.vetSubtitle)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                } else {
                    VStack(spacing: 8) {
                        ForEach(Array(upcomingEvents)) { event in
                            CompactEventRow(event: event)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.vetCardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.vetStroke.opacity(0.3), lineWidth: 1)
        )
    }
}

struct QuickAddButton: View {
    let type: CalendarEventType
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                Text(type.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.vetTitle)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(color.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct CompactEventRow: View {
    let event: PetCalendarEvent
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: event.type.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(eventColor)
                .frame(width: 28, height: 28)
                .background(eventColor.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.vetTitle)
                    .lineLimit(1)
                
                Text(dateFormatter.string(from: event.date))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.vetSubtitle)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var eventColor: Color {
        switch event.type {
        case .medication: return .orange
        case .vaccination: return .green
        case .appointment: return .blue
        case .reminder: return .purple
        }
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

// EditPetView is now in its own file: EditPetView.swift

// MARK: - Preview

#Preview("Pet Profile") {
    NavigationStack {
        PetProfileView(
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
                medicalHistory: MedicalHistory(
                    id: nil,
                    vaccinations: ["Rabies", "DHPP"],
                    chronicConditions: nil,
                    currentMedications: [Medication(name: "Heartworm Prevention", dosage: "Monthly")]
                )
            )
        )
        .environmentObject(ThemeStore())
    }
}


#Preview("Pet Profile – Dark") {
    NavigationStack {
        PetProfileView(
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
        .environmentObject(ThemeStore())
        .preferredColorScheme(.dark)
    }
}
