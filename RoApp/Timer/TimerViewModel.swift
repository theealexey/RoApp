import WidgetKit
import SwiftUI
import ActivityKit

protocol TimerViewModelProtocol: AnyObject {
    var mode: TimerMode { get }
    var state: TimerState { get }
    var timeRemaining: TimeInterval { get }
    var progress: Double { get }
    var formattedTime: String { get }

    func start()
    func pause()
    func reset()
    func skipToNextMode()
    func select(mode: TimerMode)
    func setCustomDuration(minutes: Int)
}

@MainActor
@Observable
final class TimerViewModel: TimerViewModelProtocol {

    private(set) var mode: TimerMode = .focus
    private(set) var state: TimerState = .idle
    private(set) var timeRemaining: TimeInterval

    private var sessionStartDuration: TimeInterval
    private var endDate: Date?
    private var countdownTask: Task<Void, Never>?

    private let repository: SessionRepositoryProtocol
    private let settingsStore: SettingsStoreProtocol

    init(
        repository: SessionRepositoryProtocol,
        settingsStore: SettingsStoreProtocol = SettingsStore()
    ) {
        self.repository = repository
        self.settingsStore = settingsStore

        let initialDuration = settingsStore.duration(for: TimerMode.focus.rawValue)
        self.timeRemaining = initialDuration
        self.sessionStartDuration = initialDuration
    }

    var progress: Double {
        guard sessionStartDuration > 0 else { return 0 }

        let progressValue = 1.0 - (timeRemaining / sessionStartDuration)
        return min(max(progressValue, 0), 1)
    }

    var formattedTime: String {
        let totalSeconds = max(0, Int(ceil(timeRemaining)))
        return String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    var isRunning: Bool {
        state == .running
    }

    var currentBaseDurationMinutes: Int {
        Int(duration(for: mode) / 60)
    }

    func start() {
        guard state != .running else { return }

        let currentEndDate = Date().addingTimeInterval(timeRemaining)
        endDate = currentEndDate
        state = .running

        scheduleCountdown()
        startOrUpdateLiveActivity()
        syncToWidget()

        if settingsStore.notificationsEnabled {
            NotificationService.shared.scheduleCompletion(for: mode, in: timeRemaining)
        }
    }

    func pause() {
        guard state == .running else { return }

        if let endDate {
            timeRemaining = max(0, endDate.timeIntervalSinceNow)
        }

        self.endDate = nil
        state = .paused

        cancelCountdown()
        updateLiveActivityState()
        syncToWidget()
        NotificationService.shared.cancelCompletion(for: mode)
    }

    func reset() {
        cancelCountdown()

        let currentDuration = duration(for: mode)
        endDate = nil
        timeRemaining = currentDuration
        sessionStartDuration = currentDuration
        state = .idle

        syncToWidget()
        endLiveActivity()
        NotificationService.shared.cancelAll()
    }

    func skipToNextMode() {
        cancelCountdown()
        NotificationService.shared.cancelAll()

        let nextMode = nextMode(after: mode)
        let nextDuration = duration(for: nextMode)

        mode = nextMode
        endDate = nil
        timeRemaining = nextDuration
        sessionStartDuration = nextDuration
        state = .idle

        syncToWidget()
        endLiveActivity()
    }

    func select(mode newMode: TimerMode) {
        cancelCountdown()

        let newDuration = duration(for: newMode)
        mode = newMode
        endDate = nil
        timeRemaining = newDuration
        sessionStartDuration = newDuration
        state = .idle

        syncToWidget()
        NotificationService.shared.cancelAll()
    }

    func setCustomDuration(minutes: Int) {
        guard state == .idle || state == .paused else { return }

        let customDuration = TimeInterval(max(minutes, 1) * 60)
        timeRemaining = customDuration
        sessionStartDuration = customDuration

        syncToWidget()
    }

    private func scheduleCountdown() {
        cancelCountdown()

        countdownTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))

                guard !Task.isCancelled, let self else { return }
                guard let endDate = self.endDate else { return }

                let remainingTime = max(0, endDate.timeIntervalSinceNow)

                if remainingTime > 0 {
                    self.timeRemaining = remainingTime
                    self.syncToWidget()
                } else {
                    self.handleCompletion()
                    return
                }
            }
        }
    }

    private func handleCompletion() {
        let completedMode = mode
        let completedDuration = sessionStartDuration

        timeRemaining = 0
        state = .finished
        endDate = nil

        saveSession(mode: completedMode, duration: completedDuration)
        syncToWidget()
        cancelCountdown()
        NotificationService.shared.cancelAll()

        HapticsService.shared.finish()
        endLiveActivity()

        moveToNextStateAfterCompletion(from: completedMode)
    }

    private func moveToNextStateAfterCompletion(from completedMode: TimerMode) {
        let next = nextMode(after: completedMode)
        let nextDuration = duration(for: next)

        mode = next
        timeRemaining = nextDuration
        sessionStartDuration = nextDuration
        state = .idle
        syncToWidget()

        if completedMode == .focus, settingsStore.autoStartBreaksEnabled {
            start()
        }
    }

    private func saveSession(mode: TimerMode, duration: TimeInterval) {
        do {
            try repository.save(mode: mode, duration: duration)
        } catch {
            print("Failed to save session: \(error.localizedDescription)")
        }
    }

    private func syncToWidget() {
        let sharedState = SharedTimerState(
            isRunning: state == .running,
            timeRemaining: timeRemaining,
            totalDuration: sessionStartDuration,
            modeRaw: mode.rawValue,
            endDate: endDate
        )

        AppGroup.save(sharedState)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func cancelCountdown() {
        countdownTask?.cancel()
        countdownTask = nil
    }

    private func duration(for mode: TimerMode) -> TimeInterval {
        settingsStore.duration(for: mode.rawValue)
    }

    private func nextMode(after currentMode: TimerMode) -> TimerMode {
        switch currentMode {
        case .focus: .short
        case .short, .long: .focus
        }
    }
    
    // MARK: - Live Activity

    private var currentActivity: Activity<RoTimerAttributes>?

    private func startOrUpdateLiveActivity() {
        let contentState = makeContentState()

        if let activity = currentActivity {
            Task {
                await activity.update(
                    ActivityContent(state: contentState, staleDate: endDate)
                )
            }
            return
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = RoTimerAttributes()
        let content = ActivityContent(state: contentState, staleDate: endDate)

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            print("Live Activity start failed: \(error.localizedDescription)")
        }
    }

    private func updateLiveActivityState() {
        guard let activity = currentActivity else { return }
        let contentState = makeContentState()
        Task {
            await activity.update(
                ActivityContent(state: contentState, staleDate: nil)
            )
        }
    }

    private func endLiveActivity() {
        guard let activity = currentActivity else { return }
        let contentState = makeContentState()
        Task {
            await activity.end(
                ActivityContent(state: contentState, staleDate: nil),
                dismissalPolicy: .after(.now + 4)
            )
        }
        currentActivity = nil
    }

    private func makeContentState() -> RoTimerAttributes.ContentState {
        RoTimerAttributes.ContentState(
            timeRemaining: timeRemaining,
            totalDuration: sessionStartDuration,
            modeRaw: mode.rawValue,
            isRunning: state == .running,
            endDate: endDate
        )
    }
}
