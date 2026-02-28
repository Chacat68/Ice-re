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
    ///
    /// Thread-safe implementation using thread-local storage.
    static func cachedCheckPermissions(reset: Bool = false) -> Bool {
        enum Context {
            static var lastCheckResult: Bool?
            static let lock = NSLock()
        }

        Context.lock.lock()
        defer { Context.lock.unlock() }

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
        if #available(macOS 15.0, *) {
            // CGRequestScreenCaptureAccess() is broken on macOS 15. SCShareableContent requires
            // screen capture permissions, and triggers a request if the user doesn't have them.
            SCShareableContent.getWithCompletionHandler { _, _ in }
        } else {
            CGRequestScreenCaptureAccess()
        }
    }

    /// Captures a composite image of an array of windows.
    ///
    /// - Parameters:
    ///   - windowIDs: The identifiers of the windows to capture.
    ///   - screenBounds: The bounds to capture. Pass `nil` to capture the minimum rectangle that encloses the windows.
    ///   - option: Options that specify the image to be captured.
    static func captureWindows(_ windowIDs: [CGWindowID], screenBounds: CGRect? = nil, option: CGWindowImageOption = []) -> CGImage? {
        guard !windowIDs.isEmpty else {
            return nil
        }
        let bounds = screenBounds ?? .null
        if windowIDs.count == 1 {
            return _CGWindowListCreateImage(bounds, .optionIncludingWindow, windowIDs[0], option)
        } else {
            let pointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: windowIDs.count)
            for (index, windowID) in windowIDs.enumerated() {
                pointer[index] = UnsafeRawPointer(bitPattern: UInt(windowID))
            }
            guard let windowArray = CFArrayCreate(kCFAllocatorDefault, pointer, windowIDs.count, nil) else {
                pointer.deallocate()
                return nil
            }
            pointer.deallocate()
            return _CGWindowListCreateImageFromArray(bounds, windowArray, option)
        }
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
