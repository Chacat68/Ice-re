//
//  Constants.swift
//  Ice
//

import Foundation

enum Constants {
    /// The version string in the app's bundle.
    static var versionString: String {
        Bundle.main.versionString ?? "1.0"
    }

    /// The build string in the app's bundle.
    static var buildString: String {
        Bundle.main.buildString ?? "1"
    }

    /// The user-readable copyright string in the app's bundle.
    static var copyrightString: String {
        Bundle.main.copyrightString ?? "© \(Calendar.current.component(.year, from: Date()))"
    }

    /// The bundle identifier of the app.
    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.jordanteacher.Ice"
    }

    /// The identifier for the settings window.
    static let settingsWindowID = "SettingsWindow"

    /// The identifier for the permissions window.
    static let permissionsWindowID = "PermissionsWindow"

    /// The title for the settings window.
    static let settingsWindowTitle = "Ice"

    /// The title for the permissions window.
    static let permissionsWindowTitle = "Permissions"
}
