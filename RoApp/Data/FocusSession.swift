import SwiftData
import Foundation

@Model
final class FocusSession {
    var id:          UUID
    var modeRaw:     String
    var duration:    TimeInterval
    var completedAt: Date
    var tagRaw:      String?

    init(mode: TimerMode, duration: TimeInterval, tag: SessionTag = .none) {
        self.id          = UUID()
        self.modeRaw     = mode.rawValue
        self.duration    = duration
        self.completedAt = Date()
        self.tagRaw      = tag == .none ? nil : tag.rawValue
    }

    var mode: TimerMode {
        TimerMode(resolving: modeRaw)
    }

    var tag: SessionTag {
        guard let tagRaw else { return .none }
        return SessionTag(rawValue: tagRaw) ?? .none
    }

    var durationMinutes: Int { Int(duration / 60) }
}
