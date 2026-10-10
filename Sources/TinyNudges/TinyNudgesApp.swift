import SwiftUI

/// Opens the app window when the app icon is clicked (fresh launch, or while it already runs in the menu bar).
/// The login item starts with `--background`, so only the menu-bar icon appears then.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// The instance SwiftUI creates for `@NSApplicationDelegateAdaptor`.
    private(set) static var shared: AppDelegate!
    let scheduler = NudgeScheduler()
    private var window: NSWindow?

    static let showNotification = Notification.Name("com.tinynudges.app.showWindow")

    /// True for the first copy to run; the lock is held until the process ends.
    nonisolated static func acquireSingleInstanceLock() -> Bool {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("com.tinynudges.app.lock").path
        let fd = open(path, O_CREAT | O_RDWR, 0o600)
        guard fd >= 0 else { return true }
        if flock(fd, LOCK_EX | LOCK_NB) != 0 { close(fd); return false }
        // fd is left open on purpose: the lock lasts as long as the process.
        return true
    }

    override init() {
        super.init()
        Self.shared = self
    }

    func showMainWindow() {
        if window == nil {
            let w = NSWindow(contentViewController: NSHostingController(rootView: AppView().environmentObject(scheduler)))
            w.title = "Tiny Nudges"
            w.styleMask = [.titled, .closable, .miniaturizable]
            w.isReleasedWhenClosed = false
            w.center()
            window = w
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        DistributedNotificationCenter.default().addObserver(forName: Self.showNotification, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { AppDelegate.shared.showMainWindow() }
        }
        if !CommandLine.arguments.contains("--background") { showMainWindow() }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow()
        return true
    }
}

@main
struct TinyNudgesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    init() {
        // One menu-bar icon only: if a copy is already running (installed app or a dev build), ask it to show its
        // window and quit. A lock file works for every copy, with or without a bundle identifier.
        if !AppDelegate.acquireSingleInstanceLock() {
            DistributedNotificationCenter.default().postNotificationName(AppDelegate.showNotification, object: nil, userInfo: nil, deliverImmediately: true)
            usleep(300_000)
            exit(0)
        }

        // Menu-bar only: no Dock icon.
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra("Tiny Nudges", systemImage: "drop.fill") {
            MenuBarView().environmentObject(AppDelegate.shared.scheduler)
        }
        .menuBarExtraStyle(.window)
    }
}
