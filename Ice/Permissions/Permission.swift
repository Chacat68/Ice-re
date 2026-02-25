//
//  Permission.swift
//  Ice
//

import AXSwift
import Combine
import Cocoa
import ScreenCaptureKit

// MARK: - Permission

/// An object that encapsulates the behavior of checking for and requesting
/// a specific permission for the app.
@MainActor
class Permission: ObservableObject, Identifiable {
    /// A Boolean value that indicates whether the app has this permission.
    @Published private(set) var hasPermission = false

    /// The title of the permission.
    let title: String
    /// Descriptive details for the permission.
    let details: [String]
    /// A Boolean value that indicates if the app can work without this permission.
    let isRequired: Bool

    /// Ordered list of candidate URLs for the settings pane.
    private let settingsURLs: [URL]
    /// The function that checks permissions.
    private let check: () -> Bool
    /// The function that requests permissions.
    private let request: () -> Void

    /// Observer that runs on a timer to check permissions.
    private var timerCancellable: AnyCancellable?
    /// Observer that observes the ``hasPermission`` property.
    private var hasPermissionCancellable: AnyCancellable?

    /// Creates a permission.
    ///
    /// - Parameters:
    ///   - title: The title of the permission.
    ///   - details: Descriptive details for the permission.
    ///   - isRequired: A Boolean value that indicates if the app can work without this permission.
    ///   - settingsURLs: Ordered list of candidate URLs for the settings pane.
    ///     A preferred URL is selected based on the current macOS version.
    ///   - check: A function that checks permissions.
    ///   - request: A function that requests permissions.
    init(
        title: String,
        details: [String],
        isRequired: Bool,
        settingsURLs: [URL] = [],
        check: @escaping () -> Bool,
        request: @escaping () -> Void
    ) {
        self.title = title
        self.details = details
        self.isRequired = isRequired
        self.settingsURLs = settingsURLs
        self.check = check
        self.request = request
        self.hasPermission = check()
        configureCancellables()
    }

    /// Convenience initialiser accepting a single optional URL.
    convenience init(
        title: String,
        details: [String],
        isRequired: Bool,
        settingsURL: URL?,
        check: @escaping () -> Bool,
        request: @escaping () -> Void
    ) {
        self.init(
            title: title,
            details: details,
            isRequired: isRequired,
            settingsURLs: [settingsURL].compactMap { $0 },
            check: check,
            request: request
        )
    }

    /// Sets up the internal observers for the permission.
    private func configureCancellables() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
            .merge(with: Just(.now))
            .sink { [weak self] _ in
                guard let self else {
                    return
                }
                hasPermission = check()
            }
    }

    /// Performs the request and opens the System Settings app to the appropriate pane.
    func performRequest() {
        request()
        openSettings()
    }

    /// Opens System Settings to the appropriate permissions pane.
    ///
    /// The URL is selected based on the current macOS version instead of relying on
    /// `NSWorkspace.open(_:)` to indicate whether a deep link's route is supported.
    /// If opening the selected URL fails, it falls back to the generic System Settings page.
    private func openSettings() {
        for url in settingsURLsInPreferredOrder() {
            if NSWorkspace.shared.open(url) {
                return
            }
        }

        if let genericSettingsURL = URL(string: "x-apple.systempreferences:") {
            NSWorkspace.shared.open(genericSettingsURL)
        }
    }

    /// Returns candidate settings URLs ordered for the current macOS version.
    private func settingsURLsInPreferredOrder() -> [URL] {
        // The new Settings deep-link format is available on newer macOS versions.
        // Prior versions generally use the legacy `com.apple.preference.*` format.
        let majorVersion = ProcessInfo.processInfo.operatingSystemVersion.majorVersion
        let prefersModernSettingsFormat = majorVersion >= 26

        let preferredIdentifier = prefersModernSettingsFormat
            ? "com.apple.settings."
            : "com.apple.preference."

        let preferred = settingsURLs.filter { $0.absoluteString.contains(preferredIdentifier) }
        let nonPreferred = settingsURLs.filter { !$0.absoluteString.contains(preferredIdentifier) }

        return preferred + nonPreferred
    }

    /// Asynchronously waits for the app to be granted this permission.
    func waitForPermission() async {
        configureCancellables()
        guard !hasPermission else {
            return
        }
        return await withCheckedContinuation { continuation in
            hasPermissionCancellable = $hasPermission.sink { [weak self] hasPermission in
                guard let self else {
                    continuation.resume()
                    return
                }
                if hasPermission {
                    hasPermissionCancellable?.cancel()
                    continuation.resume()
                }
            }
        }
    }

    /// Stops running the permission check.
    func stopCheck() {
        timerCancellable?.cancel()
        timerCancellable = nil
        hasPermissionCancellable?.cancel()
        hasPermissionCancellable = nil
    }
}

// MARK: - AccessibilityPermission

final class AccessibilityPermission: Permission {
    init() {
        super.init(
            title: NSLocalizedString("Accessibility", comment: "Permission title"),
            details: [
                NSLocalizedString("Get real-time information about the menu bar.", comment: "Accessibility permission detail"),
                NSLocalizedString("Arrange menu bar items.", comment: "Accessibility permission detail"),
            ],
            isRequired: true,
            settingsURLs: [
                // Newer macOS (15+) format
                URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility"),
                // Legacy format (macOS 13/14)
                URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"),
            ].compactMap { $0 },
            check: {
                // Use native macOS API to check accessibility permissions
                AXIsProcessTrusted()
            },
            request: {
                // Use native macOS API with prompt option
                let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
                AXIsProcessTrustedWithOptions(options)
            }
        )
    }
}

// MARK: - ScreenRecordingPermission

final class ScreenRecordingPermission: Permission {
    init() {
        super.init(
            title: NSLocalizedString("Screen Recording", comment: "Permission title"),
            details: [
                NSLocalizedString("Edit the menu bar's appearance.", comment: "Screen recording permission detail"),
                NSLocalizedString("Display images of individual menu bar items.", comment: "Screen recording permission detail"),
            ],
            isRequired: false,
            settingsURLs: ScreenRecordingPermission.candidateSettingsURLs(),
            check: {
                ScreenCapture.checkPermissions()
            },
            request: {
                ScreenCapture.requestPermissions()
            }
        )
    }

    /// Returns an ordered list of candidate URLs for opening Screen Recording privacy settings.
    /// The list covers macOS 15+ (Sequoia/26) new-style URLs first, then the legacy URL.
    /// Note: The URL parameter is "ScreenCapture" (not "ScreenRecording") — this matches
    /// Apple's internal identifier for the screen recording privacy pane.
    private static func candidateSettingsURLs() -> [URL] {
        [
            // macOS 15+ (Sequoia / Tahoe) new settings URL format
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ScreenCapture",
            // Legacy format (macOS 13/14) with correct identifier
            "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture",
        ].compactMap { URL(string: $0) }
    }
}
