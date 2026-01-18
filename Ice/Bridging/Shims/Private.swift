//
//  Private.swift
//  Ice
//
//  This file contains shims for private Apple APIs used for menu bar management.
//  These APIs are not officially documented and may change without notice.
//
//  API Categories:
//  - CGSConnection: Window server connection management
//  - CGSSpace: Desktop spaces management (fullscreen detection, etc.)
//  - CGSWindow: Window list and frame management
//
//  Note: These APIs have been stable since macOS 10.x and continue to work in
//  macOS 26. They are essential for Ice's core functionality and have no
//  official public API alternatives.
//

import CoreGraphics

// MARK: - Bridged Types

typealias CGSConnectionID = Int32
typealias CGSSpaceID = size_t

enum CGSSpaceType: UInt32 {
    case user = 0
    case system = 2
    case fullscreen = 4
}

struct CGSSpaceMask: OptionSet {
    let rawValue: UInt32

    static let includesCurrent = CGSSpaceMask(rawValue: 1 << 0)
    static let includesOthers = CGSSpaceMask(rawValue: 1 << 1)
    static let includesUser = CGSSpaceMask(rawValue: 1 << 2)

    static let includesVisible = CGSSpaceMask(rawValue: 1 << 16)

    static let currentSpace: CGSSpaceMask = [.includesUser, .includesCurrent]
    static let otherSpaces: CGSSpaceMask = [.includesOthers, .includesCurrent]
    static let allSpaces: CGSSpaceMask = [.includesUser, .includesOthers, .includesCurrent]
    static let allVisibleSpaces: CGSSpaceMask = [.includesVisible, .allSpaces]
}

// MARK: - CGSConnection Functions
// Used for managing the connection to the window server.
// Essential for all other CGS operations.

@_silgen_name("CGSMainConnectionID")
func CGSMainConnectionID() -> CGSConnectionID

@_silgen_name("CGSCopyConnectionProperty")
func CGSCopyConnectionProperty(
    _ cid: CGSConnectionID,
    _ targetCID: CGSConnectionID,
    _ key: CFString,
    _ outValue: inout Unmanaged<CFTypeRef>?
) -> CGError

@_silgen_name("CGSSetConnectionProperty")
func CGSSetConnectionProperty(
    _ cid: CGSConnectionID,
    _ targetCID: CGSConnectionID,
    _ key: CFString,
    _ value: CFTypeRef
) -> CGError

// MARK: - CGSEvent Functions
// Used for detecting unresponsive applications.
// Required by Bridging.responsivity(for:) as a fallback mechanism.

@_silgen_name("CGSEventIsAppUnresponsive")
func CGSEventIsAppUnresponsive(
    _ cid: CGSConnectionID,
    _ psn: inout ProcessSerialNumber
) -> Bool

// MARK: - CGSSpace Functions
// Used for detecting fullscreen spaces and managing window-to-space mapping.
// Essential for proper menu bar behavior in fullscreen apps.

@_silgen_name("CGSGetActiveSpace")
func CGSGetActiveSpace(_ cid: CGSConnectionID) -> CGSSpaceID

@_silgen_name("CGSCopySpacesForWindows")
func CGSCopySpacesForWindows(
    _ cid: CGSConnectionID,
    _ mask: CGSSpaceMask,
    _ windowIDs: CFArray
) -> Unmanaged<CFArray>?

@_silgen_name("CGSSpaceGetType")
func CGSSpaceGetType(
    _ cid: CGSConnectionID,
    _ sid: CGSSpaceID
) -> CGSSpaceType

// MARK: - CGSWindow Functions
// Used for getting window lists and window information.
// Essential for menu bar item management and positioning.

@_silgen_name("CGSGetWindowList")
func CGSGetWindowList(
    _ cid: CGSConnectionID,
    _ targetCID: CGSConnectionID,
    _ count: Int32,
    _ list: UnsafeMutablePointer<CGWindowID>,
    _ outCount: inout Int32
) -> CGError

@_silgen_name("CGSGetOnScreenWindowList")
func CGSGetOnScreenWindowList(
    _ cid: CGSConnectionID,
    _ targetCID: CGSConnectionID,
    _ count: Int32,
    _ list: UnsafeMutablePointer<CGWindowID>,
    _ outCount: inout Int32
) -> CGError

@_silgen_name("CGSGetProcessMenuBarWindowList")
func CGSGetProcessMenuBarWindowList(
    _ cid: CGSConnectionID,
    _ targetCID: CGSConnectionID,
    _ count: Int32,
    _ list: UnsafeMutablePointer<CGWindowID>,
    _ outCount: inout Int32
) -> CGError

@_silgen_name("CGSGetWindowCount")
func CGSGetWindowCount(
    _ cid: CGSConnectionID,
    _ targetCID: CGSConnectionID,
    _ outCount: inout Int32
) -> CGError

@_silgen_name("CGSGetOnScreenWindowCount")
func CGSGetOnScreenWindowCount(
    _ cid: CGSConnectionID,
    _ targetCID: CGSConnectionID,
    _ outCount: inout Int32
) -> CGError

@_silgen_name("CGSGetScreenRectForWindow")
func CGSGetScreenRectForWindow(
    _ cid: CGSConnectionID,
    _ wid: CGWindowID,
    _ outRect: inout CGRect
) -> CGError
