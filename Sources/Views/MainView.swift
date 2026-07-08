import SwiftUI

struct MainView: View {
    @EnvironmentObject var driveMonitor: DriveMonitor
    @State private var selectedDrive: USBDrive?
    
    var body: some View {
        NavigationSplitView {
            List(driveMonitor.connectedDrives, selection: $selectedDrive) { drive in
                NavigationLink(value: drive) {
                    Label(drive.name, systemImage: "externaldrive.fill")
                }
            }
            .navigationTitle("USB Drives")
            .listStyle(.sidebar)
        } detail: {
            if let drive = selectedDrive {
                DriveDetailView(drive: drive)
            } else {
                Text("Select a drive to view its running processes.")
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            if selectedDrive == nil {
                selectedDrive = driveMonitor.connectedDrives.first
            }
        }
        .onChange(of: driveMonitor.connectedDrives) { newDrives in
            if selectedDrive == nil || !newDrives.contains(where: { $0.id == selectedDrive?.id }) {
                selectedDrive = newDrives.first
            }
        }
    }
}

struct DriveDetailView: View {
    let drive: USBDrive
    @State private var processes: [ProcessInfo] = []
    @State private var refreshTimer: Timer?
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(drive.name)
                    .font(.largeTitle)
                    .bold()
                Spacer()
                Button(role: .destructive) {
                    killAll()
                } label: {
                    Label("Kill All", systemImage: "xmark.bin.fill")
                }
                .disabled(processes.isEmpty)
                
                Button(action: {
                    refreshProcesses()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .padding()
            
            Text("Path: \(drive.path)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            List(processes) { process in
                HStack {
                    VStack(alignment: .leading) {
                        Text(process.name)
                            .font(.headline)
                        Text("PID: \(process.id)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Kill") {
                        killProcess(pid: process.id)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
            .overlay(Group {
                if processes.isEmpty {
                    Text("No processes currently running from this drive.")
                        .foregroundColor(.secondary)
                }
            })
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: drive) { _ in
            refreshProcesses()
        }
    }
    
    private func startTimer() {
        refreshProcesses()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            refreshProcesses()
        }
    }
    
    private func stopTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func refreshProcesses() {
        processes = ProcessMonitor.shared.getProcesses(originatingFrom: drive.path)
    }
    
    private func killProcess(pid: Int32) {
        ProcessMonitor.shared.killProcess(pid: pid)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            refreshProcesses()
        }
    }
    
    private func killAll() {
        let pids = processes.map { $0.id }
        ProcessMonitor.shared.killAllProcesses(pids: pids)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            refreshProcesses()
        }
    }
}
