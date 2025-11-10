//
//  JoinVetView.swift
//  vet.tn
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

struct JoinVetView: View {
    @Environment(\.dismiss) private var dismiss

    // MARK: - Form state
    @State private var fullName = ""
    @State private var licenseNumber = ""
    @State private var clinicName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var clinicAddress = ""
    @State private var yearsOfExperience = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var selectedSpecs: Set<VetSpecialty> = []

    // Map picker state
    @State private var showMapPicker = false
    @State private var pickedCoordinate = CLLocationCoordinate2D(latitude: 36.8065, longitude: 10.1815) // Tunis
    @State private var isGeocoding = false

    // Navigation
    @State private var goVerify = false

    // Focus
    @FocusState private var focused: Field?
    enum Field: Hashable { case fullName, license, clinicName, email, phone, address, years, password, confirm }

    // SPECIALIZATIONS grid layout
    private var chipColumns: [GridItem] { [GridItem(.adaptive(minimum: 110), spacing: 8)] }

    // MARK: - Validation
    private var isNameValid: Bool { fullName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 }
    private var isLicenseValid: Bool { licenseNumber.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 }
    private var isClinicValid: Bool { clinicName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 }
    private var isEmailValid: Bool {
        let t = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.contains("@") && t.contains(".") && t.count >= 5
    }
    private var isPhoneValid: Bool { phone.filter(\.isNumber).count >= 6 }
    private var isAddressValid: Bool { clinicAddress.trimmingCharacters(in: .whitespacesAndNewlines).count >= 5 }
    private var isYearsValid: Bool { Int(yearsOfExperience) != nil && (Int(yearsOfExperience) ?? 0) >= 0 }
    private var isPasswordValid: Bool { password.count >= 6 }
    private var isConfirmValid: Bool { !confirmPassword.isEmpty && confirmPassword == password }
    private var hasSpecs: Bool { !selectedSpecs.isEmpty }

