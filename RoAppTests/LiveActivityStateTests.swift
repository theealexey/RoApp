import Testing
import Foundation
@testable import RoApp

struct LiveActivityStateTests {

    private func makeState(
        timeRemaining: TimeInterval = 300,
        totalDuration: TimeInterval = 1500,
        modeRaw: String = "focus",
        isRunning: Bool = false,
        endDate: Date? = nil
    ) -> RoTimerAttributes.ContentState {
        RoTimerAttributes.ContentState(
            timeRemaining: timeRemaining,
            totalDuration: totalDuration,
            modeRaw: modeRaw,
            isRunning: isRunning,
            endDate: endDate
        )
    }

    // MARK: - Progress

    @Test func progressAtStartIsZero() {
        let state = makeState(timeRemaining: 1500, totalDuration: 1500)
        #expect(state.progress == 0)
    }

    @Test func progressAtHalfway() {
        let state = makeState(timeRemaining: 750, totalDuration: 1500)
        let diff = abs(state.progress - 0.5)
        #expect(diff < 0.01)
    }

    @Test func progressAtEndIsOne() {
        let state = makeState(timeRemaining: 0, totalDuration: 1500)
        #expect(state.progress == 1.0)
    }

    @Test func progressWithZeroTotalDuration() {
        let state = makeState(timeRemaining: 100, totalDuration: 0)
        #expect(state.progress == 0)
    }

    @Test func progressClampsToZeroWhenNegative() {
        let state = makeState(timeRemaining: 2000, totalDuration: 1500)
        #expect(state.progress >= 0)
    }

    @Test func progressClampsToOneWhenOverflow() {
        let state = makeState(timeRemaining: -100, totalDuration: 1500)
        #expect(state.progress <= 1)
    }

    // MARK: - Formatted Time

    @Test func formattedTimeZero() {
        let state = makeState(timeRemaining: 0)
        #expect(state.formattedTime == "00:00")
    }

    @Test func formattedTimeFiveMinutes() {
        let state = makeState(timeRemaining: 300)
        #expect(state.formattedTime == "05:00")
    }

    @Test func formattedTimeTwentyFiveMinutes() {
        let state = makeState(timeRemaining: 1500)
        #expect(state.formattedTime == "25:00")
    }

    @Test func formattedTimeWithSeconds() {
        let state = makeState(timeRemaining: 67)
        #expect(state.formattedTime == "01:07")
    }

    @Test func formattedTimeNegativeClampsToZero() {
        let state = makeState(timeRemaining: -5)
        #expect(state.formattedTime == "00:00")
    }

    // MARK: - Live Time Remaining

    @Test func liveTimeRemainingWhenNotRunning() {
        let state = makeState(timeRemaining: 300, isRunning: false)
        #expect(state.liveTimeRemaining == 300)
    }

    @Test func liveTimeRemainingWhenRunningWithEndDate() {
        let endDate = Date().addingTimeInterval(120)
        let state = makeState(timeRemaining: 300, isRunning: true, endDate: endDate)
        let live = state.liveTimeRemaining
        #expect(live > 118)
        #expect(live <= 120)
    }

    @Test func liveTimeRemainingWhenRunningWithPastEndDate() {
        let endDate = Date().addingTimeInterval(-10)
        let state = makeState(timeRemaining: 300, isRunning: true, endDate: endDate)
        #expect(state.liveTimeRemaining == 0)
    }

    @Test func liveTimeRemainingWhenRunningNoEndDate() {
        let state = makeState(timeRemaining: 300, isRunning: true, endDate: nil)
        #expect(state.liveTimeRemaining == 300)
    }

    @Test func liveTimeRemainingNegativeTimeRemaining() {
        let state = makeState(timeRemaining: -50, isRunning: false)
        #expect(state.liveTimeRemaining == 0)
    }

    // MARK: - Mode Label

    @Test func modeLabelFocus() {
        let state = makeState(modeRaw: "focus")
        #expect(state.modeLabel == "FOCUS")
    }

    @Test func modeLabelShort() {
        let state = makeState(modeRaw: "short")
        #expect(state.modeLabel == "BREAK")
    }

    @Test func modeLabelLong() {
        let state = makeState(modeRaw: "long")
        #expect(state.modeLabel == "LONG BREAK")
    }

    @Test func modeLabelUnknownFallsBackToFocus() {
        let state = makeState(modeRaw: "invalid")
        #expect(state.modeLabel == "FOCUS")
    }

    // MARK: - Accent Color

    @Test func accentColorFocus() {
        let state = makeState(modeRaw: "focus")
        #expect(state.accentColor != makeState(modeRaw: "short").accentColor)
    }

    @Test func accentColorShortAndLongAreSame() {
        let short = makeState(modeRaw: "short")
        let long = makeState(modeRaw: "long")
        #expect(short.accentColor == long.accentColor)
    }

    @Test func accentColorUnknownFallsBackToFocus() {
        let unknown = makeState(modeRaw: "???")
        let focus = makeState(modeRaw: "focus")
        #expect(unknown.accentColor == focus.accentColor)
    }

    // MARK: - Codable

    @Test func codableRoundTrip() throws {
        let original = makeState(
            timeRemaining: 742,
            totalDuration: 1500,
            modeRaw: "short",
            isRunning: true,
            endDate: Date(timeIntervalSince1970: 1700000000)
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RoTimerAttributes.ContentState.self, from: data)

        #expect(decoded.timeRemaining == original.timeRemaining)
        #expect(decoded.totalDuration == original.totalDuration)
        #expect(decoded.modeRaw == original.modeRaw)
        #expect(decoded.isRunning == original.isRunning)
        #expect(decoded.endDate == original.endDate)
    }

    @Test func codableWithNilEndDate() throws {
        let original = makeState(endDate: nil)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RoTimerAttributes.ContentState.self, from: data)
        #expect(decoded.endDate == nil)
    }

    // MARK: - Hashable

    @Test func hashableEquality() {
        let a = makeState(timeRemaining: 100, modeRaw: "focus")
        let b = makeState(timeRemaining: 100, modeRaw: "focus")
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }

    @Test func hashableInequality() {
        let a = makeState(timeRemaining: 100, modeRaw: "focus")
        let b = makeState(timeRemaining: 200, modeRaw: "focus")
        #expect(a != b)
    }
}
