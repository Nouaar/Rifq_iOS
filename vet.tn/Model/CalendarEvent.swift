//
//  CalendarEvent.swift
//  vet.tn
//
//  Created for pet calendar integration
//

import Foundation
import EventKit

// MARK: - Calendar Event Types

enum CalendarEventType: String, Codable, CaseIterable {
    case medication = "medication"
    case vaccination = "vaccination"
    case appointment = "appointment"
    case reminder = "reminder"
    
    var icon: String {
        switch self {
        case .medication: return "pills.fill"
        case .vaccination: return "syringe.fill"
        case .appointment: return "calendar.badge.clock"
        case .reminder: return "bell.fill"
        }
    }
    
    var color: String {
        switch self {
        case .medication: return "orange"
        case .vaccination: return "green"
        case .appointment: return "blue"
        case .reminder: return "purple"
        }
    }
    
    var displayName: String {
        switch self {
        case .medication: return "Medication"
        case .vaccination: return "Vaccination"
        case .appointment: return "Appointment"
        case .reminder: return "Reminder"
        }
    }
}

// MARK: - Pet Calendar Event Model

struct PetCalendarEvent: Identifiable, Codable {
    let id: String
    let petId: String
    let type: CalendarEventType
    let title: String
    let notes: String?
    let date: Date
    let endDate: Date?
    let isRecurring: Bool
    let recurrenceRule: RecurrenceRule?
    let eventIdentifier: String? // EKEvent identifier for iOS Calendar
    
    init(
        id: String = UUID().uuidString,
        petId: String,
        type: CalendarEventType,
        title: String,
        notes: String? = nil,
        date: Date,
        endDate: Date? = nil,
        isRecurring: Bool = false,
        recurrenceRule: RecurrenceRule? = nil,
        eventIdentifier: String? = nil
    ) {
        self.id = id
        self.petId = petId
        self.type = type
        self.title = title
        self.notes = notes
        self.date = date
        self.endDate = endDate
        self.isRecurring = isRecurring
        self.recurrenceRule = recurrenceRule
        self.eventIdentifier = eventIdentifier
    }
}

// MARK: - Recurrence Rule

struct RecurrenceRule: Codable {
    let frequency: RecurrenceFrequency
    let interval: Int
    let endDate: Date?
    
    enum RecurrenceFrequency: String, Codable {
        case daily
        case weekly
        case monthly
        case yearly
    }
}

// MARK: - Create Calendar Event Request

struct CreateCalendarEventRequest: Encodable {
    let petId: String
    let type: String
    let title: String
    let notes: String?
    let date: String // ISO8601 format
    let endDate: String? // ISO8601 format
    let isRecurring: Bool
    let recurrenceFrequency: String?
    let recurrenceInterval: Int?
}

