import Foundation
@testable import RoApp

final class MockWidgetSyncService: WidgetSyncServiceProtocol {

    private(set) var syncCalls: [SharedTimerState] = []

    func sync(_ state: SharedTimerState) {
        syncCalls.append(state)
    }
}
