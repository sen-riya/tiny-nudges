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
            Text("Next water: \(scheduler.nextWater.formatted(date: .omitted, time: .shortened))")
            Text("Next eye break: \(scheduler.nextEye.formatted(date: .omitted, time: .shortened))")
            Divider()
            Button("Water reminder now") { scheduler.waterNow() }
            Button("Eye break now") { scheduler.eyeBreakNow() }
            Divider()
            Button("Quit") { NSApplication.shared.terminate(nil) }
        }
    }
}
