//
//  ProfileView.swift
//  vet.tn
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var theme: ThemeStore
    @EnvironmentObject private var session: SessionManager
    @StateObject private var petViewModel = PetViewModel()
    
    // Track if this is the first appearance to avoid unnecessary reloads
    @State private var hasAppeared = false
    @State private var showingSettings = false
    @State private var showLogoutConfirmation = false
    @State private var goMessages = false
    @State private var goJoinTeam = false
    @State private var showingEditProfile = false
    
    private var displayName: String {
        session.user?.name?.isEmpty == false ? (session.user?.name ?? "User") : (session.user?.email ?? "User")
    }
    
    private var displayRole: String {
        // Display role based on user's actual role from the server
        guard let role = session.user?.role?.lowercased() else {
            return "Pet Owner"
        }
        
        switch role {
        case "vet", "veterinarian":
            return "Veterinarian"
        case "sitter", "petsitter", "pet sitter":
            return "Pet Sitter"
        case "admin":
            return "Administrator"
        case "owner":
            return "Pet Owner"
        default:
            return "Pet Owner"
        }
    }
    
    private var phoneText: String {
        let trimmed = session.user?.phone?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "—" : trimmed
    }
    
    private var locationText: String {
        let city = session.user?.city?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let country = session.user?.country?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        switch (city.isEmpty, country.isEmpty) {
        case (false, false):
            return "\(city), \(country)"
        case (false, true):
            return city
        case (true, false):
            return country
        default:
            return "—"
        }
    }
    
    private var avatarURL: URL? {
        guard let s = session.user?.avatarUrl, let url = URL(string: s) else { return nil }
        return url
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Top Bar
                    TopBar(
                        title: "Profile",
                        onSettings: {
                            showingSettings = true
                        },
                        onCommunity: {
                            goMessages = true
                        }
                    )
                    
                    VStack(spacing: 24) {
                        // User Profile Section
                        VStack(spacing: 16) {
                            // Profile Image (network if available, else system icon)
                            ZStack {
                                if let url = avatarURL {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(width: 100, height: 100)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .clipShape(Circle())
                                        case .failure:
                                            fallbackAvatar
                                        @unknown default:
                                            fallbackAvatar
                                        }
                                    }
                                } else {
                                    fallbackAvatar
                                }
                            }
                            
                            // User Info
                            VStack(spacing: 4) {
                                Text(displayName)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.vetTitle)
                                
                                Text(displayRole)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.vetSubtitle)
                            }

                            Button {
                                // Explicitly open edit profile
                                session.shouldPresentEditProfile = true
                                showingEditProfile = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "pencil")
                                    Text("Modify Profile")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(Color.vetCardBackground)
                                .foregroundColor(.vetCanyon)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.vetCanyon, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            
                            // Stats
                            HStack(spacing: 40) {
                                VStack(spacing: 4) {
                                    Text("\(petViewModel.pets.count)")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.vetCanyon)
                                    Text("Pets")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.vetSubtitle)
                                }
                                
                                VStack(spacing: 4) {
                                    Text("—")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.vetCanyon)
                                    Text("Appointments")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.vetSubtitle)
                                }
                            }
                        }
                        .padding(.top, 24)
                        
                        // Account Info Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Account Info")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.vetTitle)
                                .padding(.leading, 16)
                            
                            VStack(spacing: 12) {
                                ProfileInfoRow(
                                    title: "Email",
                                    value: session.user?.email ?? "—",
                                    icon: "envelope.fill"
                                )
                                
                                // Keep placeholders for now; replace with real data when available
                                ProfileInfoRow(
                                    title: "Phone",
                                    value: phoneText,
                                    icon: "phone.fill"
                                )
                                
                                ProfileInfoRow(
                                    title: "Location",
                                    value: locationText,
                                    icon: "location.fill"
                                )
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Settings Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Settings")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.vetTitle)
                                .padding(.leading, 16)
                            
                            VStack(spacing: 8) {
                                SettingsRow(
                                    title: "Notifications",
                                    icon: "bell.fill",
                                    iconColor: .yellow
                                )
                                
                                SettingsRow(
                                    title: "Language",
                                    icon: "globe",
                                    iconColor: .blue
                                )
                                
                                SettingsRow(
                                    title: "Privacy",
                                    icon: "lock.fill",
                                    iconColor: .green
                                )
                            }
                            .padding(.horizontal, 16)

                            Button {
                                goJoinTeam = true
                            } label: {
                                Text("JOIN US")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.vetCanyon)
                                    )
                                    .overlay(
                                        HStack {
                                            Image(systemName: "person.2.fill")
                                                .foregroundColor(.white)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 18)
                                    )
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            
                            // Theme Switcher
                            VStack(spacing: 0) {
                                HStack {
                                    HStack(spacing: 12) {
                                        Image(systemName: "paintbrush.fill")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.purple)
                                            .frame(width: 24, height: 24)
                                        
                                        Text("Appearance")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.vetTitle)
                                        
                                        Spacer()
                                    }
                                    
                                    Picker("Theme", selection: $theme.selection) {
                                        HStack {
                                            Image(systemName: "circle.lefthalf.filled")
                                            Text("System")
                                        }
                                        .tag(AppTheme.system)
                                        
                                        HStack {
                                            Image(systemName: "sun.max.fill")
                                            Text("Light")
                                        }
                                        .tag(AppTheme.light)
                                        
                                        HStack {
                                            Image(systemName: "moon.fill")
                                            Text("Dark")
                                        }
                                        .tag(AppTheme.dark)
                                    }
                                    .pickerStyle(.menu)
                                    .tint(.vetCanyon)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.vetCardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.vetStroke.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .padding(.horizontal, 16)
                            
                            // Logout Button
                            Button {
                                showLogoutConfirmation = true
                            } label: {
                                Text("LOG OUT")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.vetCanyon)
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.vetCanyon, lineWidth: 2)
                                    )
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .alert("Are you sure you want to logout?", isPresented: $showLogoutConfirmation) {
                                Button("Cancel", role: .cancel) {
                                    showLogoutConfirmation = false
                                }
                                Button("Yes", role: .destructive) {
                                    Task { await session.logout() }
                                }
                            }
                        }
                        
                        Spacer(minLength: 100) // Space for tab bar
                    }
                }
            }
            .background(Color.vetBackground.ignoresSafeArea())
            .refreshable {
                // Pull-to-refresh support
                guard session.user?.id != nil else { return }
                await petViewModel.loadPets()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsDetailView()
            }
            .sheet(isPresented: $showingEditProfile, onDismiss: {
                showingEditProfile = false
                session.shouldPresentEditProfile = false
            }) {
                EditProfileView()
            }
            .onChange(of: session.shouldPresentEditProfile) { shouldPresent in
                if shouldPresent {
                    showingEditProfile = true
                }
            }
            .onAppear {
                petViewModel.sessionManager = session
                if session.shouldPresentEditProfile {
                    showingEditProfile = true
                }
                
                // Always reload pets when view appears to reflect any changes
                // This ensures pets are loaded even if view was recreated
                if !hasAppeared {
                    hasAppeared = true
                }
                
                Task { @MainActor in
                    guard session.user?.id != nil else { return }
                    // Refresh user data to get latest role and other info
                    await session.refreshUserData()
                    // Force reload to ensure we have the latest data
                    await petViewModel.loadPets()
                }
            }
            .onChange(of: session.user?.role) { oldRole, newRole in
                // If role changed, refresh user data to ensure everything is up to date
                if oldRole != newRole {
                    Task {
                        await session.refreshUserData()
                    }
                }
            }
            .task(id: session.user?.id) {
                // Load pets when user ID changes
                guard session.user?.id != nil else { return }
                await petViewModel.loadPets()
            }
            .onChange(of: session.isAuthenticated) { oldValue, newValue in
                // Only load pets when authentication state changes from false to true
                if !oldValue && newValue {
                    Task {
                        await petViewModel.loadPets()
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Reload when app comes to foreground
                Task {
                    guard session.user?.id != nil else { return }
                    await petViewModel.loadPets()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshProfilePets"))) { _ in
                // Reload when Profile tab is selected
                // Ensure sessionManager is set before loading
                petViewModel.sessionManager = session
                Task { @MainActor in
                    guard session.user?.id != nil else { return }
                    await petViewModel.loadPets()
                }
            }
            // Profile completion prompt: "Complete now" -> open Edit Profile, "Later" -> dismiss
            .alert("Complete your profile", isPresented: Binding(
                get: { session.showProfileCompletionAlert },
                set: { session.showProfileCompletionAlert = $0 }
            )) {
                Button("Later", role: .cancel) {
                    session.showProfileCompletionAlert = false
                    session.shouldPresentEditProfile = false
                }
                Button("Complete now") {
                    session.showProfileCompletionAlert = false
                    session.shouldPresentEditProfile = true
                    showingEditProfile = true
                }
            } message: {
                Text("To get the best experience, please complete your profile now.")
            }
            .navigationDestination(isPresented: $goMessages) {
                ConversationsListView()
            }
            .navigationDestination(isPresented: $goJoinTeam) {
                JoinTeamView()
            }
        }
    }
    
    private var fallbackAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.vetCanyon.opacity(0.2))
                .frame(width: 100, height: 100)
            
            Image(systemName: "person.fill")
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(.vetCanyon)
        }
    }
}

