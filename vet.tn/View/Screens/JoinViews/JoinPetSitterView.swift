//
//  JoinPetSitterView.swift
//  vet.tn
//

import SwiftUI
import MapKit
import CoreLocation

struct JoinPetSitterView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager
    
    @State private var goVerify = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    // MARK: - Form state
    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var sitterAddress = ""
    @State private var yearsOfExperience = ""
    @State private var hourlyRate = ""
    @State private var bio = ""

    @State private var selectedServices: Set<SitterService> = []
    @State private var availableWeekends = true
    @State private var canHostPets = false

    // Availability calendar
    @State private var selectedDays: Set<Date> = []   // free days
    @State private var calendarMonthAnchor: Date = Date() // current month shown

    // Map picker
    @State private var showMapPicker = false
    @State private var pickedCoordinate = CLLocationCoordinate2D(latitude: 36.8065, longitude: 10.1815)

    // Auth
    @State private var password = ""
    @State private var confirmPassword = ""

    // Focus
    @FocusState private var focused: Field?
    enum Field: Hashable { case name, email, phone, address, years, rate, bio, password, confirm }

    private var chipColumns: [GridItem] { [GridItem(.adaptive(minimum: 120), spacing: 8)] }

    // MARK: - Validation
    private var isNameValid: Bool { fullName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 }
    private var isEmailValid: Bool {
        let t = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.contains("@") && t.contains(".") && t.count >= 5
    }
    private var isPhoneValid: Bool { phone.filter(\.isNumber).count >= 6 }
    private var isAddressValid: Bool { sitterAddress.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 }
    private var isYearsValid: Bool { Int(yearsOfExperience) != nil && (Int(yearsOfExperience) ?? -1) >= 0 }
    private var isRateValid: Bool {
        if let v = Double(hourlyRate.replacingOccurrences(of: ",", with: ".")) { return v > 0 }
        return false
    }
    private var hasServices: Bool { !selectedServices.isEmpty }
    private var isPasswordValid: Bool { password.count >= 6 }
    private var isConfirmValid: Bool { !confirmPassword.isEmpty && confirmPassword == password }

    private var canSubmit: Bool {
        let baseValid = isNameValid && isEmailValid && isPhoneValid && isAddressValid &&
        isYearsValid && isRateValid && hasServices
        // Availability is optional for now
        
        // If user is logged in (converting), password is not required
        if session.user != nil {
            return baseValid
        }
        
        // For new registration, password is required
        return baseValid && isPasswordValid && isConfirmValid
    }

    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    TopBar(title: "Join as Pet Sitter")

                    header

                    // MARK: - Basic Info
                    sectionTitle("PROFILE")
                        .padding(.horizontal, 16)

                    VStack(spacing: 10) {
                        inputRow(icon: "person.fill") {
                            TextField("Full Name", text: $fullName)
                                .textContentType(.name)
                                .autocorrectionDisabled(true)
                                .foregroundStyle(Color.vetTitle)
                                .focused($focused, equals: .name)
                                .submitLabel(.next)
                                .onSubmit { focused = .email }
                        }
                        .validated(isValid: isNameValid, touched: !fullName.isEmpty)

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

                        // Address + Set on Map
                        HStack(spacing: 10) {
                            Image(systemName: "mappin.and.ellipse").foregroundStyle(Color.vetSubtitle)

                            TextField("Address / City", text: $sitterAddress)
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
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 52)
                        .background(Color.vetInputBackground)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.vetStroke, lineWidth: 1))
                        .cornerRadius(14)
                        .validated(isValid: isAddressValid, touched: !sitterAddress.isEmpty)
                    }
                    .padding(.horizontal, 16)

                    // MARK: - Experience & Rate
                    sectionTitle("EXPERIENCE & RATE")
                        .padding(.horizontal, 16)

                    VStack(spacing: 10) {
                        inputRow(icon: "clock.fill") {
                            TextField("Years of Experience", text: $yearsOfExperience)
                                .keyboardType(.numberPad)
                                .foregroundStyle(Color.vetTitle)
                                .focused($focused, equals: .years)
                                .submitLabel(.next)
                                .onSubmit { focused = .rate }
                                .onChange(of: yearsOfExperience) {
                                    yearsOfExperience = yearsOfExperience.filter(\.isNumber)
                                }
                        }
                        .validated(isValid: isYearsValid, touched: !yearsOfExperience.isEmpty)

                        inputRow(icon: "dollarsign.circle.fill") {
                            TextField("Hourly Rate (TND)", text: $hourlyRate)
                                .keyboardType(.decimalPad)
                                .foregroundStyle(Color.vetTitle)
                                .focused($focused, equals: .rate)
                                .submitLabel(.next)
                                .onSubmit { focused = .bio }
                        }
                        .validated(isValid: isRateValid, touched: !hourlyRate.isEmpty)
                    }
                    .padding(.horizontal, 16)

                    // MARK: - Services
                    sectionTitle("SERVICES")
                        .padding(.horizontal, 16)

                    LazyVGrid(columns: chipColumns, spacing: 8) {
                        ForEach(SitterService.allCases, id: \.self) { service in
                            let isOn = selectedServices.contains(service)
                            Button {
                                if isOn { selectedServices.remove(service) } else { selectedServices.insert(service) }
                            } label: {
                                TagChip(
                                    text: service.title,
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

                    // MARK: - Availability Calendar
                    sectionTitle("AVAILABILITY (FREE DAYS)")
                        .padding(.horizontal, 16)

                    AvailabilityCalendar(
                        monthAnchor: $calendarMonthAnchor,
                        selectedDays: $selectedDays
                    )
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.vetCardBackground)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.vetStroke, lineWidth: 1))
                    .cornerRadius(14)
                    .padding(.horizontal, 16)

                    // MARK: - Options
                    VStack(spacing: 10) {
                        toggleRow(title: "Available on Weekends", isOn: $availableWeekends)
                        toggleRow(title: "Can Host Pets at Home", isOn: $canHostPets)
                    }
                    .padding(.horizontal, 16)

                    // MARK: - Bio
                    sectionTitle("ABOUT YOU")
                        .padding(.horizontal, 16)

                    VStack(spacing: 8) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "text.justify")
                                .foregroundStyle(Color.vetSubtitle)
                                .padding(.top, 8)
                            TextEditor(text: $bio)
                                .frame(minHeight: 110)
                                .foregroundStyle(Color.vetTitle)
                                .padding(8)
                                .background(Color.vetInputBackground)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.vetStroke, lineWidth: 1))
                                .cornerRadius(14)
                                .focused($focused, equals: .bio)
                        }
                    }
                    .padding(.horizontal, 16)

                    // MARK: - Passwords (only for new registrations)
                    if session.user == nil {
                    sectionTitle("ACCOUNT SECURITY")
                        .padding(.horizontal, 16)

                    VStack(spacing: 10) {
                        inputRow(icon: "lock.fill") {
                            SecureOrPlain(placeholder: "Password (min 6)", text: $password, focused: $focused, own: .password)
                        }
                        .validated(isValid: isPasswordValid, touched: !password.isEmpty)

                        inputRow(icon: "checkmark.shield.fill") {
                            SecureOrPlain(placeholder: "Confirm Password", text: $confirmPassword, focused: $focused, own: .confirm)
                        }
                        .validated(isValid: isConfirmValid, touched: !confirmPassword.isEmpty)
                    }
                    .padding(.horizontal, 16)
                    }

                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(.horizontal, 16)
                    }

                    // Submit
                    Button {
                        Task {
                            await submitSitterForm()
                        }
                    } label: {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity, minHeight: 56)
                        } else {
                            Text(session.user != nil ? "CONVERT TO PET SITTER" : "CREATE SITTER ACCOUNT")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity, minHeight: 56)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 18).fill(canSubmit && !isSubmitting ? Color.vetCanyon : Color.vetCanyon.opacity(0.4))
                    )
                    .foregroundStyle(Color.white)
                    .disabled(!canSubmit || isSubmitting)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    Spacer(minLength: 18)
                }
                .padding(.bottom, 24)
            }
        }
        .preference(key: TabBarHiddenPreferenceKey.self, value: false)
        .onAppear {
            // Pre-fill form if user is already logged in
            if let user = session.user {
                if fullName.isEmpty {
                    fullName = user.name ?? ""
                }
                if email.isEmpty {
                    email = user.email
                }
                if phone.isEmpty {
                    phone = user.phone ?? ""
                }
            }
        }
        .navigationDestination(isPresented: $goVerify) {
            EmailVerificationView(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                isFromConversion: true
            )
                .navigationBarBackButtonHidden(false)
        }
        .sheet(isPresented: $showMapPicker) {
            MapPickerSheet(
                initialCoordinate: pickedCoordinate,
                onUseCurrent: { coord in pickedCoordinate = coord },
                onConfirm: { coord in
                    pickedCoordinate = coord
                    reverseGeocode(coord) { address in
                        sitterAddress = address ?? "\(coord.latitude), \(coord.longitude)"
                    }
                }
            )
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Helpers
    
    @MainActor
    private func submitSitterForm() async {
        isSubmitting = true
        errorMessage = nil
        
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.isEmpty ? nil : phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = sitterAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBio = bio.isEmpty ? nil : bio.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let servicesArray = selectedServices.map { $0.rawValue }
        let years = Int(yearsOfExperience) ?? 0
        let rate = Double(hourlyRate.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        
        // Convert selected days to ISO date strings
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let availabilityStrings = selectedDays.map { dateFormatter.string(from: $0) }
        
        let service = VetSitterService.shared
        
        do {
            // Check if user is already logged in
            if let currentUser = session.user {
                // Ensure we have a valid access token (refresh if needed)
                var accessToken = session.tokens?.accessToken
                if accessToken == nil {
                    // Try to refresh tokens
                    await session.refreshTokensIfPossible()
                    accessToken = session.tokens?.accessToken
                }
                
                guard let token = accessToken else {
                    errorMessage = "Please log in again to continue"
                    isSubmitting = false
                    return
                }
                
                // Convert existing user to sitter
                do {
                    let updatedUser = try await service.convertUserToSitter(
                        userId: currentUser.id,
                        hourlyRate: rate,
                        sitterAddress: trimmedAddress,
                        services: servicesArray.isEmpty ? nil : servicesArray,
                        yearsOfExperience: years > 0 ? years : nil,
                        availableWeekends: availableWeekends,
                        canHostPets: canHostPets,
                        availability: availabilityStrings.isEmpty ? nil : availabilityStrings,
                        latitude: pickedCoordinate.latitude,
                        longitude: pickedCoordinate.longitude,
                        bio: trimmedBio,
                        accessToken: token
                    )
                    
                    // Update session
                    session.setUserFromServer(updatedUser)
                    
                    // Always require email verification when converting to sitter
                    // Send verification email and navigate to verification view
                        session.requiresEmailVerification = true
                        session.pendingEmail = trimmedEmail
                    
                    // Send verification email
                    _ = await session.resendVerification(email: trimmedEmail)
                    
                    // Navigate to verification view
                        goVerify = true
                } catch {
                    // If we get a 401, try refreshing token and retry once
                    if case APIClient.APIError.http(let status, _) = error, status == 401 {
                        await session.refreshTokensIfPossible()
                        if let refreshedToken = session.tokens?.accessToken {
                            let updatedUser = try await service.convertUserToSitter(
                                userId: currentUser.id,
                                hourlyRate: rate,
                                sitterAddress: trimmedAddress,
                                services: servicesArray.isEmpty ? nil : servicesArray,
                                yearsOfExperience: years > 0 ? years : nil,
                                availableWeekends: availableWeekends,
                                canHostPets: canHostPets,
                                availability: availabilityStrings.isEmpty ? nil : availabilityStrings,
                                latitude: pickedCoordinate.latitude,
                                longitude: pickedCoordinate.longitude,
                                bio: trimmedBio,
                                accessToken: refreshedToken
                            )
                            
                            // Update session
                            session.setUserFromServer(updatedUser)
                            
                            // Always require email verification when converting to sitter
                            // Send verification email and navigate to verification view
                                session.requiresEmailVerification = true
                                session.pendingEmail = trimmedEmail
                            
                            // Send verification email
                            _ = await session.resendVerification(email: trimmedEmail)
                            
                            // Navigate to verification view
                                goVerify = true
                        } else {
                            throw error
                        }
                    } else {
                        throw error
                    }
                }
            } else {
                // Create new sitter account
                let request = CreateSitterRequest(
                    email: trimmedEmail,
                    name: trimmedName,
                    password: password,
                    phoneNumber: trimmedPhone,
                    hourlyRate: rate,
                    sitterAddress: trimmedAddress,
                    services: servicesArray.isEmpty ? nil : servicesArray,
                    yearsOfExperience: years > 0 ? years : nil,
                    availableWeekends: availableWeekends,
                    canHostPets: canHostPets,
                    availability: availabilityStrings.isEmpty ? nil : availabilityStrings,
                    latitude: pickedCoordinate.latitude,
                    longitude: pickedCoordinate.longitude,
                    bio: trimmedBio
                )
                
                let newUser = try await service.createSitter(request)
                
                // Navigate to email verification
                session.requiresEmailVerification = true
                session.pendingEmail = trimmedEmail
                goVerify = true
            }
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("❌ Failed to register sitter: \(error)")
            #endif
        }
        
        isSubmitting = false
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Care for pets, earn with flexibility.")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.vetTitle)
            Text("Create a trusted sitter profile and start receiving bookings from nearby pet owners.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.vetSubtitle)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
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

    private func toggleRow(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.vetTitle)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
        }
        .padding(12)
        .background(Color.vetCardBackground)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.vetStroke, lineWidth: 1))
        .cornerRadius(12)
    }

    private func reverseGeocode(_ coord: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(CLLocation(latitude: coord.latitude, longitude: coord.longitude)) { placemarks, _ in
            guard let p = placemarks?.first else { return completion(nil) }
            let parts = [p.name, p.locality, p.administrativeArea, p.country].compactMap { $0 }.filter { !$0.isEmpty }
            completion(parts.isEmpty ? nil : parts.joined(separator: ", "))
        }
    }
}

