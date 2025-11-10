//
//  ProfileView.swift
//  vet.tn
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var theme: ThemeStore
    @EnvironmentObject private var session: SessionManager
    @State private var showingSettings = false
    
    private var displayName: String {
        session.user?.name?.isEmpty == false ? (session.user?.name ?? "User") : (session.user?.email ?? "User")
    }
    
    private var displayRole: String {
        // If you later add role to AppUser, show it here. For now, show a generic label.
        "Pet Owner"
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
                        onNotifications: {
                            // Handle notifications
                        },
                        onSettings: {
                            showingSettings = true
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
                            
                            // Stats (placeholder; hook to real data when available)
                            HStack(spacing: 40) {
                                VStack(spacing: 4) {
                                    Text("—")
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
                                    value: "—",
                                    icon: "phone.fill"
                                )
                                
                                ProfileInfoRow(
                                    title: "Location",
                                    value: "—",
                                    icon: "location.fill"
                                )
                            }
                            .padding(.horizontal, 16)
                        }
                        
                        // My Pets Section (placeholder content kept)
                        VStack(alignment: .leading, spacing: 16) {
                            Text("My Pets")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.vetTitle)
                                .padding(.leading, 16)
                            
                            VStack(spacing: 12) {
                                NavigationLink {
                                    PetProfileView(pet: .mock1)
                                } label: {
                                    PetRow(
                                        name: "Max",
                                        breed: "Doberman",
                                        age: "3 years",
                                        color: .vetCanyon
                                    )
                                }
                                .buttonStyle(.plain)

                                NavigationLink {
                                    PetProfileView(pet: .mock2)
                                } label: {
                                    PetRow(
                                        name: "Luna",
                                        breed: "Siamese",
                                        age: "2 years",
                                        color: .brown
                                    )
                                }
                                .buttonStyle(.plain)
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
                                Task { await session.logout() }
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
                        }
                        
                        Spacer(minLength: 100) // Space for tab bar
                    }
                }
            }
            .background(Color.vetBackground.ignoresSafeArea())
            .sheet(isPresented: $showingSettings) {
                SettingsDetailView()
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

extension Pet {
    static var mock1: Pet { Pet(name: "Max", breed: "Doberman", emoji: "🐕", medsCount: 1, weight: "2.8 kg") }
    static var mock2: Pet { Pet(name: "Luna", breed: "Siamese", emoji: "🐈", medsCount: 0, weight: "4.1 kg") }
}

// MARK: - Preview

#Preview("ProfileView") {
    ProfileView()
        .environmentObject(ThemeStore())
        .environmentObject(SessionManager())
}
