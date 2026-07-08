# USBGuard

USBGuard is a macOS Menu Bar application designed to protect your system from battery drain and application freezes when a USB storage device is unexpectedly unplugged.

## Features

- **Menu Bar Native**: Runs unobtrusively in the background without cluttering your Dock.
- **Drive Monitoring**: Lists all connected external/removable storage devices.
- **Process Tracking**: Leverages native macOS APIs (`libproc`) to identify exactly which running processes and applications are originating from a specific USB drive.
- **Safety Ejection Guardian**: If a drive is yanked out while apps from it are running, a prominent floating warning window appears instantly with a 5-second countdown timer. If not manually stopped, all rogue processes are forcefully terminated to prevent the system from crashing.
- **Kill Processes manually**: Allows killing processes directly from the UI.
- **Daemon Mode & Startup**: Can be set to launch automatically on login.

## Requirements

- macOS 13.0 or later.
- Full access to `Background Modes` (Login Items) in System Settings to allow background monitoring.

## Building the App

To generate the `.xcodeproj` file and build the app, we use `xcodegen`:

```bash
xcodegen generate
xcodebuild -project USBGuard.xcodeproj -scheme USBGuard build
```

Alternatively, run `swiftc` manually to compile the executable if Xcode is not fully installed.

## Usage

Launch `USBGuard.app`. A small exclamation mark icon will appear in your top-right Menu Bar. Click it to open the main window, view settings, or quit the application.
