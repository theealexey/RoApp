import Foundation
import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

protocol SettingsStoreProtocol: AnyObject {
    var focusDurationMinutes: Int { get set }
    var shortBreakDurationMinutes: Int { get set }
    var longBreakDurationMinutes: Int { get set }

    var hapticsEnabled: Bool { get set }
    var notificationsEnabled: Bool { get set }
    var autoStartBreaksEnabled: Bool { get set }
    var appearanceMode: AppearanceMode { get set }
    var hasSeenOnboarding: Bool { get set }

    func duration(for mode: TimerMode) -> TimeInterval
}

final class SettingsStore: SettingsStoreProtocol {
    private enum Keys {
        static let focusDurationMinutes = "focusDurationMinutes"
        static let shortBreakDurationMinutes = "shortBreakDurationMinutes"
        static let longBreakDurationMinutes = "longBreakDurationMinutes"

        static let hapticsEnabled = "hapticsEnabled"
        static let notificationsEnabled = "notificationsEnabled"
        static let autoStartBreaksEnabled = "autoStartBreaksEnabled"
        static let appearanceMode = "appearanceMode"
        static let hasSeenOnboarding = "settings.hasSeenOnboarding"
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

    var appearanceMode: AppearanceMode {
        get {
            guard let raw = userDefaults.string(forKey: Keys.appearanceMode) else { return .system }
            return AppearanceMode(rawValue: raw) ?? .system
        }
        set { userDefaults.set(newValue.rawValue, forKey: Keys.appearanceMode) }
    }

    var hasSeenOnboarding: Bool {
        get { userDefaults.bool(forKey: Keys.hasSeenOnboarding) }
        set { userDefaults.set(newValue, forKey: Keys.hasSeenOnboarding) }
    }

    func duration(for mode: TimerMode) -> TimeInterval {
        let minutes: Int

        switch mode {
        case .focus: minutes = focusDurationMinutes
        case .short: minutes = shortBreakDurationMinutes
        case .long:  minutes = longBreakDurationMinutes
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

    private func clampedMinutes(forKey key: String, fallback: Int) -> Int {
        guard userDefaults.object(forKey: key) != nil else {
            return clamp(minutes: fallback)
        }

        return clamp(minutes: userDefaults.integer(forKey: key))
    }

    private func clamp(minutes: Int) -> Int {
        min(max(minutes, 1), 180)
    }
}
