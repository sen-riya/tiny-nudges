import Foundation

/// Decides *when* each reminder shows.
/// Defaults: water every hour, or 15 minutes after "Maybe later". Esc dismisses either one for 15 minutes. The two never run back-to-back (10-minute gap). Eye break every 3 hours (10 minutes after "Not yet"), lasting 1 minute.
/// All timings are adjustable in Settings (see `TimingSetting`); TINY_NUDGES_*_SECONDS environment variables override them for testing.
@MainActor
final class NudgeScheduler: ObservableObject {
    private var waterInterval: TimeInterval { TimingSetting.waterInterval.seconds }
    private var snooze: TimeInterval { TimingSetting.waterSnooze.seconds }
    private var eyeInterval: TimeInterval { TimingSetting.eyeInterval.seconds }
    private var eyeSnooze: TimeInterval { TimingSetting.eyeSnooze.seconds }
    /// After one reminder finishes, the other waits at least this long (no back-to-back visits).
    private var minGap: TimeInterval { TimingSetting.gap.seconds }
    private var dismissSnooze: TimeInterval { TimingSetting.dismissSnooze.seconds }
    private var eyeDuration: Int { Int(TimingSetting.eyeDuration.seconds) }

    @Published private(set) var nextWater: Date
    @Published private(set) var nextEye: Date
    /// "Yes" answers to the water reminder today; starts over at midnight.
    @Published private(set) var glassesToday = NudgeScheduler.storedGlasses()
    private let overlay = OverlayController()
    private var timer: Timer?

    init() {
        nextWater = Date().addingTimeInterval(TimingSetting.waterInterval.seconds)
        nextEye = Date().addingTimeInterval(TimingSetting.eyeInterval.seconds)
        // Poll instead of one long timer so sleep/wake can't make us miss the time.
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
    }

    /// Restart the countdowns from now, e.g. after the interval is changed in Settings.
    func rescheduleWater() { nextWater = Date().addingTimeInterval(waterInterval) }
    func rescheduleEye() { nextEye = Date().addingTimeInterval(eyeInterval) }

    func waterNow() {
        guard !overlay.isShowing else { return }
        Task { await showWater() }
    }

    func eyeBreakNow() {
        guard !overlay.isShowing else { return }
        Task { await showEyeBreak() }
    }

    private static let glassesKey = "glassesToday"
    private static let glassesDayKey = "glassesDay"
    private static var todayStamp: String { Calendar.current.startOfDay(for: Date()).formatted(.iso8601.year().month().day()) }

    private static func storedGlasses() -> Int {
        let d = UserDefaults.standard
        return d.string(forKey: glassesDayKey) == todayStamp ? d.integer(forKey: glassesKey) : 0
    }

    private func addGlass() {
        let d = UserDefaults.standard
        glassesToday = Self.storedGlasses() + 1
        d.set(glassesToday, forKey: Self.glassesKey)
        d.set(Self.todayStamp, forKey: Self.glassesDayKey)
    }

    private func tick() {
        if glassesToday != Self.storedGlasses() { glassesToday = Self.storedGlasses() }   // new day
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
        case .done: wait = waterInterval; addGlass()
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
}
