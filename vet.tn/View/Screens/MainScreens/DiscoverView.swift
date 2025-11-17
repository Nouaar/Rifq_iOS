//
//  DiscoverView.swift
//  vet.tn
//
//  Combined view that allows switching between list (Find Care) and map views

import SwiftUI
import MapKit

enum DiscoverMode: String, CaseIterable {
    case list = "Find Care"
    case map = "Map"
}

struct DiscoverView: View {
    @State private var mode: DiscoverMode = .list
    @State private var navigateToVets = false
    @State private var navigateToSitters = false
    
    // Map state
    @StateObject private var viewModel = MapViewModel()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 36.8065, longitude: 10.1815),
        span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
    )
    @State private var selectedVet: VetLocation?
    @State private var selectedSitter: SitterLocation?
    @State private var selectedVetProfile: VetProfile?
    @State private var selectedSitterProfile: PetSitter?

    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar with mode selector
                VStack(spacing: 0) {
                    TopBar(title: "Discover")
                    
                    // Mode selector
                    Picker("Mode", selection: $mode) {
                        ForEach(DiscoverMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 12)
                }
                .background(Color.vetBackground)
                
                // Content based on selected mode
                Group {
                    if mode == .list {
                        listView
                    } else {
                        mapView
                    }
                }
            }
        }
        .navigationDestination(isPresented: $navigateToVets) {
            FindVetView()
        }
        .navigationDestination(isPresented: $navigateToSitters) {
            AvailableSittersView()
        }
        .navigationDestination(item: $selectedVetProfile) { profile in
            VetProfileView(vet: profile, vetUserId: profile.vetUserId)
        }
        .navigationDestination(item: $selectedSitterProfile) { sitter in
            PetSitterProfileView(sitter: sitter, sitterUserId: sitter.userId)
        }
        .sheet(item: $selectedVet) { vet in
            vetSheetContent(vet: vet)
        }
        .sheet(item: $selectedSitter) { sitter in
            sitterSheetContent(sitter: sitter)
        }
        .task {
            if mode == .map {
                await viewModel.loadLocations()
            }
        }
        .onChange(of: mode) { oldMode, newMode in
            if newMode == .map {
                Task {
                    await viewModel.loadLocations()
                }
            }
        }
        .refreshable {
            if mode == .map {
                await viewModel.loadLocations()
            }
        }
        .preference(key: TabBarHiddenPreferenceKey.self, value: false)
    }
    
    // MARK: - List View (Find Care)
    
    private var listView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
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
    
    // MARK: - Map View
    
    private var mapView: some View {
        ZStack(alignment: .topLeading) {
            Map(
                coordinateRegion: $region,
                interactionModes: [.all],
                annotationItems: allLocations
            ) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    VStack(spacing: 6) {
                        Text(location.name)
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.thinMaterial)
                            .clipShape(Capsule())
                        
                        Button {
                            switch location {
                            case .vet(let vet):
                                selectedVet = vet
                            case .sitter(let sitter):
                                selectedSitter = sitter
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(location.isAvailable ? (location.isVet ? Color.vetCanyon : Color.blue) : Color.gray)
                                    .frame(width: 30, height: 30)
                                
                                Image(systemName: location.isVet ? "cross.fill" : "pawprint.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .ignoresSafeArea()
            .overlay(alignment: .topTrailing) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(Circle())
                        .padding(.trailing, 16)
                        .padding(.top, 20)
                }
            }
            
            legend
                .padding(.leading, 16)
                .padding(.top, 20)
        }
    }
    
    private var legend: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Available vet", systemImage: "circle.fill")
                .foregroundStyle(Color.vetCanyon)
            Label("Available sitter", systemImage: "circle.fill")
                .foregroundStyle(Color.blue)
            Label("Offline", systemImage: "circle.fill")
                .foregroundStyle(Color.gray)
        }
        .font(.system(size: 12, weight: .semibold))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
    }
    
    private var allLocations: [MapLocation] {
        var locations: [MapLocation] = []
        locations.append(contentsOf: viewModel.vetLocations.map { MapLocation.vet($0) })
        locations.append(contentsOf: viewModel.sitterLocations.map { MapLocation.sitter($0) })
        return locations
    }
    
    // MARK: - Sheet Content
    
    private func vetSheetContent(vet: VetLocation) -> some View {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.vetStroke.opacity(0.4))
                .frame(width: 42, height: 4)
                .padding(.top, 12)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(vet.name)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Spacer()
                    availabilityBadge(isAvailable: vet.isAvailable)
                }
                
                Text(vet.address)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.vetSubtitle)
                
                Divider().padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("General consultation · Vaccinations", systemImage: "stethoscope")
                    Label("Emergency availability 9am – 6pm", systemImage: "clock")
                    Label("Call +216 55 123 456", systemImage: "phone.fill")
                }
                .font(.system(size: 13))
                .foregroundStyle(Color.vetTitle)
                
                Button {
                    selectedVetProfile = mapToVetProfile(from: vet)
                    selectedVet = nil
                } label: {
                    Text("View Profile")
                        .font(.system(size: 15, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.vetCanyon)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .presentationDetents([.fraction(0.35), .fraction(0.55)])
        .presentationDragIndicator(.hidden)
    }
    
    private func sitterSheetContent(sitter: SitterLocation) -> some View {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.vetStroke.opacity(0.4))
                .frame(width: 42, height: 4)
                .padding(.top, 12)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(sitter.name)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Spacer()
                    availabilityBadge(isAvailable: sitter.isAvailable)
                }
                
                Text(sitter.address)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.vetSubtitle)
                
                Divider().padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("Pet Sitter Services", systemImage: "pawprint.fill")
                    Label("Available for bookings", systemImage: "calendar")
                }
                .font(.system(size: 13))
                .foregroundStyle(Color.vetTitle)
                
                Button {
                    selectedSitterProfile = mapToPetSitter(from: sitter)
                    selectedSitter = nil
                } label: {
                    Text("View Profile")
                        .font(.system(size: 15, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .presentationDetents([.fraction(0.35), .fraction(0.55)])
        .presentationDragIndicator(.hidden)
    }
    
    private func availabilityBadge(isAvailable: Bool) -> some View {
        Text(isAvailable ? "Available" : "Offline")
            .font(.system(size: 12, weight: .bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isAvailable ? Color.vetCanyon.opacity(0.15) : Color.gray.opacity(0.18))
            )
            .foregroundStyle(isAvailable ? Color.vetCanyon : Color.gray)
    }
    
    // MARK: - Helper Functions
    
    private func mapToVetProfile(from vetLocation: VetLocation) -> VetProfile {
        let user = vetLocation.appUser
        return VetProfile(
            name: vetLocation.name,
            role: "Veterinary Specialist",
            emoji: "🧑‍⚕️",
            rating: 4.5,
            reviews: 0,
            is24_7: false,
            about: user.role?.lowercased() == "vet" ? "Experienced veterinarian offering high-quality medical services for your pets." : "Professional veterinary services.",
            services: [
                .init(label: "Cabinet", price: "Contact for pricing"),
                .init(label: "Home Visit", price: "Contact for pricing"),
                .init(label: "Video Call", price: "Contact for pricing")
            ],
            hours: [
                "Mon–Sat: 9:00 AM – 6:00 PM",
                "Sun: 10:00 AM – 4:00 PM"
            ],
            vetUserId: vetLocation.userId
        )
    }
    
    private func mapToPetSitter(from sitterLocation: SitterLocation) -> PetSitter {
        let user = sitterLocation.appUser
        return PetSitter(
            id: UUID(),
            displayName: sitterLocation.name,
            emoji: "🧑‍🍼",
            about: "Professional pet sitter with experience caring for various pets.",
            priceAtHome: "Contact for pricing",
            priceVisit: "Contact for pricing",
            rating: 4.7,
            reviews: [],
            userId: sitterLocation.userId
        )
    }
}

// MARK: - Map Location Enum

private enum MapLocation: Identifiable {
    case vet(VetLocation)
    case sitter(SitterLocation)
    
    var id: String {
        switch self {
        case .vet(let vet): return vet.id
        case .sitter(let sitter): return sitter.id
        }
    }
    
    var name: String {
        switch self {
        case .vet(let vet): return vet.name
        case .sitter(let sitter): return sitter.name
        }
    }
    
    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .vet(let vet): return vet.coordinate
        case .sitter(let sitter): return sitter.coordinate
        }
    }
    
    var address: String {
        switch self {
        case .vet(let vet): return vet.address
        case .sitter(let sitter): return sitter.address
        }
    }
    
    var isAvailable: Bool {
        switch self {
        case .vet(let vet): return vet.isAvailable
        case .sitter(let sitter): return sitter.isAvailable
        }
    }
    
    var isVet: Bool {
        switch self {
        case .vet: return true
        case .sitter: return false
        }
    }
}

#Preview("DiscoverView") {
    DiscoverView()
        .environmentObject(ThemeStore())
}

