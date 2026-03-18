import WidgetKit
import SwiftUI

// MARK: - Timeline Entry & Provider (без изменений)

struct TimerEntry: TimelineEntry {
    let date: Date
    let state: SharedTimerState
}

struct TimerProvider: TimelineProvider {
    func placeholder(in context: Context) -> TimerEntry {
        TimerEntry(date: Date(), state: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (TimerEntry) -> Void) {
        completion(TimerEntry(date: Date(), state: AppGroup.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimerEntry>) -> Void) {
        let state = AppGroup.load()
        let now = Date()
        let entry = TimerEntry(date: now, state: state)

        let refreshDate: Date
        if state.isRunning, let endDate = state.endDate {
            refreshDate = min(now.addingTimeInterval(1), endDate)
        } else {
            refreshDate = now.addingTimeInterval(60)
        }

        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }
}

// MARK: - System Small / Medium View

struct RoWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TimerEntry

    var body: some View {
        switch family {
        case .systemSmall, .systemMedium:
            RoSystemWidgetView(state: entry.state)
        case .accessoryCircular:
            RoAccessoryCircularView(state: entry.state)
        case .accessoryRectangular:
            RoAccessoryRectangularView(state: entry.state)
        default:
            RoSystemWidgetView(state: entry.state)
        }
    }
}

// MARK: - System Widget

private struct RoSystemWidgetView: View {
    let state: SharedTimerState

    private var accentColor: Color {
        switch state.modeRaw {
        case "short", "long": Color(red: 0.30, green: 0.85, blue: 0.60)
        default:              Color(red: 0.35, green: 0.30, blue: 0.90)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(state.modeLabelEN)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                if state.isRunning {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(accentColor)
                }
            }

            Spacer()

            Text(state.formattedTime)
                .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)

            ProgressView(value: state.progress)
                .progressViewStyle(.linear)
                .tint(accentColor)
        }
        .padding(16)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.10, blue: 0.14),
                    Color(red: 0.16, green: 0.14, blue: 0.24)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Accessory Circular (Lock Screen)

private struct RoAccessoryCircularView: View {
    let state: SharedTimerState

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.2), lineWidth: 2)
            Circle()
                .trim(from: 0, to: state.progress)
                .stroke(.white, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(state.formattedTime)
                .font(.system(size: 12, weight: .medium).monospacedDigit())
                .minimumScaleFactor(0.7)
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}

// MARK: - Accessory Rectangular (Lock Screen)

private struct RoAccessoryRectangularView: View {
    let state: SharedTimerState

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.25), lineWidth: 1.5)
                Circle()
                    .trim(from: 0, to: state.progress)
                    .stroke(.white, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text(state.modeLabelEN)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                Text(state.formattedTime)
                    .font(.system(size: 18, weight: .medium).monospacedDigit())
                    .foregroundStyle(.white)
            }

            Spacer()
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}

// MARK: - Widget Configuration

struct RoWidget: Widget {
    let kind: String = "RoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimerProvider()) { entry in
            RoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(String(localized: "widget.displayName", defaultValue: "Ro Focus Timer"))
        .description(String(localized: "widget.description", defaultValue: "Shows your current focus session and remaining time."))
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}

// MARK: - Widget Bundle Entry Point

@main
struct RoWidgetBundle: WidgetBundle {
    var body: some Widget {
        RoWidget()
        RoLiveActivityWidget()
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    RoWidget()
} timeline: {
    TimerEntry(
        date: .now,
        state: SharedTimerState(
            isRunning: true,
            timeRemaining: 18 * 60,
            totalDuration: 25 * 60,
            modeRaw: "focus",
            endDate: Date().addingTimeInterval(18 * 60)
        )
    )
}
