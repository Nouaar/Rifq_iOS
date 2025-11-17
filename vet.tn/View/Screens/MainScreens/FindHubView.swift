//
//  FindHubView.swift
//  vet.tn
//

import SwiftUI

struct FindHubView: View {

    @State private var navigateToVets = false
    @State private var navigateToSitters = false

    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    TopBar(
                        title: "Find Care"
                    )

                    heroCard

                    VStack(spacing: 16) {
                        destinationCard(
                            title: "Find a Vet",
                            subtitle: "Search trusted veterinary clinics near you, view availability and book appointments.",
                            icon: "stethoscope",
                            tint: .vetCanyon
                        ) {
                            navigateToVets = true
                        }

                        destinationCard(
                            title: "Find a Pet Sitter",
                            subtitle: "Browse verified pet sitters, review profiles and arrange stays or daily visits.",
                            icon: "house.fill",
                            tint: .blue
                        ) {
                            navigateToSitters = true
                        }
                    }
                    .padding(.horizontal, 18)

                    insightsSection

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationDestination(isPresented: $navigateToVets) {
            FindVetView()
        }
        .navigationDestination(isPresented: $navigateToSitters) {
            AvailableSittersView()
        }
        .preference(key: TabBarHiddenPreferenceKey.self, value: false)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Find trusted care for every need.")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.vetTitle)

            Text("Discover experienced veterinarians and pet sitters available within your community. Compare profiles, read reviews and stay connected.")
                .font(.system(size: 14))
                .foregroundColor(.vetSubtitle)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.vetCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.vetStroke.opacity(0.35), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            Image(systemName: "location.magnifyingglass")
                .font(.system(size: 36, weight: .semibold))
                .foregroundColor(.vetCanyon)
                .padding()
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
    }

    private func destinationCard(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.18))
                        .frame(width: 54, height: 54)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(tint)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.vetTitle)

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.vetSubtitle)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(tint)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.vetCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.vetStroke.opacity(0.3), lineWidth: 1)
            )
            .vetShadow(radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Care Highlights")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.vetTitle)
                .padding(.horizontal, 18)

            VStack(spacing: 12) {
                insightRow(
                    icon: "star.fill",
                    title: "Top-rated clinics",
                    detail: "Meet the best-reviewed vets near you, curated from community feedback."
                )
                insightRow(
                    icon: "clock.badge.checkmark",
                    title: "Same-day visits",
                    detail: "Filter for professionals available today for urgent care appointments."
                )
                insightRow(
                    icon: "message.fill",
                    title: "Chat first",
                    detail: "Reach out in advance, ask pre-visit questions and share pet histories."
                )
            }
            .padding(.horizontal, 18)
        }
    }

    private func insightRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.vetCanyon)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.vetTitle)
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundColor(.vetSubtitle)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.vetCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.vetStroke.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview("FindHubView") {
    FindHubView()
        .environmentObject(ThemeStore())
}

