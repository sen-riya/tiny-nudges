import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var scheduler: NudgeScheduler

    var body: some View {
        Form {
            Section("Water") {
                TimingRow(.waterInterval, "Remind me every", range: 5...480, step: 5, unit: "min") {
                    scheduler.rescheduleWater()
                }
                TimingRow(.waterSnooze, "“Maybe later” comes back after", range: 1...120, step: 1, unit: "min")
            }
            Section("Eye break") {
                TimingRow(.eyeInterval, "Remind me every", range: 10...600, step: 5, unit: "min") {
                    scheduler.rescheduleEye()
                }
                TimingRow(.eyeSnooze, "“Not yet” comes back after", range: 1...120, step: 1, unit: "min")
                TimingRow(.eyeDuration, "Break lasts", range: 10...300, step: 5, unit: "sec")
            }
            Section("Both") {
                TimingRow(.dismissSnooze, "Esc comes back after", range: 1...120, step: 1, unit: "min")
                TimingRow(.gap, "Minimum gap between reminders", range: 0...60, step: 1, unit: "min")
            }
            Button("Reset to defaults") {
                TimingSetting.resetAll()
                scheduler.settingsReset()
            }
        }
        .id(scheduler.resetCount)
        .formStyle(.grouped)
        .frame(width: 440, height: 480)
    }
}

private struct TimingRow: View {
    let label: String
    let range: ClosedRange<Int>
    let step: Int
    let unit: String
    let onChange: (() -> Void)?
    @AppStorage private var value: Int

    init(_ setting: TimingSetting, _ label: String, range: ClosedRange<Int>, step: Int, unit: String,
         onChange: (() -> Void)? = nil) {
        self.label = label
        self.range = range
        self.step = step
        self.unit = unit
        self.onChange = onChange
        _value = AppStorage(wrappedValue: setting.defaultValue, setting.key)
    }

    var body: some View {
        Stepper(value: $value, in: range, step: step) {
            HStack {
                Text(label)
                Spacer()
                Text("\(value) \(unit)").monospacedDigit().foregroundStyle(.secondary)
            }
        }
        .onChange(of: value) { _ in onChange?() }
    }
}
