import Testing
import Foundation
@testable import RoApp

@MainActor
struct StatisticsViewModelTests {

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

    private func makeSession(
        mode: TimerMode = .focus,
        durationMinutes: Int = 25,
        daysAgo: Int = 0,
        hour: Int = 12
    ) -> MockFocusSessionData {
        let date = Calendar.current.date(
            byAdding: .day,
            value: -daysAgo,
            to: Calendar.current.date(
                bySettingHour: hour, minute: 0, second: 0,
                of: Date()
            )!
        )!
        return MockFocusSessionData(
            mode: mode,
            duration: TimeInterval(durationMinutes * 60),
            completedAt: date
        )
    }

    // MARK: - Empty State

    @Test func emptyRepositoryReturnsZeros() {
        let (vm, repo) = makeSUT()
        vm.load()
        #expect(vm.todayMinutes == 0)
        #expect(vm.todaySessions == 0)
        #expect(vm.currentStreak == 0)
        #expect(vm.longestStreak == 0)
        #expect(vm.weekBars.count == 7)
        #expect(vm.weekBars.allSatisfy { $0.minutes == 0 })
        #expect(vm.recentSessions.isEmpty)
    }

    // MARK: - Fetch Failure

    @Test func fetchFailureResetsToZeros() {
        let (vm, repo) = makeSUT()

        // First load with data
        repo.sessionsToReturn = [makeSession()]
        vm.load()
        #expect(vm.todaySessions > 0)

        // Then fail
        repo.shouldThrow = true
        vm.load()
        #expect(vm.todayMinutes == 0)
        #expect(vm.todaySessions == 0)
        #expect(vm.currentStreak == 0)
        #expect(vm.longestStreak == 0)
    }

    // MARK: - Today's Sessions

    @Test func todaySessionsCounted() {
        let (vm, repo) = makeSUT()
        repo.sessionsToReturn = [
            makeSession(durationMinutes: 25, daysAgo: 0),
            makeSession(durationMinutes: 30, daysAgo: 0),
            makeSession(durationMinutes: 25, daysAgo: 1),
        ]
        vm.load()
        #expect(vm.todaySessions == 2)
        #expect(vm.todayMinutes == 55)
    }

    @Test func nonFocusSessionsExcludedFromTodayCount() {
        let (vm, repo) = makeSUT()
        repo.sessionsToReturn = [
            makeSession(mode: .focus, durationMinutes: 25, daysAgo: 0),
            makeSession(mode: .short, durationMinutes: 5, daysAgo: 0),
        ]
        vm.load()
        #expect(vm.todaySessions == 1)
        #expect(vm.todayMinutes == 25)
    }

    // MARK: - Week Bars

    @Test func weekBarsHasSevenItems() {
        let (vm, repo) = makeSUT()
        repo.sessionsToReturn = [makeSession()]
        vm.load()
        #expect(vm.weekBars.count == 7)
    }

    @Test func weekBarsContainsTodaysMinutes() {
        let (vm, repo) = makeSUT()
        repo.sessionsToReturn = [
            makeSession(durationMinutes: 25, daysAgo: 0),
            makeSession(durationMinutes: 30, daysAgo: 0),
        ]
        vm.load()
        let todayBar = vm.weekBars.last
        #expect(todayBar?.minutes == 55)
    }

    // MARK: - Streaks

    @Test func singleDayStreak() {
        let (vm, repo) = makeSUT()
        repo.sessionsToReturn = [makeSession(daysAgo: 0)]
        vm.load()
        #expect(vm.currentStreak == 1)
        #expect(vm.longestStreak == 1)
    }

    @Test func consecutiveDaysStreak() {
        let (vm, repo) = makeSUT()
        repo.sessionsToReturn = [
            makeSession(daysAgo: 0),
            makeSession(daysAgo: 1),
            makeSession(daysAgo: 2),
        ]
        vm.load()
        #expect(vm.currentStreak == 3)
        #expect(vm.longestStreak == 3)
    }

    @Test func gapBreaksCurrentStreak() {
        let (vm, repo) = makeSUT()
        repo.sessionsToReturn = [
            makeSession(daysAgo: 0),
            // gap at daysAgo: 1
            makeSession(daysAgo: 2),
            makeSession(daysAgo: 3),
        ]
        vm.load()
        #expect(vm.currentStreak == 1)
        #expect(vm.longestStreak == 2)
    }

    @Test func streakStartsFromYesterday() {
        let (vm, repo) = makeSUT()
        repo.sessionsToReturn = [
            makeSession(daysAgo: 1),
            makeSession(daysAgo: 2),
        ]
        vm.load()
        #expect(vm.currentStreak == 2)
    }

    @Test func noRecentSessionsMeansZeroCurrentStreak() {
        let (vm, repo) = makeSUT()
        repo.sessionsToReturn = [
            makeSession(daysAgo: 5),
        ]
        vm.load()
        #expect(vm.currentStreak == 0)
    }

    // MARK: - Recent Sessions

    @Test func recentSessionsLimitedToTen() {
        let (vm, repo) = makeSUT()
        repo.sessionsToReturn = (0..<15).map { i in
            makeSession(daysAgo: i)
        }
        vm.load()
        #expect(vm.recentSessions.count == 10)
    }
}
