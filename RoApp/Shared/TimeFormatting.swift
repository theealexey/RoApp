import Foundation

enum TimeFormatting {
    static func format(seconds: TimeInterval) -> String {
        let totalSeconds = max(0, Int(ceil(seconds)))
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}
