import SwiftUI

@main
struct TinyNudgesApp: App {
    @StateObject private var scheduler = NudgeScheduler()

    init() {
        // One menu-bar icon only: if another copy is already running, this one quits.
        let me = ProcessInfo.processInfo.processIdentifier
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "")
            .filter { $0.processIdentifier != me }
        if Bundle.main.bundleIdentifier != nil, !others.isEmpty { exit(0) }

        // Menu-bar only: no Dock icon.
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra("Tiny Nudges", systemImage: "drop.fill") {
            MenuBarView().environmentObject(scheduler)
        }
        .menuBarExtraStyle(.window)
        Window("Tiny Nudges", id: "main") {
            AppView().environmentObject(scheduler)
        }
        .windowResizability(.contentSize)
    }
}
