import Testing
import Foundation
@testable import RoApp

struct SharedTimerStateTests {

    // MARK: - Codable

    @Test func codableRoundTrip() throws {
        let state = SharedTimerState(
            isRunning: true,
            timeRemaining: 300,
            totalDuration: 1500,
            modeRaw: "focus",
            endDate: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(SharedTimerState.self, from: data)

        #expect(decoded.isRunning == state.isRunning)
        #expect(decoded.timeRemaining == state.timeRemaining)
        #expect(decoded.totalDuration == state.totalDuration)
        #expect(decoded.modeRaw == state.modeRaw)
        #expect(decoded.endDate == state.endDate)
    }

    @Test func codableWithNilEndDate() throws {
        let state = SharedTimerState(
            isRunning: false,
            timeRemaining: 1500,
            totalDuration: 1500,
            modeRaw: "short",
            endDate: nil
        )

        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(SharedTimerState.self, from: data)

        #expect(decoded.endDate == nil)
        #expect(decoded.modeRaw == "short")
    }

    // MARK: - Progress

    @Test func progressAtStart() {
        let state = SharedTimerState(
            isRunning: false,
            timeRemaining: 1500,
            totalDuration: 1500,
            modeRaw: "focus",
            endDate: nil
        )
        #expect(state.progress == 0)
    }

    @Test func progressAtHalfway() {
        let state = SharedTimerState(
            isRunning: false,
            timeRemaining: 750,
            totalDuration: 1500,
            modeRaw: "focus",
            endDate: nil
        )
        #expect(state.progress == 0.5)
    }

    @Test func progressAtEnd() {
        let state = SharedTimerState(
            isRunning: false,
            timeRemaining: 0,
            totalDuration: 1500,
            modeRaw: "focus",
            endDate: nil
        )
        #expect(state.progress == 1.0)
    }

    @Test func progressWithZeroTotalDuration() {
        let state = SharedTimerState(
            isRunning: false,
            timeRemaining: 0,
            totalDuration: 0,
            modeRaw: "focus",
            endDate: nil
        )
        #expect(state.progress == 0)
    }

    // MARK: - Formatted Time

    @Test func formattedTimeFullDuration() {
        let state = SharedTimerState(
            isRunning: false,
            timeRemaining: 1500,
            totalDuration: 1500,
            modeRaw: "focus",
            endDate: nil
        )
        #expect(state.formattedTime == "25:00")
    }

    @Test func formattedTimeNinetySeconds() {
        let state = SharedTimerState(
            isRunning: false,
            timeRemaining: 90,
            totalDuration: 1500,
            modeRaw: "focus",
            endDate: nil
        )
        #expect(state.formattedTime == "01:30")
    }

    @Test func formattedTimeOneSecond() {
        let state = SharedTimerState(
            isRunning: false,
            timeRemaining: 0.5,
            totalDuration: 1500,
            modeRaw: "focus",
            endDate: nil
        )
        #expect(state.formattedTime == "00:01")
    }

    @Test func formattedTimeZero() {
        let state = SharedTimerState(
            isRunning: false,
            timeRemaining: 0,
            totalDuration: 1500,
            modeRaw: "focus",
            endDate: nil
        )
        #expect(state.formattedTime == "00:00")
    }

    // MARK: - Mode Label

    @Test func modeLabelEN() {
        #expect(SharedTimerState(isRunning: false, timeRemaining: 0, totalDuration: 0, modeRaw: "focus", endDate: nil).modeLabelEN == "FOCUS")
        #expect(SharedTimerState(isRunning: false, timeRemaining: 0, totalDuration: 0, modeRaw: "short", endDate: nil).modeLabelEN == "BREAK")
        #expect(SharedTimerState(isRunning: false, timeRemaining: 0, totalDuration: 0, modeRaw: "long", endDate: nil).modeLabelEN == "LONG BREAK")
        #expect(SharedTimerState(isRunning: false, timeRemaining: 0, totalDuration: 0, modeRaw: "unknown", endDate: nil).modeLabelEN == "FOCUS")
    }

    // MARK: - Empty Factory

    @Test func emptyFactory() {
        let empty = SharedTimerState.empty
        #expect(empty.isRunning == false)
        #expect(empty.timeRemaining == 25 * 60)
        #expect(empty.totalDuration == 25 * 60)
        #expect(empty.modeRaw == "focus")
        #expect(empty.endDate == nil)
    }

    // MARK: - Live Time Remaining

    @Test func liveTimeRemainingWhenNotRunning() {
        let state = SharedTimerState(
            isRunning: false,
            timeRemaining: 600,
            totalDuration: 1500,
            modeRaw: "focus",
            endDate: Date.distantFuture
        )
        #expect(state.liveTimeRemaining == 600)
    }

    @Test func liveTimeRemainingWhenRunningUsesEndDate() {
        let endDate = Date().addingTimeInterval(120)
        let state = SharedTimerState(
            isRunning: true,
            timeRemaining: 999,
            totalDuration: 1500,
            modeRaw: "focus",
            endDate: endDate
        )
        let live = state.liveTimeRemaining
        #expect(live > 118 && live <= 120)
    }

    @Test func liveTimeRemainingNeverNegative() {
        let state = SharedTimerState(
            isRunning: true,
            timeRemaining: 0,
            totalDuration: 1500,
            modeRaw: "focus",
            endDate: Date.distantPast
        )
        #expect(state.liveTimeRemaining == 0)
    }
}
