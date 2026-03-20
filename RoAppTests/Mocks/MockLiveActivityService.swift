import Foundation
@testable import RoApp

@MainActor
final class MockLiveActivityService: LiveActivityServiceProtocol {

    private(set) var startOrUpdateCalls: [LiveActivityState] = []
    private(set) var updateCalls: [LiveActivityState] = []
    private(set) var endCalls: [LiveActivityState] = []

    func startOrUpdate(state: LiveActivityState) {
        startOrUpdateCalls.append(state)
    }

    func update(state: LiveActivityState) {
        updateCalls.append(state)
    }

    func end(state: LiveActivityState) {
        endCalls.append(state)
    }
}