    private var canSubmit: Bool {
        isNameValid && isLicenseValid && isClinicValid &&
        isEmailValid && isPhoneValid && isAddressValid &&
        isYearsValid && isPasswordValid && isConfirmValid && hasSpecs
    }

    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {

                    TopBar(title: "Join Our Team")

                    // Hero / benefits
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("🙋‍♂️")
                                .font(.system(size: 28))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Join Our Team")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.vetTitle)
                                Text("Become a Veterinarian Partner")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.vetSubtitle)
                            }
                            Spacer()
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Why join vet.tn?")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.vetTitle)
                            benefitRow("Reach thousands of pet owners")
                            benefitRow("Manage appointments easily")
                            benefitRow("Grow your practice")
                            benefitRow("Secure payments")
                            benefitRow("24/7 Support")
                        }
                        .padding(12)
                        .background(Color.vetCardBackground)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.vetStroke, lineWidth: 1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)

                    sectionTitle("REGISTRATION FORM")
                        .padding(.horizontal, 16)

                    // Form fields
                    VStack(spacing: 10) {
                        inputRow(icon: "person.fill") {
                            TextField("Full Name", text: $fullName)
                                .foregroundStyle(Color.vetTitle)
                                .textContentType(.name)
                                .autocorrectionDisabled(true)
                                .focused($focused, equals: .fullName)
                                .submitLabel(.next)
                                .onSubmit { focused = .license }
                        }
                        .validated(isValid: isNameValid, touched: !fullName.isEmpty)

                        inputRow(icon: "number.square.fill") {
                            TextField("License Number", text: $licenseNumber)
                                .foregroundStyle(Color.vetTitle)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .focused($focused, equals: .license)
                                .submitLabel(.next)
                                .onSubmit { focused = .clinicName }
                        }
                        .validated(isValid: isLicenseValid, touched: !licenseNumber.isEmpty)

                        inputRow(icon: "building.2.fill") {
                            TextField("Clinic Name", text: $clinicName)
                                .foregroundStyle(Color.vetTitle)
                                .autocorrectionDisabled(true)
                                .focused($focused, equals: .clinicName)
                                .submitLabel(.next)
                                .onSubmit { focused = .email }
                        }
                        .validated(isValid: isClinicValid, touched: !clinicName.isEmpty)

                        inputRow(icon: "envelope.fill") {
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .textContentType(.emailAddress)
                                .foregroundStyle(Color.vetTitle)
                                .focused($focused, equals: .email)
                                .submitLabel(.next)
                                .onSubmit { focused = .phone }
                        }
                        .validated(isValid: isEmailValid, touched: !email.isEmpty)

                        inputRow(icon: "phone.fill") {
                            TextField("Phone", text: $phone)
                                .keyboardType(.numberPad)
                                .textContentType(.telephoneNumber)
                                .foregroundStyle(Color.vetTitle)
                                .focused($focused, equals: .phone)
                                .submitLabel(.next)
                                .onSubmit { focused = .address }
                                .onChange(of: phone) { phone = phone.filter(\.isNumber) }
                        }
                        .validated(isValid: isPhoneValid, touched: !phone.isEmpty)

                        // Clinic Address with "Set on map"
                        HStack(spacing: 10) {
                            Image(systemName: "mappin.and.ellipse").foregroundStyle(Color.vetSubtitle)

                            TextField("Clinic Address", text: $clinicAddress)
                                .foregroundStyle(Color.vetTitle)
                                .focused($focused, equals: .address)
                                .submitLabel(.next)
                                .onSubmit { focused = .years }

                            Button {
                                focused = nil
                                showMapPicker = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "location.fill")
                                    Text("Set on map")
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color.vetCardBackground)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.vetStroke, lineWidth: 1))
                                .cornerRadius(8)
                                .foregroundStyle(Color.vetTitle)
                            }
                            .accessibilityLabel("Set address on map")
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 52)
                        .background(Color.vetInputBackground)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.vetStroke, lineWidth: 1))
                        .cornerRadius(14)
                        .validated(isValid: isAddressValid, touched: !clinicAddress.isEmpty)

                        inputRow(icon: "clock.fill") {
                            TextField("Years of Experience", text: $yearsOfExperience)
                                .keyboardType(.numberPad)
                                .foregroundStyle(Color.vetTitle)
                                .focused($focused, equals: .years)
                                .submitLabel(.next)
                                .onSubmit { focused = .password }
                                .onChange(of: yearsOfExperience) {
                                    yearsOfExperience = yearsOfExperience.filter(\.isNumber)
                                }
                        }
                        .validated(isValid: isYearsValid, touched: !yearsOfExperience.isEmpty)
                    }
                    .padding(.horizontal, 16)

                    // MARK: - SPECIALIZATIONS
                    sectionTitle("SPECIALIZATIONS")
                        .padding(.horizontal, 16)

                    LazyVGrid(columns: chipColumns, spacing: 8) {
                        ForEach(VetSpecialty.allCases, id: \.self) { spec in
                            let isOn = selectedSpecs.contains(spec)
                            Button {
                                if isOn { selectedSpecs.remove(spec) } else { selectedSpecs.insert(spec) }
                            } label: {
                                TagChip(
                                    text: spec.title,
                                    isSelected: isOn,
                                    selectedBG: Color.vetCanyon.opacity(0.18),
                                    selectedFG: Color.vetCanyon,
                                    normalBG: Color.vetCardBackground,
                                    normalFG: Color.vetTitle
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 2)

                    // Passwords
                    VStack(spacing: 10) {
                        inputRow(icon: "lock.fill") {
                            SecureOrPlainField(
                                placeholder: "Password (min 6)",
                                text: $password,
                                focused: $focused,
                                own: .password
                            )
                        }
                        .validated(isValid: isPasswordValid, touched: !password.isEmpty)

                        inputRow(icon: "checkmark.shield.fill") {
                            SecureOrPlainField(
                                placeholder: "Confirm Password",
                                text: $confirmPassword,
                                focused: $focused,
                                own: .confirm
                            )
                        }
                        .validated(isValid: isConfirmValid, touched: !confirmPassword.isEmpty)
                    }
                    .padding(.horizontal, 16)

                    // Submit
                    Button {
                        // TODO: call backend to create vet account
                        goVerify = true
                    } label: {
                        Text("REGISTER CLINIC")
                            .font(.system(size: 16, weight: .bold))
                            .kerning(0.8)
                            .frame(maxWidth: .infinity, minHeight: 56)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(canSubmit ? Color.vetCanyon : Color.vetCanyon.opacity(0.4))
                    )
                    .foregroundStyle(Color.white)
                    .disabled(!canSubmit)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    Spacer(minLength: 18)
                }
                .padding(.bottom, 24)
            }
        }
        // Keep bottom tab bar visible in your MainTabView setup (if you use the preference key pattern)
        .preference(key: TabBarHiddenPreferenceKey.self, value: false)
        .navigationDestination(isPresented: $goVerify) {
            EmailVerificationView(email: email.trimmingCharacters(in: .whitespacesAndNewlines))
                .navigationBarBackButtonHidden(false)
        }
        // Map picker sheet
        .sheet(isPresented: $showMapPicker) {
            MapPickerSheet(
                initialCoordinate: pickedCoordinate,
                onUseCurrent: { coord in
                    pickedCoordinate = coord
                },
                onConfirm: { coord in
                    pickedCoordinate = coord
                    geocodeCoordinate(coord) { address in
                        clinicAddress = address ?? "\(coord.latitude), \(coord.longitude)"
                    }
                }
            )
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Helpers

    private func geocodeCoordinate(_ coord: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        isGeocoding = true
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(CLLocation(latitude: coord.latitude, longitude: coord.longitude)) { placemarks, _ in
            isGeocoding = false
            guard let p = placemarks?.first else { return completion(nil) }
            let parts = [p.name, p.locality, p.administrativeArea, p.country]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
            completion(parts.isEmpty ? nil : parts.joined(separator: ", "))
        }
    }

    private func benefitRow(_ text: String) -> some View {
        HStack(spacing: 8) {
            Text("•").foregroundStyle(Color.vetSubtitle)
            Text(text).foregroundStyle(Color.vetTitle).font(.system(size: 13))
            Spacer()
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(Color.vetSubtitle)
    }

    private func inputRow<Content: View>(icon: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(Color.vetSubtitle)
            content()
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(Color.vetInputBackground)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.vetStroke, lineWidth: 1))
        .cornerRadius(14)
    }
}