// MARK: - Services

enum SitterService: String, CaseIterable, Hashable {
    case walking, homeVisits, daycare, overnight, grooming, training, vetAssist

    var title: String {
        switch self {
        case .walking:    return "Dog Walking"
        case .homeVisits: return "Home Visits"
        case .daycare:    return "Daycare"
        case .overnight:  return "Overnight"
        case .grooming:   return "Grooming"
        case .training:   return "Training"
        case .vetAssist:  return "Vet Visit Assist"
        }
    }
}

// MARK: - Secure Field

private struct SecureOrPlain: View {
    let placeholder: String
    @Binding var text: String
    let focused: FocusState<JoinPetSitterView.Field?>.Binding
    let own: JoinPetSitterView.Field
    @State private var secure = true

    var body: some View {
        HStack {
            Group {
                if secure { SecureField(placeholder, text: $text) }
                else { TextField(placeholder, text: $text) }
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

// MARK: - Validation overlay

private extension View {
    func validated(isValid: Bool, touched: Bool) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(touched ? (isValid ? Color.green.opacity(0.75) : Color.red.opacity(0.8)) : Color.vetStroke, lineWidth: 1)
        )
    }
}

// MARK: - Availability Calendar

private struct AvailabilityCalendar: View {
    @Binding var monthAnchor: Date
    @Binding var selectedDays: Set<Date>

    private let calendar = Calendar.current
    private let weekdays = Calendar.current.shortWeekdaySymbols // e.g., ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]

    var body: some View {
        VStack(spacing: 10) {
            header

            // Weekday symbols
            HStack {
                ForEach(weekdaySymbolsStartingOnMonday(), id: \.self) { w in
                    Text(w)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.vetSubtitle)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.bottom, 2)

            // Grid of days
            let days = monthDays()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(days, id: \.self) { day in
                    if let day = day {
                        dayCell(for: day)
                    } else {
                        // empty slot
                        Rectangle()
                            .fill(.clear)
                            .frame(height: 36)
                    }
                }
            }

            // Helper row
            HStack(spacing: 10) {
                Circle().fill(Color.vetCanyon).frame(width: 10, height: 10)
                Text("Free day")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.vetSubtitle)
                Spacer()
                Button("Clear") { selectedDays.removeAll() }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.vetCanyon)
            }
            .padding(.top, 4)
        }
        .padding(12)
    }

    private var header: some View {
        HStack {
            Button {
                monthAnchor = calendar.date(byAdding: .month, value: -1, to: monthAnchor) ?? monthAnchor
            } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Text(monthTitle(for: monthAnchor))
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.vetTitle)

            Spacer()

            Button {
                monthAnchor = calendar.date(byAdding: .month, value: 1, to: monthAnchor) ?? monthAnchor
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .foregroundStyle(Color.vetTitle)
    }

    private func dayCell(for date: Date) -> some View {
        let isSelected = selectedDays.contains(date.stripToDay())
        return Button {
            let d = date.stripToDay()
            if isSelected { selectedDays.remove(d) } else { selectedDays.insert(d) }
        } label: {
            VStack(spacing: 0) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity, minHeight: 28, alignment: .center)
                    .foregroundStyle(isSelected ? Color.white : Color.vetTitle)
            }
            .frame(height: 36)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.vetCanyon : Color.vetCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.vetStroke, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func monthTitle(for date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "LLLL yyyy"
        return f.string(from: date).capitalized
    }

    private func weekdaySymbolsStartingOnMonday() -> [String] {
        // Reorder symbols so Monday is first
        var symbols = weekdays
        // Calendar.shortWeekdaySymbols usually starts on Sunday; rotate
        if let sundayIndex = symbols.firstIndex(of: symbols.first ?? "") {
            // Move first (Sunday) to end to start Monday
            let first = symbols.remove(at: sundayIndex)
            symbols.append(first)
        }
        return symbols
    }

    private func monthDays() -> [Date?] {
        // Build an array representing the visible grid
        let comps = calendar.dateComponents([.year, .month], from: monthAnchor)
        guard let firstOfMonth = calendar.date(from: comps) else { return [] }

        let range = calendar.range(of: .day, in: .month, for: firstOfMonth) ?? 1..<1
        let daysInMonth = range.count

        // Determine the weekday index for the first day (1 = Sunday ... 7 = Saturday)
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)

        // We want Monday-based grid; compute leading blanks accordingly
        // Convert to 0..6 where 0 is Monday
        // Sunday(1) -> 6 leading blanks; Monday(2) -> 0 leading blanks ...
        let leading: Int = (firstWeekday == 1) ? 6 : (firstWeekday - 2)

        var result: [Date?] = Array(repeating: nil, count: max(leading, 0))

        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                result.append(date)
            }
        }
        return result
    }
}

// MARK: - Date helper

private extension Date {
    func stripToDay() -> Date {
        Calendar.current.startOfDay(for: self)
    }
}

// MARK: - Previews

#Preview("Join Pet Sitter – Light") {
    let store: ThemeStore = { let s = ThemeStore(); s.selection = .light; return s }()
    return NavigationStack {
        JoinPetSitterView()
            .environmentObject(store)
            .preferredColorScheme(.light)
    }
}

#Preview("Join Pet Sitter – Dark") {
    let store: ThemeStore = { let s = ThemeStore(); s.selection = .dark; return s }()
    return NavigationStack {
        JoinPetSitterView()
            .environmentObject(store)
            .preferredColorScheme(.dark)
    }
}
