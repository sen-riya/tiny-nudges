import SwiftUI

/// Timing settings, styled like the menu-bar popover. (The character is picked there, not here.)
struct SettingsView: View {
    @EnvironmentObject private var scheduler: NudgeScheduler
    @AppStorage(Persona.storageKey) private var personaID = Persona.all[0].id

    private var persona: Persona { Persona.all.first { $0.id == personaID } ?? Persona.all[0] }
    private var palette: Persona.Palette { persona.palette }
    private var ink: Color { Color(palette.ink) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                SettingsCard(palette: palette, title: "Water", symbol: "drop.fill", tint: Color(palette.aqua)) {
                    TimingRow(palette, .waterInterval, "Reminder interval", "How often a water reminder appears.", range: 5...480, step: 5, unit: "min") {
                        scheduler.rescheduleWater()
                    }
                    TimingRow(palette, .waterSnooze, "Snooze delay", "How long to wait before asking again when you say later.", range: 1...120, step: 1, unit: "min")
                }
                SettingsCard(palette: palette, title: "Eye break", symbol: "eye.fill", tint: Color(palette.apricot)) {
                    TimingRow(palette, .eyeInterval, "Reminder interval", "How often an eye break is suggested.", range: 10...600, step: 5, unit: "min") {
                        scheduler.rescheduleEye()
                    }
                    TimingRow(palette, .eyeSnooze, "Snooze delay", "How long to wait before asking again when you say not now.", range: 1...120, step: 1, unit: "min")
                    TimingRow(palette, .eyeDuration, "Break length", "How long the guided eye-break routine runs.", range: 10...300, step: 5, unit: "sec")
                }
                SettingsCard(palette: palette, title: "Both", symbol: "bell.fill", tint: Color(palette.blush)) {
                    TimingRow(palette, .dismissSnooze, "Esc delay", "How long to wait before coming back after you press Esc.", range: 1...120, step: 1, unit: "min")
                    TimingRow(palette, .gap, "Minimum gap", "The least time between a water reminder and an eye break.", range: 0...60, step: 1, unit: "min")
                }
                Button {
                    TimingSetting.resetAll()
                    scheduler.settingsReset()
                } label: {
                    Label("Reset to defaults", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(ink)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Capsule().fill(ink.opacity(0.08)))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .id(scheduler.resetCount)
        .frame(width: 440, height: 560)
        .background(Color(palette.cream))
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(nsImage: persona.avatar)
                .resizable().interpolation(.high).aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 48)
            VStack(alignment: .leading, spacing: 1) {
                Text("Settings")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                Text("Changes apply straight away")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .opacity(0.65)
            }
            .foregroundColor(ink)
            Spacer(minLength: 0)
        }
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
    let onChange: (() -> Void)?
    @AppStorage private var value: Int

    init(_ palette: Persona.Palette, _ setting: TimingSetting, _ label: String, _ detail: String, range: ClosedRange<Int>,
         step: Int, unit: String, onChange: (() -> Void)? = nil) {
        self.palette = palette
        self.label = label
        self.detail = detail
        self.range = range
        self.step = step
        self.unit = unit
        self.onChange = onChange
        _value = AppStorage(wrappedValue: setting.defaultValue, setting.key)
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
        .onChange(of: value) { _ in onChange?() }
    }
}
