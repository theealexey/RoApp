import WidgetKit
import SwiftUI

struct TimerEntry: TimelineEntry {
    let date: Date
    let state: SharedTimerState
}

struct TimerProvider: TimelineProvider {
    func placeholder(in context: Context) -> TimerEntry {
        TimerEntry(date: Date(), state: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (TimerEntry) -> Void) {
        let entry = TimerEntry(date: Date(), state: AppGroup.load())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimerEntry>) -> Void) {
        let state = AppGroup.load()
        let currentDate = Date()
        let entry = TimerEntry(date: currentDate, state: state)

        let refreshDate: Date
        if state.isRunning, let endDate = state.endDate {
            refreshDate = min(currentDate.addingTimeInterval(1), endDate)
        } else {
            refreshDate = currentDate.addingTimeInterval(60)
        }

        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

struct RoWidgetEntryView: View {
    let entry: TimerEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.10, blue: 0.14),
                    Color(red: 0.16, green: 0.14, blue: 0.24)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(entry.state.modeLabelEN)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))

                    Spacer()

                    if entry.state.isRunning {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }

                Spacer()

                Text(entry.state.formattedTime)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)

                ProgressView(value: entry.state.progress)
                    .progressViewStyle(.linear)
                    .tint(.white.opacity(0.9))
            }
            .padding(16)
        }
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
            .systemMedium
        ])
    }
}

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

    TimerEntry(
        date: .now,
        state: SharedTimerState(
            isRunning: false,
            timeRemaining: 5 * 60,
            totalDuration: 5 * 60,
            modeRaw: "shortBreak",
            endDate: nil
        )
    )
}
