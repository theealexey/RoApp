import Testing
import Foundation
@testable import RoApp

struct SettingsStoreAppearanceTests {

    private func makeSUT() -> SettingsStore {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        return SettingsStore(userDefaults: defaults)
    }

    // MARK: - Appearance Mode Defaults

    @Test func defaultAppearanceModeIsSystem() {
        let sut = makeSUT()
        #expect(sut.appearanceMode == .system)
    }

    // MARK: - Appearance Mode Persistence

    @Test func setLightMode() {
        let sut = makeSUT()
        sut.appearanceMode = .light
        #expect(sut.appearanceMode == .light)
    }

    @Test func setDarkMode() {
        let sut = makeSUT()
        sut.appearanceMode = .dark
        #expect(sut.appearanceMode == .dark)
    }

    @Test func setSystemMode() {
        let sut = makeSUT()
        sut.appearanceMode = .dark
        sut.appearanceMode = .system
        #expect(sut.appearanceMode == .system)
    }

    // MARK: - Corrupt Data Fallback

    @Test func corruptAppearanceModeRawFallsBackToSystem() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        defaults.set("garbage", forKey: "appearanceMode")
        let sut = SettingsStore(userDefaults: defaults)
        #expect(sut.appearanceMode == .system)
    }

    @Test func missingAppearanceModeKeyFallsBackToSystem() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        // Don't set anything
        let sut = SettingsStore(userDefaults: defaults)
        #expect(sut.appearanceMode == .system)
    }

    // MARK: - Edge Cases for Existing Settings

    @Test func registerDefaultsDoesNotOverwriteExistingValues() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        defaults.set(50, forKey: "focusDurationMinutes")
        let sut = SettingsStore(userDefaults: defaults)
        #expect(sut.focusDurationMinutes == 50)
    }

    @Test func clampedMinutesFallbackForMissingKey() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        // register defaults will set these, so read should work
        let sut = SettingsStore(userDefaults: defaults)
        #expect(sut.focusDurationMinutes == 25)
        #expect(sut.shortBreakDurationMinutes == 5)
        #expect(sut.longBreakDurationMinutes == 15)
    }

    // MARK: - Boundary Clamping

    @Test func clampAtExactBoundaries() {
        let sut = makeSUT()
        sut.focusDurationMinutes = 1
        #expect(sut.focusDurationMinutes == 1)

        sut.focusDurationMinutes = 180
        #expect(sut.focusDurationMinutes == 180)
    }

    @Test func clampJustOutsideBoundaries() {
        let sut = makeSUT()
        sut.shortBreakDurationMinutes = 0
        #expect(sut.shortBreakDurationMinutes == 1)

        sut.shortBreakDurationMinutes = 181
        #expect(sut.shortBreakDurationMinutes == 180)
    }
}
