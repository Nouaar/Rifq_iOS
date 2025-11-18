//
//  MyPetsView.swift
//  vet.tn
//
//  View showing the list of pets owned by the user

import SwiftUI
import EventKit

struct MyPetsView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var petViewModel = PetViewModel()
    @StateObject private var calendarManager = CalendarManager()
    
    @State private var hasAppeared = false
    @State private var showFullCalendar = false
    
    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    TopBar(title: "My Pets")
                    
                    // General Calendar Section
                    if !petViewModel.pets.isEmpty {
                        GeneralCalendarSection(
                            pets: petViewModel.pets,
                            calendarManager: calendarManager,
                            showFullCalendar: $showFullCalendar
                        )
                        .padding(.horizontal, 18)
                    }
                    
                    if petViewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if petViewModel.pets.isEmpty {
                        emptyStateView
                    } else {
                        petsList
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.top, 6)
            }
        }
        .onAppear {
            petViewModel.sessionManager = session
            if !hasAppeared {
                hasAppeared = true
                Task {
                    guard session.user?.id != nil else { return }
                    await petViewModel.loadPets()
                }
            }
        }
        .refreshable {
            guard session.user?.id != nil else { return }
            await petViewModel.loadPets()
        }
        .task(id: session.user?.id) {
            guard session.user?.id != nil else { return }
            await petViewModel.loadPets()
        }
        .onChange(of: session.isAuthenticated) { oldValue, newValue in
            if !oldValue && newValue {
                Task {
                    await petViewModel.loadPets()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshProfilePets"))) { _ in
            petViewModel.sessionManager = session
            Task {
                guard session.user?.id != nil else { return }
                await petViewModel.loadPets()
            }
        }
        .preference(key: TabBarHiddenPreferenceKey.self, value: false)
        .sheet(isPresented: $showFullCalendar) {
            NavigationStack {
                GeneralCalendarView(
                    pets: petViewModel.pets,
                    calendarManager: calendarManager
                )
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 48))
                .foregroundColor(.vetSubtitle.opacity(0.5))
            
            Text("No pets yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.vetTitle)
            
            Text("Add your first pet to get started")
                .font(.system(size: 14))
                .foregroundColor(.vetSubtitle)
                .multilineTextAlignment(.center)
            
            NavigationLink {
                AddPetFlowView()
                    .onDisappear {
                        Task {
                            guard session.user?.id != nil else { return }
                            await petViewModel.loadPets()
                        }
                    }
            } label: {
                Text("Add Your First Pet")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.vetCanyon)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 18)
    }
    
    private var petsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Pets")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.vetTitle)
                
                Spacer()
                
                NavigationLink {
                    AddPetFlowView()
                        .onDisappear {
                            Task {
                                guard session.user?.id != nil else { return }
                                await petViewModel.loadPets()
                            }
                        }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("Add Pet")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.vetCanyon)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.vetCanyon.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 18)
            
            VStack(spacing: 12) {
                ForEach(petViewModel.pets) { pet in
                    NavigationLink {
                        PetProfileView(pet: pet)
                    } label: {
                        PetRow(
                            name: pet.name,
                            breed: pet.breed ?? "Unknown",
                            age: pet.ageText,
                            color: .vetCanyon
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
        }
    }
}

// MARK: - General Calendar Section

struct GeneralCalendarSection: View {
    let pets: [Pet]
    @ObservedObject var calendarManager: CalendarManager
    @Binding var showFullCalendar: Bool
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("THIS WEEK")
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
        .onAppear {
            loadWeekEvents()
        }
        .onChange(of: pets.count) { _, _ in
            loadWeekEvents()
        }
    }
    
    private var authorizationPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 24))
                .foregroundColor(.vetSubtitle)
            
            Text("Enable calendar access to see all pet events")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.vetSubtitle)
                .multilineTextAlignment(.center)
            
            Button {
                Task { @MainActor in
                    _ = await calendarManager.requestAccess()
                    calendarManager.checkAuthorizationStatus()
                    if calendarManager.authorizationStatus == .authorized {
                        loadWeekEvents()
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
            if calendarManager.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                let weekEvents = getWeekEvents()
                
                if weekEvents.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 24))
                            .foregroundColor(.vetSubtitle)
                        Text("No events this week")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.vetSubtitle)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                } else {
                    VStack(spacing: 8) {
                        ForEach(weekEvents.prefix(5)) { event in
                            GeneralEventRow(event: event, pets: pets)
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
    
    private func loadWeekEvents() {
        guard calendarManager.authorizationStatus == .authorized else { return }
        let petIds = pets.map { $0.id }
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) ?? now
        
        Task {
            await calendarManager.loadAllPetsEvents(petIds: petIds, startDate: startOfWeek, endDate: endOfWeek)
        }
    }
    
    private func getWeekEvents() -> [PetCalendarEvent] {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) ?? now
        
        return calendarManager.events.filter { event in
            event.date >= startOfWeek && event.date < endOfWeek
        }.sorted { $0.date < $1.date }
    }
}

