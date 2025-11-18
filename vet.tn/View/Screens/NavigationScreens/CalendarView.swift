import SwiftUI
import EventKit

struct CalendarView: View {
    @Binding var tabSelection: VetTab
    let useSystemNavBar: Bool
    let pet: Pet?
    @EnvironmentObject private var theme: ThemeStore
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var calendarManager = CalendarManager()
    @State private var selectedDate = Date()
    @State private var showAddEventSheet = false
    @State private var selectedEventType: CalendarEventType = .appointment
    @State private var showEventDetail = false
    @State private var selectedEvent: PetCalendarEvent?
    
    init(tabSelection: Binding<VetTab>, useSystemNavBar: Bool, pet: Pet? = nil) {
        self._tabSelection = tabSelection
        self.useSystemNavBar = useSystemNavBar
        self.pet = pet
    }
    
    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                if !useSystemNavBar {
                    TopBar(
                        title: pet != nil ? "\(pet!.name)'s Calendar" : "Calendar",
                        showBack: true,
                        onBack: { dismiss() }
                    )
                }
                
                if calendarManager.authorizationStatus == .notDetermined || calendarManager.authorizationStatus == .denied {
                    authorizationView
                } else {
                    calendarContentView
                }
            }
        }
        .navigationTitle(useSystemNavBar ? (pet != nil ? "\(pet!.name)'s Calendar" : "Calendar") : "")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if useSystemNavBar && pet != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            selectedEventType = .medication
                            showAddEventSheet = true
                        } label: {
                            Label("Medication Reminder", systemImage: "pills.fill")
                        }
                        
                        Button {
                            selectedEventType = .vaccination
                            showAddEventSheet = true
                        } label: {
                            Label("Vaccination", systemImage: "syringe.fill")
                        }
                        
                        Button {
                            selectedEventType = .appointment
                            showAddEventSheet = true
                        } label: {
                            Label("Appointment", systemImage: "calendar.badge.clock")
                        }
                        
                        Button {
                            selectedEventType = .reminder
                            showAddEventSheet = true
                        } label: {
                            Label("Reminder", systemImage: "bell.fill")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.vetCanyon)
                    }
                }
            }
        }
        .onAppear {
            if let pet = pet {
                Task {
                    if calendarManager.authorizationStatus != .authorized {
                        _ = await calendarManager.requestAccess()
                    }
                    await calendarManager.loadEvents(for: pet.id)
                }
            }
        }
        .sheet(isPresented: $showAddEventSheet) {
            if let pet = pet {
                AddCalendarEventView(
                    pet: pet,
                    eventType: selectedEventType,
                    calendarManager: calendarManager
                )
            }
        }
        .sheet(isPresented: $showEventDetail) {
            if let event = selectedEvent, let pet = pet {
                EventDetailView(event: event, pet: pet, calendarManager: calendarManager)
            }
        }
    }
    
    private var authorizationView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.vetCanyon)
            
            Text("Calendar Access Required")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.vetTitle)
            
            Text("To track your pet's appointments, medications, and vaccinations, please allow calendar access.")
                .font(.system(size: 16))
                .foregroundColor(.vetSubtitle)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                Task { @MainActor in
                    let granted = await calendarManager.requestAccess()
                    // Force a refresh of the authorization status
                    calendarManager.checkAuthorizationStatus()
                    if granted && calendarManager.authorizationStatus == .authorized, let pet = pet {
                        await calendarManager.loadEvents(for: pet.id)
                    }
                }
            } label: {
                Text("Grant Access")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: 200)
                    .padding()
                    .background(Color.vetCanyon)
                    .cornerRadius(12)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
    }
    
    private var calendarContentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // iOS Calendar Component
                CalendarMonthView(
                    selectedDate: $selectedDate,
                    events: calendarManager.events,
                    pet: pet
                )
                .padding(.horizontal)
                .padding(.top, useSystemNavBar ? 16 : 0)
                
                // Quick Add Buttons
                if let pet = pet {
                    quickAddSection(pet: pet)
                }
                
                // Events List
                eventsListSection
            }
            .padding(.bottom, 32)
        }
    }
    
    private func quickAddSection(pet: Pet) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QUICK ADD")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.vetSubtitle)
                .padding(.horizontal)
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2),
                spacing: 12
            ) {
                CalendarActionCard(
                    title: "Medication",
                    icon: "pills.fill",
                    color: .orange
                ) {
                    selectedEventType = .medication
                    showAddEventSheet = true
                }
                
                CalendarActionCard(
                    title: "Vaccination",
                    icon: "syringe.fill",
                    color: .green
                ) {
                    selectedEventType = .vaccination
                    showAddEventSheet = true
                }
                
                CalendarActionCard(
                    title: "Appointment",
                    icon: "calendar.badge.clock",
                    color: .blue
                ) {
                    selectedEventType = .appointment
                    showAddEventSheet = true
                }
                
                CalendarActionCard(
                    title: "Reminder",
                    icon: "bell.fill",
                    color: .purple
                ) {
                    selectedEventType = .reminder
                    showAddEventSheet = true
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var eventsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("UPCOMING EVENTS")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.vetSubtitle)
                .padding(.horizontal)
            
            if calendarManager.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if calendarManager.events.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.vetSubtitle)
                    Text("No events scheduled")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.vetSubtitle)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                let upcomingEvents = calendarManager.events.filter { $0.date >= Date() }
                if upcomingEvents.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                        Text("All caught up!")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.vetSubtitle)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(upcomingEvents.prefix(10)) { event in
                        EventRowView(event: event) {
                            selectedEvent = event
                            showEventDetail = true
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
}

struct CalendarActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    init(title: String, icon: String, color: Color, action: @escaping () -> Void = {}) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.vetTitle)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(Color.vetCardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.vetStroke.opacity(0.3), lineWidth: 1)
            )
            .vetLightShadow()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Calendar Month View

