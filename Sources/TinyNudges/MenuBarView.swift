import SwiftUI

/// The menu-bar popover: who's nagging, when each reminder is due (with a "now" button), settings and quit.
struct MenuBarView: View {
    @EnvironmentObject private var scheduler: NudgeScheduler
    @Environment(\.openWindow) private var openWindow
    @AppStorage(Persona.storageKey) private var personaID = Persona.all[0].id

    private var persona: Persona { Persona.all.first { $0.id == personaID } ?? Persona.all[0] }
    private var palette: Persona.Palette { persona.palette }
    private var ink: Color { Color(palette.ink) }

    var body: some View {
        VStack(spacing: 14) {
            header
            ReminderCard(palette: palette, symbol: "drop.fill", title: "Water", tint: Color(palette.aqua),
                         next: scheduler.nextWater, action: { act(scheduler.waterNow) })
            ReminderCard(palette: palette, symbol: "eye.fill", title: "Eye break", tint: Color(palette.apricot),
                         next: scheduler.nextEye, action: { act(scheduler.eyeBreakNow) })
            footer
        }
        .padding(16)
        .frame(width: 310)
        .background(Color(palette.cream))
        .animation(.easeInOut(duration: 0.2), value: personaID)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(nsImage: persona.avatar)
                .resizable().interpolation(.high).aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 58)
            VStack(alignment: .leading, spacing: 1) {
                Text("Tiny Nudges")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                Text("Looking after you")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .opacity(0.65)
            }
            .foregroundColor(ink)
            Spacer(minLength: 0)
            if Persona.all.count > 1 {
                HStack(spacing: 6) {
                    ForEach(Persona.all) { p in
                        Button { personaID = p.id } label: {
                            Image(nsImage: p.avatar)
                                .resizable().interpolation(.high).aspectRatio(contentMode: .fit)
                                .frame(width: 22, height: 26)
                                .padding(5)
                                .background(Circle().fill(Color(p.palette.cream)))
                                .overlay(Circle().strokeBorder(ink.opacity(p.id == personaID ? 1 : 0.2),
                                                               lineWidth: p.id == personaID ? 2.5 : 1.5))
                        }
                        .buttonStyle(.plain)
                        .help(p.name)
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            FooterButton(palette: palette, title: "Settings…", symbol: "gearshape.fill") {
                dismissMenu()
                openWindow(id: "settings")
                NSApp.activate(ignoringOtherApps: true)
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

/// One reminder: what it is, when it's next due, and a button to run it right away.
private struct ReminderCard: View {
    let palette: Persona.Palette
    let symbol: String
    let title: String
    let tint: Color
    let next: Date
    let action: () -> Void

    private var ink: Color { Color(palette.ink) }

    /// "in 12 min", "in 2 h 5 min", "any moment".
    private static func countdown(to date: Date, from now: Date) -> String {
        let minutes = Int((date.timeIntervalSince(now) / 60).rounded(.up))
        if minutes <= 0 { return "any moment" }
        if minutes < 60 { return "in \(minutes) min" }
        return minutes % 60 == 0 ? "in \(minutes / 60) h" : "in \(minutes / 60) h \(minutes % 60) min"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(ink)
                .frame(width: 42, height: 42)
                .background(Circle().fill(tint))
                .overlay(Circle().strokeBorder(ink, lineWidth: 2.5))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                TimelineView(.periodic(from: .now, by: 20)) { context in
                    Text("\(next.formatted(date: .omitted, time: .shortened)) · \(Self.countdown(to: next, from: context.date))")
                }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .opacity(0.7)
                .lineLimit(1)
            }
            .foregroundColor(ink)
            Spacer(minLength: 4)
            Button(action: action) {
                Text("Now")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(ink)
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .background(Capsule().fill(tint).overlay(Capsule().strokeBorder(ink, lineWidth: 2.5)))
            }
            .buttonStyle(PressableStyle())
        }
        .padding(12)
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

private struct FooterButton: View {
    let palette: Persona.Palette
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(Color(palette.ink))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color(palette.ink).opacity(0.08)))
        }
        .buttonStyle(PressableStyle())
    }
}

private struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
