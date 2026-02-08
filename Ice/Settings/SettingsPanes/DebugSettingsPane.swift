//
//  DebugSettingsPane.swift
//  Ice
//

import SwiftUI
import UserNotifications

struct DebugSettingsPane: View {
    @EnvironmentObject var appState: AppState
    @State private var diagnosticInfo = DiagnosticInfo()
    @State private var isShowingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            // 系统信息
            IceGroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Text("System Information")
                        .font(.headline)
                    diagnosticRow("macOS Version", diagnosticInfo.systemVersion)
                    diagnosticRow("App Version", diagnosticInfo.appVersion)
                    diagnosticRow("Build Version", diagnosticInfo.buildVersion)
                    diagnosticRow("Bundle ID", diagnosticInfo.bundleIdentifier)
                }
                .padding(4)
            }

            // 权限状态
            IceGroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Permission Status")
                        .font(.headline)
                    permissionRow("Accessibility", diagnosticInfo.accessibilityPermission)
                    permissionRow("Screen Recording", diagnosticInfo.screenRecordingPermission)
                }
                .padding(4)
            }

            // 运行状态
            IceGroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Run Status")
                        .font(.headline)
                    diagnosticRow("App is frontmost", diagnosticInfo.isAppFrontmost ? "Yes" : "No")
                    diagnosticRow("Settings window is open", diagnosticInfo.isSettingsPresented ? "Yes" : "No")
                    diagnosticRow("Permissions window is open", diagnosticInfo.isPermissionsPresented ? "Yes" : "No")
                }
                .padding(4)
            }

            // 操作按钮
            HStack(spacing: 12) {
                Button("Refresh Diagnostic Info") {
                    diagnosticInfo = DiagnosticInfo(appState: appState)
                }
                .buttonStyle(.borderedProminent)

                Button("Export Diagnostic Report") {
                    exportDiagnostics()
                }

                Button("Open Logs Folder") {
                    openLogsFolder()
                }

                Button("Test Notification") {
                    testNotification()
                }
            }

            Spacer()
        }
        .padding()
        .onAppear {
            diagnosticInfo = DiagnosticInfo(appState: appState)
        }
        .alert("Diagnostic Information", isPresented: $isShowingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    private func diagnosticRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .frame(width: 150, alignment: .leading)
                .foregroundStyle(.secondary)
            Text(value)
                .foregroundStyle(.primary)
            Spacer()
        }
    }

    private func permissionRow(_ label: String, _ isGranted: Bool) -> some View {
        HStack {
            Text(label)
                .frame(width: 150, alignment: .leading)
                .foregroundStyle(.secondary)
            Image(systemName: isGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(isGranted ? .green : .red)
            Text(isGranted ? "Granted" : "Not Granted")
                .foregroundStyle(isGranted ? .green : .red)
            Spacer()
        }
    }

    private func exportDiagnostics() {
        let info = diagnosticInfo.exportAsText(appState: appState)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(info, forType: .string)
        alertMessage = "Diagnostic information copied to clipboard"
        isShowingAlert = true
    }

    private func openLogsFolder() {
        if let logsPath = getLogsPath() {
            NSWorkspace.shared.open(URL(fileURLWithPath: logsPath))
        } else {
            alertMessage = "Could not find logs folder"
            isShowingAlert = true
        }
    }

    private func testNotification() {
        let notification = UNMutableNotificationContent()
        notification.title = "Ice Test Notification"
        notification.body = "If you see this notification, the notification feature is working properly"

        UNUserNotificationCenter.current().add(UNNotificationRequest(
            identifier: UUID().uuidString,
            content: notification,
            trigger: nil as UNNotificationTrigger?
        ))

        alertMessage = "Test notification sent"
        isShowingAlert = true
    }

    private func getLogsPath() -> String? {
        let fileManager = FileManager.default
        guard let logsURL = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            return nil
        }
        return logsURL.appendingPathComponent("Logs").path
    }
}

// MARK: - DiagnosticInfo

struct DiagnosticInfo {
    var systemVersion: String = ""
    var appVersion: String = ""
    var buildVersion: String = ""
    var bundleIdentifier: String = ""
    var accessibilityPermission: Bool = false
    var screenRecordingPermission: Bool = false
    var isAppFrontmost: Bool = false
    var isSettingsPresented: Bool = false
    var isPermissionsPresented: Bool = false

    init() {
        self.systemVersion = ProcessInfo.processInfo.operatingSystemVersionString
        self.appVersion = Constants.versionString
        self.buildVersion = Constants.buildString
        self.bundleIdentifier = Constants.bundleIdentifier
    }

    @MainActor
    init(appState: AppState) {
        self.init()
        self.accessibilityPermission = appState.permissionsManager.accessibilityPermission.hasPermission
        self.screenRecordingPermission = ScreenCapture.cachedCheckPermissions()
        self.isAppFrontmost = appState.navigationState.isAppFrontmost
        self.isSettingsPresented = appState.navigationState.isSettingsPresented
        self.isPermissionsPresented = appState.permissionsWindow?.isVisible ?? false
    }

    @MainActor
    func exportAsText(appState: AppState) -> String {
        var text = """
        Ice Diagnostic Report
        =====================

        System Information
        ------------------
        macOS Version: \(systemVersion)
        App Version: \(appVersion)
        Build Version: \(buildVersion)
        Bundle ID: \(bundleIdentifier)

        Permission Status
        -----------------
        Accessibility: \(accessibilityPermission ? "✓ Granted" : "✗ Not Granted")
        Screen Recording: \(screenRecordingPermission ? "✓ Granted" : "✗ Not Granted")

        Run Status
        ---------
        App is frontmost: \(isAppFrontmost ? "Yes" : "No")
        Settings window open: \(isSettingsPresented ? "Yes" : "No")
        Permissions window open: \(isPermissionsPresented ? "Yes" : "No")

        """

        // 添加错误日志
        if let errorLog = getRecentErrorLog() {
            text += "\nRecent Errors\n--------------\n\(errorLog)\n"
        }

        return text
    }

    private func getRecentErrorLog() -> String? {
        let fileManager = FileManager.default
        guard let logsURL = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            return nil
        }

        let logsPath = logsURL.appendingPathComponent("Logs")

        guard let logFiles = try? fileManager.contentsOfDirectory(at: logsPath, includingPropertiesForKeys: nil) else {
            return nil
        }

        // 查找 Ice 相关的日志文件
        let iceLogs = logFiles.filter { $0.lastPathComponent.contains("Ice") }

        guard let latestLog = iceLogs.max(by: { $0.path < $1.path }) else {
            return nil
        }

        // 读取最后几行日志
        if let logContent = try? String(contentsOf: latestLog) {
            let lines = logContent.components(separatedBy: "\n")
            let errorLines = lines.filter { $0.contains("error") || $0.contains("Error") || $0.contains("ERROR") || $0.contains("warning") || $0.contains("Failed") }
            if !errorLines.isEmpty {
                return errorLines.suffix(10).joined(separator: "\n")
            }
        }

        return nil
    }
}

#Preview {
    DebugSettingsPane()
        .environmentObject(AppState())
}
