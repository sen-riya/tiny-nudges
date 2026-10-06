import Foundation

/// Decides *when* each reminder shows.
/// Water: every hour, or 15 minutes after "Maybe later". Esc dismisses either one for 15 minutes. The two never run back-to-back (10-minute gap). Eye break: every 3 hours (10 minutes after "Ten more mins"), lasting 1 minute.
/// Set REMINDER_INTERVAL_SECONDS / REMINDER_SNOOZE_SECONDS / REMINDER_EYE_INTERVAL_SECONDS /
/// REMINDER_EYE_DURATION_SECONDS / REMINDER_EYE_SNOOZE_SECONDS / REMINDER_DISMISS_SECONDS / REMINDER_GAP_SECONDS to test with short timings.
@MainActor
final class ReminderScheduler: ObservableObject {
    private let waterInterval = ReminderScheduler.seconds("REMINDER_INTERVAL_SECONDS", default: 60 * 60)
    private let snooze = ReminderScheduler.seconds("REMINDER_SNOOZE_SECONDS", default: 15 * 60)
    private let eyeInterval = ReminderScheduler.seconds("REMINDER_EYE_INTERVAL_SECONDS", default: 3 * 60 * 60)
    private let eyeSnooze = ReminderScheduler.seconds("REMINDER_EYE_SNOOZE_SECONDS", default: 10 * 60)
    /// After one reminder finishes, the other waits at least this long (no back-to-back visits).
    private let minGap = ReminderScheduler.seconds("REMINDER_GAP_SECONDS", default: 10 * 60)
    private let dismissSnooze = ReminderScheduler.seconds("REMINDER_DISMISS_SECONDS", default: 15 * 60)
    private let eyeDuration = Int(ReminderScheduler.seconds("REMINDER_EYE_DURATION_SECONDS", default: 60))

    @Published private(set) var nextWater: Date
    @Published private(set) var nextEye: Date
    private let overlay = OverlayController()
    private var timer: Timer?

    init() {
        nextWater = Date().addingTimeInterval(waterInterval)
        nextEye = Date().addingTimeInterval(eyeInterval)
        // Poll instead of one long timer so sleep/wake can't make us miss the time.
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
    }

    func waterNow() {
        guard !overlay.isShowing else { return }
        Task { await showWater() }
    }

    func eyeBreakNow() {
        guard !overlay.isShowing else { return }
        Task { await showEyeBreak() }
    }

    private func tick() {
        guard !overlay.isShowing else { return }
        let now = Date()
        // One at a time; whichever is still due goes on the next tick.
        if now >= nextWater {
            Task { await showWater() }
        } else if now >= nextEye {
            Task { await showEyeBreak() }
        }
    }

    private func showWater() async {
        let outcome = await overlay.runWater()
        let wait: TimeInterval
        switch outcome {
        case .done: wait = waterInterval
        case .later: wait = snooze
        case .dismissed: wait = dismissSnooze      // Esc
        }
        let end = Date()
        nextWater = end.addingTimeInterval(wait)
        nextEye = max(nextEye, end.addingTimeInterval(minGap))
    }

    private func showEyeBreak() async {
        let outcome = await overlay.runEyeBreak(duration: eyeDuration)
        let wait: TimeInterval
        switch outcome {
        case .done: wait = eyeInterval
        case .later: wait = eyeSnooze
        case .dismissed: wait = dismissSnooze      // Esc
        }
        let end = Date()
        nextEye = end.addingTimeInterval(wait)
        nextWater = max(nextWater, end.addingTimeInterval(minGap))
    }

    private static func seconds(_ key: String, default value: TimeInterval) -> TimeInterval {
        ProcessInfo.processInfo.environment[key].flatMap(TimeInterval.init) ?? value
    }
}
