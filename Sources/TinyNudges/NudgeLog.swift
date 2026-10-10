import Foundation

/// One answered reminder.
struct NudgeEvent: Codable {
    let date: Date
    let reminder: Persona.Reminder
    let outcome: Outcome
    /// Seconds spent on a completed eye break; 0 otherwise.
    let seconds: Int
}

/// A history of every answer (yes / later / Esc), kept in UserDefaults, for the stats in the app window.
@MainActor
final class NudgeLog: ObservableObject {
    @Published private(set) var events: [NudgeEvent]
    private static let key = "nudgeLog"
    private static let maxEvents = 5000

    init() {
        let data = UserDefaults.standard.data(forKey: Self.key)
        events = data.flatMap { try? JSONDecoder().decode([NudgeEvent].self, from: $0) } ?? []
    }

    func record(_ reminder: Persona.Reminder, _ outcome: Outcome, seconds: Int = 0) {
        events.append(NudgeEvent(date: Date(), reminder: reminder, outcome: outcome, seconds: seconds))
        if events.count > Self.maxEvents { events.removeFirst(events.count - Self.maxEvents) }
        if let data = try? JSONEncoder().encode(events) { UserDefaults.standard.set(data, forKey: Self.key) }
    }

    func count(_ reminder: Persona.Reminder, _ outcome: Outcome, since start: Date = .distantPast) -> Int {
        events.filter { $0.reminder == reminder && $0.outcome == outcome && $0.date >= start }.count
    }

    func seconds(_ reminder: Persona.Reminder, since start: Date = .distantPast) -> Int {
        events.filter { $0.reminder == reminder && $0.date >= start }.reduce(0) { $0 + $1.seconds }
    }

    var glassesToday: Int { count(.water, .done, since: Calendar.current.startOfDay(for: Date())) }

    /// The last `days` days (oldest first, ending today) with how many "yes" answers each had.
    func daily(_ reminder: Persona.Reminder, days: Int = 7) -> [(day: Date, done: Int)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<days).reversed().map { back in
            let day = cal.date(byAdding: .day, value: -back, to: today)!
            let next = cal.date(byAdding: .day, value: 1, to: day)!
            let n = events.filter { $0.reminder == reminder && $0.outcome == .done && $0.date >= day && $0.date < next }.count
            return (day, n)
        }
    }
}
