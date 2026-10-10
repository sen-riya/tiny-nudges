import SwiftUI

/// Timing settings, shown in the app window. (Characters are picked on the Reminders tab.)
struct SettingsView: View {
    @EnvironmentObject private var scheduler: NudgeScheduler
    @AppStorage(Persona.Reminder.water.storageKey) private var personaID = ""
    /// Edits stay here until Save is pressed.
    @StateObject private var model = DraftModel()

    private var persona: Persona { Persona.resolve(personaID, for: .water) }
    private var palette: Persona.Palette { persona.palette }
    private var ink: Color { Color(palette.ink) }

    private var hasChanges: Bool { model.draft != DraftModel.stored() }

    private func binding(_ setting: TimingSetting) -> Binding<Int> {
        Binding(get: { model.draft[setting] ?? setting.defaultValue }, set: { model.draft[setting] = $0 })
    }

    private func save() {
        let old = DraftModel.stored()
        for (setting, value) in model.draft { UserDefaults.standard.set(value, forKey: setting.key) }
        if model.draft[.waterInterval] != old[.waterInterval] { scheduler.rescheduleWater() }
        if model.draft[.eyeInterval] != old[.eyeInterval] { scheduler.rescheduleEye() }
        model.objectWillChange.send()   // re-evaluate hasChanges
    }

    var body: some View {
        VStack(spacing: 16) {
            SettingsCard(palette: palette, title: "Water", symbol: "drop.fill", tint: Color(palette.aqua)) {
                TimingRow(palette, .waterInterval, binding(.waterInterval), "Reminder interval", "How often a water reminder appears.", range: 5...480, step: 5, unit: "min")
                TimingRow(palette, .waterSnooze, binding(.waterSnooze), "Snooze delay", "How long to wait before asking again when you say later.", range: 1...120, step: 1, unit: "min")
            }
            SettingsCard(palette: palette, title: "Eye break", symbol: "eye.fill", tint: Color(palette.apricot)) {
                TimingRow(palette, .eyeInterval, binding(.eyeInterval), "Reminder interval", "How often an eye break is suggested.", range: 10...600, step: 5, unit: "min")
                TimingRow(palette, .eyeSnooze, binding(.eyeSnooze), "Snooze delay", "How long to wait before asking again when you say not now.", range: 1...120, step: 1, unit: "min")
                TimingRow(palette, .eyeDuration, binding(.eyeDuration), "Break length", "How long the guided eye-break routine runs.", range: 10...300, step: 5, unit: "sec")
            }
            SettingsCard(palette: palette, title: "Both", symbol: "bell.fill", tint: Color(palette.blush)) {
                TimingRow(palette, .dismissSnooze, binding(.dismissSnooze), "Esc delay", "How long to wait before coming back after you press Esc.", range: 1...120, step: 1, unit: "min")
                TimingRow(palette, .gap, binding(.gap), "Minimum gap", "The least time between a water reminder and an eye break.", range: 0...60, step: 1, unit: "min")
            }
            HStack(spacing: 10) {
                Button {
                    for setting in TimingSetting.allCases { model.draft[setting] = setting.defaultValue }
                } label: {
                    Label("Reset to defaults", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(ink)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Capsule().fill(ink.opacity(0.08)))
                }
                .buttonStyle(.plain)
                Button(action: save) {
                    Label(hasChanges ? "Save" : "Saved", systemImage: hasChanges ? "square.and.arrow.down.fill" : "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(ink)
                        .padding(.horizontal, 18).padding(.vertical, 8)
                        .background(Capsule().fill(hasChanges ? Color(palette.apricot) : Color(palette.aqua)))
                        .overlay(Capsule().strokeBorder(ink, lineWidth: 2))
                        .animation(.easeInOut(duration: 0.2), value: hasChanges)
                }
                .buttonStyle(.plain)
                .allowsHitTesting(hasChanges)
            }
        }
    }
}

/// Unsaved edits; nothing reaches UserDefaults until Save.
private final class DraftModel: ObservableObject {
    @Published var draft = DraftModel.stored()

    static func stored() -> [TimingSetting: Int] {
        Dictionary(uniqueKeysWithValues: TimingSetting.allCases.map { ($0, $0.storedValue) })
    }
}

/// A titled group of rows on a bordered card.
private struct SettingsCard<Content: View>: View {
    let palette: Persona.Palette
    let title: String
    let symbol: String
    let tint: Color
    @ViewBuilder let content: Content

    private var ink: Color { Color(palette.ink) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(ink)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(tint))
                    .overlay(Circle().strokeBorder(ink, lineWidth: 2))
                Text(title).font(.system(size: 15, weight: .heavy, design: .rounded))
            }
            .foregroundColor(ink)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous).fill(ink).offset(x: 3, y: 4)
                RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white)
                RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(ink, lineWidth: 2.5)
            }
        )
        .padding(.trailing, 3).padding(.bottom, 4)
    }
}

private struct TimingRow: View {
    let palette: Persona.Palette
    let label: String
    let detail: String
    let range: ClosedRange<Int>
    let step: Int
    let unit: String
    @Binding private var value: Int

    init(_ palette: Persona.Palette, _ setting: TimingSetting, _ value: Binding<Int>, _ label: String, _ detail: String,
         range: ClosedRange<Int>, step: Int, unit: String) {
        self.palette = palette
        self.label = label
        self.detail = detail
        self.range = range
        self.step = step
        self.unit = unit
        _value = value
    }

    private var ink: Color { Color(palette.ink) }

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                Text(detail)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .opacity(0.6)
            }
            .foregroundColor(ink)
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 6)
            Text("\(value) \(unit)")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundColor(ink)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Capsule().fill(Color(palette.cream)).overlay(Capsule().strokeBorder(ink.opacity(0.3), lineWidth: 1.5)))
            Stepper("", value: $value, in: range, step: step)
                .labelsHidden()
        }
    }
}
