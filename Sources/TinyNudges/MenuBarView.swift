import SwiftUI

/// The menu-bar popover: kept simple. When each reminder is due (with a "now" button), then open the app or quit.
/// Characters, settings and the glasses count live in the app window.
struct MenuBarView: View {
    @EnvironmentObject private var scheduler: NudgeScheduler
    @AppStorage(Persona.Reminder.water.storageKey) private var waterID = ""
    @AppStorage(Persona.Reminder.eye.storageKey) private var eyeID = ""

    private var persona: Persona { Persona.resolve(waterID, for: .water) }
    private var eyePersona: Persona { Persona.resolve(eyeID, for: .eye) }
    private var palette: Persona.Palette { persona.palette }
    private var ink: Color { Color(palette.ink) }

    var body: some View {
        VStack(spacing: 12) {
            header
            QuickRow(palette: palette, symbol: "drop.fill", title: "Water", tint: Color(palette.aqua),
                     next: scheduler.nextWater, action: { act(scheduler.waterNow) })
            QuickRow(palette: palette, symbol: "eye.fill", title: "Eye break", tint: Color(eyePersona.palette.apricot),
                     next: scheduler.nextEye, action: { act(scheduler.eyeBreakNow) })
            footer
        }
        .padding(16)
        .frame(width: 290)
        .background(Color(palette.cream))
    }

    /// The app logo, so the header stays the same whichever characters are picked.
    static let logo: NSImage = Bundle.module.url(forResource: "logo", withExtension: "png", subdirectory: "Resources")
        .flatMap { NSImage(contentsOf: $0) } ?? NSImage()

    private var header: some View {
        HStack(spacing: 10) {
            Image(nsImage: Self.logo)
                .resizable().interpolation(.high).aspectRatio(contentMode: .fit)
                .frame(width: 36, height: 36)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(ink, lineWidth: 2))
            Text("Tiny Nudges")
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundColor(ink)
            Spacer(minLength: 0)
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            FooterButton(palette: palette, title: "Open app", symbol: "macwindow") {
                dismissMenu()
                AppDelegate.shared.showMainWindow()
            }
            .keyboardShortcut(",")
            FooterButton(palette: palette, title: "Quit", symbol: "power") {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    /// Runs a reminder and closes the popover so the character isn't hidden behind it.
    private func act(_ action: () -> Void) {
        dismissMenu()
        action()
    }

    private func dismissMenu() {
        NSApp.keyWindow?.orderOut(nil)
    }
}

/// A compact reminder line: name, when it's next due, and a Now button.
private struct QuickRow: View {
    let palette: Persona.Palette
    let symbol: String
    let title: String
    let tint: Color
    let next: Date
    let action: () -> Void

    private var ink: Color { Color(palette.ink) }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(ink)
                .frame(width: 32, height: 32)
                .background(Circle().fill(tint))
                .overlay(Circle().strokeBorder(ink, lineWidth: 2))
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 13, weight: .heavy, design: .rounded))
                TimelineView(.periodic(from: .now, by: 20)) { context in
                    Text("\(next.formatted(date: .omitted, time: .shortened)) · \(ReminderCard.countdown(to: next, from: context.date))")
                }
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .opacity(0.7)
                .lineLimit(1)
            }
            .foregroundColor(ink)
            Spacer(minLength: 4)
            Button(action: action) {
                Text("Now")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(ink)
                    .padding(.horizontal, 12).padding(.vertical, 5)
                    .background(Capsule().fill(tint).overlay(Capsule().strokeBorder(ink, lineWidth: 2)))
            }
            .buttonStyle(PressableStyle())
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(ink, lineWidth: 2))
    }
}
