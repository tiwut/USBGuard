import SwiftUI
import AppKit

class WarningWindowController: NSObject {
    private var window: NSWindow?
    private var timer: Timer?
    private var countdown = 5
    private var processesToKill: [ProcessInfo] = []
    
    func showWarning(for driveName: String, processes: [ProcessInfo]) {
        self.processesToKill = processes
        self.countdown = 5
        
        if window == nil {
            let warningView = WarningView(
                driveName: driveName,
                processes: processes,
                countdown: self.countdown,
                onStop: { [weak self] in
                    self?.stopTimer()
                },
                onKillNow: { [weak self] in
                    self?.executeKill()
                }
            )
            
            let hostView = NSHostingView(rootView: warningView)
            
            let newWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 450, height: 300),
                styleMask: [.titled, .closable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            newWindow.center()
            newWindow.isReleasedWhenClosed = false
            newWindow.level = .floating
            newWindow.title = "Warning: Unsafe Ejection"
            newWindow.contentView = hostView
            
            self.window = newWindow
        } else {
            if let hostView = window?.contentView as? NSHostingView<WarningView> {
                hostView.rootView = WarningView(
                    driveName: driveName,
                    processes: processes,
                    countdown: self.countdown,
                    onStop: { [weak self] in
                        self?.stopTimer()
                    },
                    onKillNow: { [weak self] in
                        self?.executeKill()
                    }
                )
            }
        }
        
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        startTimer()
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.countdown -= 1
            if self.countdown <= 0 {
                self.executeKill()
            }
            if let hostView = self.window?.contentView as? NSHostingView<WarningView> {
                var rootView = hostView.rootView
                rootView.countdown = self.countdown
                hostView.rootView = rootView
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func executeKill() {
        stopTimer()
        let pids = processesToKill.map { $0.id }
        ProcessMonitor.shared.killAllProcesses(pids: pids)
        window?.close()
        window = nil
    }
}

struct WarningView: View {
    let driveName: String
    let processes: [ProcessInfo]
    var countdown: Int
    let onStop: () -> Void
    let onKillNow: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.red)
            
            Text("USB Drive Unexpectedly Removed!")
                .font(.title2)
                .bold()
                .foregroundColor(.red)
            
            Text("The drive '**\(driveName)**' was unplugged while \(processes.count) app(s) were still running from it.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("To prevent system freezes, these processes will be forcefully terminated in:")
                .font(.subheadline)
                .multilineTextAlignment(.center)
            
            Text("\(countdown) seconds")
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundColor(.red)
            
            HStack(spacing: 30) {
                Button("Stop Timer") {
                    onStop()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Kill Now") {
                    onKillNow()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 450, height: 350)
    }
}
