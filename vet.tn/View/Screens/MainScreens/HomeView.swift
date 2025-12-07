//
//  HomeView.swift
//  vet.tn
//

import SwiftUI
import EventKit

// MARK: - Home

struct HomeView: View {
    // Binding vers l'onglet actif de MainTabView
    @Binding var tabSelection: VetTab
    @EnvironmentObject private var session: SessionManager
    @StateObject private var petViewModel = PetViewModel()
    @StateObject private var chatManager = ChatManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var aiViewModel = PetAIViewModel()
    @StateObject private var calendarManager = CalendarManager()

    // Navigation flags
    @State private var goFindVet   = false
    @State private var goChatAI    = false
    @State private var goCalendar  = false
    @State private var goPetSitter = false
    @State private var goAddPet    = false   // ⬅️ NEW
    @State private var goMessages = false
    @State private var showDrawer = false

    // Sélection animée
    @State private var selectedActionID: UUID?  = nil
    @State private var selectedVetID: UUID?     = nil

    // (si tu veux chercher plus tard)
    @State private var searchText = ""
    
    // AI-generated data
    @State private var petTips: [PetTip] = []
    @State private var petStatuses: [String: PetStatus] = [:]
    @State private var allReminders: [PetReminder] = []
    @State private var isLoadingAI = false
    @State private var aiError: String?
    @State private var hasLoadedAI = false
    
    // Auto-refresh
    @State private var refreshTask: Task<Void, Never>?
    private let refreshInterval: TimeInterval = 60 * 60 // 1 hour

    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    TopBar(
                        title: "Home",
                        onCommunity: { goMessages = true },
                        onDrawer: { showDrawer = true }
                    )

                    dailyTipCarousel
                    healthSnapshotSection
                    remindersSection
                 //   quickActionsSection
                  //  recommendedProfessionals

