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
        TimerMode(resolving: modeRaw)
    }

    var durationMinutes: Int { Int(duration / 60) }
}
