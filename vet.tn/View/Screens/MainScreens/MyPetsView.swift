//
//  MyPetsView.swift
//  vet.tn
//
//  View showing the list of pets owned by the user

import SwiftUI

struct MyPetsView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var petViewModel = PetViewModel()
    
    @State private var hasAppeared = false
    
    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    TopBar(title: "My Pets")
                    
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

#Preview("MyPetsView") {
    MyPetsView()
        .environmentObject(SessionManager())
        .environmentObject(ThemeStore())
}

