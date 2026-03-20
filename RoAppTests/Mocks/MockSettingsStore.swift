import Foundation
@testable import RoApp

final class MockSettingsStore: SettingsStoreProtocol {

    var focusDurationMinutes: Int = 25
    var shortBreakDurationMinutes: Int = 5
    var longBreakDurationMinutes: Int = 15

    var hapticsEnabled: Bool = true
    var notificationsEnabled: Bool = true
    var autoStartBreaksEnabled: Bool = false
    var appearanceMode: AppearanceMode = .system
    var hasSeenOnboarding: Bool = false

    func duration(for mode: TimerMode) -> TimeInterval {
        let minutes: Int
        switch mode {
        case .focus: minutes = focusDurationMinutes
        case .short: minutes = shortBreakDurationMinutes
        case .long:  minutes = longBreakDurationMinutes
        }
        return TimeInterval(minutes * 60)
    }
}