// MARK: - Supporting Views

struct ProfileInfoRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.vetSubtitle)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.vetTitle)
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.vetCanyon)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.vetCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.vetStroke.opacity(0.3), lineWidth: 1)
        )
    }
}

struct PetRow: View {
    let name: String
    let breed: String
    let age: String
    let color: Color
    
    var body: some View {
        HStack {
            // Pet Avatar
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(name.prefix(1)))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(color)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.vetTitle)
                
                Text("\(breed) • \(age)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.vetSubtitle)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.vetSubtitle)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.vetCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.vetStroke.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SettingsRow: View {
    let title: String
    let icon: String
    let iconColor: Color
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.vetTitle)
                
                Spacer()
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.vetSubtitle)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.vetCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.vetStroke.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Settings Detail View

struct SettingsDetailView: View {
    @EnvironmentObject private var theme: ThemeStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Appearance")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.vetTitle)
                        
                        VStack(spacing: 8) {
                            ForEach(AppTheme.allCases, id: \.self) { themeOption in
                                Button {
                                    theme.selection = themeOption
                                } label: {
                                    HStack {
                                        Image(systemName: themeOption.icon)
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.vetCanyon)
                                            .frame(width: 24)
                                        
                                        Text(themeOption.displayName)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.vetTitle)
                                        
                                        Spacer()
                                        
                                        if theme.selection == themeOption {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.vetCanyon)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.vetCardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                theme.selection == themeOption ? Color.vetCanyon : Color.vetStroke.opacity(0.3),
                                                lineWidth: theme.selection == themeOption ? 2 : 1
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer()
                }
                .padding(.top, 24)
            }
            .background(Color.vetBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.vetCanyon)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }
}

// MARK: - AppTheme Extensions

extension AppTheme {
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark:  return "Dark"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }
}

// MARK: - Pet mocks & routing support
// Removed - now using real pets from PetViewModel

// MARK: - Preview

#Preview("ProfileView") {
    ProfileView()
        .environmentObject(ThemeStore())
        .environmentObject(SessionManager())
}

