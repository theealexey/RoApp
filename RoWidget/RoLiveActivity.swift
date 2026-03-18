import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Activity Attributes

struct RoTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var timeRemaining: TimeInterval
        var totalDuration: TimeInterval
        var modeRaw: String
        var isRunning: Bool
        var endDate: Date?

        var progress: Double {
            guard totalDuration > 0 else { return 0 }
            let live = liveTimeRemaining
            return min(max(1.0 - (live / totalDuration), 0), 1)
        }

        var formattedTime: String {
            let s = max(0, Int(ceil(liveTimeRemaining)))
            return String(format: "%02d:%02d", s / 60, s % 60)
        }

        var liveTimeRemaining: TimeInterval {
            guard isRunning, let endDate else { return max(0, timeRemaining) }
            return max(0, endDate.timeIntervalSinceNow)
        }

        var modeLabel: String {
            switch modeRaw {
            case "focus": return "FOCUS"
            case "short": return "BREAK"
            case "long":  return "LONG BREAK"
            default:      return "FOCUS"
            }
        }

        var accentColor: Color {
            switch modeRaw {
            case "focus": return Color(red: 0.35, green: 0.30, blue: 0.90)
            case "short": return Color(red: 0.30, green: 0.85, blue: 0.60)
            case "long":  return Color(red: 0.30, green: 0.85, blue: 0.60)
            default:      return Color(red: 0.35, green: 0.30, blue: 0.90)
            }
        }
    }
}

// MARK: - Live Activity Widget

struct RoLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RoTimerAttributes.self) { context in
            // Lock Screen / StandBy banner
            RoLockScreenLiveActivityView(state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.modeLabel)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                        Text(context.state.formattedTime)
                            .font(.system(size: 28, weight: .thin).monospacedDigit())
                            .foregroundStyle(.white)
                    }
                    .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    ZStack {
                        Circle()
                            .stroke(.white.opacity(0.15), lineWidth: 2)
                        Circle()
                            .trim(from: 0, to: context.state.progress)
                            .stroke(
                                context.state.accentColor,
                                style: StrokeStyle(lineWidth: 2, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 36, height: 36)
                    .padding(.trailing, 4)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: context.state.progress)
                        .progressViewStyle(.linear)
                        .tint(context.state.accentColor)
                        .padding(.horizontal, 4)
                        .padding(.bottom, 4)
                }
            } compactLeading: {
                Image(systemName: context.state.isRunning ? "timer" : "timer.square")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(context.state.accentColor)
            } compactTrailing: {
                Text(context.state.formattedTime)
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                    .foregroundStyle(.white)
                    .frame(minWidth: 44)
            } minimal: {
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.2), lineWidth: 1.5)
                    Circle()
                        .trim(from: 0, to: context.state.progress)
                        .stroke(
                            context.state.accentColor,
                            style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }
            }
        }
    }
}

// MARK: - Lock Screen View

private struct RoLockScreenLiveActivityView: View {
    let state: RoTimerAttributes.ContentState

    var body: some View {
        HStack(spacing: 16) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.15), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: state.progress)
                    .stroke(
                        state.accentColor,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(state.modeLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                Text(state.formattedTime)
                    .font(.system(size: 32, weight: .thin).monospacedDigit())
                    .foregroundStyle(.white)
            }

            Spacer()

            Image(systemName: state.isRunning ? "pause.fill" : "play.fill")
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.black.opacity(0.6))
    }
}
