//
//  MenuBarItemIconProvider.swift
//  Ice
//

import Cocoa
import OSLog

/// Provides icons for menu bar items by extracting them from app bundles.
final class MenuBarItemIconProvider {
    /// Shared instance of the icon provider.
    static let shared = MenuBarItemIconProvider()

    /// In-memory cache of icons, keyed by bundle identifier.
    private var iconCache: [String: NSImage] = [:]

    /// Cache directory for persisted icons.
    private let cacheDirectory: URL

    /// The standard menu bar height for icon sizing.
    private let standardMenuBarHeight: CGFloat = 22

    private init() {
        // Create cache directory in Application Support
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            cacheDirectory = appSupport.appendingPathComponent("Ice/IconCache", isDirectory: true)
        } else {
            cacheDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("Ice/IconCache", isDirectory: true)
        }

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Load cached icons from disk
        loadCachedIcons()
    }

    // MARK: - Public API

    /// Gets the icon for a menu bar item.
    /// - Parameter item: The menu bar item to get the icon for.
    /// - Returns: An image suitable for display in the menu bar layout, or nil if not found.
    func getIcon(for item: MenuBarItem) -> NSImage? {
        guard let bundleIdentifier = item.owningApplication?.bundleIdentifier else {
            Logger.iconProvider.debug("No bundle identifier for item: \(item.displayName)")
            return nil
        }

        // Check in-memory cache first
        if let cachedIcon = iconCache[bundleIdentifier] {
            return cachedIcon
        }

        // Try to extract icon from bundle
        guard let bundleURL = item.owningApplication?.bundleURL else {
            Logger.iconProvider.debug("No bundle URL for item: \(item.displayName)")
            Logger.iconProvider.debug("No bundle URL for item: \(item.displayName)")
            // Fallback to generic icon
            return getGenericIcon()
        }

        if let icon = extractIcon(from: bundleURL, bundleIdentifier: bundleIdentifier) {
            // Cache the icon
            iconCache[bundleIdentifier] = icon
            saveIconToCache(icon, bundleIdentifier: bundleIdentifier)
            return icon
        }

        return nil
    }

    /// Clears all cached icons.
    func clearCache() {
        iconCache.removeAll()
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Icon Extraction

    /// Extracts an icon from an app bundle.
    private func extractIcon(from bundleURL: URL, bundleIdentifier: String) -> NSImage? {
        guard let bundle = Bundle(url: bundleURL) else {
            Logger.iconProvider.debug("Could not load bundle: \(bundleURL.path)")
            return nil
        }

        // Priority 1: Try to find a status bar icon in the bundle
        if let statusBarIcon = findStatusBarIcon(in: bundle) {
            Logger.iconProvider.debug("Found status bar icon for: \(bundleIdentifier)")
            return prepareIconForMenuBar(statusBarIcon)
        }

        // Priority 2: Use the app icon as a fallback
        if let appIcon = getAppIcon(from: bundleURL) {
            Logger.iconProvider.debug("Using app icon for: \(bundleIdentifier)")
            return prepareIconForMenuBar(appIcon)
        }

        Logger.iconProvider.debug("No icon found for: \(bundleIdentifier)")
        Logger.iconProvider.debug("No icon found for: \(bundleIdentifier)")

        // Final fallback: Generic app icon for the bundle path
        if let icon = NSWorkspace.shared.icon(forFile: bundleURL.path) as NSImage? {
            return prepareIconForMenuBar(icon)
        }

        return nil
    }

    /// Searches for a status bar icon in the bundle's resources.
    private func findStatusBarIcon(in bundle: Bundle) -> NSImage? {
        // Common names for status bar icons
        let statusBarIconNames = [
            "StatusBarIcon",
            "StatusIcon",
            "MenuBarIcon",
            "MenuIcon",
            "StatusBarItem",
            "StatusItem",
            "TrayIcon",
            "menubar",
            "statusbar",
            "status-bar",
            "menu-bar",
        ]

        // Try each common name
        for name in statusBarIconNames {
            if let image = bundle.image(forResource: name) {
                return image
            }
        }

        // Try to find any image with "status" or "menu" in the name
        if let resourcePath = bundle.resourcePath {
            let resourceURL = URL(fileURLWithPath: resourcePath)
            if let enumerator = FileManager.default.enumerator(at: resourceURL, includingPropertiesForKeys: nil) {
                while let fileURL = enumerator.nextObject() as? URL {
                    let filename = fileURL.lastPathComponent.lowercased()
                    if (filename.contains("status") || filename.contains("menu") || filename.contains("tray")) &&
                        (filename.hasSuffix(".png") || filename.hasSuffix(".pdf") || filename.hasSuffix(".tiff")) {
                        if let image = NSImage(contentsOf: fileURL) {
                            return image
                        }
                    }
                }
            }
        }

        return nil
    }

    /// Gets the application icon from the bundle.
    private func getAppIcon(from bundleURL: URL) -> NSImage? {
        // Use NSWorkspace to get the icon
        return NSWorkspace.shared.icon(forFile: bundleURL.path)
    }

    /// Gets a generic system icon.
    private func getGenericIcon() -> NSImage? {
        return NSImage(systemSymbolName: "app.dashed", accessibilityDescription: "Application")
    }

    /// Prepares an icon for display in the menu bar.
    private func prepareIconForMenuBar(_ icon: NSImage) -> NSImage {
        let targetHeight = standardMenuBarHeight
        let targetSize: NSSize

        // Calculate aspect ratio and size
        let aspectRatio = icon.size.width / icon.size.height
        if aspectRatio > 1 {
            // Wider than tall
            targetSize = NSSize(width: targetHeight * aspectRatio, height: targetHeight)
        } else {
            // Taller than wide or square
            targetSize = NSSize(width: targetHeight, height: targetHeight)
        }

        // Create a properly sized copy
        let resizedIcon = NSImage(size: targetSize)
        resizedIcon.lockFocus()

        NSGraphicsContext.current?.imageInterpolation = .high
        icon.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: icon.size),
            operation: .copy,
            fraction: 1.0
        )

        resizedIcon.unlockFocus()
        resizedIcon.isTemplate = icon.isTemplate

        return resizedIcon
    }

    // MARK: - Disk Cache

    /// Loads icons from disk cache.
    private func loadCachedIcons() {
        guard let contents = try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            return
        }

        for fileURL in contents where fileURL.pathExtension == "png" {
            let bundleIdentifier = fileURL.deletingPathExtension().lastPathComponent
            if let image = NSImage(contentsOf: fileURL) {
                iconCache[bundleIdentifier] = image
            }
        }

        Logger.iconProvider.debug("Loaded \(self.iconCache.count) icons from cache")
    }

    /// Saves an icon to disk cache.
    private func saveIconToCache(_ icon: NSImage, bundleIdentifier: String) {
        let fileURL = cacheDirectory.appendingPathComponent("\(bundleIdentifier).png")

        guard
            let tiffData = icon.tiffRepresentation,
            let bitmapRep = NSBitmapImageRep(data: tiffData),
            let pngData = bitmapRep.representation(using: .png, properties: [:])
        else {
            return
        }

        try? pngData.write(to: fileURL)
    }
}

// MARK: - Logger
private extension Logger {
    static let iconProvider = Logger(category: "MenuBarItemIconProvider")
}
