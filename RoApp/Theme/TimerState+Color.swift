import SwiftUI

extension TimerState {

    var accentColor: Color {
        switch self {
        case .running:  RoTheme.Colors.accent
        case .paused:   RoTheme.Colors.accentMuted
        case .finished: RoTheme.Colors.success
        case .idle:     RoTheme.Colors.accentSubtle
        }
    }

    var orbColor: Color {
        switch self {
        case .running, .paused: RoTheme.Colors.accent
        case .finished:         RoTheme.Colors.success
        case .idle:             RoTheme.Colors.idleOrb
        }
    }
}
