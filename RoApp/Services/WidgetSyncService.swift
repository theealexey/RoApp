import WidgetKit

// MARK: - Protocol

protocol WidgetSyncServiceProtocol: AnyObject {
    func sync(_ state: SharedTimerState)
}

// MARK: - Implementation

final class WidgetSyncService: WidgetSyncServiceProtocol {
    func sync(_ state: SharedTimerState) {
        AppGroup.save(state)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
