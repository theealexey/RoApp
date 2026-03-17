import SwiftData
import Foundation

@MainActor @Observable
final class StatisticsViewModel {

    private(set) var todayMinutes: Int  = 0
    private(set) var todaySessions: Int = 0
    private(set) var currentStreak: Int = 0
    private(set) var longestStreak: Int = 0
    private(set) var weekBars: [DayBar] = []
    private(set) var recentSessions: [FocusSession] = []

    func load(repository: SessionRepositoryProtocol) {
        guard let all = try? repository.fetchAll() else { return }

        let focus = all.filter { $0.mode == .focus }
        let todayStart = Calendar.current.startOfDay(for: Date())
        let todayFocus = focus.filter { $0.completedAt >= todayStart }

        todayMinutes  = todayFocus.reduce(0) { $0 + $1.durationMinutes }
        todaySessions = todayFocus.count
        recentSessions = Array(all.prefix(10))
        weekBars = buildWeekBars(from: focus)

        let streaks   = computeStreaks(from: focus)
        currentStreak = streaks.current
        longestStreak = streaks.longest
    }

    private func buildWeekBars(from sessions: [FocusSession]) -> [DayBar] {
        let cal = Calendar.current
        return (0..<7).reversed().map { offset -> DayBar in
            guard let date = cal.date(byAdding: .day, value: -offset, to: Date()) else {
                return DayBar(date: Date(), minutes: 0)
            }
            let start = cal.startOfDay(for: date)
            let end   = cal.date(byAdding: .day, value: 1, to: start)!
            let mins  = sessions
                .filter { $0.completedAt >= start && $0.completedAt < end }
                .reduce(0) { $0 + $1.durationMinutes }
            return DayBar(date: date, minutes: mins)
        }
    }

    private func computeStreaks(from sessions: [FocusSession]) -> (current: Int, longest: Int) {
        guard !sessions.isEmpty else { return (0, 0) }
        let cal = Calendar.current

        let uniqueDays = Set(sessions.map {
            cal.dateComponents([.year, .month, .day], from: $0.completedAt)
        })
        let sorted = uniqueDays
            .compactMap { cal.date(from: $0) }
            .sorted(by: >)

        let today     = cal.startOfDay(for: Date())
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!

        var current = 0
        if let first = sorted.first,
           cal.startOfDay(for: first) == today || cal.startOfDay(for: first) == yesterday {
            current = 1
            for i in 1..<sorted.count {
                let prev = cal.startOfDay(for: sorted[i - 1])
                let curr = cal.startOfDay(for: sorted[i])
                guard cal.dateComponents([.day], from: curr, to: prev).day == 1 else { break }
                current += 1
            }
        }

        var longest = current
        var streak  = 1
        for i in 1..<sorted.count {
            let prev = cal.startOfDay(for: sorted[i - 1])
            let curr = cal.startOfDay(for: sorted[i])
            if cal.dateComponents([.day], from: curr, to: prev).day == 1 {
                streak += 1
                longest = max(longest, streak)
            } else {
                streak = 1
            }
        }

        return (current, max(longest, 1))
    }
}

struct DayBar: Identifiable {
    let id    = UUID()
    let date: Date
    let minutes: Int

    private static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    var label: String {
        let s = Self.weekdayFormatter.string(from: date)
        return s.prefix(1).uppercased() + s.dropFirst().lowercased()
    }
}