                    Spacer(minLength: 32)
                }
                .padding(.top, 6)
            }
        }
        // MARK: - Destinations
        .navigationDestination(isPresented: $goFindVet) {
            FindVetView()
                .navigationBarBackButtonHidden(false)
        }
        .navigationDestination(isPresented: $goChatAI) {
            // ChatAI avec back iOS rond (system nav bar)
            ChatAIView(tabSelection: $tabSelection, useSystemNavBar: true)
                .navigationBarBackButtonHidden(false)
        }
        .navigationDestination(isPresented: $goCalendar) {
            // Calendar avec back iOS rond (system nav bar)
            CalendarView(tabSelection: $tabSelection, useSystemNavBar: true, pet: nil)
                .navigationBarBackButtonHidden(false)
        }
        .navigationDestination(isPresented: $goPetSitter) {
            PetSitterView()
                .navigationBarBackButtonHidden(false)
        }
        .navigationDestination(isPresented: $goAddPet) {
            // ⬅️ Push to your multi-step Add Pet flow
           AddPetFlowView()
               .navigationBarBackButtonHidden(false)
        }
        .navigationDestination(isPresented: $goMessages) {
            ConversationsListView()
                .navigationBarBackButtonHidden(false)
        }
        .sheet(isPresented: $showDrawer) {
            NavigationStack {
                DrawerView()
            }
            .environmentObject(session)
        }
        .onAppear {
            petViewModel.sessionManager = session
            aiViewModel.sessionManager = session
            chatManager.setSessionManager(session)
            chatManager.startPolling()
            notificationManager.setSessionManager(session)
            notificationManager.startPolling()
            
            // Initial load of unread count
            Task {
                await chatManager.updateUnreadCount()
                await notificationManager.updateUnreadCount()
            }
            
            // Load AI content when pets are loaded
            if !petViewModel.pets.isEmpty {
                Task {
                    await loadAIContent()
                }
            }
            
            // Start auto-refresh timer (every 1 hour)
            startAutoRefresh()
        }
        .onDisappear {
            // Stop timer when view disappears
            stopAutoRefresh()
        }
        .task(id: session.user?.id) {
            // Only load pets when user ID changes, not on every appear
            guard session.user?.id != nil else { return }
            await petViewModel.loadPets()
            // Load AI content after pets are loaded
            if !petViewModel.pets.isEmpty {
                print("🏠 HomeView: Loading AI content for \(petViewModel.pets.count) pets")
                await loadAIContent()
            } else {
                print("🏠 HomeView: No pets found, skipping AI content")
            }
        }
        .onAppear {
            // Also try to load AI content when view appears (if pets are already loaded)
            if !petViewModel.pets.isEmpty && !hasLoadedAI && !isLoadingAI {
                print("🏠 HomeView: onAppear - Loading AI content")
                Task {
                    await loadAIContent()
                }
            }
        }
        .onChange(of: session.isAuthenticated) { oldValue, newValue in
            // Only load pets when authentication state changes from false to true
            if !oldValue && newValue {
                Task {
                    await petViewModel.loadPets()
                    if !petViewModel.pets.isEmpty {
                        await loadAIContent()
                    }
                }
            }
        }
        .onChange(of: petViewModel.pets.count) { oldCount, newCount in
            // Reload AI content when pets are added/removed
            if newCount > 0 && newCount != oldCount {
                Task {
                    await loadAIContent()
                }
            }
        }
    }

    private var dailyTipCarousel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Daily Tips")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.vetTitle)

                Spacer()

                Button {
                    hapticTap()
                    goAddPet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Add a pet")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.vetCardBackground)
                    .foregroundStyle(Color.vetCanyon)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.vetCanyon, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            if isLoadingAI && !hasLoadedAI && petTips.isEmpty {
                // Only show loading if we don't have any tips yet
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Generating AI tips...")
                        .font(.system(size: 13))
                        .foregroundColor(.vetSubtitle)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if let error = aiError, petTips.isEmpty {
                // Only show error if we don't have cached tips
                VStack(spacing: 8) {
                    Text("AI unavailable")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.vetSubtitle)
                    Button("Retry") {
                        Task {
                            await loadAIContent()
                        }
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.vetCanyon)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if !petTips.isEmpty {
                // Show AI-generated tips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(petTips) { tip in
                            DailyTipCard(tip: tip)
                        }
                    }
                    .padding(.vertical, 2)
                }
            } else if petViewModel.pets.isEmpty {
                // No pets - show empty state
                VStack(spacing: 8) {
                    Text("No tips or recommendations")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.vetSubtitle)
                    Text("Add a pet to get personalized tips")
                        .font(.system(size: 12))
                        .foregroundColor(.vetSubtitle.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                // Fallback to static tips if AI not loaded and no cached tips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(dailyTipsMock) { tip in
                            DailyTipCard(tip: tip)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(.horizontal, 18)
    }

    private var healthSnapshotSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Pet Health Snapshot")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.vetTitle)

            VStack(spacing: 12) {
                if petViewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if petViewModel.pets.isEmpty {
                    Text("No pets yet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.vetSubtitle)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    ForEach(petViewModel.pets) { pet in
                        NavigationLink {
                            PetProfileView(pet: pet)
                        } label: {
                            PetStatusRow(pet: pet, status: petStatuses[pet.id])
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Refresh AI status button
                    if !petViewModel.pets.isEmpty {
                        Button {
                            Task {
                                await loadAIContent()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 12))
                                Text("Refresh AI Status")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.vetCanyon)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.vetCanyon.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
                    .padding(.horizontal, 18)
    }

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Upcoming Reminders")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.vetTitle)

            VStack(spacing: 12) {
                if isLoadingAI && !hasLoadedAI && allReminders.isEmpty {
                    // Only show loading if we don't have any reminders yet
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Generating reminders...")
                            .font(.system(size: 13))
                            .foregroundColor(.vetSubtitle)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else if !allReminders.isEmpty {
                    // Show AI-generated reminders
                    ForEach(allReminders.prefix(5)) { reminder in
                        ReminderRow(reminder: reminder)
                    }
                } else if petViewModel.pets.isEmpty {
                    // No pets
                    Text("No reminders")
                        .font(.system(size: 13))
                        .foregroundColor(.vetSubtitle)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    // No reminders generated - show empty state
                    VStack(spacing: 8) {
                        Text("No reminders coming soon")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.vetSubtitle)
                        Text("All scheduled care is up to date")
                            .font(.system(size: 12))
                            .foregroundColor(.vetSubtitle.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
        }
        .padding(.horizontal, 18)
    }
    
    // MARK: - Auto-Refresh Timer
    
    private func startAutoRefresh() {
        // Stop existing task if any
        stopAutoRefresh()
        
        // Create async task that refreshes every 1 hour
        refreshTask = Task {
            while !Task.isCancelled {
                // Wait 1 hour
                try? await Task.sleep(nanoseconds: UInt64(refreshInterval * 1_000_000_000))
                
                // Check if task was cancelled
                guard !Task.isCancelled else { break }
                
                // Only refresh if we have pets and are authenticated
                guard !petViewModel.pets.isEmpty, session.isAuthenticated else { continue }
                
                await MainActor.run {
                    print("🔄 Auto-refreshing AI content (1-hour interval)")
                }
                
                await loadAIContent(silent: true) // Silent refresh - don't show loading if we have cached content
            }
        }
        
        print("⏰ Started auto-refresh task (every \(Int(refreshInterval / 60)) minutes)")
    }
    
    private func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }
    
    // MARK: - AI Content Loading
    
    private func loadAIContent(silent: Bool = false) async {
        guard !petViewModel.pets.isEmpty else {
            print("⚠️ No pets to generate AI content for")
            return
        }
        
        print("🤖 Starting AI content generation for \(petViewModel.pets.count) pets (silent: \(silent))")
        
        await MainActor.run {
            // Only show loading if not silent and we don't have cached content
            if !silent || (petTips.isEmpty && allReminders.isEmpty) {
                isLoadingAI = true
            }
            aiError = nil
        }
        
        // Request calendar access if needed
        if calendarManager.authorizationStatus != .authorized {
            print("📅 Requesting calendar access...")
            _ = await calendarManager.requestAccess()
        }
        
        var tips: [PetTip] = []
        var statuses: [String: PetStatus] = [:]
        var reminders: [PetReminder] = []
        var hasError = false
        
        // Load content for each pet
        // Note: Rate limiting is now handled centrally in GeminiService
        // The service ensures max 2 requests per minute with proper delays
        
        // First, load all calendar events
        for pet in petViewModel.pets {
            if calendarManager.authorizationStatus == .authorized {
                await calendarManager.loadEvents(for: pet.id)
            }
        }
        
        // Process each pet completely: tips → recommendations → status → reminders
        // This ensures each pet's data is shown together before moving to the next
        print("🤖 Processing AI content for each pet (tips → recommendations → status → reminders)...")
        for (index, pet) in petViewModel.pets.enumerated() {
            print("🐾 Processing pet \(index + 1)/\(petViewModel.pets.count): \(pet.name)")
            
            var calendarEvents: [PetCalendarEvent] = []
            if calendarManager.authorizationStatus == .authorized {
                calendarEvents = calendarManager.events.filter { $0.petId == pet.id }
            }
            
            // 1. Generate tip for this pet
            print("  💡 Generating tip for \(pet.name)...")
            if let tip = await aiViewModel.generateHomeTips(for: pet, calendarEvents: calendarEvents) {
                print("  ✅ Generated tip: \(tip.title)")
                tips.append(tip)
                
                // Update UI immediately when we get a tip (progressive loading)
                await MainActor.run {
                    if !tips.isEmpty {
                        self.petTips = tips
                    }
                }
            } else {
                print("  ⚠️ Failed to generate tip for \(pet.name)")
                if let error = aiViewModel.error {
                    print("  ❌ Error: \(error)")
                    hasError = true
                }
            }
            
            // 2. Generate recommendations for this pet (if needed)
            // Note: Recommendations might be generated separately, skipping for now
            
            // 3. Generate status for this pet (right after tips/recommendations)
            print("  📊 Generating status for \(pet.name)...")
            let status = await aiViewModel.generatePetStatus(for: pet, calendarEvents: calendarEvents)
            print("  ✅ Generated status: \(status.status) with \(status.pills.count) pills")
            statuses[pet.id] = status
            
            // Update UI immediately with status for this pet
            await MainActor.run {
                self.petStatuses[pet.id] = status
            }
            
            // 4. Generate reminders for this pet
            print("  🔔 Generating reminders for \(pet.name)...")
            let petReminders = await aiViewModel.generateHomeReminders(for: pet, calendarEvents: calendarEvents)
            print("  ✅ Generated \(petReminders.count) reminders")
            reminders.append(contentsOf: petReminders)
            
            // Update UI immediately with reminders
            await MainActor.run {
                let existingReminders = self.allReminders
                let allReminders = (existingReminders + petReminders).sorted { $0.date < $1.date }
                var uniqueReminders: [PetReminder] = []
                var seen = Set<String>()
                for reminder in allReminders {
                    let key = "\(reminder.title)-\(reminder.date.timeIntervalSince1970)"
                    if !seen.contains(key) {
                        seen.insert(key)
                        uniqueReminders.append(reminder)
                    }
                }
                self.allReminders = uniqueReminders
            }
        }
        
        await MainActor.run {
            print("🔄 Updating UI state - Tips collected: \(tips.count), Current tips: \(self.petTips.count)")
            
            // Always update if we got new content, otherwise keep old content
            if !tips.isEmpty {
                self.petTips = tips
                print("✅ Updated tips: \(tips.count) - \(tips.map { $0.title }.joined(separator: ", "))")
                print("   Tip details: \(tips.map { "\($0.title): \($0.detail.prefix(30))..." }.joined(separator: " | "))")
            } else if !silent {
                print("⚠️ No new tips generated, keeping existing \(self.petTips.count) tips")
            }
            
            if !statuses.isEmpty {
                // Merge new statuses with existing ones (don't lose statuses for pets we didn't process)
                for (petId, status) in statuses {
                    self.petStatuses[petId] = status
                    print("✅ Updated status for pet \(petId): \(status.status) with pills: \(status.pills.map { $0.text }.joined(separator: ", "))")
                }
                print("✅ Updated statuses: \(statuses.count) total")
            }
            
            if !reminders.isEmpty {
                // Merge reminders and sort
                let existingReminders = self.allReminders
                let allReminders = (existingReminders + reminders).sorted { $0.date < $1.date }
                // Remove duplicates based on title and date
                var uniqueReminders: [PetReminder] = []
                var seen = Set<String>()
                for reminder in allReminders {
                    let key = "\(reminder.title)-\(reminder.date.timeIntervalSince1970)"
                    if !seen.contains(key) {
                        seen.insert(key)
                        uniqueReminders.append(reminder)
                    }
                }
                self.allReminders = uniqueReminders
                print("✅ Updated reminders: \(reminders.count) new, \(self.allReminders.count) total")
            } else if !silent {
                print("⚠️ No new reminders generated, keeping existing \(self.allReminders.count) reminders")
            }
            
            if hasError && tips.isEmpty && self.petTips.isEmpty {
                self.aiError = aiViewModel.error ?? "Failed to generate AI content"
            } else {
                self.aiError = nil
            }
            
            self.isLoadingAI = false
            self.hasLoadedAI = true
            
            print("🤖 AI content generation complete:")
            print("   - Tips: \(self.petTips.count) - Displaying: \(self.petTips.map { $0.title }.joined(separator: ", "))")
            print("   - Statuses: \(self.petStatuses.count)")
            print("   - Reminders: \(self.allReminders.count)")
        }
    }

  /*  private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
                    Text("Quick Actions")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.vetTitle)

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 2),
                        spacing: 14
                    ) {
                        ForEach(actionsMock) { action in
                    quickActionButton(for: action)
                }
            }
        }
        .padding(.horizontal, 18)
    }  */

  /*  private func quickActionButton(for action: QuickAction) -> some View {
                                Button {
                                    hapticTap()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedActionID = action.id
                                    }

                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                switch action.title {
                case "Vet AI":
                    goChatAI = true
                case "Find Vet":
                    goFindVet = true
                case "Calendar":
                                            goCalendar = true
                case "Pet Sitter":
                                            goPetSitter = true
                default:
                    break
                                        }
                                    }

                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            selectedActionID = nil
                                        }
                                    }
                                } label: {
                                    QuickActionCard(action: action, isSelected: selectedActionID == action.id)
                                        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                .buttonStyle(.plain)
    }  */

  /*  private var recommendedProfessionals: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recommended Professionals")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.vetTitle)

                    VStack(spacing: 12) {
                        ForEach(vetsMock) { vet in
                            VetRow(vet: vet, isSelected: selectedVetID == vet.id)
                                .onTapGesture {
                                    hapticTap()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedVetID = vet.id
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            selectedVetID = nil
                                        }
                                    }
                                }
                        }
                    }
        }
                    .padding(.horizontal, 18)
    } */

    private func hapticTap() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}

// MARK: - Components

struct Pill: View {
    let text: String
    let bg: Color
    let fg: Color

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(fg)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Helper for pet photo display

@ViewBuilder
private func petAvatarView(photoString: String, emoji: String, size: CGFloat) -> some View {
    // Check if it's a URL
    if photoString.hasPrefix("http://") || photoString.hasPrefix("https://"),
       let photoURL = URL(string: photoString) {
        AsyncImage(url: photoURL) { phase in
            switch phase {
            case .empty:
                ZStack {
                    Circle()
                        .fill(Color.vetCanyon.opacity(0.28))
                        .frame(width: size, height: size)
                    ProgressView()
                        .scaleEffect(0.7)
                }
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            case .failure:
                ZStack {
                    Circle()
                        .fill(Color.vetCanyon.opacity(0.28))
                        .frame(width: size, height: size)
                    Text(emoji)
                        .font(.system(size: size * 0.48))
                }
            @unknown default:
                ZStack {
                    Circle()
                        .fill(Color.vetCanyon.opacity(0.28))
                        .frame(width: size, height: size)
                    Text(emoji)
                        .font(.system(size: size * 0.48))
                }
            }
        }
    } else if let base64String = extractBase64String(from: photoString),
              let imageData = Data(base64Encoded: base64String),
              let uiImage = UIImage(data: imageData) {
        Image(uiImage: uiImage)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
    } else {
        ZStack {
            Circle()
                .fill(Color.vetCanyon.opacity(0.28))
                .frame(width: size, height: size)
            Text(emoji)
                .font(.system(size: size * 0.48))
        }
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

struct PetStatusRow: View {
    let pet: Pet
    let status: PetStatus?

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Display photo if available, otherwise show emoji
            if let photoString = pet.photo, !photoString.isEmpty {
                petAvatarView(photoString: photoString, emoji: pet.emoji, size: 42)
            } else {
                ZStack {
                    Circle()
                        .fill(Color.vetCanyon.opacity(0.28))
                        .frame(width: 42, height: 42)
                    Text(pet.emoji)
                        .font(.system(size: 20))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(pet.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.vetTitle)
                Text(status?.summary ?? "✓ Up-to-date | \(pet.medsCount) med | \(pet.weightText)")
                    .font(.system(size: 12))
                    .foregroundColor(.vetSubtitle)
            }

            Spacer(minLength: 10)

            // Use AI-generated pills or fallback
            if let status = status, !status.pills.isEmpty {
                ForEach(Array(status.pills.enumerated()), id: \.offset) { _, pill in
                    Pill(text: pill.text, bg: pill.bg, fg: pill.fg)
                }
            } else {
                // Fallback pills
                Pill(text: "Healthy",
                     bg: Color.green.opacity(0.12),
                     fg: Color.green.darker())
                Pill(text: "Due Soon",
                     bg: Color.vetCanyon.opacity(0.14),
                     fg: Color.vetCanyon)
            }
        }
        .padding(12)
        .background(Color.vetCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.vetStroke, lineWidth: 1)
        )
        .vetLightShadow()
    }
}

/* struct QuickActionCard: View {
    let action: QuickAction
    var isSelected: Bool = false

    var body: some View {
        VStack(spacing: 10) {
            Text(action.emoji)
                .font(.system(size: 26))
            Text(action.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.vetTitle)
        }
        .frame(maxWidth: .infinity, minHeight: 92)
        .background(isSelected ? Color.vetCanyon.opacity(0.15) : Color.vetCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isSelected ? Color.vetCanyon : Color.vetStroke, lineWidth: 2)
        )
        .vetShadow(radius: isSelected ? 10 : 4, x: 0, y: isSelected ? 4 : 2)
        .scaleEffect(isSelected ? 1.04 : 1.0)
    }
} */

struct DailyTipCard: View {
    let tip: DailyTip
    
    init(tip: DailyTip) {
        self.tip = tip
    }
    
    init(tip: PetTip) {
        // Convert PetTip to DailyTip for compatibility
        self.tip = DailyTip(emoji: tip.emoji, title: tip.title, detail: tip.detail)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(tip.emoji)
                .font(.system(size: 36))

            VStack(alignment: .leading, spacing: 6) {
                Text(tip.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.vetTitle)
                Text(tip.detail)
                    .font(.system(size: 13))
                    .foregroundColor(.vetSubtitle)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(width: 220, alignment: .leading)
        .background(Color.vetCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.vetStroke.opacity(0.35), lineWidth: 1)
        )
        .vetShadow(radius: 6, x: 0, y: 3)
    }
}

struct ReminderRow: View {
    let reminder: Reminder
    
    init(reminder: Reminder) {
        self.reminder = reminder
    }
    
    init(reminder: PetReminder) {
        // Convert PetReminder to Reminder for compatibility
        self.reminder = Reminder(
            icon: reminder.icon,
            title: reminder.title,
            detail: reminder.detail,
            date: reminder.date,
            tint: reminder.tint
        )
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(reminder.tint.opacity(0.18))
                    .frame(width: 46, height: 46)
                Image(systemName: reminder.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(reminder.tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.vetTitle)
                Text(reminder.detail)
                    .font(.system(size: 13))
                    .foregroundColor(.vetSubtitle)
                Text(reminder.dateFormatted)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(reminder.tint)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.vetCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.vetStroke.opacity(0.3), lineWidth: 1)
        )
    }
}

/* struct VetRow: View {
    let vet: Vet
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.vetCanyon.opacity(0.28))
                    .frame(width: 48, height: 48)
                Text("👨‍⚕️")
                    .font(.system(size: 22))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(vet.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.vetTitle)
                Text(vet.hours)
                    .font(.system(size: 13))
                    .foregroundColor(.vetSubtitle)
            }

            Spacer()

            Image(systemName: "chevron.right.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.vetTitle.opacity(0.85))
        }
        .padding(12)
        .background(isSelected ? Color.vetCanyon.opacity(0.15) : Color.vetCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isSelected ? Color.vetCanyon : Color.vetStroke, lineWidth: 2)
        )
        .vetShadow(radius: isSelected ? 10 : 4, x: 0, y: isSelected ? 4 : 2)
        .scaleEffect(isSelected ? 1.03 : 1.0)
    }
}  */

// MARK: - Models + Mock

// Old mock Pet struct removed - now using Model/Pet.swift

struct QuickAction: Identifiable {
    let id = UUID()
    let title: String
    let emoji: String
}

struct Vet: Identifiable {
    let id = UUID()
    let name: String
    let hours: String
}

struct DailyTip: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
    let detail: String
}

struct Reminder: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let detail: String
    let date: Date
    let tint: Color

    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d • h:mm a"
        return formatter.string(from: date)
    }
}

// petsMock removed - now using real pets from PetViewModel

let actionsMock: [QuickAction] = [
    .init(title: "Vet AI",    emoji: "🤖"),
    .init(title: "Find Vet",   emoji: "🩺"),
    .init(title: "Calendar",   emoji: "📅"),
    .init(title: "Pet Sitter", emoji: "🧑‍⚕️")
]

let vetsMock: [Vet] = [
    .init(name: "John Smith", hours: "Mon–Wed, 9 am – 6 pm"),
    .init(name: "Lil Kim",    hours: "Tue–Fri, 9 am – 6 pm")
]

let dailyTipsMock: [DailyTip] = [
    .init(emoji: "🥕", title: "Fresh Nutrition", detail: "Rotate crunchy vegetables with high-protein treats to keep meals balanced."),
    .init(emoji: "🚶‍♀️", title: "Stay Active", detail: "Short walks twice a day help maintain healthy joints and reduce anxiety."),
    .init(emoji: "🪥", title: "Dental Care", detail: "Brush teeth 2-3 times per week to prevent plaque build-up and gum issues.")
]

let remindersMock: [Reminder] = [
    .init(icon: "syringe", title: "Luna • Vaccination Booster", detail: "Feline FVCRP booster due soon.", date: Date().addingTimeInterval(86400 * 3), tint: .vetCanyon),
    .init(icon: "pills.fill", title: "Max • Heartworm Prevention", detail: "Monthly chewable due this weekend.", date: Date().addingTimeInterval(86400 * 5), tint: .blue),
    .init(icon: "pawprint.fill", title: "Grooming Session", detail: "Schedule grooming and nail trim.", date: Date().addingTimeInterval(86400 * 8), tint: .purple)
]

// MARK: - Previews

#Preview("Home – Light") {
    let store: ThemeStore = { let s = ThemeStore(); s.selection = .light; return s }()
    return NavigationStack {
        HomeView(tabSelection: .constant(.home))
            .environmentObject(store)
            .preferredColorScheme(.light)
    }
}

#Preview("Home – Dark") {
    let store: ThemeStore = { let s = ThemeStore(); s.selection = .dark; return s }()
    return NavigationStack {
        HomeView(tabSelection: .constant(.home))
            .environmentObject(store)
            .preferredColorScheme(.dark)
    }
}
