//
//  HomeView.swift
//  vet.tn
//

import SwiftUI

// MARK: - Home

struct HomeView: View {
    // Binding vers l’onglet actif de MainTabView
    @Binding var tabSelection: VetTab

    // Navigation flags
    @State private var goFindVet   = false
    @State private var goChatAI    = false
    @State private var goCalendar  = false
    @State private var goPetSitter = false
    @State private var goJoinVet   = false
    @State private var goJoinSitter = false
    @State private var goAddPet    = false   // ⬅️ NEW

    // Sélection animée
    @State private var selectedPetID: UUID?     = nil
    @State private var selectedActionID: UUID?  = nil
    @State private var selectedVetID: UUID?     = nil

    // (si tu veux chercher plus tard)
    @State private var searchText = ""

    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {

                    TopBar(title: "My pets")

                    // ⬇️ Add button above the pets grid
                    HStack {
                        Text("Your Pets")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
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
                            .overlay(
                                Capsule().stroke(Color.vetCanyon, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 2)

                    // Pets grid (2 cards)
                    HStack(spacing: 14) {
                        ForEach(petsMock.prefix(2)) { pet in
                            PetCard(pet: pet, isSelected: selectedPetID == pet.id)
                                .onTapGesture {
                                    hapticTap()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedPetID = pet.id
                                    }
                                    // retour à l’état normal
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            selectedPetID = nil
                                        }
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 18)

                    // Status row for first pet
                    if let first = petsMock.first {
                        PetStatusRow(pet: first)
                            .padding(.horizontal, 18)
                    }

                    // Quick actions title
                    Text("Quick Actions")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.vetTitle)
                        .padding(.horizontal, 18)
                        .padding(.top, 6)

                    // Actions grid 2×2
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 2),
                        spacing: 14
                    ) {
                        ForEach(actionsMock) { action in
                            if action.title == "Chat AI" {
                                Button {
                                    hapticTap()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedActionID = action.id
                                    }
                                    // micro-délai pour garder le "tap feel"
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                        goChatAI = true
                                    }
                                    // reset sélection
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            selectedActionID = nil
                                        }
                                    }
                                } label: {
                                    QuickActionCard(action: action, isSelected: selectedActionID == action.id)
                                        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                .buttonStyle(.plain) // pas de teinte grise

                            } else if action.title == "Find Vet" {
                                // ✅ Navigation programmatique
                                Button {
                                    hapticTap()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedActionID = action.id
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                        goFindVet = true
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

                            } else {
                                // Calendar / Pet Sitter
                                Button {
                                    hapticTap()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedActionID = action.id
                                    }

                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                        if action.title == "Calendar" {
                                            goCalendar = true
                                        } else if action.title == "Pet Sitter" {
                                            goPetSitter = true
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
                            }
                        }
                    }
                    .padding(.horizontal, 18)

                    // Vets
                    Text("Veterinary")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.vetTitle)
                        .padding(.horizontal, 18)
                        .padding(.top, 6)

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
                    .padding(.horizontal, 18)
                    .padding(.bottom, 24)
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
            CalendarView(tabSelection: $tabSelection, useSystemNavBar: true)
                .navigationBarBackButtonHidden(false)
        }
        .navigationDestination(isPresented: $goPetSitter) {
            PetSitterView()
                .navigationBarBackButtonHidden(false)
        }
        .navigationDestination(isPresented: $goJoinVet) {
            JoinVetView()
                .navigationBarBackButtonHidden(false)
        }
        .navigationDestination(isPresented: $goJoinSitter) {
            JoinPetSitterView()
                .navigationBarBackButtonHidden(false)
        }
        .navigationDestination(isPresented: $goAddPet) {
            // ⬅️ Push to your multi-step Add Pet flow
           AddPetFlowView()
               .navigationBarBackButtonHidden(false)
        }
    }

    @ViewBuilder
    private func headerBadge(system: String) -> some View {
        Image(systemName: system)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.vetTitle)
            .frame(width: 34, height: 34)
            .background(Color.vetCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.vetStroke, lineWidth: 1)
            )
            .vetLightShadow()
    }

    private func hapticTap() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}

// MARK: - Components

struct PetCard: View {
    let pet: Pet
    var isSelected: Bool = false

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.vetCanyon.opacity(0.28))
                    .frame(width: 92, height: 92)
                Text(pet.emoji)
                    .font(.system(size: 36))
            }
            VStack(spacing: 2) {
                Text(pet.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.vetTitle)
                Text(pet.breed)
                    .font(.system(size: 13))
                    .foregroundColor(.vetSubtitle)
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.vetCanyon.opacity(0.15) : Color.vetCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isSelected ? Color.vetCanyon : Color.vetStroke, lineWidth: 2)
        )
        .vetShadow(radius: isSelected ? 10 : 4, x: 0, y: isSelected ? 4 : 2)
        .scaleEffect(isSelected ? 1.04 : 1.0)
    }
}

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

struct PetStatusRow: View {
    let pet: Pet

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.vetCanyon.opacity(0.28))
                    .frame(width: 42, height: 42)
                Text(pet.emoji)
                    .font(.system(size: 20))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(pet.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.vetTitle)
                Text("✓ Up-to-date | \(pet.medsCount) med | \(pet.weight)")
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

struct QuickActionCard: View {
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
}

struct VetRow: View {
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
}

// MARK: - Models + Mock

struct Pet: Identifiable {
    let id = UUID()
    let name: String
    let breed: String
    let emoji: String
    let medsCount: Int
    let weight: String
}

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

let petsMock: [Pet] = [
    .init(name: "Max",  breed: "Doberman", emoji: "🐕", medsCount: 1, weight: "2.8kg"),
    .init(name: "Luna", breed: "Siamese",  emoji: "🐈", medsCount: 0, weight: "4.1kg")
]

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

// MARK: - Previews

#Preview("Home – Light") {
    let store: ThemeStore = { let s = ThemeStore(); s.selection = .light; return s }()
    return NavigationStack {
        HomeView(tabSelection: .constant(.pets))
            .environmentObject(store)
            .preferredColorScheme(.light)
    }
}

#Preview("Home – Dark") {
    let store: ThemeStore = { let s = ThemeStore(); s.selection = .dark; return s }()
    return NavigationStack {
        HomeView(tabSelection: .constant(.pets))
            .environmentObject(store)
            .preferredColorScheme(.dark)
    }
}
