import Foundation

/// A user-adjustable timing. Stored in UserDefaults (minutes, except `eyeDuration` in seconds).
/// A TINY_NUDGES_*_SECONDS environment variable, when set, overrides the stored value (for testing).
enum TimingSetting: String, CaseIterable {
    case waterInterval, waterSnooze, eyeInterval, eyeSnooze, eyeDuration, dismissSnooze, gap

    var key: String { "timing.\(rawValue)" }

    var envName: String {
        switch self {
        case .waterInterval: return "TINY_NUDGES_INTERVAL_SECONDS"
        case .waterSnooze: return "TINY_NUDGES_SNOOZE_SECONDS"
        case .eyeInterval: return "TINY_NUDGES_EYE_INTERVAL_SECONDS"
        case .eyeSnooze: return "TINY_NUDGES_EYE_SNOOZE_SECONDS"
        case .eyeDuration: return "TINY_NUDGES_EYE_DURATION_SECONDS"
        case .dismissSnooze: return "TINY_NUDGES_DISMISS_SECONDS"
        case .gap: return "TINY_NUDGES_GAP_SECONDS"
        }
    }

    /// In the setting's own unit: minutes, or seconds for `eyeDuration`.
    var defaultValue: Int {
        switch self {
        case .waterInterval: return 60
        case .waterSnooze: return 15
        case .eyeInterval: return 180
        case .eyeSnooze: return 10
        case .eyeDuration: return 60
        case .dismissSnooze: return 15
        case .gap: return 10
        }
    }

    var secondsPerUnit: TimeInterval { self == .eyeDuration ? 1 : 60 }

    /// Saved value in the setting's own unit (ignores the environment override).
    var storedValue: Int { UserDefaults.standard.object(forKey: key) as? Int ?? defaultValue }

    /// Current value in seconds.
    var seconds: TimeInterval {
        if let override = ProcessInfo.processInfo.environment[envName].flatMap(TimeInterval.init) {
            return override
        }
        return TimeInterval(storedValue) * secondsPerUnit
    }
}
