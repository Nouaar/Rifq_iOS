//
//  MainTabView.swift
//  vet.tn
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var themeStore = ThemeStore()
    @State private var tab: VetTab = .home
    @State private var hideTabBar = false
    @State private var showProfileAlert = false

    var body: some View {
        NavigationStack {                
            ZStack(alignment: .bottom) {

                Group {
                    switch tab {
                    case .home:
                        HomeView(tabSelection: $tab)     
                    case .find:
                        FindHubView()
                    case .ai:
                        ChatAIView(tabSelection: $tab)
                    case .store:
                        MapScreen()
                    case .profile:
                        ProfileView()
                    }
                }
                .transition(.opacity.combined(with: .scale))
                .animation(.easeInOut(duration: 0.25), value: tab)
                .onPreferenceChange(TabBarHiddenPreferenceKey.self) { hideTabBar = $0 }
                .onChange(of: tab) { oldTab, newTab in
                    // When switching to Profile tab, trigger a refresh notification
                    // Small delay to ensure ProfileView is ready
                    if newTab == .profile {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            NotificationCenter.default.post(name: NSNotification.Name("RefreshProfilePets"), object: nil)
                        }
                    }
                }

                if !hideTabBar {
                    VetTabBar(selection: $tab)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.2), value: hideTabBar)
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .background(Color.vetBackground.ignoresSafeArea())
        }
        .environmentObject(themeStore)
        .preferredColorScheme(themeStore.preferred)
        .onAppear {
            if session.requiresProfileCompletion {
                tab = .profile
                showProfileAlert = true
            }
        }
        .onChange(of: session.requiresProfileCompletion) { needs in
            if needs {
                tab = .profile
                showProfileAlert = true
            } else {
                showProfileAlert = false
            }
        }
        .alert("Complete your profile to start", isPresented: $showProfileAlert) {
            Button("Complete Now") {
                tab = .profile
                session.shouldPresentEditProfile = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    tab = .profile
                    session.shouldPresentEditProfile = true
                }
            }
            Button("Later", role: .cancel) {
                showProfileAlert = false
            }
        } message: {
            Text("Add your photo, phone number, and location to unlock all features.")
        }
    }
}
