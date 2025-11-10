import SwiftUI
import UIKit

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue:  Double(b) / 255,
                  opacity: Double(a) / 255)
    }

    // 🎨 Dynamic Colors for Light/Dark Mode Support
    static let vetBackground = Color(
        light: Color(hex: "#F6EFEA"), // Light cream background
        dark: Color(hex: "#1C1C1E")   // Dark background
    )
    
    static let vetSand = Color(
        light: Color(hex: "#E8D8CF"), // Light sand for top bar
        dark: Color(hex: "#2C2C2E")   // Dark gray for top bar
    )
    
    static let vetStroke = Color(
        light: Color(hex: "#DDDDDD"), // Light stroke
        dark: Color(hex: "#48484A")   // Dark stroke
    )
    
    static let vetTitle = Color(
        light: Color(hex: "#2A2A2A"), // Dark text on light
        dark: Color(hex: "#FFFFFF")   // Light text on dark
    )
    
    static let vetSubtitle = Color(
        light: Color(hex: "#9A9A9A"), // Light gray subtitle
        dark: Color(hex: "#8E8E93")   // Dark gray subtitle
    )
    
    static let vetCanyon = Color(hex: "#C77A56")  // Orange stays same in both modes
    
    // Card backgrounds
    static let vetCardBackground = Color(
        light: Color.white,
        dark: Color(hex: "#2C2C2E")
    )
    
    // Text field backgrounds
    static let vetInputBackground = Color(
        light: Color.white,
        dark: Color(hex: "#1C1C1E")
    )
    
    func darker(_ amount: Double = 0.35) -> Color {
        #if canImport(UIKit)
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if ui.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return Color(
                red: max(0, Double(r) - amount),
                green: max(0, Double(g) - amount),
                blue: max(0, Double(b) - amount),
                opacity: Double(a)
            )
        }
        #endif
        return self.opacity(0.9)
    }
}

// MARK: - Dynamic Color Helper
extension Color {
    init(light: Color, dark: Color) {
        self = Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}

// MARK: - Dynamic Shadow Helper
extension View {
    func vetShadow(radius: CGFloat = 4, x: CGFloat = 0, y: CGFloat = 2) -> some View {
        self.shadow(
            color: Color(
                light: Color.black.opacity(0.08),
                dark: Color.black.opacity(0.25)
            ), 
            radius: radius, x: x, y: y
        )
    }
    
    func vetLightShadow(radius: CGFloat = 6, x: CGFloat = 0, y: CGFloat = 2) -> some View {
        self.shadow(
            color: Color(
                light: Color.black.opacity(0.04),
                dark: Color.black.opacity(0.15)
            ), 
            radius: radius, x: x, y: y
        )
    }
}
