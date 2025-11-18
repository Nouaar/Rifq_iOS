//
//  AddCalendarEventView.swift
//  vet.tn
//
//  Form to add calendar events for pets
//

import SwiftUI

struct AddCalendarEventView: View {
    let pet: Pet
    let eventType: CalendarEventType
    @ObservedObject var calendarManager: CalendarManager
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var date: Date = Date()
    @State private var endDate: Date?
    @State private var isRecurring: Bool = false
    @State private var recurrenceFrequency: RecurrenceRule.RecurrenceFrequency = .daily
    @State private var recurrenceInterval: Int = 1
    @State private var hasEndDate: Bool = false
    
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.vetBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Event Type Header
                        HStack {
                            Image(systemName: eventType.icon)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(eventColor)
                            
                            Text("New \(eventType.displayName)")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.vetTitle)
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.vetCardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Form Fields
                        VStack(spacing: 16) {
                            // Title
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Title")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.vetTitle)
                                
                                TextField("Enter event title", text: $title)
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(Color.vetInputBackground)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.vetStroke.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            
                            // Date & Time
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Date & Time")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.vetTitle)
                                
                                DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.compact)
                                    .padding()
                                    .background(Color.vetInputBackground)
                                    .cornerRadius(12)
                            }
                            
                            // End Date (optional)
                            Toggle("Set End Date", isOn: $hasEndDate)
                                .toggleStyle(SwitchToggleStyle(tint: .vetCanyon))
                                .padding()
                                .background(Color.vetInputBackground)
                                .cornerRadius(12)
                            
                            if hasEndDate {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("End Date & Time")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.vetTitle)
                                    
                                    DatePicker("", selection: Binding(
                                        get: { endDate ?? date.addingTimeInterval(3600) },
                                        set: { endDate = $0 }
                                    ), displayedComponents: [.date, .hourAndMinute])
                                        .datePickerStyle(.compact)
                                        .padding()
                                        .background(Color.vetInputBackground)
                                        .cornerRadius(12)
                                }
                            }
                            
                            // Notes
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes (Optional)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.vetTitle)
                                
                                TextField("Add any additional notes", text: $notes, axis: .vertical)
                                    .textFieldStyle(.plain)
                                    .lineLimit(3...6)
                                    .padding()
                                    .background(Color.vetInputBackground)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.vetStroke.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            
                            // Recurring Toggle
                            Toggle("Recurring Event", isOn: $isRecurring)
                                .toggleStyle(SwitchToggleStyle(tint: .vetCanyon))
                                .padding()
                                .background(Color.vetInputBackground)
                                .cornerRadius(12)
                            
                            if isRecurring {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Recurrence")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.vetTitle)
                                    
                                    Picker("Frequency", selection: $recurrenceFrequency) {
                                        Text("Daily").tag(RecurrenceRule.RecurrenceFrequency.daily)
                                        Text("Weekly").tag(RecurrenceRule.RecurrenceFrequency.weekly)
                                        Text("Monthly").tag(RecurrenceRule.RecurrenceFrequency.monthly)
                                        Text("Yearly").tag(RecurrenceRule.RecurrenceFrequency.yearly)
                                    }
                                    .pickerStyle(.segmented)
                                    
                                    HStack {
                                        Text("Repeat every")
                                        Spacer()
                                        Stepper("\(recurrenceInterval)", value: $recurrenceInterval, in: 1...30)
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.vetTitle)
                                }
                                .padding()
                                .background(Color.vetInputBackground)
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                        .background(Color.vetCardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Save Button
                        Button {
                            Task {
                                await saveEvent()
                            }
                        } label: {
                            Text("Add to Calendar")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isValid ? Color.vetCanyon : Color.gray)
                                .cornerRadius(12)
                        }
                        .disabled(!isValid || isSaving)
                        .padding(.horizontal)
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.vetCanyon)
                }
            }
            .overlay {
                if isSaving {
                    ProgressView("Saving...")
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        .onAppear {
            setupDefaultTitle()
        }
    }
    
    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var eventColor: Color {
        switch eventType {
        case .medication: return .orange
        case .vaccination: return .green
        case .appointment: return .blue
        case .reminder: return .purple
        }
    }
    
    private func setupDefaultTitle() {
        if title.isEmpty {
            switch eventType {
            case .medication:
                if let med = pet.medicalHistory?.currentMedications?.first {
                    title = "\(med.name) - \(pet.name)"
                } else {
                    title = "Medication - \(pet.name)"
                }
            case .vaccination:
                if let vaccine = pet.medicalHistory?.vaccinations?.first {
                    title = "\(vaccine) - \(pet.name)"
                } else {
                    title = "Vaccination - \(pet.name)"
                }
            case .appointment:
                title = "Vet Appointment - \(pet.name)"
            case .reminder:
                title = "Reminder - \(pet.name)"
            }
        }
    }
    
    private func saveEvent() async {
        isSaving = true
        errorMessage = nil
        
        let recurrenceRule: RecurrenceRule? = isRecurring ? RecurrenceRule(
            frequency: recurrenceFrequency,
            interval: recurrenceInterval,
            endDate: nil
        ) : nil
        
        let event = PetCalendarEvent(
            petId: pet.id,
            type: eventType,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.isEmpty ? nil : notes,
            date: date,
            endDate: hasEndDate ? (endDate ?? date.addingTimeInterval(3600)) : nil,
            isRecurring: isRecurring,
            recurrenceRule: recurrenceRule
        )
        
        do {
            _ = try await calendarManager.createEvent(event)
            // Events are reloaded automatically in createEvent
            await MainActor.run {
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isSaving = false
            }
        }
    }
}

#Preview {
    AddCalendarEventView(
        pet: Pet(
            id: "1",
            name: "Max",
            species: "dog",
            breed: "Doberman",
            age: 3.0,
            gender: "Male",
            color: nil,
            weight: nil,
            height: nil,
            photo: nil,
            microchipId: nil,
            owner: nil,
            medicalHistory: nil
        ),
        eventType: .medication,
        calendarManager: CalendarManager()
    )
}

