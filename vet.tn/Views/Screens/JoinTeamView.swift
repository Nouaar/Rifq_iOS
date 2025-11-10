//
//  JoinTeam.swift
//  vet.tn
//

import SwiftUI

struct JoinTeamView: View {
    // Bind to the app's current tab (same as HomeView)
    @Binding var tabSelection: VetTab

    // Navigation
    @State private var goPetSitter = false
    @State private var goVet       = false

    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    TopBar(title: "Join Our Team")

                    header

                    VStack(spacing: 16) {
                        JoinCard(
                            emoji: "🧑‍🍼",
                            title: "Join as Pet Sitter",
                            blurb: "Offer trusted care for pets near you. Set your availability, receive bookings, and get paid securely through the app.",
                            bullets: [
                                "Flexible schedule",
                                "In-app chat & bookings",
                                "Secure payouts"
                            ],
                            cta: "Become a Pet Sitter",
                            accent: Color.vetCanyon
                        ) { goPetSitter = true }

                        JoinCard(
                            emoji: "🩺",
                            title: "Join as Veterinary",
                            blurb: "Reach pet owners, manage appointments, and grow your clinic with our tools and 24/7 support.",
                            bullets: [
                                "Appointments & reminders",
                                "Clinic profile & reviews",
                                "Dashboard & analytics"
                            ],
                            cta: "Register Clinic",
                            accent: Color.vetCanyon
                        ) { goVet = true }
                    }
                    .padding(.horizontal, 16)

                    Spacer(minLength: 24)
                }
                .padding(.bottom, 24) // content padding above tab bar
            }
        }
        // Keep the global tab bar visible for MainTabView
        .preference(key: TabBarHiddenPreferenceKey.self, value: false)

        // If you want the tab bar to appear even when this view is presented standalone,
        // keep this safeAreaInset. If MainTabView already renders the bar, you can remove it.
        .safeAreaInset(edge: .bottom) {
            VetTabBar(selection: $tabSelection)
                .background(Color.vetBackground)
        }

        // Navigation
        .navigationDestination(isPresented: $goPetSitter) { JoinPetSitterView() }
        .navigationDestination(isPresented: $goVet)       { JoinVetView() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Grow with vet.tn")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color.vetTitle)
            Text("Choose your role to get started.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.vetSubtitle)
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }
}

// MARK: - Card

private struct JoinCard: View {
    let emoji: String
    let title: String
    let blurb: String
    let bullets: [String]
    let cta: String
    let accent: Color
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Text(emoji).font(.system(size: 28))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.vetTitle)
                    Text(blurb)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.vetSubtitle)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(bullets, id: \.self) { b in
                    HStack(spacing: 8) {
                        Circle().fill(accent).frame(width: 6, height: 6)
                        Text(b)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.vetTitle)
                    }
                }
            }

            Button(action: action) {
                Text(cta)
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .foregroundStyle(Color.white)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(accent)
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.vetCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.vetStroke, lineWidth: 1)
        )
        .vetShadow(radius: 8, x: 0, y: 2)
    }
}

// MARK: - Previews

#Preview("Join Team – Light") {
    let store: ThemeStore = { let s = ThemeStore(); s.selection = .light; return s }()
    return NavigationStack {
        JoinTeamView(tabSelection: .constant(.join))
            .environmentObject(store)
            .preferredColorScheme(.light)
    }
}

#Preview("Join Team – Dark") {
    let store: ThemeStore = { let s = ThemeStore(); s.selection = .dark; return s }()
    return NavigationStack {
        JoinTeamView(tabSelection: .constant(.join))
            .environmentObject(store)
            .preferredColorScheme(.dark)
    }
}
