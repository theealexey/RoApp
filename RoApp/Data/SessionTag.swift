import SwiftUI

/// Predefined session categories for organizing focus sessions.
///
/// Tags help users track where their focus time goes — work, study, personal projects, etc.
/// Stored as `rawValue` string in SwiftData for persistence compatibility.
enum SessionTag: String, CaseIterable, Codable, Identifiable, Sendable {
    case work
    case study
    case personal
    case health
    case creative
    case none

    var id: String { rawValue }

    // MARK: - Display

    var label: String {
        switch self {
        case .work:     String(localized: "tag.work",     defaultValue: "Work")
        case .study:    String(localized: "tag.study",    defaultValue: "Study")
        case .personal: String(localized: "tag.personal", defaultValue: "Personal")
        case .health:   String(localized: "tag.health",   defaultValue: "Health")
        case .creative: String(localized: "tag.creative", defaultValue: "Creative")
        case .none:     String(localized: "tag.none",     defaultValue: "No tag")
        }
    }

    var icon: String {
        switch self {
        case .work:     "briefcase"
        case .study:    "book"
        case .personal: "person"
        case .health:   "heart"
        case .creative: "paintbrush"
        case .none:     "tag"
        }
    }

    var color: Color {
        switch self {
        case .work:     Color(red: 0.35, green: 0.55, blue: 1.0)   // blue
        case .study:    Color(red: 0.55, green: 0.80, blue: 0.35)  // green
        case .personal: Color(red: 0.90, green: 0.60, blue: 0.25)  // orange
        case .health:   Color(red: 0.95, green: 0.40, blue: 0.45)  // red
        case .creative: Color(red: 0.70, green: 0.45, blue: 0.90)  // purple
        case .none:     Color.gray
        }
    }

    /// Tags available for user selection (excludes `.none`).
    static var selectable: [SessionTag] {
        allCases.filter { $0 != .none }
    }
}
