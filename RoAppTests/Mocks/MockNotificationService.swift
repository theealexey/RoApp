import Foundation
@testable import RoApp

final class MockNotificationService: NotificationServiceProtocol, @unchecked Sendable {

    private(set) var scheduleCompletionCalls: [(mode: TimerMode, seconds: TimeInterval)] = []
    private(set) var cancelCompletionCalls: [TimerMode] = []
    private(set) var cancelAllCallCount = 0
    private(set) var requestAuthorizationCallCount = 0

    var authorizationResult = true

    func requestAuthorization() async -> Bool {
        requestAuthorizationCallCount += 1
        return authorizationResult
    }

    func scheduleCompletion(for mode: TimerMode, in seconds: TimeInterval) {
        scheduleCompletionCalls.append((mode, seconds))
    }

    func cancelCompletion(for mode: TimerMode) {
        cancelCompletionCalls.append(mode)
    }

    func cancelAll() {
        cancelAllCallCount += 1
    }
}
