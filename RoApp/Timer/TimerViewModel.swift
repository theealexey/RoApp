import SwiftUI
import os.log

// MARK: - Protocol

@MainActor
protocol TimerViewModelProtocol: AnyObject {
    var mode: TimerMode { get }
    var state: TimerState { get }
    var timeRemaining: TimeInterval { get }
    var progress: Double { get }
    var formattedTime: String { get }
    var isRunning: Bool { get }
    var currentBaseDurationMinutes: Int { get }
    var selectedTag: SessionTag { get }

    func start()
    func pause()
    func reset()
    func skipToNextMode()
    func select(mode: TimerMode)
    func select(tag: SessionTag)
    func setCustomDuration(minutes: Int)
}

// MARK: - Implementation

@MainActor
@Observable
final class TimerViewModel: TimerViewModelProtocol {

    private(set) var mode: TimerMode = .focus
    private(set) var state: TimerState = .idle
    private(set) var timeRemaining: TimeInterval
    private(set) var selectedTag: SessionTag = .none

    private var sessionStartDuration: TimeInterval
    private var endDate: Date?
    private var countdownTask: Task<Void, Never>?

    private let repository: SessionRepositoryProtocol
    private let settingsStore: SettingsStoreProtocol
    private let notifications: NotificationServiceProtocol
    private let haptics: HapticsServiceProtocol
    private let liveActivity: LiveActivityServiceProtocol
    private let widgetSync: WidgetSyncServiceProtocol

    convenience init(repository: SessionRepositoryProtocol) {
        let settings = SettingsStore()
        self.init(
            repository: repository,
            settingsStore: settings,
            notifications: NotificationService.shared,
            haptics: HapticsService(settingsStore: settings),
            liveActivity: LiveActivityService(),
            widgetSync: WidgetSyncService()
        )
    }

    init(
        repository: SessionRepositoryProtocol,
        settingsStore: SettingsStoreProtocol,
        notifications: NotificationServiceProtocol,
        haptics: HapticsServiceProtocol,
        liveActivity: LiveActivityServiceProtocol,
        widgetSync: WidgetSyncServiceProtocol
    ) {
        self.repository = repository
        self.settingsStore = settingsStore
        self.notifications = notifications
        self.haptics = haptics
        self.liveActivity = liveActivity
        self.widgetSync = widgetSync

        let initialDuration = settingsStore.duration(for: .focus)
        self.timeRemaining = initialDuration
        self.sessionStartDuration = initialDuration
    }

    // MARK: - Computed

    var progress: Double {
        guard sessionStartDuration > 0 else { return 0 }
        let value = 1.0 - (timeRemaining / sessionStartDuration)
        return min(max(value, 0), 1)
    }

    var formattedTime: String {
        TimeFormatting.format(seconds: timeRemaining)
    }

    var isRunning: Bool { state == .running }

    var currentBaseDurationMinutes: Int {
        Int(settingsStore.duration(for: mode) / 60)
    }

    // MARK: - Actions

    func start() {
        guard state != .running else { return }

        let currentEndDate = Date().addingTimeInterval(timeRemaining)
        endDate = currentEndDate
        state = .running

        scheduleCountdown()
        liveActivity.startOrUpdate(state: makeLiveState())
        syncToWidget()
        haptics.start()

        if settingsStore.notificationsEnabled {
            notifications.scheduleCompletion(for: mode, in: timeRemaining)
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
        liveActivity.update(state: makeLiveState())
        syncToWidget()
        notifications.cancelCompletion(for: mode)
        haptics.pause()
    }

    func reset() {
        cancelCountdown()

        let currentDuration = settingsStore.duration(for: mode)
        endDate = nil
        timeRemaining = currentDuration
        sessionStartDuration = currentDuration
        state = .idle

        syncToWidget()
        liveActivity.end(state: makeLiveState())
        notifications.cancelAll()
        haptics.reset()
    }

    func skipToNextMode() {
        cancelCountdown()
        notifications.cancelAll()

        let nextMode = nextMode(after: mode)
        let nextDuration = settingsStore.duration(for: nextMode)

        mode = nextMode
        endDate = nil
        timeRemaining = nextDuration
        sessionStartDuration = nextDuration
        state = .idle

        syncToWidget()
        liveActivity.end(state: makeLiveState())
        haptics.reset()
    }

    func select(mode newMode: TimerMode) {
        cancelCountdown()

        let newDuration = settingsStore.duration(for: newMode)
        mode = newMode
        endDate = nil
        timeRemaining = newDuration
        sessionStartDuration = newDuration
        state = .idle

        syncToWidget()
        notifications.cancelAll()
        haptics.tap()
    }

    func select(tag: SessionTag) {
        selectedTag = tag
        haptics.tap()
    }

    func setCustomDuration(minutes: Int) {
        guard state == .idle || state == .paused else { return }

        let customDuration = TimeInterval(max(minutes, 1) * 60)
        timeRemaining = customDuration
        sessionStartDuration = customDuration

        syncToWidget()
    }

    // MARK: - Private

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
        notifications.cancelAll()
        haptics.finish()
        liveActivity.end(state: makeLiveState())

        moveToNextStateAfterCompletion(from: completedMode)
    }

    private func moveToNextStateAfterCompletion(from completedMode: TimerMode) {
        let next = nextMode(after: completedMode)
        let nextDuration = settingsStore.duration(for: next)

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
            try repository.save(mode: mode, duration: duration, tag: selectedTag)
        } catch {
            Logger.timer.error("Failed to save session: \(error.localizedDescription)")
        }
    }

    private func syncToWidget() {
        let sharedState = SharedTimerState(
            isRunning: state == .running,
            timeRemaining: timeRemaining,
            totalDuration: sessionStartDuration,
            modeRaw: mode.rawValue,
            endDate: endDate,
            tagRaw: selectedTag == .none ? nil : selectedTag.rawValue
        )
        widgetSync.sync(sharedState)
    }

    private func makeLiveState() -> LiveActivityState {
        LiveActivityState(
            timeRemaining: timeRemaining,
            totalDuration: sessionStartDuration,
            modeRaw: mode.rawValue,
            isRunning: state == .running,
            endDate: endDate
        )
    }

    private func cancelCountdown() {
        countdownTask?.cancel()
        countdownTask = nil
    }

    private func nextMode(after currentMode: TimerMode) -> TimerMode {
        switch currentMode {
        case .focus: .short
        case .short, .long: .focus
        }
    }
}

// MARK: - Logger

extension Logger {
    static let timer = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.ro.app", category: "Timer")
}
