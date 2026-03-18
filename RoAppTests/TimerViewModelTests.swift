import Testing
import Foundation
@testable import RoApp

@MainActor
struct TimerViewModelTests {

    private func makeSUT(
        settings: MockSettingsStore = MockSettingsStore(),
        repository: MockSessionRepository = MockSessionRepository()
    ) -> (vm: TimerViewModel, settings: MockSettingsStore, repo: MockSessionRepository) {
        let vm = TimerViewModel(repository: repository, settingsStore: settings)
        return (vm, settings, repository)
    }

    // MARK: - Initial State

    @Test func initialState() {
        let (vm, _, _) = makeSUT()
        #expect(vm.state == .idle)
        #expect(vm.mode == .focus)
        #expect(vm.timeRemaining == 25 * 60)
        #expect(vm.progress == 0)
        #expect(vm.isRunning == false)
    }

    @Test func initialStateUsesSettingsDuration() {
        let settings = MockSettingsStore()
        settings.focusDurationMinutes = 50
        let (vm, _, _) = makeSUT(settings: settings)
        #expect(vm.timeRemaining == 50 * 60)
    }

    // MARK: - Start

    @Test func startTransitionsToRunning() {
        let (vm, _, _) = makeSUT()
        vm.start()
        #expect(vm.state == .running)
        #expect(vm.isRunning == true)
    }

    @Test func startWhenAlreadyRunningIsNoOp() {
        let (vm, _, _) = makeSUT()
        vm.start()
        let timeBefore = vm.timeRemaining
        vm.start()
        #expect(vm.state == .running)
        #expect(vm.timeRemaining <= timeBefore)
    }

    // MARK: - Pause

    @Test func pauseTransitionsToPaused() {
        let (vm, _, _) = makeSUT()
        vm.start()
        vm.pause()
        #expect(vm.state == .paused)
        #expect(vm.isRunning == false)
    }

    @Test func pausePreservesTimeRemaining() {
        let (vm, _, _) = makeSUT()
        vm.start()
        vm.pause()
        #expect(vm.timeRemaining > 0)
        #expect(vm.timeRemaining <= 25 * 60)
    }

    @Test func pauseWhenIdleIsNoOp() {
        let (vm, _, _) = makeSUT()
        vm.pause()
        #expect(vm.state == .idle)
    }

    // MARK: - Reset

    @Test func resetRestoresFullDuration() {
        let (vm, _, _) = makeSUT()
        vm.start()
        vm.reset()
        #expect(vm.state == .idle)
        #expect(vm.timeRemaining == 25 * 60)
        #expect(vm.progress == 0)
    }

    @Test func resetFromPaused() {
        let (vm, _, _) = makeSUT()
        vm.start()
        vm.pause()
        vm.reset()
        #expect(vm.state == .idle)
        #expect(vm.timeRemaining == 25 * 60)
    }

    // MARK: - Skip to Next Mode

    @Test func skipFromFocusGoesToShort() {
        let (vm, _, _) = makeSUT()
        vm.skipToNextMode()
        #expect(vm.mode == .short)
        #expect(vm.state == .idle)
        #expect(vm.timeRemaining == 5 * 60)
    }

    @Test func skipFromShortGoesToFocus() {
        let (vm, _, _) = makeSUT()
        vm.skipToNextMode() // focus → short
        vm.skipToNextMode() // short → focus
        #expect(vm.mode == .focus)
        #expect(vm.timeRemaining == 25 * 60)
    }

    @Test func skipFromLongGoesToFocus() {
        let (vm, _, _) = makeSUT()
        vm.select(mode: .long)
        vm.skipToNextMode()
        #expect(vm.mode == .focus)
    }

    // MARK: - Select Mode

    @Test func selectModeChangesMode() {
        let (vm, _, _) = makeSUT()
        vm.select(mode: .long)
        #expect(vm.mode == .long)
        #expect(vm.state == .idle)
        #expect(vm.timeRemaining == 15 * 60)
    }

    @Test func selectModeResetsRunningState() {
        let (vm, _, _) = makeSUT()
        vm.start()
        vm.select(mode: .short)
        #expect(vm.state == .idle)
        #expect(vm.mode == .short)
    }

    // MARK: - Custom Duration

    @Test func setCustomDurationInIdle() {
        let (vm, _, _) = makeSUT()
        vm.setCustomDuration(minutes: 45)
        #expect(vm.timeRemaining == 45 * 60)
    }

    @Test func setCustomDurationInPaused() {
        let (vm, _, _) = makeSUT()
        vm.start()
        vm.pause()
        vm.setCustomDuration(minutes: 10)
        #expect(vm.timeRemaining == 10 * 60)
    }

    @Test func setCustomDurationIgnoredWhenRunning() {
        let (vm, _, _) = makeSUT()
        vm.start()
        vm.setCustomDuration(minutes: 10)
        #expect(vm.timeRemaining != 10 * 60)
    }

    @Test func setCustomDurationClampsMinimum() {
        let (vm, _, _) = makeSUT()
        vm.setCustomDuration(minutes: 0)
        #expect(vm.timeRemaining == 60)
    }

    // MARK: - Progress

    @Test func progressIsZeroAtStart() {
        let (vm, _, _) = makeSUT()
        #expect(vm.progress == 0)
    }

    @Test func progressAfterCustomDuration() {
        let (vm, _, _) = makeSUT()
        vm.setCustomDuration(minutes: 10)
        #expect(vm.progress == 0)
    }

    // MARK: - Formatted Time

    @Test func formattedTimeDefault() {
        let (vm, _, _) = makeSUT()
        #expect(vm.formattedTime == "25:00")
    }

    @Test func formattedTimeCustom() {
        let settings = MockSettingsStore()
        settings.focusDurationMinutes = 1
        let (vm, _, _) = makeSUT(settings: settings)
        #expect(vm.formattedTime == "01:00")
    }

    // MARK: - Current Base Duration

    @Test func currentBaseDurationMinutes() {
        let (vm, _, _) = makeSUT()
        #expect(vm.currentBaseDurationMinutes == 25)

        vm.select(mode: .short)
        #expect(vm.currentBaseDurationMinutes == 5)
    }
}
