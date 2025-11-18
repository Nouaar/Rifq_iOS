//
//  HomeView.swift
//  vet.tn
//

import SwiftUI

// MARK: - Home

struct HomeView: View {
    // Binding vers l’onglet actif de MainTabView
    @Binding var tabSelection: VetTab
    @EnvironmentObject private var session: SessionManager
    @StateObject private var petViewModel = PetViewModel()
    @StateObject private var chatManager = ChatManager.shared
    @StateObject private var notificationManager = NotificationManager.shared

    // Navigation flags
    @State private var goFindVet   = false
    @State private var goChatAI    = false
    @State private var goCalendar  = false
    @State private var goPetSitter = false
    @State private var goAddPet    = false   // ⬅️ NEW
    @State private var goMessages = false

    // Sélection animée
    @State private var selectedActionID: UUID?  = nil
    @State private var selectedVetID: UUID?     = nil

    // (si tu veux chercher plus tard)
    @State private var searchText = ""

    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    TopBar(
                        title: "Home",
                        onCommunity: { goMessages = true }
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
        .onAppear {
            petViewModel.sessionManager = session
            chatManager.setSessionManager(session)
            chatManager.startPolling()
            notificationManager.setSessionManager(session)
            notificationManager.startPolling()
            
            // Initial load of unread count
            Task {
                await chatManager.updateUnreadCount()
                await notificationManager.updateUnreadCount()
            }
        }
        .task(id: session.user?.id) {
            // Only load pets when user ID changes, not on every appear
            guard session.user?.id != nil else { return }
            await petViewModel.loadPets()
        }
        .onChange(of: session.isAuthenticated) { oldValue, newValue in
            // Only load pets when authentication state changes from false to true
            if !oldValue && newValue {
                Task {
                    await petViewModel.loadPets()
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

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(dailyTipsMock) { tip in
                        DailyTipCard(tip: tip)
                    }
                }
                .padding(.vertical, 2)
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
                            PetStatusRow(pet: pet)
                        }
                        .buttonStyle(.plain)
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
                ForEach(remindersMock) { reminder in
                    ReminderRow(reminder: reminder)
                }
            }
        }
                            .padding(.horizontal, 18)
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
                case "Chat AI":
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
                Text("✓ Up-to-date | \(pet.medsCount) med | \(pet.weightText)")
                    .font(.system(size: 12))
                    .foregroundColor(.vetSubtitle)
            }

            Spacer(minLength: 10)

            Pill(text: "Healthy",
                 bg: Color.green.opacity(0.12),
                 fg: Color.green.darker())
            Pill(text: "Due Soon",
                 bg: Color.vetCanyon.opacity(0.14),
                 fg: Color.vetCanyon)
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
    .init(title: "Chat AI",    emoji: "🤖"),
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
