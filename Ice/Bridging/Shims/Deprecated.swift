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
