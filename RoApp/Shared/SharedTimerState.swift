import Foundation

// MARK: - Shared between App and Widget
struct SharedTimerState: Codable, Sendable {
    let isRunning: Bool
    let timeRemaining: TimeInterval
    let totalDuration: TimeInterval
    let modeRaw: String
    let endDate: Date?

    static let defaultDuration: TimeInterval = 25 * 60
    static let defaultModeRaw = "focus"

    static let empty = SharedTimerState(
        isRunning: false,
        timeRemaining: defaultDuration,
        totalDuration: defaultDuration,
        modeRaw: defaultModeRaw,
        endDate: nil
    )

    var progress: Double {
        guard totalDuration > 0 else { return 0 }

        let remainingTime = liveTimeRemaining
        let progressValue = 1.0 - (remainingTime / totalDuration)

        return min(max(progressValue, 0), 1)
    }

    var formattedTime: String {
        let totalSeconds = max(0, Int(ceil(liveTimeRemaining)))
        return String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    var modeLabelEN: String {
        switch modeRaw {
        case "focus": "FOCUS"
        case "short": "BREAK"
        case "long":  "LONG BREAK"
        default:      "FOCUS"
        }
    }

    var liveTimeRemaining: TimeInterval {
        guard isRunning, let endDate else {
            return max(0, timeRemaining)
        }

        return max(0, endDate.timeIntervalSinceNow)
    }
}
