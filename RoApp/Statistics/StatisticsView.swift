import SwiftUI
import Charts

struct StatisticsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var vm = StatisticsViewModel()

    var body: some View {
        ZStack {
            RoTheme.Colors.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    header
                    todayRow
                    streakRow
                    weekChart
                    recentList
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 52)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            let repository = SessionRepository(context: context)
            vm.load(repository: repository)
        }
    }

    private var header: some View {
        HStack {
            Text(LocalizedStringKey("stats.title"))
                .font(RoTheme.Typography.modeLabel)
                .foregroundStyle(RoTheme.Colors.textTertiary)
                .tracking(4)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(RoTheme.Colors.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }

    private var todayRow: some View {
        HStack(spacing: 12) {
            StatCard(value: "\(vm.todayMinutes)", label: "stats.minutes", icon: "timer")
            StatCard(value: "\(vm.todaySessions)", label: "stats.sessions", icon: "checkmark.circle")
        }
    }

    private var streakRow: some View {
        HStack(spacing: 12) {
            StatCard(value: "\(vm.currentStreak)", label: "stats.streak", icon: "flame")
            StatCard(value: "\(vm.longestStreak)", label: "stats.record", icon: "trophy")
        }
    }

    private var weekChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedStringKey("stats.week"))
                .font(RoTheme.Typography.modeLabel)
                .foregroundStyle(RoTheme.Colors.textTertiary)
                .tracking(2)

            if vm.weekBars.isEmpty {
                emptyState
            } else {
                Chart(vm.weekBars) { bar in
                    BarMark(
                        x: .value("Day", bar.label),
                        y: .value("Minutes", bar.minutes)
                    )
                    .foregroundStyle(bar.minutes > 0
                        ? RoTheme.Colors.accent.opacity(0.8)
                        : RoTheme.Colors.trackStroke)
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(RoTheme.Colors.textTertiary)
                            .font(.system(size: 10))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisValueLabel()
                            .foregroundStyle(RoTheme.Colors.textGhost)
                            .font(.system(size: 9))
                    }
                }
                .frame(height: 140)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(chartAccessibilityLabel)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(RoTheme.Colors.surfaceGlass))
    }

    private var chartAccessibilityLabel: String {
        let summary = vm.weekBars
            .filter { $0.minutes > 0 }
            .map { "\($0.label): \($0.minutes)" }
            .joined(separator: ", ")
        return summary.isEmpty
            ? String(localized: "stats.empty", defaultValue: "пока нет сессий")
            : summary
    }

    private var recentList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey("stats.recent"))
                .font(RoTheme.Typography.modeLabel)
                .foregroundStyle(RoTheme.Colors.textTertiary)
                .tracking(2)

            if vm.recentSessions.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(vm.recentSessions.enumerated()), id: \.element.id) { idx, session in
                        SessionRow(session: session)
                        if idx < vm.recentSessions.count - 1 {
                            Divider().background(RoTheme.Colors.borderSubtle)
                        }
                    }
                }
                .background(RoundedRectangle(cornerRadius: 16).fill(RoTheme.Colors.surfaceGlass))
            }
        }
    }

    private var emptyState: some View {
        Text(LocalizedStringKey("stats.empty"))
            .font(.system(size: 14, weight: .light))
            .foregroundStyle(RoTheme.Colors.textGhost)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
    }
}

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .thin))
                .foregroundStyle(RoTheme.Colors.accent.opacity(0.7))
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .thin))
                    .foregroundStyle(RoTheme.Colors.textPrimary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text(LocalizedStringKey(label))
                    .font(RoTheme.Typography.modeLabel)
                    .foregroundStyle(RoTheme.Colors.textTertiary)
                    .tracking(2)
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16).fill(RoTheme.Colors.surfaceGlass))
        .accessibilityElement(children: .combine)
    }
}

private struct SessionRow: View {
    let session: FocusSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.mode.label)
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(RoTheme.Colors.textPrimary)
                Text(session.completedAt.formatted(.relative(presentation: .named)))
                    .font(.system(size: 11, weight: .light))
                    .foregroundStyle(RoTheme.Colors.textTertiary)
            }
            Spacer()
            Text("\(session.durationMinutes) \(String(localized: "stats.minutes", defaultValue: "мин"))")
                .font(.system(size: 13, weight: .thin))
                .foregroundStyle(RoTheme.Colors.textSecondary)
                .monospacedDigit()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    StatisticsView()
}
