import UserNotifications
import Foundation

final class NotificationService: Sendable {

    static let shared = NotificationService()
    private init() {}

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleCompletion(for mode: TimerMode, in seconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        switch mode {
        case .focus:
            content.title = String(localized: "notif.focus.title", defaultValue: "Сессия завершена 完了")
            content.body  = String(localized: "notif.focus.body",  defaultValue: "Время отдохнуть.")
        case .short:
            content.title = String(localized: "notif.short.title", defaultValue: "Перерыв окончен")
            content.body  = String(localized: "notif.short.body",  defaultValue: "Готов к следующей сессии?")
        case .long:
            content.title = String(localized: "notif.long.title",  defaultValue: "Длинный перерыв окончен")
            content.body  = String(localized: "notif.long.body",   defaultValue: "Заряжен и готов к работе.")
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(
            identifier: "ro.timer.\(mode.rawValue)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func cancelCompletion(for mode: TimerMode) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["ro.timer.\(mode.rawValue)"])
    }
}
