import SwiftUI

@main
struct TinyNudgesApp: App {
    @StateObject private var scheduler = NudgeScheduler()

    init() {
        // Menu-bar only: no Dock icon.
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra("Tiny Nudges", systemImage: "drop.fill") {
            MenuContent().environmentObject(scheduler)
        }
        Window("Tiny Nudges Settings", id: "settings") {
            SettingsView().environmentObject(scheduler)
        }
        .windowResizability(.contentSize)
    }
}

private struct MenuContent: View {
    @EnvironmentObject private var scheduler: NudgeScheduler
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text("Next water: \(scheduler.nextWater.formatted(date: .omitted, time: .shortened))")
        Text("Next eye break: \(scheduler.nextEye.formatted(date: .omitted, time: .shortened))")
        Divider()
        Button("Water reminder now") { scheduler.waterNow() }
        Button("Eye break now") { scheduler.eyeBreakNow() }
        Divider()
        Button("Settings…") {
            openWindow(id: "settings")
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut(",")
        Button("Quit") { NSApplication.shared.terminate(nil) }
    }
}
