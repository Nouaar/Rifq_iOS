import SwiftUI
import MapKit

struct MapScreen: View {
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
        .task {
            await viewModel.loadLocations()
        }
        .refreshable {
            await viewModel.loadLocations()
        }
        .sheet(item: $selectedVet) { vet in
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
                        // Map VetLocation to VetProfile and navigate
                        selectedVetProfile = mapToVetProfile(from: vet)
                        selectedVet = nil // Dismiss sheet
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
        .sheet(item: $selectedSitter) { sitter in
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
                        // Map SitterLocation to PetSitter and navigate
                        selectedSitterProfile = mapToPetSitter(from: sitter)
                        selectedSitter = nil // Dismiss sheet
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
        .navigationDestination(item: $selectedVetProfile) { profile in
            VetProfileView(vet: profile, vetUserId: profile.vetUserId)
        }
        .navigationDestination(item: $selectedSitterProfile) { sitter in
            PetSitterProfileView(sitter: sitter, sitterUserId: sitter.userId)
        }
    }
    
    // MARK: - Helper Functions
    
    private func mapToVetProfile(from vetLocation: VetLocation) -> VetProfile {
        let user = vetLocation.appUser
        // Create a VetProfile from the AppUser data
        // Since we don't have all the vet-specific details from AppUser, we'll use defaults
        return VetProfile(
            name: vetLocation.name,
            role: "Veterinary Specialist",
            emoji: "🧑‍⚕️",
            rating: 4.5, // Default rating
            reviews: 0, // Default reviews
            is24_7: false, // Default
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
        // Create a PetSitter from the AppUser data
        return PetSitter(
            id: UUID(),
            displayName: sitterLocation.name,
            emoji: "🧑‍🍼",
            about: "Professional pet sitter with experience caring for various pets.",
            priceAtHome: "Contact for pricing",
            priceVisit: "Contact for pricing",
            rating: 4.7, // Default rating
            reviews: [], // Empty for now
            userId: sitterLocation.userId
        )
    }
    
    // MARK: - Computed Properties
    
    private var allLocations: [MapLocation] {
        var locations: [MapLocation] = []
        locations.append(contentsOf: viewModel.vetLocations.map { MapLocation.vet($0) })
        locations.append(contentsOf: viewModel.sitterLocations.map { MapLocation.sitter($0) })
        return locations
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

#Preview("MapScreen") {
    MapScreen()
        .environmentObject(ThemeStore())
}
