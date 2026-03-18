import Testing
import Foundation
@testable import RoApp

struct TimerModelTests {

    // MARK: - TimerMode

    @Test func focusDefaultDuration() {
        #expect(TimerMode.focus.defaultDuration == 25 * 60)
    }

    @Test func shortDefaultDuration() {
        #expect(TimerMode.short.defaultDuration == 5 * 60)
    }

    @Test func longDefaultDuration() {
        #expect(TimerMode.long.defaultDuration == 15 * 60)
    }

    @Test func rawValues() {
        #expect(TimerMode.focus.rawValue == "focus")
        #expect(TimerMode.short.rawValue == "short")
        #expect(TimerMode.long.rawValue == "long")
    }

    @Test func allCasesContainsThreeModes() {
        #expect(TimerMode.allCases.count == 3)
        #expect(TimerMode.allCases.contains(.focus))
        #expect(TimerMode.allCases.contains(.short))
        #expect(TimerMode.allCases.contains(.long))
    }

    @Test func identifiableUsesRawValue() {
        for mode in TimerMode.allCases {
            #expect(mode.id == mode.rawValue)
        }
    }

    @Test func codableRoundTrip() throws {
        for mode in TimerMode.allCases {
            let data = try JSONEncoder().encode(mode)
            let decoded = try JSONDecoder().decode(TimerMode.self, from: data)
            #expect(decoded == mode)
        }
    }

    // MARK: - TimerState

    @Test func timerStateEquality() {
        #expect(TimerState.idle == TimerState.idle)
        #expect(TimerState.running == TimerState.running)
        #expect(TimerState.paused == TimerState.paused)
        #expect(TimerState.finished == TimerState.finished)
        #expect(TimerState.idle != TimerState.running)
    }
}
