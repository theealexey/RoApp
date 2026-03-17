import SwiftUI

struct ContentView: View {
    @State private var vm: TimerViewModel
    @State private var showStats = false
    @State private var showSettings = false

    init(repository: SessionRepositoryProtocol) {
        _vm = State(initialValue: TimerViewModel(repository: repository))
    }

    var body: some View {
        ZStack {
            RoBackground(vm: vm)

            VStack(spacing: 36) {
                TopBarView(
                    onStats: { showStats = true },
                    onSettings: { showSettings = true }
                )

                ModePickerView(vm: vm)
                TimerRingView(vm: vm)
                ControlsView(vm: vm)
            }
            .padding(.horizontal, 24)
        }
        .sheet(isPresented: $showStats) {
            StatisticsView()
                .presentationBackground(RoTheme.Colors.background)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .presentationBackground(RoTheme.Colors.background)
        }
    }
}

private struct TopBarView: View {
    let onStats: () -> Void
    let onSettings: () -> Void

    var body: some View {
        HStack {
            Text("ro")
                .font(RoTheme.Typography.brand)
                .foregroundStyle(RoTheme.Colors.textGhost)
                .tracking(6)

            Spacer()

            HStack(spacing: 8) {
                TopBarButton(
                    icon: "chart.bar",
                    label: String(localized: "a11y.stats", defaultValue: "Statistics"),
                    action: onStats
                )
                TopBarButton(
                    icon: "gearshape",
                    label: String(localized: "a11y.settings", defaultValue: "Settings"),
                    action: onSettings
                )
            }
        }
        .padding(.top, 8)
    }
}