// MARK: - Specialty & Tag chip

enum VetSpecialty: String, CaseIterable, Hashable {
    case general, surgery, dermatology, emergency, dental, cardiology, radiology

    var title: String {
        switch self {
        case .general:      return "General"
        case .surgery:      return "Surgery"
        case .dermatology:  return "Dermatology"
        case .emergency:    return "Emergency"
        case .dental:       return "Dental"
        case .cardiology:   return "Cardiology"
        case .radiology:    return "Radiology"
        }
    }
}

struct TagChip: View {
    let text: String
    let isSelected: Bool
    let selectedBG: Color
    let selectedFG: Color
    let normalBG: Color
    let normalFG: Color

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(isSelected ? selectedBG : normalBG)
            .foregroundStyle(isSelected ? selectedFG : normalFG)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? selectedFG : Color.vetStroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .contentShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Secure field with eye toggle (accepts FocusState binding)

private struct SecureOrPlainField: View {
    let placeholder: String
    @Binding var text: String

    // Accept FocusState binding from parent
    let focused: FocusState<JoinVetView.Field?>.Binding
    let own: JoinVetView.Field

    @State private var secure = true

    var body: some View {
        HStack {
            Group {
                if secure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .foregroundStyle(Color.vetTitle)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .focused(focused, equals: own)
            .submitLabel(own == .password ? .next : .done)

            Button { secure.toggle() } label: {
                Image(systemName: secure ? "eye.slash" : "eye")
                    .foregroundStyle(Color.vetSubtitle)
            }
        }
    }
}

// MARK: - Map Picker Sheet (region-based; works on iOS 14+)

struct MapPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var region: MKCoordinateRegion
    @State private var userTracking: MapUserTrackingMode = .none
    @StateObject private var loc = LocationHelper()

    let onUseCurrent: (CLLocationCoordinate2D) -> Void
    let onConfirm: (CLLocationCoordinate2D) -> Void

    private var centerCoordinate: CLLocationCoordinate2D {
        region.center
    }

    init(
        initialCoordinate: CLLocationCoordinate2D,
        onUseCurrent: @escaping (CLLocationCoordinate2D) -> Void,
        onConfirm: @escaping (CLLocationCoordinate2D) -> Void
    ) {
        let reg = MKCoordinateRegion(
            center: initialCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        _region = State(initialValue: reg)
        self.onUseCurrent = onUseCurrent
        self.onConfirm = onConfirm
    }

    var body: some View {
        ZStack {
            Map(
                coordinateRegion: $region,
                interactionModes: .all,
                showsUserLocation: true,
                userTrackingMode: $userTracking
            )
            .ignoresSafeArea(.container, edges: .bottom)

            // Center pin
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 36))
                .shadow(radius: 2)
                .foregroundStyle(Color.vetCanyon)

            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding([.top, .horizontal], 16)

                Spacer()

                // Bottom action bar
                HStack(spacing: 10) {
                    Button {
                        loc.requestOnce { location in
                            guard let l = location else { return }
                            withAnimation(.easeInOut) {
                                region = MKCoordinateRegion(
                                    center: l.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
                                )
                            }
                            onUseCurrent(l.coordinate)
                        }
                    } label: {
                        Label("Use current", systemImage: "location.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.vetCardBackground)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.vetStroke, lineWidth: 1))
                            .cornerRadius(10)
                            .foregroundStyle(Color.vetTitle)
                    }

                    Spacer()

                    Button {
                        onConfirm(centerCoordinate)
                        dismiss()
                    } label: {
                        Text("Use this location")
                            .font(.system(size: 15, weight: .bold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.vetCanyon))
                            .foregroundStyle(Color.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }
}

// MARK: - Location helper (one-shot permission + current coord)

final class LocationHelper: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var completion: ((CLLocation?) -> Void)?

    func requestOnce(_ completion: @escaping (CLLocation?) -> Void) {
        self.completion = completion
        manager.delegate = self
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            completion(nil); self.completion = nil
        default:
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        } else if status == .denied || status == .restricted {
            completion?(nil); completion = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        completion?(locations.first)
        completion = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        completion?(nil)
        completion = nil
    }
}

// MARK: - Validation overlay helper

private extension View {
    func validated(isValid: Bool, touched: Bool) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(touched ? (isValid ? Color.green.opacity(0.75) : Color.red.opacity(0.8)) : Color.vetStroke, lineWidth: 1)
        )
    }
}

// MARK: - Previews

#Preview("Join Vet – Light") {
    let store: ThemeStore = { let s = ThemeStore(); s.selection = .light; return s }()
    return NavigationStack {
        JoinVetView()
            .environmentObject(store)
            .preferredColorScheme(.light)
    }
}

#Preview("Join Vet – Dark") {
    let store: ThemeStore = { let s = ThemeStore(); s.selection = .dark; return s }()
    return NavigationStack {
        JoinVetView()
            .environmentObject(store)
            .preferredColorScheme(.dark)
    }
}
