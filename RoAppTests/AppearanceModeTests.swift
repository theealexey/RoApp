import Testing
import SwiftUI
@testable import RoApp

struct AppearanceModeTests {

    // MARK: - Raw Values

    @Test func rawValues() {
        #expect(AppearanceMode.system.rawValue == "system")
        #expect(AppearanceMode.light.rawValue == "light")
        #expect(AppearanceMode.dark.rawValue == "dark")
    }

    @Test func initFromRawValue() {
        #expect(AppearanceMode(rawValue: "system") == .system)
        #expect(AppearanceMode(rawValue: "light") == .light)
        #expect(AppearanceMode(rawValue: "dark") == .dark)
    }

    @Test func initFromInvalidRawValueReturnsNil() {
        #expect(AppearanceMode(rawValue: "auto") == nil)
        #expect(AppearanceMode(rawValue: "") == nil)
        #expect(AppearanceMode(rawValue: "DARK") == nil)
    }

    // MARK: - Identifiable

    @Test func idMatchesRawValue() {
        for mode in AppearanceMode.allCases {
            #expect(mode.id == mode.rawValue)
        }
    }

    // MARK: - Color Scheme Mapping

    @Test func systemReturnsNilColorScheme() {
        #expect(AppearanceMode.system.colorScheme == nil)
    }

    @Test func lightReturnsLightColorScheme() {
        #expect(AppearanceMode.light.colorScheme == .light)
    }

    @Test func darkReturnsDarkColorScheme() {
        #expect(AppearanceMode.dark.colorScheme == .dark)
    }

    // MARK: - CaseIterable

    @Test func allCasesContainsExactlyThree() {
        #expect(AppearanceMode.allCases.count == 3)
        #expect(AppearanceMode.allCases.contains(.system))
        #expect(AppearanceMode.allCases.contains(.light))
        #expect(AppearanceMode.allCases.contains(.dark))
    }
}
