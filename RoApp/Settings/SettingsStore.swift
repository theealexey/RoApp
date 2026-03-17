import Foundation

protocol SettingsStoreProtocol: AnyObject {
    var focusDurationMinutes: Int { get set }
    var shortBreakDurationMinutes: Int { get set }
    var longBreakDurationMinutes: Int { get set }

    var hapticsEnabled: Bool { get set }
    var notificationsEnabled: Bool { get set }
    var autoStartBreaksEnabled: Bool { get set }

    func duration(for modeRawValue: String) -> TimeInterval
}

final class SettingsStore: SettingsStoreProtocol {
    private enum Keys {
        static let focusDurationMinutes = "focusDurationMinutes"
        static let shortBreakDurationMinutes = "shortBreakDurationMinutes"
        static let longBreakDurationMinutes = "longBreakDurationMinutes"

        static let hapticsEnabled = "hapticsEnabled"
        static let notificationsEnabled = "notificationsEnabled"
        static let autoStartBreaksEnabled = "autoStartBreaksEnabled"
    }

    private enum Defaults {
        static let focusDurationMinutes = 25
        static let shortBreakDurationMinutes = 5
        static let longBreakDurationMinutes = 15

        static let hapticsEnabled = true
        static let notificationsEnabled = true
        static let autoStartBreaksEnabled = false
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        registerDefaultsIfNeeded()
    }

    var focusDurationMinutes: Int {
        get { clampedMinutes(forKey: Keys.focusDurationMinutes, fallback: Defaults.focusDurationMinutes) }
        set { userDefaults.set(clamp(minutes: newValue), forKey: Keys.focusDurationMinutes) }
    }

    var shortBreakDurationMinutes: Int {
        get { clampedMinutes(forKey: Keys.shortBreakDurationMinutes, fallback: Defaults.shortBreakDurationMinutes) }
        set { userDefaults.set(clamp(minutes: newValue), forKey: Keys.shortBreakDurationMinutes) }
    }

    var longBreakDurationMinutes: Int {
        get { clampedMinutes(forKey: Keys.longBreakDurationMinutes, fallback: Defaults.longBreakDurationMinutes) }
        set { userDefaults.set(clamp(minutes: newValue), forKey: Keys.longBreakDurationMinutes) }
    }

    var hapticsEnabled: Bool {
        get { userDefaults.object(forKey: Keys.hapticsEnabled) as? Bool ?? Defaults.hapticsEnabled }
        set { userDefaults.set(newValue, forKey: Keys.hapticsEnabled) }
    }

    var notificationsEnabled: Bool {
        get { userDefaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? Defaults.notificationsEnabled }
        set { userDefaults.set(newValue, forKey: Keys.notificationsEnabled) }
    }

    var autoStartBreaksEnabled: Bool {
        get { userDefaults.object(forKey: Keys.autoStartBreaksEnabled) as? Bool ?? Defaults.autoStartBreaksEnabled }
        set { userDefaults.set(newValue, forKey: Keys.autoStartBreaksEnabled) }
    }

    func duration(for modeRawValue: String) -> TimeInterval {
        let minutes: Int

        switch modeRawValue {
        case "focus":
            minutes = focusDurationMinutes
        case "short":
            minutes = shortBreakDurationMinutes
        case "long":
            minutes = longBreakDurationMinutes
        default:
            minutes = Defaults.focusDurationMinutes
        }

        return TimeInterval(minutes * 60)
    }

    private func registerDefaultsIfNeeded() {
        userDefaults.register(defaults: [
            Keys.focusDurationMinutes: Defaults.focusDurationMinutes,
            Keys.shortBreakDurationMinutes: Defaults.shortBreakDurationMinutes,
            Keys.longBreakDurationMinutes: Defaults.longBreakDurationMinutes,
            Keys.hapticsEnabled: Defaults.hapticsEnabled,
            Keys.notificationsEnabled: Defaults.notificationsEnabled,
            Keys.autoStartBreaksEnabled: Defaults.autoStartBreaksEnabled
        ])
    }

    private func clampedMinutes(forKey key: String, fallback _: Int) -> Int {
        clamp(minutes: userDefaults.integer(forKey: key))
    }

    private func clamp(minutes: Int) -> Int {
        min(max(minutes, 1), 180)
    }
}
