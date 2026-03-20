import Testing
import Foundation
@testable import RoApp

struct FocusSessionTests {

    // MARK: - Initialization

    @Test func initSetsCorrectMode() {
        let session = FocusSession(mode: .focus, duration: 1500)
        #expect(session.modeRaw == "focus")
        #expect(session.mode == .focus)
    }

    @Test func initSetsDuration() {
        let session = FocusSession(mode: .short, duration: 300)
        #expect(session.duration == 300)
    }

    @Test func initSetsCompletedAtToNow() {
        let before = Date()
        let session = FocusSession(mode: .focus, duration: 100)
        let after = Date()
        #expect(session.completedAt >= before)
        #expect(session.completedAt <= after)
    }

    @Test func initGeneratesUniqueIDs() {
        let a = FocusSession(mode: .focus, duration: 100)
        let b = FocusSession(mode: .focus, duration: 100)
        #expect(a.id != b.id)
    }

    // MARK: - Mode Property (legacy migration)

    @Test func modeFocusFromRawValue() {
        let session = FocusSession(mode: .focus, duration: 100)
        session.modeRaw = "focus"
        #expect(session.mode == .focus)
    }

    @Test func modeShortFromRawValue() {
        let session = FocusSession(mode: .focus, duration: 100)
        session.modeRaw = "short"
        #expect(session.mode == .short)
    }

    @Test func modeLongFromRawValue() {
        let session = FocusSession(mode: .focus, duration: 100)
        session.modeRaw = "long"
        #expect(session.mode == .long)
    }

    @Test func legacyRussianFocusMigrates() {
        let session = FocusSession(mode: .focus, duration: 100)
        session.modeRaw = "Фокус"
        #expect(session.mode == .focus)
    }

    @Test func legacyRussianShortMigrates() {
        let session = FocusSession(mode: .focus, duration: 100)
        session.modeRaw = "Перерыв"
        #expect(session.mode == .short)
    }

    @Test func legacyRussianLongMigrates() {
        let session = FocusSession(mode: .focus, duration: 100)
        session.modeRaw = "Длинный"
        #expect(session.mode == .long)
    }

    @Test func unknownRawValueFallsBackToFocus() {
        let session = FocusSession(mode: .focus, duration: 100)
        session.modeRaw = "garbage"
        #expect(session.mode == .focus)
    }

    @Test func emptyRawValueFallsBackToFocus() {
        let session = FocusSession(mode: .focus, duration: 100)
        session.modeRaw = ""
        #expect(session.mode == .focus)
    }

    // MARK: - Duration Minutes

    @Test func durationMinutesCalculatesCorrectly() {
        let session = FocusSession(mode: .focus, duration: 1500)
        #expect(session.durationMinutes == 25)
    }

    @Test func durationMinutesTruncatesPartialMinutes() {
        let session = FocusSession(mode: .focus, duration: 90) // 1.5 min
        #expect(session.durationMinutes == 1)
    }

    @Test func durationMinutesZeroForShortDuration() {
        let session = FocusSession(mode: .focus, duration: 30) // 0.5 min
        #expect(session.durationMinutes == 0)
    }

    // MARK: - All Modes Produce Correct Sessions

    @Test(arguments: TimerMode.allCases)
    func initPreservesMode(mode: TimerMode) {
        let session = FocusSession(mode: mode, duration: 600)
        #expect(session.mode == mode)
        #expect(session.modeRaw == mode.rawValue)
    }
}
