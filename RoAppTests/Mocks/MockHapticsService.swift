import Foundation
@testable import RoApp

@MainActor
final class MockHapticsService: HapticsServiceProtocol {

    private(set) var tapCallCount = 0
    private(set) var startCallCount = 0
    private(set) var pauseCallCount = 0
    private(set) var finishCallCount = 0
    private(set) var resetCallCount = 0

    func tap() { tapCallCount += 1 }
    func start() { startCallCount += 1 }
    func pause() { pauseCallCount += 1 }
    func finish() { finishCallCount += 1 }
    func reset() { resetCallCount += 1 }
}
