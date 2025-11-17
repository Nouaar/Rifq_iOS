import SwiftUI

struct CalendarView: View {
    @Binding var tabSelection: VetTab
    let useSystemNavBar: Bool
    @EnvironmentObject private var theme: ThemeStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.vetBackground.ignoresSafeArea()
            
            VStack(spacing: 20) {
                if !useSystemNavBar {
                    TopBar(
                        title: "Calendar",
                        showBack: true,
                        onBack: { dismiss() }
                    )
                }
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Calendar placeholder
                        VStack(spacing: 16) {
                            Image(systemName: "calendar")
                                .font(.system(size: 60))
                                .foregroundColor(.vetCanyon)
                            
                            Text("Pet Calendar")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.vetTitle)
                            
                            Text("Track appointments, medication schedules, and important dates for your pets")
                                .font(.system(size: 16))
                                .foregroundColor(.vetSubtitle)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding()
                        .background(Color.vetCardBackground)
                        .cornerRadius(16)
                        .vetShadow()
                        .padding(.horizontal)
                        
                        // Quick actions
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2),
                            spacing: 12
                        ) {
                            CalendarActionCard(
                                title: "New Appointment",
                                icon: "plus.circle.fill",
                                color: .vetCanyon
                            )
                            
                            CalendarActionCard(
                                title: "Medication",
                                icon: "pills.fill",
                                color: .blue
                            )
                            
                            CalendarActionCard(
                                title: "Reminders",
                                icon: "bell.fill",
                                color: .orange
                            )
                            
                            CalendarActionCard(
                                title: "History",
                                icon: "clock.fill",
                                color: .purple
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
            }
        }
        .navigationTitle(useSystemNavBar ? "Calendar" : "")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct CalendarActionCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button {
            // Handle action
        } label: {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.vetTitle)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(Color.vetCardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.vetStroke.opacity(0.3), lineWidth: 1)
            )
            .vetLightShadow()
        }
        .buttonStyle(.plain)
    }
}

#Preview("CalendarView - System Nav") {
    NavigationStack {
        CalendarView(tabSelection: .constant(.home), useSystemNavBar: true)
            .environmentObject(ThemeStore())
    }
}

#Preview("CalendarView - Custom Nav") {
    CalendarView(tabSelection: .constant(.home), useSystemNavBar: false)
        .environmentObject(ThemeStore())
}
