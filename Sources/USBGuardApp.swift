import SwiftUI

@main
struct USBGuardApp: App {
    @StateObject private var driveMonitor = DriveMonitor()
    @State private var warningWindowController: WarningWindowController?
    
    init() {
        UserDefaults.standard.register(defaults: [
            "DaemonEnabled": true
        ])
    }
    
    var body: some Scene {
        WindowGroup("USBGuard", id: "MainWindow") {
            MainView()
                .environmentObject(driveMonitor)
                .frame(minWidth: 500, minHeight: 400)
                .onReceive(NotificationCenter.default.publisher(for: .driveUnexpectedlyUnmounted)) { notification in
                    handleUnexpectedUnmount(notification)
                }
        }
        
        WindowGroup("Settings", id: "SettingsWindow") {
            SettingsView()
                .frame(width: 400, height: 300)
        }
        
        MenuBarExtra("USBGuard", systemImage: "externaldrive.badge.exclamationmark") {
            MenuBarCommands()
        }
    }
    
    private func handleUnexpectedUnmount(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let processes = userInfo["Processes"] as? [ProcessInfo],
              let driveName = userInfo["DriveName"] as? String else {
            return
        }
        
        if warningWindowController == nil {
            warningWindowController = WarningWindowController()
        }
        warningWindowController?.showWarning(for: driveName, processes: processes)
    }
}

struct MenuBarCommands: View {
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        Button("Open USBGuard") {
            openWindow(id: "MainWindow")
            bringToFront()
        }
        Divider()
        Button("Settings...") {
            openWindow(id: "SettingsWindow")
            bringToFront()
        }
        Divider()
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
    
    private func bringToFront() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
