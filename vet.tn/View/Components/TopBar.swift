import SwiftUI

struct TopBar: View {
    let title: String
    var showBack: Bool = false
    var onBack: (() -> Void)? = nil
    var onNotifications: (() -> Void)? = nil
    var onSettings: (() -> Void)? = nil   // (kept in case you still want a custom action)
    var onCommunity: (() -> Void)? = nil

    @EnvironmentObject private var theme: ThemeStore
    @EnvironmentObject private var session: SessionManager
    @StateObject private var chatManager = ChatManager.shared
    @StateObject private var notificationManager = NotificationManager.shared

    @State private var showCommunitySheet = false
    @State private var showNotificationsSheet = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if showBack {
                    Button { onBack?() } label: { headerBadge("chevron.left") }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Back")
                }

                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.vetTitle)

                Spacer()

                HStack(spacing: 10) {
                    // Community button with badge
                    Button {
                        if let onCommunity {
                            onCommunity()
                        } else {
                            showCommunitySheet = true
                        }
                    } label: {
                        headerBadgeWithBadge("person.3.fill", count: chatManager.unreadCount)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Community")
                    
                    Button {
                        if let onNotifications {
                            onNotifications()
                        } else {
                            showNotificationsSheet = true
                        }
                    } label: {
                        headerBadgeWithBadge("bell.fill", count: notificationManager.unreadCount)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Notifications")

                    // Settings menu with theme switch
                    Menu {
                        // Optional: call a custom settings action first
                        if onSettings != nil {
                            Button("Open Settings…") { onSettings?() }
                            Divider()
                        }

                        Picker("Appearance", selection: $theme.selection) {
                            Label("System", systemImage: "circle.lefthalf.filled")
                                .tag(AppTheme.system)
                            Label("Light", systemImage: "sun.max.fill")
                                .tag(AppTheme.light)
                            Label("Dark",  systemImage: "moon.fill")
                                .tag(AppTheme.dark)
                        }
                    } label: {
                        headerBadge("gearshape.fill")
                    }
                    .accessibilityLabel("Appearance")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .background(Color.vetSand)
            .overlay(
                Rectangle()
                    .fill(Color.vetStroke.opacity(0.4))
                    .frame(height: 1),
                alignment: .bottom
            )
        }
        .sheet(isPresented: $showCommunitySheet) {
            NavigationStack {
                CommunityView()
            }
            .environmentObject(theme)
        }
        .sheet(isPresented: $showNotificationsSheet) {
            NavigationStack {
                NotificationsView()
            }
            .environmentObject(theme)
            .environmentObject(session)
            .onAppear {
                // Ensure NotificationManager is initialized with session when sheet opens
                notificationManager.setSessionManager(session)
                notificationManager.startPolling()
            }
        }
    }

    // iOS-style badge
    private func headerBadge(_ system: String) -> some View {
        Image(systemName: system)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.vetTitle)
            .frame(width: 32, height: 32)
            .background(Color.vetCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.vetStroke))
    }
    
    // Badge with notification count
    private func headerBadgeWithBadge(_ system: String, count: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            headerBadge(system)
            
            if count > 0 {
                Text("\(count > 99 ? "99+" : "\(count)")")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, count > 9 ? 4 : 6)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .clipShape(Capsule())
                    .offset(x: 8, y: -8)
            }
        }
    }
}
