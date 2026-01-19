//
//  AppLanguage.swift
//  Ice
//

import Foundation

/// The language used by the app.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case english = "en"
    case chinese = "zh-Hans"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system:
            return NSLocalizedString("System", comment: "System language option")
        case .english:
            return "English"
        case .chinese:
            return "中文"
        }
    }

    /// Applies this language to the app.
    func apply() {
        switch self {
        case .system:
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        case .english:
            UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
        case .chinese:
            UserDefaults.standard.set(["zh-Hans"], forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()
    }
}
