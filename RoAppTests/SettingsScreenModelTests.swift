import Testing
import Foundation
@testable import RoApp

@MainActor
struct SettingsScreenModelTests {

    private func makeSUT(
        settings: MockSettingsStore? = nil
    ) -> (model: SettingsScreenModel, settings: MockSettingsStore) {
        let s = settings ?? MockSettingsStore()
        let model = SettingsScreenModel(settingsStore: s)
        return (model, s)
    }

    // MARK: - Init Reads From Store

    @Test func initReadsFocusFromStore() {
        let store = MockSettingsStore()
        store.focusDurationMinutes = 42
        let (model, _) = makeSUT(settings: store)
        #expect(model.focusMinutes == 42)
    }

    @Test func initReadsShortFromStore() {
        let store = MockSettingsStore()
        store.shortBreakDurationMinutes = 7
        let (model, _) = makeSUT(settings: store)
        #expect(model.shortMinutes == 7)
    }

    @Test func initReadsLongFromStore() {
        let store = MockSettingsStore()
        store.longBreakDurationMinutes = 20
        let (model, _) = makeSUT(settings: store)
        #expect(model.longMinutes == 20)
    }

    @Test func initReadsBooleans() {
        let store = MockSettingsStore()
        store.hapticsEnabled = false
        store.notificationsEnabled = false
        store.autoStartBreaksEnabled = true
        let (model, _) = makeSUT(settings: store)
        #expect(model.hapticsEnabled == false)
        #expect(model.notificationsEnabled == false)
        #expect(model.autoStartBreak == true)
    }

    @Test func initReadsAppearanceMode() {
        let store = MockSettingsStore()
        store.appearanceMode = .dark
        let (model, _) = makeSUT(settings: store)
        #expect(model.appearanceMode == .dark)
    }

    // MARK: - didSet Writes To Store

    @Test func settingFocusMinutesWritesToStore() {
        let (model, store) = makeSUT()
        model.focusMinutes = 50
        #expect(store.focusDurationMinutes == 50)
    }

    @Test func settingShortMinutesWritesToStore() {
        let (model, store) = makeSUT()
        model.shortMinutes = 10
        #expect(store.shortBreakDurationMinutes == 10)
    }

    @Test func settingLongMinutesWritesToStore() {
        let (model, store) = makeSUT()
        model.longMinutes = 30
        #expect(store.longBreakDurationMinutes == 30)
    }

    @Test func settingHapticsWritesToStore() {
        let (model, store) = makeSUT()
        model.hapticsEnabled = false
        #expect(store.hapticsEnabled == false)
    }

    @Test func settingNotificationsWritesToStore() {
        let (model, store) = makeSUT()
        model.notificationsEnabled = false
        #expect(store.notificationsEnabled == false)
    }

    @Test func settingAutoStartBreakWritesToStore() {
        let (model, store) = makeSUT()
        model.autoStartBreak = true
        #expect(store.autoStartBreaksEnabled == true)
    }

    @Test func settingAppearanceModeWritesToStore() {
        let (model, store) = makeSUT()
        model.appearanceMode = .light
        #expect(store.appearanceMode == .light)
    }

    // MARK: - Round Trip

    @Test func roundTripAllProperties() {
        let store = MockSettingsStore()
        let model = SettingsScreenModel(settingsStore: store)

        model.focusMinutes = 60
        model.shortMinutes = 15
        model.longMinutes = 45
        model.hapticsEnabled = false
        model.notificationsEnabled = false
        model.autoStartBreak = true
        model.appearanceMode = .dark

        // Verify store received all changes
        #expect(store.focusDurationMinutes == 60)
        #expect(store.shortBreakDurationMinutes == 15)
        #expect(store.longBreakDurationMinutes == 45)
        #expect(store.hapticsEnabled == false)
        #expect(store.notificationsEnabled == false)
        #expect(store.autoStartBreaksEnabled == true)
        #expect(store.appearanceMode == .dark)

        // Create new model from same store — should read back
        let model2 = SettingsScreenModel(settingsStore: store)
        #expect(model2.focusMinutes == 60)
        #expect(model2.shortMinutes == 15)
        #expect(model2.longMinutes == 45)
        #expect(model2.appearanceMode == .dark)
    }
}
