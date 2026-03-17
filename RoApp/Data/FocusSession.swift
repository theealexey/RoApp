import SwiftData
import Foundation

@Model
final class FocusSession {
    var id:          UUID
    var modeRaw:     String
    var duration:    TimeInterval
    var completedAt: Date

    init(mode: TimerMode, duration: TimeInterval) {
        self.id          = UUID()
        self.modeRaw     = mode.rawValue
        self.duration    = duration
        self.completedAt = Date()
    }

    var mode: TimerMode {
        // Support both legacy Russian rawValues and new English ones
        switch modeRaw {
        case "Фокус":   return .focus
        case "Перерыв": return .short
        case "Длинный": return .long
        default:        return TimerMode(rawValue: modeRaw) ?? .focus
        }
    }

    var durationMinutes: Int { Int(duration / 60) }
}
