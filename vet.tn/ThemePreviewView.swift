import SwiftUI

struct ThemePreviewView: View {
    @StateObject private var lightTheme = ThemeStore()
    @StateObject private var darkTheme = ThemeStore()
    
    var body: some View {
        HStack(spacing: 0) {
            // Light Mode Preview
            VStack {
                Text("Light Mode")
                    .font(.headline)
                    .padding()
                
                PreviewContent()
                    .environmentObject(lightTheme)
                    .preferredColorScheme(.light)
            }
            .onAppear {
                lightTheme.selection = .light
            }
            
            Divider()
            
            // Dark Mode Preview
            VStack {
                Text("Dark Mode")
                    .font(.headline)
                    .padding()
                
                PreviewContent()
                    .environmentObject(darkTheme)
                    .preferredColorScheme(.dark)
            }
            .onAppear {
                darkTheme.selection = .dark
            }
        }
    }
}

struct PreviewContent: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Sample TopBar
                TopBar(title: "Preview")
                
                VStack(spacing: 12) {
                    // Sample Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sample Card")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.vetTitle)
                        
                        Text("This shows how cards look in different themes")
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
                    
                    // Sample Input
                    TextField("Sample Input", text: .constant(""))
                        .padding()
                        .background(Color.vetInputBackground)
                        .foregroundColor(.vetTitle)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.vetStroke))
                        .cornerRadius(12)
                    
                    // Sample Button
                    Button("Sample Button") {}
                        .buttonStyle(PrimaryButtonStyle())
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .background(Color.vetBackground.ignoresSafeArea())
    }
}

#Preview("Theme Comparison") {
    ThemePreviewView()
}