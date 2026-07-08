import Foundation
import AppKit

public struct USBDrive: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let path: String
}

@MainActor
public class DriveMonitor: ObservableObject {
    @Published public var connectedDrives: [USBDrive] = []
    
    private var recentlyUnmountedDrives: [String: USBDrive] = [:]
    
    public init() {
        refreshDrives()
        
        let ws = NSWorkspace.shared
        ws.notificationCenter.addObserver(self, selector: #selector(volumeDidMount(_:)), name: NSWorkspace.didMountNotification, object: nil)
        ws.notificationCenter.addObserver(self, selector: #selector(volumeDidUnmount(_:)), name: NSWorkspace.didUnmountNotification, object: nil)
        ws.notificationCenter.addObserver(self, selector: #selector(volumeWillUnmount(_:)), name: NSWorkspace.willUnmountNotification, object: nil)
    }
    
    public func refreshDrives() {
        let keys: [URLResourceKey] = [.volumeIsRemovableKey, .volumeIsInternalKey, .volumeNameKey]
        guard let volumeURLs = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) else {
            return
        }
        
        var drives: [USBDrive] = []
        for url in volumeURLs {
            if isRemovableOrExternal(url: url) {
                let name = (try? url.resourceValues(forKeys: [.volumeNameKey]).volumeName) ?? url.lastPathComponent
                drives.append(USBDrive(id: url.path, name: name, path: url.path))
            }
        }
        self.connectedDrives = drives
    }
    
    private func isRemovableOrExternal(url: URL) -> Bool {
        guard let values = try? url.resourceValues(forKeys: [.volumeIsRemovableKey, .volumeIsInternalKey]) else { return false }
        let isRemovable = values.volumeIsRemovable ?? false
        let isInternal = values.volumeIsInternal ?? true
        return isRemovable || !isInternal
    }
    
    @objc private func volumeDidMount(_ notification: Notification) {
        refreshDrives()
    }
    
    @objc private func volumeWillUnmount(_ notification: Notification) {
        if let url = notification.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL {
            if let drive = connectedDrives.first(where: { $0.path == url.path }) {
                recentlyUnmountedDrives[url.path] = drive
            }
        }
    }
    
    @objc private func volumeDidUnmount(_ notification: Notification) {
        guard let url = notification.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL else { return }
        
        connectedDrives.removeAll { $0.path == url.path }
        
        let path = url.path
        let driveName = recentlyUnmountedDrives[path]?.name ?? url.lastPathComponent
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.recentlyUnmountedDrives.removeValue(forKey: path)
        }
        
        if UserDefaults.standard.bool(forKey: "DaemonEnabled") {
            let activeProcesses = ProcessMonitor.shared.getProcesses(originatingFrom: path)
            if !activeProcesses.isEmpty {
                NotificationCenter.default.post(name: .driveUnexpectedlyUnmounted, object: nil, userInfo: [
                    "DriveName": driveName,
                    "Processes": activeProcesses,
                    "DrivePath": path
                ])
            }
        }
    }
}

extension Notification.Name {
    static let driveUnexpectedlyUnmounted = Notification.Name("driveUnexpectedlyUnmounted")
}
