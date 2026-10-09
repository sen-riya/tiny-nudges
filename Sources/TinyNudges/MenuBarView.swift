import SwiftUI

/// The menu-bar popover: who's nagging, when each reminder is due (with a "now" button), settings and quit.
struct MenuBarView: View {
    @EnvironmentObject private var scheduler: NudgeScheduler
    @Environment(\.openWindow) private var openWindow
    @AppStorage(Persona.Reminder.water.storageKey) private var waterID = ""
    @AppStorage(Persona.Reminder.eye.storageKey) private var eyeID = ""

    /// The popover is themed after the water character; the eye card shows its own character.
    private var persona: Persona { Persona.resolve(waterID, for: .water) }
    private var eyePersona: Persona { Persona.resolve(eyeID, for: .eye) }
    private var palette: Persona.Palette { persona.palette }
    private var ink: Color { Color(palette.ink) }

    var body: some View {
        VStack(spacing: 14) {
            header
            ReminderCard(persona: persona, choice: $waterID, symbol: "drop.fill", title: "Water", tint: Color(palette.aqua),
                         next: scheduler.nextWater, note: glassesText, action: { act(scheduler.waterNow) })
            ReminderCard(persona: eyePersona, choice: $eyeID, symbol: "eye.fill", title: "Eye break", tint: Color(eyePersona.palette.apricot),
                         next: scheduler.nextEye, action: { act(scheduler.eyeBreakNow) })
            footer
        }
        .padding(16)
        .frame(width: 310)
        .background(Color(palette.cream))
        .animation(.easeInOut(duration: 0.2), value: waterID)
    }

    /// The app logo, so the header stays the same whichever characters are picked.
    private static let logo: NSImage = Bundle.module.url(forResource: "logo", withExtension: "png", subdirectory: "Resources")
        .flatMap { NSImage(contentsOf: $0) } ?? NSImage()

    private var glassesText: String {
        let n = scheduler.glassesToday
        let ui = persona.ui
        return n == 1 ? ui.glassesOne : String(format: ui.glassesMany, n)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(nsImage: Self.logo)
                .resizable().interpolation(.high).aspectRatio(contentMode: .fit)
                .frame(width: 52, height: 52)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(ink, lineWidth: 2.5))
            VStack(alignment: .leading, spacing: 1) {
                Text("Tiny Nudges")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                Text(persona.ui.menuTagline)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .opacity(0.65)
            }
            .foregroundColor(ink)
            Spacer(minLength: 0)
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
    let persona: Persona
    @Binding var choice: String
    @StateObject private var open = PickerState()
    let symbol: String
    let title: String
    let tint: Color
    let next: Date
    var note: String? = nil
    let action: () -> Void

    private var palette: Persona.Palette { persona.palette }
    private var ink: Color { Color(palette.ink) }

    /// "in 12 min", "in 2 h 5 min", "any moment".
    private static func countdown(to date: Date, from now: Date) -> String {
        let minutes = Int((date.timeIntervalSince(now) / 60).rounded(.up))
        if minutes <= 0 { return "any moment" }
        if minutes < 60 { return "in \(minutes) min" }
        return minutes % 60 == 0 ? "in \(minutes / 60) h" : "in \(minutes / 60) h \(minutes % 60) min"
    }

    private func avatar(_ p: Persona, size: CGFloat) -> some View {
        Image(nsImage: p.avatar)
            .resizable().interpolation(.high).aspectRatio(contentMode: .fit)
            .frame(width: size * 0.55, height: size * 0.66)
            .frame(width: size, height: size)
            .background(Circle().fill(Color(p.palette.cream)))
            .overlay(Circle().strokeBorder(ink.opacity(0.25), lineWidth: 1.5))
    }

    /// A picker list: the current character, and a list of all of them when opened.
    /// The list scrolls after a few rows, so any number of characters fits.
    private var picker: some View {
        VStack(spacing: 6) {
            Button { withAnimation(.easeInOut(duration: 0.18)) { open.isOpen.toggle() } } label: {
                HStack(spacing: 8) {
                    avatar(persona, size: 28)
                    Text(persona.name).font(.system(size: 13, weight: .heavy, design: .rounded))
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .rotationEffect(.degrees(open.isOpen ? 180 : 0))
                }
                .foregroundColor(ink)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(ink.opacity(0.08)))
            }
            .buttonStyle(PressableStyle())

            if open.isOpen {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(Persona.all) { p in
                            Button {
                                choice = p.id
                                withAnimation(.easeInOut(duration: 0.18)) { open.isOpen = false }
                            } label: {
                                HStack(spacing: 8) {
                                    avatar(p, size: 26)
                                    Text(p.name).font(.system(size: 12, weight: .bold, design: .rounded))
                                    Spacer(minLength: 0)
                                    if p.id == persona.id { Image(systemName: "checkmark").font(.system(size: 10, weight: .heavy)) }
                                }
                                .foregroundColor(ink)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .frame(height: 32)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(height: min(CGFloat(Persona.all.count) * 34 + 4, 138))   // explicit: a ScrollView alone collapses in the popover
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(ink.opacity(0.2), lineWidth: 1.5))
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            row
            VStack(alignment: .leading, spacing: 6) {
                Text("Nagged by")
                    .font(.system(size: 11, weight: .medium, design: .rounded)).opacity(0.65)
                picker
            }
            .foregroundColor(ink)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous).fill(ink).offset(x: 3, y: 4)
                RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white)
                RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(ink, lineWidth: 2.5)
            }
        )
        .padding(.trailing, 3).padding(.bottom, 4)
    }

    private var row: some View {
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
                if let note {
                    Text(note)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .lineLimit(1)
                }
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

private final class PickerState: ObservableObject {
    @Published var isOpen = false
}