struct CalendarMonthView: View {
    @Binding var selectedDate: Date
    let events: [PetCalendarEvent]
    let pet: Pet?
    
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 16) {
            // Month Header
            HStack {
                Button {
                    changeMonth(-1)
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.vetCanyon)
                }
                
                Spacer()
                
                Text(dateFormatter.string(from: currentMonth))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.vetTitle)
                
                Spacer()
                
                Button {
                    changeMonth(1)
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.vetCanyon)
                }
            }
            .padding(.horizontal)
            
            // Weekday Headers
            HStack(spacing: 0) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.vetSubtitle)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
                ForEach(Array(calendarDays.enumerated()), id: \.offset) { index, date in
                    CalendarDayView(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date),
                        isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month),
                        hasEvent: hasEvent(on: date),
                        onTap: {
                            selectedDate = date
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color.vetCardBackground)
        .cornerRadius(16)
        .vetShadow()
    }
    
    private var calendarDays: [Date] {
        guard let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)),
              let firstDayWeekday = calendar.dateComponents([.weekday], from: firstDayOfMonth).weekday else {
            return []
        }
        
        // Normalize first day to start of day
        let normalizedFirstDay = calendar.startOfDay(for: firstDayOfMonth)
        
        let startOffset = (firstDayWeekday - 1) % 7
        var days: [Date] = []
        
        // Calculate the first day to show (might be from previous month)
        let firstDayToShow = calendar.date(byAdding: .day, value: -startOffset, to: normalizedFirstDay) ?? normalizedFirstDay
        
        // Generate exactly 42 days (6 weeks x 7 days)
        for i in 0..<42 {
            if let date = calendar.date(byAdding: .day, value: i, to: firstDayToShow) {
                // Normalize to start of day to avoid timezone issues
                let normalizedDate = calendar.startOfDay(for: date)
                days.append(normalizedDate)
            }
        }
        
        return days
    }
    
    private func hasEvent(on date: Date) -> Bool {
        events.contains { event in
            calendar.isDate(event.date, inSameDayAs: date)
        }
    }
    
    private func changeMonth(_ direction: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: direction, to: currentMonth) {
            currentMonth = newMonth
        }
    }
}

// MARK: - Calendar Day View

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let hasEvent: Bool
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: isToday ? .bold : .medium))
                    .foregroundColor(dayColor)
                
                if hasEvent {
                    Circle()
                        .fill(isSelected ? .white : .vetCanyon)
                        .frame(width: 4, height: 4)
                } else {
                    Spacer()
                        .frame(height: 4)
                }
            }
            .frame(width: 40, height: 50)
            .background(isSelected ? Color.vetCanyon : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isToday && !isSelected ? Color.vetCanyon : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var dayColor: Color {
        if isSelected {
            return .white
        } else if !isCurrentMonth {
            return .vetSubtitle.opacity(0.3)
        } else if isToday {
            return .vetCanyon
        } else {
            return .vetTitle
        }
    }
}

// MARK: - Event Row View

