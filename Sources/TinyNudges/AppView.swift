import SwiftUI

/// The app window: reminders (with characters and today's glasses) and all settings.
struct AppView: View {
    @EnvironmentObject private var scheduler: NudgeScheduler
    @AppStorage(Persona.Reminder.water.storageKey) private var waterID = ""
    @AppStorage(Persona.Reminder.eye.storageKey) private var eyeID = ""
    @StateObject private var nav = TabState()

    enum Tab: String, CaseIterable { case reminders = "Reminders", settings = "Settings" }

    private final class TabState: ObservableObject {
        @Published var tab = Tab.reminders
        /// The reminder whose stats are open on the Reminders tab.
        @Published var detail: Persona.Reminder?
    }

    private var persona: Persona { Persona.resolve(waterID, for: .water) }
    private var eyePersona: Persona { Persona.resolve(eyeID, for: .eye) }
    private var palette: Persona.Palette { persona.palette }
    private var ink: Color { Color(palette.ink) }

    var body: some View {
        VStack(spacing: 14) {
            header
            if nav.detail == nil { tabs }
            ScrollView {
                VStack(spacing: 14) {
                    switch nav.tab {
                    case .reminders:
                        if let r = nav.detail {
                            ReminderDetailView(log: scheduler.log, reminder: r,
                                               persona: r == .water ? persona : eyePersona,
                                               tint: r == .water ? Color(palette.aqua) : Color(eyePersona.palette.apricot),
                                               back: { nav.detail = nil })
                        } else {
                            ReminderCard(persona: persona, choice: $waterID, symbol: "drop.fill", title: "Water", tint: Color(palette.aqua),
                                         next: scheduler.nextWater, onOpen: { nav.detail = .water }, action: { scheduler.waterNow() })
                            ReminderCard(persona: eyePersona, choice: $eyeID, symbol: "eye.fill", title: "Eye break", tint: Color(eyePersona.palette.apricot),
                                         next: scheduler.nextEye, onOpen: { nav.detail = .eye }, action: { scheduler.eyeBreakNow() })
                        }
                    case .settings:
                        SettingsView()
                    }
                }
                .padding(.horizontal, 4).padding(.bottom, 6)
            }
        }
        .padding(20)
        .frame(width: 460, height: 620)
        .background(Color(palette.cream))
        .animation(.easeInOut(duration: 0.2), value: waterID)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(nsImage: MenuBarView.logo)
                .resizable().interpolation(.high).aspectRatio(contentMode: .fit)
                .frame(width: 52, height: 52)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(ink, lineWidth: 2.5))
            VStack(alignment: .leading, spacing: 1) {
                Text("Tiny Nudges")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                Text(persona.ui.menuTagline)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .opacity(0.65)
            }
            .foregroundColor(ink)
            Spacer(minLength: 0)
        }
    }

    private var tabs: some View {
        HStack(spacing: 6) {
            ForEach(Tab.allCases, id: \.self) { t in
                Button { nav.tab = t } label: {
                    Text(t.rawValue)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(nav.tab == t ? Color(palette.aqua) : ink.opacity(0.08)))
                        .overlay(Capsule().strokeBorder(ink, lineWidth: nav.tab == t ? 2 : 0))
                }
                .buttonStyle(PressableStyle())
            }
        }
    }
}
