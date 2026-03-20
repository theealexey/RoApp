import Testing
import Foundation
@testable import RoApp

@MainActor
struct StatisticsViewModelEdgeCaseTests {

    private func makeSUT(
        sessions: [MockFocusSessionData] = [],
        shouldThrow: Bool = false
    ) -> (vm: StatisticsViewModel, repo: MockSessionRepository) {
        let repo = MockSessionRepository()
        repo.sessionsToReturn = sessions
        repo.shouldThrow = shouldThrow
        let vm = StatisticsViewModel(repository: repo)
        return (vm, repo)
    }

    private func todaySession(mode: TimerMode = .focus, duration: TimeInterval = 1500) -> MockFocusSessionData {
        MockFocusSessionData(mode: mode, duration: duration, completedAt: Date())
    }

    private func daysAgo(_ days: Int, mode: TimerMode = .focus, duration: TimeInterval = 1500) -> MockFocusSessionData {
        let date = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return MockFocusSessionData(mode: mode, duration: duration, completedAt: date)
    }

    // MARK: - Fetch Failure Resets Everything

    @Test func fetchFailureResetsAllFields() {
        let (vm, repo) = makeSUT(sessions: [todaySession()])

        // First load with data
        vm.load()
        #expect(vm.todaySessions > 0)

        // Then fail
        repo.shouldThrow = true
        vm.load()
        #expect(vm.todayMinutes == 0)
        #expect(vm.todaySessions == 0)
        #expect(vm.currentStreak == 0)
        #expect(vm.longestStreak == 0)
        #expect(vm.weekBars.isEmpty)
        #expect(vm.recentSessions.isEmpty)
    }

    // MARK: - Only Focus Sessions Count for Stats

    @Test func onlyFocusSessionsCountForTodayMinutes() {
        let (vm, _) = makeSUT(sessions: [
            todaySession(mode: .focus, duration: 1500),
            todaySession(mode: .short, duration: 300),
            todaySession(mode: .long, duration: 900),
        ])
        vm.load()
        #expect(vm.todayMinutes == 25) // Only focus counts
        #expect(vm.todaySessions == 1)
    }

    // MARK: - Recent Sessions Limits to 10

    @Test func recentSessionsMaxTen() {
        let sessions = (0..<15).map { i in
            MockFocusSessionData(
                mode: .focus,
                duration: 1500,
                completedAt: Date().addingTimeInterval(TimeInterval(-i * 60))
            )
        }
        let (vm, _) = makeSUT(sessions: sessions)
        vm.load()
        #expect(vm.recentSessions.count == 10)
    }

    @Test func recentSessionsIncludesAllModes() {
        let (vm, _) = makeSUT(sessions: [
            todaySession(mode: .focus),
            todaySession(mode: .short, duration: 300),
            todaySession(mode: .long, duration: 900),
        ])
        vm.load()
        #expect(vm.recentSessions.count == 3) // All modes in recent
    }

    // MARK: - Week Bars

    @Test func weekBarsAlwaysReturnsSeven() {
        let (vm, _) = makeSUT(sessions: [todaySession()])
        vm.load()
        #expect(vm.weekBars.count == 7)
    }

    @Test func weekBarsEmptyWithNoSessions() {
        let (vm, _) = makeSUT()
        vm.load()
        #expect(vm.weekBars.count == 7)
        #expect(vm.weekBars.allSatisfy { $0.minutes == 0 })
    }

    @Test func weekBarsTodaySessionShowsInLastBar() {
        let (vm, _) = makeSUT(sessions: [todaySession(duration: 1500)])
        vm.load()
        let todayBar = vm.weekBars.last!
        #expect(todayBar.minutes == 25)
    }

    // MARK: - Streaks

    @Test func noSessionsNoStreak() {
        let (vm, _) = makeSUT()
        vm.load()
        #expect(vm.currentStreak == 0)
        #expect(vm.longestStreak == 0)
    }

    @Test func todayOnlySessionGivesStreakOfOne() {
        let (vm, _) = makeSUT(sessions: [todaySession()])
        vm.load()
        #expect(vm.currentStreak == 1)
        #expect(vm.longestStreak == 1)
    }

    @Test func threeDayStreakIncludingToday() {
        let (vm, _) = makeSUT(sessions: [
            todaySession(),
            daysAgo(1),
            daysAgo(2),
        ])
        vm.load()
        #expect(vm.currentStreak == 3)
        #expect(vm.longestStreak == 3)
    }

    @Test func brokenStreakCountsOnlyCurrent() {
        let (vm, _) = makeSUT(sessions: [
            todaySession(),
            daysAgo(1),
            // gap at day 2
            daysAgo(3),
            daysAgo(4),
            daysAgo(5),
        ])
        vm.load()
        #expect(vm.currentStreak == 2)
        #expect(vm.longestStreak == 3)
    }

    @Test func yesterdayOnlyStreakCountsAsOne() {
        let (vm, _) = makeSUT(sessions: [daysAgo(1)])
        vm.load()
        #expect(vm.currentStreak == 1)
    }

    @Test func twoDaysAgoOnlyNoCurrentStreak() {
        let (vm, _) = makeSUT(sessions: [daysAgo(2)])
        vm.load()
        #expect(vm.currentStreak == 0)
        #expect(vm.longestStreak == 1)
    }

    @Test func multipleFocusSessionsSameDayCountAsOneStreakDay() {
        let (vm, _) = makeSUT(sessions: [
            todaySession(),
            todaySession(),
            todaySession(),
        ])
        vm.load()
        #expect(vm.currentStreak == 1)
    }

    // MARK: - DayBar

    @Test func dayBarLabel() {
        let bar = DayBar(date: Date(), minutes: 42)
        #expect(!bar.label.isEmpty)
        // First letter should be uppercase
        #expect(bar.label.first?.isUppercase == true)
    }

    @Test func dayBarId() {
        let a = DayBar(date: Date(), minutes: 0)
        let b = DayBar(date: Date(), minutes: 0)
        #expect(a.id != b.id) // UUIDs should be unique
    }
}