struct EventRowView: View {
    let event: PetCalendarEvent
    let onTap: () -> Void
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter
    }()
    
    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 12) {
                // Event Type Icon
                Image(systemName: event.type.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(eventColor)
                    .frame(width: 40, height: 40)
                    .background(eventColor.opacity(0.15))
                    .clipShape(Circle())
                
                // Event Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.vetTitle)
                        .lineLimit(1)
                    
                    Text(dateFormatter.string(from: event.date))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.vetSubtitle)
                    
                    if event.isRecurring {
                        HStack(spacing: 4) {
                            Image(systemName: "repeat")
                                .font(.system(size: 10))
                            Text("Recurring")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.vetSubtitle)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.vetSubtitle)
            }
            .padding()
            .background(Color.vetCardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.vetStroke.opacity(0.3), lineWidth: 1)
            )
            .vetLightShadow()
        }
        .buttonStyle(.plain)
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

// MARK: - Event Detail View

struct EventDetailView: View {
    let event: PetCalendarEvent
    let pet: Pet
    @ObservedObject var calendarManager: CalendarManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy 'at' h:mm a"
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.vetBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Event Header
                        VStack(spacing: 16) {
                            Image(systemName: event.type.icon)
                                .font(.system(size: 50, weight: .semibold))
                                .foregroundColor(eventColor)
                                .frame(width: 80, height: 80)
                                .background(eventColor.opacity(0.15))
                                .clipShape(Circle())
                            
                            Text(event.title)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.vetTitle)
                            
                            Text(event.type.displayName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(eventColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(eventColor.opacity(0.15))
                                .cornerRadius(8)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.vetCardBackground)
                        .cornerRadius(16)
                        .vetShadow()
                        .padding(.horizontal)
                        
                        // Event Details
                        VStack(alignment: .leading, spacing: 16) {
                            CalendarDetailRow(label: "Date & Time", value: dateFormatter.string(from: event.date))
                            
                            if let endDate = event.endDate {
                                CalendarDetailRow(label: "End Time", value: dateFormatter.string(from: endDate))
                            }
                            
                            if event.isRecurring {
                                CalendarDetailRow(label: "Recurrence", value: recurrenceText)
                            }
                            
                            if let notes = event.notes, !notes.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Notes")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.vetSubtitle)
                                    
                                    Text(notes)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.vetTitle)
                                }
                            }
                        }
                        .padding()
                        .background(Color.vetCardBackground)
                        .cornerRadius(16)
                        .vetShadow()
                        .padding(.horizontal)
                        
                        // Delete Button
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Event", systemImage: "trash")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                        }
                        .disabled(isDeleting)
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.vetCanyon)
                }
            }
            .alert("Delete Event", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteEvent()
                    }
                }
            } message: {
                Text("Are you sure you want to delete this event?")
            }
            .overlay {
                if isDeleting {
                    ProgressView("Deleting...")
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
    }
    
    private var eventColor: Color {
        switch event.type {
        case .medication: return .orange
        case .vaccination: return .green
        case .appointment: return .blue
        case .reminder: return .purple
        }
    }
    
    private var recurrenceText: String {
        guard let rule = event.recurrenceRule else { return "Recurring" }
        let frequencyText = rule.frequency.rawValue.capitalized
        let intervalText = rule.interval == 1 ? "" : "every \(rule.interval) "
        return "\(intervalText)\(frequencyText)"
    }
    
    private func deleteEvent() async {
        isDeleting = true
        do {
            print("🗑️ Deleting event from view: \(event.title)")
            try await calendarManager.deleteEvent(event)
            // Events are reloaded automatically in deleteEvent
            // Wait a moment for UI to update
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            await MainActor.run {
                dismiss()
            }
        } catch {
            print("❌ Error deleting event: \(error.localizedDescription)")
            await MainActor.run {
                isDeleting = false
                // Show error alert - you might want to add an alert state here
            }
        }
    }
}

struct CalendarDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.vetSubtitle)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.vetTitle)
        }
    }
}

#Preview("CalendarView - System Nav") {
    NavigationStack {
        CalendarView(tabSelection: .constant(.home), useSystemNavBar: true, pet: nil)
            .environmentObject(ThemeStore())
    }
}

#Preview("CalendarView - Custom Nav") {
    CalendarView(tabSelection: .constant(.home), useSystemNavBar: false, pet: nil)
        .environmentObject(ThemeStore())
}

#Preview("CalendarView - With Pet") {
    NavigationStack {
        CalendarView(
            tabSelection: .constant(.home),
            useSystemNavBar: true,
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
            )
        )
        .environmentObject(ThemeStore())
    }
}
