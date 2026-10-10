import SwiftUI

/// Stats for one reminder: how it was answered, totals, and a 7-day tracker.
struct ReminderDetailView: View {
    @ObservedObject var log: NudgeLog
    let reminder: Persona.Reminder
    let persona: Persona
    let tint: Color
    let back: () -> Void

    private var palette: Persona.Palette { persona.palette }
    private var ink: Color { Color(palette.ink) }
    private var isWater: Bool { reminder == .water }
    private var startOfToday: Date { Calendar.current.startOfDay(for: Date()) }

    private var done: Int { log.count(reminder, .done) }
    private var later: Int { log.count(reminder, .later) }
    private var skipped: Int { log.count(reminder, .dismissed) }
    private var answered: Int { done + later + skipped }
    private var doneToday: Int { log.count(reminder, .done, since: startOfToday) }
    private var days: [(day: Date, done: Int)] { log.daily(reminder) }

    private var title: String { isWater ? "Water" : "Eye break" }
    private var symbol: String { isWater ? "drop.fill" : "eye.fill" }
    private var heroTitle: String { isWater ? "glasses of water with Tiny Nudges" : "eye breaks taken with Tiny Nudges" }
    private var todayLabel: String { isWater ? "glasses today" : "breaks today" }
    private var yesLabel: String { isWater ? "Yes, drank it" : "Break taken" }
    private var laterLabel: String { isWater ? "Maybe later" : "Not yet" }

    private func minutesText(_ seconds: Int) -> String {
        seconds < 60 ? "\(seconds) sec" : (seconds % 60 == 0 ? "\(seconds / 60) min" : "\(seconds / 60) min \(seconds % 60) sec")
    }

    var body: some View {
        VStack(spacing: 14) {
            topBar
            hero
            HStack(spacing: 10) {
                StatTile(palette: palette, value: "\(done)", label: yesLabel, tint: tint)
                StatTile(palette: palette, value: "\(later)", label: laterLabel, tint: Color(palette.blush))
                StatTile(palette: palette, value: "\(skipped)", label: "Skipped (Esc)", tint: ink.opacity(0.12))
            }
            if answered > 0 {
                HStack {
                    Text("You said yes to \(Int((Double(done) / Double(answered) * 100).rounded()))% of \(answered) reminders")
                    Spacer(minLength: 0)
                    if !isWater { Text("\(minutesText(log.seconds(.eye))) resting your eyes") }
                }
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(ink.opacity(0.7))
                .padding(.horizontal, 4)
            }
            tracker
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Button(action: back) {
                Label("Reminders", systemImage: "chevron.left")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(ink)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Capsule().fill(ink.opacity(0.08)))
            }
            .buttonStyle(PressableStyle())
            Spacer(minLength: 0)
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(ink)
                .frame(width: 26, height: 26)
                .background(Circle().fill(tint))
                .overlay(Circle().strokeBorder(ink, lineWidth: 2))
            Text(title).font(.system(size: 17, weight: .heavy, design: .rounded)).foregroundColor(ink)
        }
    }

    private var hero: some View {
        HStack(spacing: 14) {
            Text("\(done)")
                .font(.system(size: 52, weight: .heavy, design: .rounded))
                .foregroundColor(ink)
            VStack(alignment: .leading, spacing: 4) {
                Text(heroTitle).font(.system(size: 13, weight: .heavy, design: .rounded))
                Text("\(doneToday) \(todayLabel)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(Capsule().fill(tint.opacity(0.5)))
            }
            .foregroundColor(ink)
            Spacer(minLength: 0)
        }
        .padding(14)
        .modifier(CardStyle(ink: ink))
    }

    private var tracker: some View {
        let data = days
        let peak = max(data.map(\.done).max() ?? 0, 1)
        let week = data.reduce(0) { $0 + $1.done }
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Daily tracker").font(.system(size: 14, weight: .heavy, design: .rounded))
                Spacer(minLength: 0)
                Text("\(week) this week").font(.system(size: 11, weight: .medium, design: .rounded)).opacity(0.7)
            }
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(data.indices, id: \.self) { i in
                    let isToday = i == data.count - 1
                    VStack(spacing: 4) {
                        Text("\(data[i].done)").font(.system(size: 11, weight: .heavy, design: .rounded))
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(data[i].done == 0 ? ink.opacity(0.12) : tint)
                            .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(ink, lineWidth: data[i].done == 0 ? 0 : 1.5))
                            .frame(height: max(6, CGFloat(data[i].done) / CGFloat(peak) * 80))
                        Text(data[i].day.formatted(.dateTime.weekday(.narrow)))
                            .font(.system(size: 11, weight: isToday ? .heavy : .medium, design: .rounded))
                            .opacity(isToday ? 1 : 0.6)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 120, alignment: .bottom)
        }
        .foregroundColor(ink)
        .padding(14)
        .modifier(CardStyle(ink: ink))
    }
}

private struct StatTile: View {
    let palette: Persona.Palette
    let value: String
    let label: String
    let tint: Color

    private var ink: Color { Color(palette.ink) }

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 24, weight: .heavy, design: .rounded))
            Text(label).font(.system(size: 10, weight: .bold, design: .rounded)).opacity(0.75)
                .lineLimit(1).minimumScaleFactor(0.8)
        }
        .foregroundColor(ink)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(tint.opacity(0.5)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(ink, lineWidth: 2))
    }
}

/// The white bordered card with an offset shadow used across the app.
struct CardStyle: ViewModifier {
    let ink: Color

    func body(content: Content) -> some View {
        content
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
}

