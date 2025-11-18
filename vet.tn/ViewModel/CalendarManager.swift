//
//  CalendarManager.swift
//  vet.tn
//
//  Manages iOS Calendar (EventKit) integration for pet events
//

import Foundation
import EventKit
import SwiftUI
import Combine

@MainActor
final class CalendarManager: ObservableObject {
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var events: [PetCalendarEvent] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private let eventStore = EKEventStore()
    private let calendarName = "Pet Care"
    private var petCalendar: EKCalendar?
    
    init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func checkAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }
    
    func requestAccess() async -> Bool {
        do {
            print("🟢 Requesting calendar access from EventKit...")
            let granted = try await eventStore.requestAccess(to: .event)
            print("🟢 EventKit returned: \(granted)")
            
            // Update status immediately - we're already on MainActor
            let newStatus = EKEventStore.authorizationStatus(for: .event)
            print("🟢 Current authorization status: \(newStatus.rawValue)")
            authorizationStatus = newStatus
            
            // Force objectWillChange to notify observers
            objectWillChange.send()
            
            return granted
        } catch {
            print("🔴 Error requesting access: \(error)")
            authorizationStatus = .denied
            objectWillChange.send()
            return false
        }
    }
    
    // MARK: - Calendar Setup
    
    private func getOrCreatePetCalendar() -> EKCalendar? {
        // Check if calendar already exists
        if let existingCalendar = eventStore.calendars(for: .event).first(where: { $0.title == calendarName }) {
            petCalendar = existingCalendar
            return existingCalendar
        }
        
        // Create new calendar
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        
        newCalendar.title = calendarName
        newCalendar.cgColor = UIColor.systemOrange.cgColor
        
        // Find the default calendar source
        if let source = eventStore.defaultCalendarForNewEvents?.source {
            newCalendar.source = source
        } else if let localSource = eventStore.sources.first(where: { $0.sourceType == .local }) {
            newCalendar.source = localSource
        } else {
            return nil
        }
        
        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
            petCalendar = newCalendar
            return newCalendar
        } catch {
            print("❌ Failed to create calendar: \(error)")
            return nil
        }
    }
    
    // MARK: - Load Events
    
    func loadAllPetsEvents(petIds: [String], startDate: Date = Date(), endDate: Date? = nil) async {
        guard authorizationStatus == .authorized else {
            await MainActor.run {
                error = "Calendar access not authorized"
                isLoading = false
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        guard let calendar = getOrCreatePetCalendar() else {
            await MainActor.run {
                error = "Could not access calendar"
                isLoading = false
            }
            return
        }
        
        let end = endDate ?? Calendar.current.date(byAdding: .year, value: 1, to: startDate) ?? Date()
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: end, calendars: [calendar])
        
        let ekEvents = eventStore.events(matching: predicate)
        
        print("📅 Found \(ekEvents.count) total events in calendar")
        
        // Filter events for any of the pets and convert to PetCalendarEvent
        var allPetEvents: [PetCalendarEvent] = []
        
        for ekEvent in ekEvents {
            guard let petIdFromNotes = extractPetId(from: ekEvent.notes ?? ""),
                  petIds.contains(petIdFromNotes) else {
                continue
            }
            
            if let converted = convertEKEventToPetEvent(ekEvent, petId: petIdFromNotes) {
                allPetEvents.append(converted)
            }
        }
        
        print("📅 Converted \(allPetEvents.count) events for \(petIds.count) pets")
        
        await MainActor.run {
            self.events = allPetEvents.sorted { $0.date < $1.date }
            self.isLoading = false
        }
    }
    
    func loadEvents(for petId: String, startDate: Date = Date(), endDate: Date? = nil) async {
        guard authorizationStatus == .authorized else {
            await MainActor.run {
                error = "Calendar access not authorized"
                isLoading = false
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        guard let calendar = getOrCreatePetCalendar() else {
            await MainActor.run {
                error = "Could not access calendar"
                isLoading = false
            }
            return
        }
        
        let end = endDate ?? Calendar.current.date(byAdding: .year, value: 1, to: startDate) ?? Date()
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: end, calendars: [calendar])
        
        let ekEvents = eventStore.events(matching: predicate)
        
        print("📅 Found \(ekEvents.count) events in calendar")
        
        // Filter events for this pet and convert to PetCalendarEvent
        let petEvents = ekEvents.compactMap { ekEvent -> PetCalendarEvent? in
            // Debug: print event details
            print("📅 Event: \(ekEvent.title ?? "No title") - Notes: \(ekEvent.notes ?? "No notes")")
            
            let petIdFromNotes = extractPetId(from: ekEvent.notes ?? "")
            guard let petIdFromNotes = petIdFromNotes,
                  petIdFromNotes == petId else {
                print("⚠️ Event filtered out - Pet ID mismatch or missing. Expected: \(petId), Found: \(petIdFromNotes ?? "nil")")
                return nil
            }
            
            let converted = convertEKEventToPetEvent(ekEvent, petId: petId)
            if let event = converted {
                print("✅ Converted event: \(event.title) - Type: \(event.type.rawValue)")
            } else {
                print("❌ Failed to convert event: \(ekEvent.title ?? "Unknown")")
            }
            return converted
        }
        
        print("📅 Converted \(petEvents.count) events for pet \(petId)")
        
        await MainActor.run {
            self.events = petEvents.sorted { $0.date < $1.date }
            self.isLoading = false
        }
    }
    
    // MARK: - Create Event
    
    func createEvent(_ event: PetCalendarEvent) async throws -> String {
        guard authorizationStatus == .authorized else {
            throw CalendarError.notAuthorized
        }
        
        guard let calendar = getOrCreatePetCalendar() else {
            throw CalendarError.calendarNotFound
        }
        
        let ekEvent = EKEvent(eventStore: eventStore)
        ekEvent.calendar = calendar
        ekEvent.title = event.title
        ekEvent.notes = createEventNotes(for: event)
        ekEvent.startDate = event.date
        ekEvent.endDate = event.endDate ?? event.date.addingTimeInterval(3600) // Default 1 hour
        
        // Set recurrence if needed
        if event.isRecurring, let recurrenceRule = event.recurrenceRule {
            ekEvent.recurrenceRules = [createEKRecurrenceRule(from: recurrenceRule)]
        } else {
            ekEvent.recurrenceRules = nil
        }
        
        // Add alarm (15 minutes before)
        ekEvent.addAlarm(EKAlarm(relativeOffset: -15 * 60))
        
        print("💾 Creating event: \(event.title) for pet \(event.petId)")
        print("💾 Event date: \(event.date)")
        
        do {
            try eventStore.save(ekEvent, span: .thisEvent, commit: true)
            print("✅ Event saved successfully with identifier: \(ekEvent.eventIdentifier ?? "nil")")
            
            // Wait a moment for EventKit to fully persist
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // Reload events after creating
            await loadEvents(for: event.petId)
            
            guard let identifier = ekEvent.eventIdentifier else {
                throw CalendarError.saveFailed("Event saved but no identifier returned")
            }
            
            return identifier
        } catch {
            print("❌ Failed to save event: \(error.localizedDescription)")
            throw CalendarError.saveFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Update Event
    
    func updateEvent(_ event: PetCalendarEvent) async throws {
        guard authorizationStatus == .authorized else {
            throw CalendarError.notAuthorized
        }
        
        guard let eventIdentifier = event.eventIdentifier,
              let ekEvent = eventStore.event(withIdentifier: eventIdentifier) else {
            throw CalendarError.eventNotFound
        }
        
        ekEvent.title = event.title
        ekEvent.notes = createEventNotes(for: event)
        ekEvent.startDate = event.date
        ekEvent.endDate = event.endDate ?? event.date.addingTimeInterval(3600)
        
        if event.isRecurring, let recurrenceRule = event.recurrenceRule {
            ekEvent.recurrenceRules = [createEKRecurrenceRule(from: recurrenceRule)]
        } else {
            ekEvent.recurrenceRules = nil
        }
        
        do {
            try eventStore.save(ekEvent, span: .thisEvent, commit: true)
            // Reload events after updating
            await loadEvents(for: event.petId)
        } catch {
            throw CalendarError.saveFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Delete Event
    
    func deleteEvent(_ event: PetCalendarEvent) async throws {
        guard authorizationStatus == .authorized else {
            throw CalendarError.notAuthorized
        }
        
        print("🗑️ Attempting to delete event: \(event.title)")
        print("🗑️ Event identifier: \(event.eventIdentifier ?? "nil")")
        
        guard let eventIdentifier = event.eventIdentifier else {
            print("❌ No event identifier found")
            throw CalendarError.eventNotFound
        }
        
        guard let ekEvent = eventStore.event(withIdentifier: eventIdentifier) else {
            print("❌ Event not found in EventStore with identifier: \(eventIdentifier)")
            // Try to find event by searching all calendars
            if let calendar = getOrCreatePetCalendar() {
                let predicate = eventStore.predicateForEvents(
                    withStart: event.date.addingTimeInterval(-86400), // 1 day before
                    end: event.date.addingTimeInterval(86400), // 1 day after
                    calendars: [calendar]
                )
                let events = eventStore.events(matching: predicate)
                let calendarHelper = Calendar.current
                if let foundEvent = events.first(where: { ekEvent in
                    ekEvent.title == event.title &&
                    calendarHelper.isDate(ekEvent.startDate, inSameDayAs: event.date)
                }) {
                    print("✅ Found event by searching: \(foundEvent.eventIdentifier ?? "no id")")
                    do {
                        try eventStore.remove(foundEvent, span: .thisEvent, commit: true)
                        return
                    } catch {
                        throw CalendarError.deleteFailed(error.localizedDescription)
                    }
                }
            }
            throw CalendarError.eventNotFound
        }
        
        print("✅ Found event to delete: \(ekEvent.title ?? "No title")")
        print("✅ Event calendar: \(ekEvent.calendar?.title ?? "nil")")
        print("✅ Event start date: \(ekEvent.startDate)")
        
        do {
            // Use .futureEvents for recurring events, .thisEvent for single events
            let span: EKSpan = ekEvent.isDetached ? .futureEvents : .thisEvent
            try eventStore.remove(ekEvent, span: span, commit: true)
            print("✅ Event deleted successfully")
            
            // Wait a moment for EventKit to fully process the deletion
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // Reload events after deletion
            await loadEvents(for: event.petId)
        } catch {
            print("❌ Failed to delete event: \(error.localizedDescription)")
            throw CalendarError.deleteFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createEventNotes(for event: PetCalendarEvent) -> String {
        var notes = "Pet ID: \(event.petId)\n"
        notes += "Type: \(event.type.rawValue)\n"
        if let eventNotes = event.notes {
            notes += "\n\(eventNotes)"
        }
        return notes
    }
    
    private func extractPetId(from notes: String) -> String? {
        let lines = notes.components(separatedBy: "\n")
        for line in lines {
            if line.hasPrefix("Pet ID: ") {
                return String(line.dropFirst(8))
            }
        }
        return nil
    }
    
    private func convertEKEventToPetEvent(_ ekEvent: EKEvent, petId: String) -> PetCalendarEvent? {
        guard let petIdFromNotes = extractPetId(from: ekEvent.notes ?? ""),
              petIdFromNotes == petId else {
            return nil
        }
        
        // Extract type from notes - look for "Type: " line
        let notesLines = ekEvent.notes?.components(separatedBy: "\n") ?? []
        var typeString: String = "reminder" // default
        
        for line in notesLines {
            if line.hasPrefix("Type: ") {
                typeString = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                break
            }
        }
        
        print("🔍 Extracted type string: '\(typeString)' from notes: \(ekEvent.notes ?? "nil")")
        
        guard let type = CalendarEventType(rawValue: typeString) else {
            print("⚠️ Unknown event type: '\(typeString)', defaulting to reminder")
            // Try to infer type from title if type parsing fails
            let title = ekEvent.title.lowercased()
            let inferredType: CalendarEventType
            if title.contains("vaccination") || title.contains("vaccine") {
                inferredType = .vaccination
            } else if title.contains("medication") || title.contains("med") || title.contains("pill") {
                inferredType = .medication
            } else if title.contains("appointment") || title.contains("vet") {
                inferredType = .appointment
            } else {
                inferredType = .reminder
            }
            print("🔍 Inferred type: \(inferredType.rawValue)")
            return createPetEvent(from: ekEvent, petId: petId, type: inferredType, notesLines: notesLines)
        }
        
        return createPetEvent(from: ekEvent, petId: petId, type: type, notesLines: notesLines)
    }
    
    private func createPetEvent(from ekEvent: EKEvent, petId: String, type: CalendarEventType, notesLines: [String]) -> PetCalendarEvent {
        // Extract notes (everything after "Pet ID:" and "Type:" lines)
        let notes = notesLines.count > 2 ? notesLines.dropFirst(2).joined(separator: "\n").trimmingCharacters(in: .whitespaces) : nil
        let finalNotes = notes?.isEmpty == false ? notes : nil
        
        let recurrenceRule: RecurrenceRule? = ekEvent.recurrenceRules?.first.map { rule in
            let frequency: RecurrenceRule.RecurrenceFrequency
            switch rule.frequency {
            case .daily: frequency = .daily
            case .weekly: frequency = .weekly
            case .monthly: frequency = .monthly
            case .yearly: frequency = .yearly
            @unknown default: frequency = .daily
            }
            return RecurrenceRule(
                frequency: frequency,
                interval: rule.interval,
                endDate: rule.recurrenceEnd?.endDate
            )
        }
        
        // Use the event identifier if available, otherwise generate a new ID
        let eventId = ekEvent.eventIdentifier ?? UUID().uuidString
        
        print("🔄 Converting event: \(ekEvent.title ?? "No title")")
        print("🔄 Event identifier: \(eventId)")
        print("🔄 Event type: \(type.rawValue)")
        
        return PetCalendarEvent(
            id: UUID().uuidString, // Internal ID for SwiftUI
            petId: petId,
            type: type,
            title: ekEvent.title,
            notes: finalNotes,
            date: ekEvent.startDate,
            endDate: ekEvent.endDate,
            isRecurring: recurrenceRule != nil,
            recurrenceRule: recurrenceRule,
            eventIdentifier: eventId // EventKit identifier - critical for deletion
        )
    }
    
    private func createEKRecurrenceRule(from rule: RecurrenceRule) -> EKRecurrenceRule {
        let frequency: EKRecurrenceFrequency
        switch rule.frequency {
        case .daily: frequency = .daily
        case .weekly: frequency = .weekly
        case .monthly: frequency = .monthly
        case .yearly: frequency = .yearly
        }
        
        let end: EKRecurrenceEnd? = rule.endDate.map { EKRecurrenceEnd(end: $0) }
        
        return EKRecurrenceRule(
            recurrenceWith: frequency,
            interval: rule.interval,
            end: end
        )
    }
}

// MARK: - Calendar Errors

enum CalendarError: LocalizedError {
    case notAuthorized
    case calendarNotFound
    case eventNotFound
    case saveFailed(String)
    case deleteFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Calendar access is not authorized. Please enable it in Settings."
        case .calendarNotFound:
            return "Could not create or find the Pet Care calendar."
        case .eventNotFound:
            return "Event not found in calendar."
        case .saveFailed(let message):
            return "Failed to save event: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete event: \(message)"
        }
    }
}

