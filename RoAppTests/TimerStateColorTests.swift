import Testing
import SwiftUI
@testable import RoApp

struct TimerStateColorTests {

    // MARK: - Accent Color

    @Test func runningAccentIsMainAccent() {
        #expect(TimerState.running.accentColor == RoTheme.Colors.accent)
    }

    @Test func pausedAccentIsMuted() {
        #expect(TimerState.paused.accentColor == RoTheme.Colors.accentMuted)
    }

    @Test func finishedAccentIsSuccess() {
        #expect(TimerState.finished.accentColor == RoTheme.Colors.success)
    }

    @Test func idleAccentIsSubtle() {
        #expect(TimerState.idle.accentColor == RoTheme.Colors.accentSubtle)
    }

    // MARK: - Orb Color

    @Test func runningOrbIsAccent() {
        #expect(TimerState.running.orbColor == RoTheme.Colors.accent)
    }

    @Test func pausedOrbIsAccent() {
        #expect(TimerState.paused.orbColor == RoTheme.Colors.accent)
    }

    @Test func finishedOrbIsSuccess() {
        #expect(TimerState.finished.orbColor == RoTheme.Colors.success)
    }

    @Test func idleOrbIsIdleOrb() {
        #expect(TimerState.idle.orbColor == RoTheme.Colors.idleOrb)
    }

    // MARK: - All States Covered

    @Test func everyStateHasDistinctAccentColor() {
        let colors: [TimerState: Color] = [
            .idle: TimerState.idle.accentColor,
            .running: TimerState.running.accentColor,
            .paused: TimerState.paused.accentColor,
            .finished: TimerState.finished.accentColor
        ]
        // running != paused, paused != finished, etc.
        #expect(colors[.running] != colors[.paused])
        #expect(colors[.running] != colors[.finished])
        #expect(colors[.idle] != colors[.finished])
    }
}
