import SwiftUI

// MARK: - Design Tokens
/// Single source of truth for all visual constants.
/// Adding a new theme = one file change, zero view edits (Open/Closed).
enum RoTheme {

    // MARK: Colors
    enum Colors {
        static let background    = Color(red: 0.04, green: 0.04, blue: 0.07)
        static let accent        = Color(red: 0.35, green: 0.30, blue: 0.90)
        static let accentMuted   = accent.opacity(0.45)
        static let accentSubtle  = accent.opacity(0.65)
        static let success       = Color(red: 0.30, green: 0.85, blue: 0.60)
        static let idleOrb       = Color(red: 0.25, green: 0.22, blue: 0.60)
        static let chipFill      = accent.opacity(0.3)
        static let chipBorder    = accent.opacity(0.5)
        static let trackStroke   = Color.white.opacity(0.06)
        static let surfaceGlass  = Color.white.opacity(0.06)
        static let borderSubtle  = Color.white.opacity(0.08)
        static let textPrimary   = Color.white
        static let textSecondary = Color.white.opacity(0.5)
        static let textTertiary  = Color.white.opacity(0.3)
        static let textGhost     = Color.white.opacity(0.2)
        static let textHint      = Color.white.opacity(0.45)
    }

    // MARK: Layout
    enum Layout {
        static let ringDiameter: CGFloat    = 280
        static let ringTrackWidth: CGFloat  = 2
        static let ringStrokeWidth: CGFloat = 3
        static let dotSize: CGFloat         = 6
        static let orbDiameter: CGFloat     = 340
        static let orbBlur: CGFloat         = 70

        static let topBarButtonSize: CGFloat = 44
        static let settingsButtonSize: CGFloat = 44
        static let controlSize: CGFloat     = 52
        static let playButtonOuter: CGFloat = 92
        static let playButtonInner: CGFloat = 76
    }

    // MARK: Animation
    enum Animation {
        static let standard = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.82)
        static let gentle   = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.80)
        static let press    = SwiftUI.Animation.spring(response: 0.2, dampingFraction: 0.90)
        static let release  = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.70)
        static let tick     = SwiftUI.Animation.linear(duration: 0.1)
    }

    // MARK: Typography
    enum Typography {
        static let timer     = Font.system(size: 62, weight: .thin)
        static let modeLabel = Font.system(size: 10, weight: .medium)
        static let chipFont  = Font.system(size: 13)
        static let brand     = Font.system(size: 15, weight: .light)
        static let hint      = Font.system(size: 11, weight: .regular)
        static let hintIcon  = Font.system(size: 9, weight: .medium)
        static let finished  = Font.system(size: 11, weight: .light)
        static let control   = Font.system(size: 18, weight: .light)
        static let playIcon  = Font.system(size: 22, weight: .medium)
    }
}