private struct TopBarButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(RoTheme.Colors.textTertiary)
                .frame(
                    width: RoTheme.Layout.topBarButtonSize,
                    height: RoTheme.Layout.topBarButtonSize
                )
                .background(Circle().fill(RoTheme.Colors.surfaceGlass))
                .overlay(
                    Circle()
                        .strokeBorder(RoTheme.Colors.borderSubtle, lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

private struct ModePickerView: View {
    let vm: TimerViewModel

    var body: some View {
        HStack(spacing: 6) {
            ForEach(TimerMode.allCases) { mode in
                ModeChip(title: mode.label, isSelected: vm.mode == mode) {
                    withAnimation(RoTheme.Animation.standard) {
                        vm.select(mode: mode)
                    }
                    HapticsService.shared.tap()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ModeChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(RoTheme.Typography.chipFont.weight(isSelected ? .medium : .regular))
                .foregroundStyle(
                    isSelected ? RoTheme.Colors.textPrimary : RoTheme.Colors.textTertiary
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? RoTheme.Colors.chipFill : Color.clear)
                        .overlay(
                            Capsule().strokeBorder(
                                isSelected
                                    ? RoTheme.Colors.chipBorder
                                    : RoTheme.Colors.borderSubtle.opacity(0.88),
                                lineWidth: 0.5
                            )
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct TimerRingView: View {
    let vm: TimerViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragOffset: CGFloat = 0
    @State private var showDurationHint = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var dragStartMinutes: Int?

    var body: some View {
        ZStack {
            Circle()
                .fill(vm.state.accentColor.opacity(0.05))
                .frame(
                    width: RoTheme.Layout.ringDiameter + 40,
                    height: RoTheme.Layout.ringDiameter + 40
                )
                .blur(radius: 24)
                .scaleEffect(pulseScale)

            Circle()
                .stroke(
                    RoTheme.Colors.trackStroke,
                    lineWidth: RoTheme.Layout.ringTrackWidth
                )
                .frame(
                    width: RoTheme.Layout.ringDiameter,
                    height: RoTheme.Layout.ringDiameter
                )

            Circle()
                .trim(from: 0, to: vm.progress)
                .stroke(
                    vm.state.accentColor,
                    style: StrokeStyle(
                        lineWidth: RoTheme.Layout.ringStrokeWidth,
                        lineCap: .round
                    )
                )
                .frame(
                    width: RoTheme.Layout.ringDiameter,
                    height: RoTheme.Layout.ringDiameter
                )
                .rotationEffect(.degrees(-90))
                .animation(RoTheme.Animation.tick, value: vm.progress)

            ProgressDot(
                progress: vm.progress,
                size: RoTheme.Layout.ringDiameter,
                color: vm.state.accentColor
            )
            .animation(RoTheme.Animation.tick, value: vm.progress)

            TimerFaceView(
                vm: vm,
                dragOffset: dragOffset,
                showHint: showDurationHint
            )
        }
        .gesture(durationDragGesture)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(vm.formattedTime), \(vm.mode.label)")
        .accessibilityValue("\(Int(vm.progress * 100))%")
        .accessibilityHint(
            vm.state == .idle || vm.state == .paused
                ? String(localized: "a11y.timer.hint", defaultValue: "Swipe up or down to adjust duration")
                : ""
        )
        .onAppear {
            startPulse()
        }
        .onChange(of: vm.state) { _, _ in
            startPulse()
        }
    }

    private var durationDragGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard vm.state == .idle || vm.state == .paused else { return }

                if dragStartMinutes == nil {
                    dragStartMinutes = vm.currentBaseDurationMinutes
                }

                dragOffset = value.translation.height
                showDurationHint = true

                let baseMinutes = dragStartMinutes ?? Int(vm.timeRemaining / 60)
                let deltaMinutes = Int(-value.translation.height / 12)
                let updatedMinutes = max(1, min(180, baseMinutes + deltaMinutes))

                vm.setCustomDuration(minutes: updatedMinutes)
            }
            .onEnded { _ in
                withAnimation(RoTheme.Animation.gentle) {
                    dragOffset = 0
                    showDurationHint = false
                }
                dragStartMinutes = nil
            }
    }

    private func startPulse() {
        guard vm.state == .running, !reduceMotion else {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                pulseScale = 1.0
            }
            return
        }

        withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.08
        }
    }
}

private struct ProgressDot: View {
    let progress: Double
    let size: CGFloat
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let centerPoint = CGPoint(
                x: geometry.size.width / 2,
                y: geometry.size.height / 2
            )
            let radius = size / 2
            let angle = (progress * 360 - 90) * .pi / 180

            Circle()
                .fill(color)
                .frame(
                    width: RoTheme.Layout.dotSize,
                    height: RoTheme.Layout.dotSize
                )
                .shadow(color: color.opacity(0.8), radius: 4)
                .position(
                    x: centerPoint.x + radius * cos(angle),
                    y: centerPoint.y + radius * sin(angle)
                )
                .opacity(progress > 0.01 ? 1 : 0)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

private struct TimerFaceView: View {
    let vm: TimerViewModel
    let dragOffset: CGFloat
    let showHint: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(vm.formattedTime)
                .font(RoTheme.Typography.timer)
                .foregroundStyle(RoTheme.Colors.textPrimary)
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
                .animation(RoTheme.Animation.standard, value: vm.formattedTime)

            Text(vm.mode.labelEN)
                .font(RoTheme.Typography.modeLabel)
                .foregroundStyle(RoTheme.Colors.textGhost)
                .tracking(4)

            if showHint {
                HStack(spacing: 4) {
                    Image(systemName: dragOffset < 0 ? "chevron.up" : "chevron.down")
                        .font(RoTheme.Typography.hintIcon)

                    Text("\(Int(vm.timeRemaining / 60)) \(String(localized: "unit.min", defaultValue: "мин"))")
                        .font(RoTheme.Typography.hint)
                }
                .foregroundStyle(RoTheme.Colors.textHint)
                .transition(.opacity.combined(with: .scale(scale: 0.85)))
            }

            if vm.state == .finished {
                Text(String(localized: "state.finished", defaultValue: "完了"))
                    .font(RoTheme.Typography.finished)
                    .foregroundStyle(RoTheme.Colors.success.opacity(0.8))
                    .tracking(2)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .animation(RoTheme.Animation.gentle, value: vm.state)
    }
}

private struct ControlsView: View {
    let vm: TimerViewModel

    var body: some View {
        HStack(spacing: 0) {
            RoControlButton(
                icon: "arrow.counterclockwise",
                label: String(localized: "a11y.reset", defaultValue: "Reset timer")
            ) {
                withAnimation(RoTheme.Animation.standard) {
                    vm.reset()
                }
                HapticsService.shared.reset()
            }

            Spacer()

            PlayPauseButton(vm: vm)

            Spacer()

            RoControlButton(
                icon: "forward.end",
                label: String(localized: "a11y.skip", defaultValue: "Skip to next mode")
            ) {
                withAnimation(RoTheme.Animation.standard) {
                    vm.skipToNextMode()
                }
                HapticsService.shared.reset()
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
    }
}

private struct RoControlButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(RoTheme.Colors.surfaceGlass)
                    .frame(
                        width: RoTheme.Layout.controlSize,
                        height: RoTheme.Layout.controlSize
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(RoTheme.Colors.borderSubtle, lineWidth: 0.5)
                    )

                Image(systemName: icon)
                    .font(RoTheme.Typography.control)
                    .foregroundStyle(RoTheme.Colors.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

private struct PlayPauseButton: View {
    let vm: TimerViewModel
    @State private var isPressed = false

    var body: some View {
        Button {
            withAnimation(RoTheme.Animation.standard) {
                if vm.isRunning {
                    vm.pause()
                    HapticsService.shared.pause()
                } else {
                    vm.start()
                    HapticsService.shared.start()
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(vm.state.accentColor.opacity(0.18))
                    .frame(
                        width: RoTheme.Layout.playButtonOuter,
                        height: RoTheme.Layout.playButtonOuter
                    )
                    .blur(radius: 14)

                Circle()
                    .fill(vm.state.accentColor)
                    .frame(
                        width: RoTheme.Layout.playButtonInner,
                        height: RoTheme.Layout.playButtonInner
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
                    )
                    .scaleEffect(isPressed ? 0.92 : 1.0)

                Image(systemName: vm.isRunning ? "pause" : "play.fill")
                    .font(RoTheme.Typography.playIcon)
                    .foregroundStyle(RoTheme.Colors.textPrimary)
                    .contentTransition(.symbolEffect(.replace))
                    .offset(x: vm.isRunning ? 0 : 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            vm.isRunning
                ? String(localized: "a11y.pause", defaultValue: "Pause timer")
                : String(localized: "a11y.start", defaultValue: "Start timer")
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(RoTheme.Animation.press) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(RoTheme.Animation.release) {
                        isPressed = false
                    }
                }
        )
    }
}

#Preview {
    ContentView(repository: PreviewSessionRepository())
}

private final class PreviewSessionRepository: SessionRepositoryProtocol {
    func save(mode: TimerMode, duration: TimeInterval) throws {}
    func fetchAll() throws -> [FocusSession] { [] }
    func totalFocusTime() throws -> TimeInterval { 0 }
    func sessionsToday() throws -> [FocusSession] { [] }
}
