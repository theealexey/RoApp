import Foundation

// MARK: - Timer Mode
enum TimerMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case focus
    case short
    case long

    var id: String { rawValue }

    var defaultDuration: TimeInterval {
        switch self {
        case .focus: 25 * 60
        case .short:  5 * 60
        case .long:  15 * 60
        }
    }

    var label: String {
        switch self {
        case .focus: String(localized: "mode.focus",  defaultValue: "Фокус")
        case .short: String(localized: "mode.short",  defaultValue: "Перерыв")
        case .long:  String(localized: "mode.long",   defaultValue: "Длинный")
        }
    }

    var labelEN: String {
        switch self {
        case .focus: "FOCUS"
        case .short: "BREAK"
        case .long:  "LONG BREAK"
        }
    }

    /// Maps legacy Russian rawValues (pre-2025 data) to current enum cases.
    init?(legacyRawValue raw: String) {
        switch raw {
        case "Фокус":   self = .focus
        case "Перерыв": self = .short
        case "Длинный": self = .long
        default:        return nil
        }
    }

    /// Resolves any rawValue — current or legacy.
    init(resolving raw: String) {
        self = TimerMode(rawValue: raw)
            ?? TimerMode(legacyRawValue: raw)
            ?? .focus
    }
}

// MARK: - Timer State
enum TimerState: Equatable, Sendable {
    case idle
    case running
    case paused
    case finished
}
