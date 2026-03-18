import Testing
import Foundation
@testable import RoApp

struct SettingsStoreTests {

    private func makeSUT() -> SettingsStore {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        return SettingsStore(userDefaults: defaults)
    }

    // MARK: - Defaults

    @Test func defaultFocusDuration() {
        let sut = makeSUT()
        #expect(sut.focusDurationMinutes == 25)
    }

    @Test func defaultShortBreakDuration() {
        let sut = makeSUT()
        #expect(sut.shortBreakDurationMinutes == 5)
    }

    @Test func defaultLongBreakDuration() {
        let sut = makeSUT()
        #expect(sut.longBreakDurationMinutes == 15)
    }

    @Test func defaultBoolSettings() {
        let sut = makeSUT()
        #expect(sut.hapticsEnabled == true)
        #expect(sut.notificationsEnabled == true)
        #expect(sut.autoStartBreaksEnabled == false)
    }

    // MARK: - Clamping

    @Test func clampMinimumToOne() {
        let sut = makeSUT()
        sut.focusDurationMinutes = 0
        #expect(sut.focusDurationMinutes == 1)
    }

    @Test func clampNegativeToOne() {
        let sut = makeSUT()
        sut.focusDurationMinutes = -10
        #expect(sut.focusDurationMinutes == 1)
    }

    @Test func clampMaximumTo180() {
        let sut = makeSUT()
        sut.focusDurationMinutes = 200
        #expect(sut.focusDurationMinutes == 180)
    }

    @Test func validValuePassesThrough() {
        let sut = makeSUT()
        sut.focusDurationMinutes = 45
        #expect(sut.focusDurationMinutes == 45)
    }

    @Test func clampAppliesToAllDurations() {
        let sut = makeSUT()

        sut.shortBreakDurationMinutes = 0
        #expect(sut.shortBreakDurationMinutes == 1)

        sut.longBreakDurationMinutes = 999
        #expect(sut.longBreakDurationMinutes == 180)
    }

    // MARK: - duration(for:)

    @Test func durationForFocus() {
        let sut = makeSUT()
        #expect(sut.duration(for: "focus") == 25 * 60)
    }

    @Test func durationForShort() {
        let sut = makeSUT()
        #expect(sut.duration(for: "short") == 5 * 60)
    }

    @Test func durationForLong() {
        let sut = makeSUT()
        #expect(sut.duration(for: "long") == 15 * 60)
    }

    @Test func durationForUnknownFallsBackToFocus() {
        let sut = makeSUT()
        #expect(sut.duration(for: "invalid") == 25 * 60)
    }

    @Test func durationReflectsCustomValues() {
        let sut = makeSUT()
        sut.focusDurationMinutes = 50
        #expect(sut.duration(for: "focus") == 50 * 60)
    }

    // MARK: - Bool persistence

    @Test func toggleBoolSettings() {
        let sut = makeSUT()
        sut.hapticsEnabled = false
        #expect(sut.hapticsEnabled == false)

        sut.notificationsEnabled = false
        #expect(sut.notificationsEnabled == false)

        sut.autoStartBreaksEnabled = true
        #expect(sut.autoStartBreaksEnabled == true)
    }
}
