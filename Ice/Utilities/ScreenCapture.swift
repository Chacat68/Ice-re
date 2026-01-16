//
//  ScreenCapture.swift
//  Ice
//

import CoreGraphics
import ScreenCaptureKit

/// A namespace for screen capture operations.
enum ScreenCapture {
    /// Returns a Boolean value that indicates whether the app has been granted screen capture permissions.
    static func checkPermissions() -> Bool {
        for item in MenuBarItem.getMenuBarItems(onScreenOnly: false, activeSpaceOnly: true) {
            // Don't check items owned by Ice.
            if item.owningApplication == .current {
                continue
            }
            return item.title != nil
        }
        // CGPreflightScreenCaptureAccess() only returns an initial value for whether the app
        // has permissions, but we can use it as a fallback.
        return CGPreflightScreenCaptureAccess()
    }

    /// Returns a Boolean value that indicates whether the app has been granted screen capture permissions.
    ///
    /// The first time this function is called, the permissions state is computed, cached, and returned.
    /// Subsequent calls either return the cached value, or recompute the permissions state before caching
    /// and returning it.
    static func cachedCheckPermissions(reset: Bool = false) -> Bool {
        enum Context {
            static var lastCheckResult: Bool?
        }

        if !reset {
            if let lastCheckResult = Context.lastCheckResult {
                return lastCheckResult
            }
        }

        let realResult = checkPermissions()
        Context.lastCheckResult = realResult
        return realResult
    }

    /// Requests screen capture permissions.
    static func requestPermissions() {
        // SCShareableContent requires screen capture permissions, and triggers a request
        // if the user doesn't have them.
        SCShareableContent.getWithCompletionHandler { _, _ in }
    }

    /// Captures a composite image of an array of windows using ScreenCaptureKit.
    ///
    /// - Parameters:
    ///   - windowIDs: The identifiers of the windows to capture.
    ///   - screenBounds: The bounds to capture. Pass `nil` to capture the minimum rectangle that encloses the windows.
    ///   - option: Options that specify the image to be captured.
    static func captureWindows(_ windowIDs: [CGWindowID], screenBounds: CGRect? = nil, option: CGWindowImageOption = []) -> CGImage? {
        guard !windowIDs.isEmpty else {
            return nil
        }

        // Use ScreenCaptureKit for capturing windows
        var resultImage: CGImage?
        let semaphore = DispatchSemaphore(value: 0)

        Task {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)

                // Find the SCWindow objects that match our window IDs
                let targetWindows = content.windows.filter { window in
                    windowIDs.contains(CGWindowID(window.windowID))
                }

                guard !targetWindows.isEmpty else {
                    semaphore.signal()
                    return
                }

                // For multiple windows, we need to capture each and composite them
                if targetWindows.count == 1, let window = targetWindows.first {
                    // Single window capture
                    let filter = SCContentFilter(desktopIndependentWindow: window)
                    let config = SCStreamConfiguration()
                    config.width = Int(window.frame.width * 2) // Retina
                    config.height = Int(window.frame.height * 2)
                    config.showsCursor = false
                    config.captureResolution = .best

                    resultImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
                } else {
                    // Multiple windows - capture the display region containing all windows
                    // Calculate the bounding rect for all windows
                    var unionRect = CGRect.null
                    for window in targetWindows {
                        unionRect = unionRect.union(window.frame)
                    }

                    if let display = content.displays.first {
                        // Create a filter for the display with only the target windows
                        let filter = SCContentFilter(display: display, including: targetWindows)
                        let config = SCStreamConfiguration()

                        let bounds = screenBounds ?? unionRect
                        config.width = Int(bounds.width * 2)
                        config.height = Int(bounds.height * 2)
                        config.showsCursor = false
                        config.captureResolution = .best

                        if screenBounds != nil {
                            config.sourceRect = bounds
                        }

                        resultImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
                    }
                }
            } catch {
                Logger.screenCapture.error("ScreenCaptureKit capture failed: \(error.localizedDescription)")
            }
            semaphore.signal()
        }

        // Wait for async capture to complete (with timeout)
        _ = semaphore.wait(timeout: .now() + 5.0)
        return resultImage
    }

    /// Captures an image of a window.
    ///
    /// - Parameters:
    ///   - windowID: The identifier of the window to capture.
    ///   - screenBounds: The bounds to capture. Pass `nil` to capture the minimum rectangle that encloses the window.
    ///   - option: Options that specify the image to be captured.
    static func captureWindow(_ windowID: CGWindowID, screenBounds: CGRect? = nil, option: CGWindowImageOption = []) -> CGImage? {
        captureWindows([windowID], screenBounds: screenBounds, option: option)
    }
}

// MARK: - Logger
private extension Logger {
    static let screenCapture = Logger(category: "ScreenCapture")
}

