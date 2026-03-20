import Testing
import Foundation
@testable import RoApp

@MainActor
struct TimerViewModelEdgeCaseTests {

    private func makeSUT(
        settings: MockSettingsStore? = nil,
        repository: MockSessionRepository? = nil
    ) -> (vm: TimerViewModel, settings: MockSettingsStore, repo: MockSessionRepository) {
        let s = settings ?? MockSettingsStore()
        let r = repository ?? MockSessionRepository()
        let vm = TimerViewModel(
            repository: r,
            settingsStore: s,
            notifications: MockNotificationService(),
            haptics: MockHapticsService(),
            liveActivity: MockLiveActivityService(),
            widgetSync: MockWidgetSyncService()
        )
        return (vm, s, r)
    }

    // MARK: - Double Start

    @Test func doubleStartDoesNotBreakState() {
        let (vm, _, _) = makeSUT()
        vm.start()
        vm.start()
        vm.start()
        #expect(vm.state == .running)
        #expect(vm.isRunning == true)
    }

    // MARK: - Double Pause

    @Test func doublePauseDoesNotBreakState() {
        let (vm, _, _) = makeSUT()
        vm.start()
        vm.pause()
        vm.pause()
        #expect(vm.state == .paused)
    }

    // MARK: - Reset From Every State

    @Test func resetFromIdleStaysIdle() {
        let (vm, _, _) = makeSUT()
        vm.reset()
        #expect(vm.state == .idle)
        #expect(vm.timeRemaining == 25 * 60)
    }

    @Test func resetFromRunningGoesToIdle() {
        let (vm, _, _) = makeSUT()
        vm.start()
        vm.reset()
        #expect(vm.state == .idle)
    }

    @Test func resetFromPausedGoesToIdle() {
        let (vm, _, _) = makeSUT()
        vm.start()
        vm.pause()
        vm.reset()
        #expect(vm.state == .idle)
    }

    // MARK: - Mode Cycling

    @Test func fullModeCycle() {
        let (vm, _, _) = makeSUT()
        #expect(vm.mode == .focus)

        vm.skipToNextMode()
        #expect(vm.mode == .short)

        vm.skipToNextMode()
        #expect(vm.mode == .focus)
    }

    @Test func selectAllModes() {
        let (vm, settings, _) = makeSUT()

        for mode in TimerMode.allCases {
            vm.select(mode: mode)
            #expect(vm.mode == mode)
            #expect(vm.state == .idle)
            #expect(vm.timeRemaining == settings.duration(for: mode))
        }
    }

    // MARK: - Skip During Running Stops Timer

    @Test func skipWhileRunningResetsToIdle() {
        let (vm, _, _) = makeSUT()
        vm.start()
        vm.skipToNextMode()
        #expect(vm.state == .idle)
        #expect(vm.mode == .short)
    }

    @Test func skipWhilePausedResetsToIdle() {
        let (vm, _, _) = makeSUT()
        vm.start()
        vm.pause()
        vm.skipToNextMode()
        #expect(vm.state == .idle)
        #expect(vm.mode == .short)
    }

    // MARK: - Custom Duration Edge Cases

    @Test func setCustomDurationToMaximum() {
        let (vm, _, _) = makeSUT()
        vm.setCustomDuration(minutes: 180)
        #expect(vm.timeRemaining == 180 * 60)
    }

    @Test func setCustomDurationNegativeClampsTo1() {
        let (vm, _, _) = makeSUT()
        vm.setCustomDuration(minutes: -5)
        #expect(vm.timeRemaining == 60)
    }

    @Test func setCustomDurationTo1Minute() {
        let (vm, _, _) = makeSUT()
        vm.setCustomDuration(minutes: 1)
        #expect(vm.timeRemaining == 60)
    }

    // MARK: - Formatted Time Edge Cases

    @Test func formattedTimeForOneMinute() {
        let settings = MockSettingsStore()
        settings.focusDurationMinutes = 1
        let (vm, _, _) = makeSUT(settings: settings)
        #expect(vm.formattedTime == "01:00")
    }

    @Test func formattedTimeForMaxDuration() {
        let settings = MockSettingsStore()
        settings.focusDurationMinutes = 180
        let (vm, _, _) = makeSUT(settings: settings)
        #expect(vm.formattedTime == "180:00")
    }

    // MARK: - Start → Pause → Start (Resume)

    @Test func resumeAfterPause() {
        let (vm, _, _) = makeSUT()
        vm.start()
        let timeAfterStart = vm.timeRemaining
        vm.pause()
        let timeAfterPause = vm.timeRemaining
        vm.start()
        #expect(vm.state == .running)
        #expect(vm.timeRemaining <= timeAfterPause)
        #expect(vm.timeRemaining <= timeAfterStart)
    }

    // MARK: - Settings Changed After Init

    @Test func settingsChangeReflectedOnReset() {
        let settings = MockSettingsStore()
        settings.focusDurationMinutes = 25
        let (vm, _, _) = makeSUT(settings: settings)

        vm.start()
        settings.focusDurationMinutes = 45
        vm.reset()

        #expect(vm.timeRemaining == 45 * 60)
    }

    // MARK: - Current Base Duration Minutes

    @Test func currentBaseDurationForAllModes() {
        let settings = MockSettingsStore()
        settings.focusDurationMinutes = 30
        settings.shortBreakDurationMinutes = 7
        settings.longBreakDurationMinutes = 20
        let (vm, _, _) = makeSUT(settings: settings)

        vm.select(mode: .focus)
        #expect(vm.currentBaseDurationMinutes == 30)

        vm.select(mode: .short)
        #expect(vm.currentBaseDurationMinutes == 7)

        vm.select(mode: .long)
        #expect(vm.currentBaseDurationMinutes == 20)
    }
}
