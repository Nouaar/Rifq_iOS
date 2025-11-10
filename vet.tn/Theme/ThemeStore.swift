import SwiftUI
import Combine   // ⬅️ required for ObservableObject/@Published

enum AppTheme: String, CaseIterable { case system, light, dark }

final class ThemeStore: ObservableObject {
    @Published var selection: AppTheme {
        didSet { UserDefaults.standard.set(selection.rawValue, forKey: "app_theme") }
    }

    var preferred: ColorScheme? {
        switch selection {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: "app_theme")
        self.selection = AppTheme(rawValue: raw ?? "") ?? .system
    }
}
