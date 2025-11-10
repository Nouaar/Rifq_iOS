import SwiftUI

/// A preview helper to test both light and dark themes side by side
struct ThemeTestView: View {
    var body: some View {
        HStack(spacing: 0) {
            // Light Mode
            VStack {
                Text("Light Mode")
                    .font(.headline)
                    .padding()
                
                DemoContent()
                    .environmentObject(ThemeStore().applying(.light))
                    .preferredColorScheme(.light)
            }
            
            Divider()
            
            // Dark Mode  
            VStack {
                Text("Dark Mode")
                    .font(.headline)
                    .padding()
                
                DemoContent()
                    .environmentObject(ThemeStore().applying(.dark))
                    .preferredColorScheme(.dark)
            }
        }
    }
}

struct DemoContent: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Demo Card
                VStack(alignment: .leading, spacing: 8) {
                    Text("Demo Card")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.vetTitle)
                    
                    Text("This shows dynamic colors in action")
                        .font(.system(size: 14))
                        .foregroundColor(.vetSubtitle)
                }
                .padding()
                .background(Color.vetCardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.vetStroke.opacity(0.3), lineWidth: 1)
                )
                .vetShadow()
                
                // Outline Button
                Button("Outline Button") {}
                    .buttonStyle(VetOutlineButtonStyle())
                
                // Primary Button
                Button("Primary Button") {}
                    .buttonStyle(PrimaryButtonStyle())
            }
            .padding()
        }
        .background(Color.vetBackground.ignoresSafeArea())
    }
}

// Helper extension for the preview
extension ThemeStore {
    func applying(_ theme: AppTheme) -> ThemeStore {
        let store = ThemeStore()
        store.selection = theme
        return store
    }
}

#Preview("Theme Test") {
    ThemeTestView()
}