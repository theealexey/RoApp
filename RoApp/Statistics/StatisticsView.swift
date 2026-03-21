import SwiftUI
import Charts

struct StatisticsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm: StatisticsViewModel

    init(repository: SessionRepositoryProtocol) {
        _vm = State(initialValue: StatisticsViewModel(repository: repository))
    }

    var body: some View {
        ZStack {
            RoTheme.Colors.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    header
                    tagFilterRow
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
        .task {
            vm.load()
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

    private var tagFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                TagFilterChip(
                    label: String(localized: "stats.filter.all", defaultValue: "All"),
                    isSelected: vm.selectedTagFilter == nil
                ) {
                    withAnimation(RoTheme.Animation.standard) { vm.filterByTag(nil) }
                }

                ForEach(SessionTag.selectable) { tag in
                    TagFilterChip(
                        label: tag.label,
                        color: tag.color,
                        isSelected: vm.selectedTagFilter == tag
                    ) {
                        withAnimation(RoTheme.Animation.standard) { vm.filterByTag(tag) }
                    }
                }
            }
        }
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
        VStack(spacing: 12) {
            EmptyStateIllustration(color: RoTheme.Colors.textGhost)
            Text(LocalizedStringKey("stats.empty"))
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(RoTheme.Colors.textGhost)
        }
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

    private var modeColor: Color {
        switch session.mode {
        case .focus: RoTheme.Colors.accent
        case .short: RoTheme.Colors.success
        case .long:  RoTheme.Colors.success.opacity(0.7)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(modeColor)
                .frame(width: 3, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(session.mode.label)
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(RoTheme.Colors.textPrimary)

                    if session.tag != .none {
                        Text(session.tag.label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(session.tag.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(session.tag.color.opacity(0.12))
                            )
                    }
                }
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

// MARK: - Tag Filter Chip

private struct TagFilterChip: View {
    let label: String
    var color: Color = RoTheme.Colors.accent
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: isSelected ? .medium : .regular))
                .foregroundStyle(isSelected ? color : RoTheme.Colors.textTertiary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? color.opacity(0.12) : Color.clear)
                        .overlay(
                            Capsule().strokeBorder(
                                isSelected ? color.opacity(0.3) : RoTheme.Colors.borderSubtle.opacity(0.6),
                                lineWidth: 0.5
                            )
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    StatisticsView(repository: PreviewSessionRepository())
}

private final class PreviewSessionRepository: SessionRepositoryProtocol {
    func save(mode: TimerMode, duration: TimeInterval, tag: SessionTag) throws {}
    func fetchAll() throws -> [FocusSession] { [] }
}
