//
//  Deprecated.swift
//  Ice
//
//  This file contains shims for deprecated Apple APIs that are still needed
//  for certain functionality. These APIs may be removed in future macOS versions.
//
//  TODO: Monitor for alternatives in future macOS releases.
//

import ApplicationServices
import CoreGraphics

// MARK: - Carbon Process Manager (Deprecated)

/// Returns a PSN for a given PID.
///
/// - Important: This API is deprecated since macOS 10.9. It's used here as a fallback
///   for `CGSEventIsAppUnresponsive` which requires a PSN. The primary responsiveness
///   check now uses `NSRunningApplication`.
///
/// - Note: This function may be removed in future macOS versions. If that happens,
///   the fallback in `Bridging.responsivity(for:)` will handle the failure gracefully.
@_silgen_name("GetProcessForPID")
func GetProcessForPID(
    _ pid: pid_t,
    _ psn: inout ProcessSerialNumber
) -> OSStatus

// MARK: - CGWindowList Image Capture (Swift-Unavailable Shims)

/// Shim for `CGWindowListCreateImage`, which is marked unavailable in Swift on newer
/// macOS SDKs but still exists as a C symbol in CoreGraphics.
///
/// - Important: Apple recommends migrating to ScreenCaptureKit. This shim is retained
///   for synchronous, lightweight window captures that do not require full SCK permissions.
@_silgen_name("CGWindowListCreateImage")
func _CGWindowListCreateImage(
    _ screenBounds: CGRect,
    _ listOption: CGWindowListOption,
    _ windowID: CGWindowID,
    _ imageOption: CGWindowImageOption
) -> CGImage?

/// Shim for `CGWindowListCreateImageFromArray`, which is marked unavailable in Swift on
/// newer macOS SDKs but still exists as a C symbol in CoreGraphics.
@_silgen_name("CGWindowListCreateImageFromArray")
func _CGWindowListCreateImageFromArray(
    _ screenBounds: CGRect,
    _ windowArray: CFArray,
    _ imageOption: CGWindowImageOption
) -> CGImage?
