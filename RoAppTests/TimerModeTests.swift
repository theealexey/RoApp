import Testing
import Foundation
@testable import RoApp

struct TimerModeTests {

    // MARK: - Raw Values

    @Test func rawValues() {
        #expect(TimerMode.focus.rawValue == "focus")
        #expect(TimerMode.short.rawValue == "short")
        #expect(TimerMode.long.rawValue == "long")
    }

    @Test func initFromRawValue() {
        #expect(TimerMode(rawValue: "focus") == .focus)
        #expect(TimerMode(rawValue: "short") == .short)
        #expect(TimerMode(rawValue: "long") == .long)
    }

    @Test func initFromInvalidRawValueReturnsNil() {
        #expect(TimerMode(rawValue: "break") == nil)
        #expect(TimerMode(rawValue: "Фокус") == nil)
        #expect(TimerMode(rawValue: "") == nil)
    }

    // MARK: - Default Durations

    @Test func focusDefaultDurationIs25Minutes() {
        #expect(TimerMode.focus.defaultDuration == 1500)
    }

    @Test func shortDefaultDurationIs5Minutes() {
        #expect(TimerMode.short.defaultDuration == 300)
    }

    @Test func longDefaultDurationIs15Minutes() {
        #expect(TimerMode.long.defaultDuration == 900)
    }

    // MARK: - Labels

    @Test func labelENFocus() {
        #expect(TimerMode.focus.labelEN == "FOCUS")
    }

    @Test func labelENShort() {
        #expect(TimerMode.short.labelEN == "BREAK")
    }

    @Test func labelENLong() {
        #expect(TimerMode.long.labelEN == "LONG BREAK")
    }

    // MARK: - Identifiable

    @Test func idMatchesRawValue() {
        for mode in TimerMode.allCases {
            #expect(mode.id == mode.rawValue)
        }
    }

    // MARK: - CaseIterable

    @Test func allCasesContainsExactlyThree() {
        #expect(TimerMode.allCases.count == 3)
    }

    // MARK: - Codable

    @Test func codableRoundTrip() throws {
        for mode in TimerMode.allCases {
            let data = try JSONEncoder().encode(mode)
            let decoded = try JSONDecoder().decode(TimerMode.self, from: data)
            #expect(decoded == mode)
        }
    }

    @Test func codableFromJSON() throws {
        let json = "\"focus\"".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(TimerMode.self, from: json)
        #expect(decoded == .focus)
    }

    @Test func codableInvalidJSONThrows() {
        let json = "\"invalid\"".data(using: .utf8)!
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(TimerMode.self, from: json)
        }
    }

    // MARK: - Sendable

    @Test func sendableAcrossTasks() async {
        let mode: TimerMode = .focus
        let result = await Task.detached { mode }.value
        #expect(result == .focus)
    }
}