struct GeneralEventRow: View {
    let event: PetCalendarEvent
    let pets: [Pet]
    
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
                
                HStack(spacing: 4) {
                    if let petName = pets.first(where: { $0.id == event.petId })?.name {
                        Text(petName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.vetCanyon)
                        Text("•")
                            .font(.system(size: 11))
                            .foregroundColor(.vetSubtitle)
                    }
                    Text(dateFormatter.string(from: event.date))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.vetSubtitle)
                }
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

// MARK: - General Calendar View

struct GeneralCalendarView: View {
    let pets: [Pet]
    @ObservedObject var calendarManager: CalendarManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDate = Date()
    @State private var showEventDetail = false
    @State private var selectedEvent: PetCalendarEvent?
    
    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Calendar
                    CalendarMonthView(
                        selectedDate: $selectedDate,
                        events: calendarManager.events,
                        pet: nil
                    )
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // Events List
                    eventsListSection
                }
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("All Pets Calendar")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(.vetCanyon)
            }
        }
        .onAppear {
            loadWeekEvents()
        }
        .sheet(isPresented: $showEventDetail) {
            if let event = selectedEvent, let pet = pets.first(where: { $0.id == event.petId }) {
                EventDetailView(event: event, pet: pet, calendarManager: calendarManager)
            }
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
                    ForEach(upcomingEvents.prefix(20)) { event in
                        GeneralEventRowWithPet(event: event, pets: pets) {
                            selectedEvent = event
                            showEventDetail = true
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    private func loadWeekEvents() {
        let petIds = pets.map { $0.id }
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        let endOfWeek = calendar.date(byAdding: .day, value: 30, to: startOfWeek) ?? now // Load next 30 days
        
        Task {
            if calendarManager.authorizationStatus != .authorized {
                _ = await calendarManager.requestAccess()
            }
            await calendarManager.loadAllPetsEvents(petIds: petIds, startDate: startOfWeek, endDate: endOfWeek)
        }
    }
}

struct GeneralEventRowWithPet: View {
    let event: PetCalendarEvent
    let pets: [Pet]
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
                Image(systemName: event.type.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(eventColor)
                    .frame(width: 40, height: 40)
                    .background(eventColor.opacity(0.15))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.vetTitle)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        if let petName = pets.first(where: { $0.id == event.petId })?.name {
                            Text(petName)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.vetCanyon)
                            Text("•")
                                .font(.system(size: 13))
                                .foregroundColor(.vetSubtitle)
                        }
                        Text(dateFormatter.string(from: event.date))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.vetSubtitle)
                    }
                    
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

#Preview("MyPetsView") {
    MyPetsView()
        .environmentObject(SessionManager())
        .environmentObject(ThemeStore())
}

