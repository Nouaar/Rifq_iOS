//
//  MainTabView.swift
//  vet.tn
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var themeStore = ThemeStore()
    @State private var tab: VetTab = .pets
    @State private var hideTabBar = false

    var body: some View {
        NavigationStack {                
            ZStack(alignment: .bottom) {

                Group {
                    switch tab {
                    case .pets:
                        HomeView(tabSelection: $tab)     
                    case .clinic:
                        MapScreen()
                    case .join:
                        JoinTeamView(tabSelection: $tab)
                            .preference(key: TabBarHiddenPreferenceKey.self, value: true)
                    case .profile:
                        ProfileView()
                    }
                }
                .transition(.opacity.combined(with: .scale))
                .animation(.easeInOut(duration: 0.25), value: tab)
                .onPreferenceChange(TabBarHiddenPreferenceKey.self) { hideTabBar = $0 }

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
    }
}
