import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("DaemonEnabled") private var daemonEnabled = true
    @State private var launchAtStartup = false
    
    var body: some View {
        Form {
            Section(header: Text("Daemon Mode")) {
                Toggle("Enable Background Monitoring", isOn: $daemonEnabled)
                Text("When enabled, USBGuard will monitor for unexpected USB disconnects and automatically terminate running processes to prevent freezes.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("Startup Options")) {
                Toggle("Launch at Login", isOn: $launchAtStartup)
                    .onChange(of: launchAtStartup) { newValue in
                        toggleLaunchAtStartup(enabled: newValue)
                    }
                Text("Start USBGuard automatically when you log in.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("Background Permissions")) {
                Text("To ensure the background monitoring works flawlessly, please make sure USBGuard is enabled in **System Settings -> General -> Login Items** under 'Allow in the Background'.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Open Login Items Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
        .padding()
        .onAppear {
            checkStartupStatus()
        }
    }
    
    private func checkStartupStatus() {
        if #available(macOS 13.0, *) {
            launchAtStartup = SMAppService.mainApp.status == .enabled
        }
    }
    
    private func toggleLaunchAtStartup(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
            } catch {
                print("Failed to change login item status: \(error)")
                checkStartupStatus()
            }
        }
    }
}
