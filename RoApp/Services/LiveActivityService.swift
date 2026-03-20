import ActivityKit
import Foundation
import os.log

// MARK: - Protocol

@MainActor
protocol LiveActivityServiceProtocol: AnyObject {
    func startOrUpdate(state: LiveActivityState)
    func update(state: LiveActivityState)
    func end(state: LiveActivityState)
}

struct LiveActivityState {
    let timeRemaining: TimeInterval
    let totalDuration: TimeInterval
    let modeRaw: String
    let isRunning: Bool
    let endDate: Date?
}

// MARK: - Implementation

@MainActor
final class LiveActivityService: LiveActivityServiceProtocol {

    private var currentActivity: Activity<RoTimerAttributes>?

    func startOrUpdate(state: LiveActivityState) {
        let contentState = makeContentState(from: state)

        if let activity = currentActivity {
            Task {
                await activity.update(
                    ActivityContent(state: contentState, staleDate: state.endDate)
                )
            }
            return
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = RoTimerAttributes()
        let content = ActivityContent(state: contentState, staleDate: state.endDate)

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            Logger.timer.error("Live Activity start failed: \(error.localizedDescription)")
        }
    }

    func update(state: LiveActivityState) {
        guard let activity = currentActivity else { return }
        let contentState = makeContentState(from: state)
        Task {
            await activity.update(
                ActivityContent(state: contentState, staleDate: nil)
            )
        }
    }

    func end(state: LiveActivityState) {
        guard let activity = currentActivity else { return }
        let contentState = makeContentState(from: state)
        Task {
            await activity.end(
                ActivityContent(state: contentState, staleDate: nil),
                dismissalPolicy: .after(.now + 4)
            )
        }
        currentActivity = nil
    }

    private func makeContentState(from state: LiveActivityState) -> RoTimerAttributes.ContentState {
        RoTimerAttributes.ContentState(
            timeRemaining: state.timeRemaining,
            totalDuration: state.totalDuration,
            modeRaw: state.modeRaw,
            isRunning: state.isRunning,
            endDate: state.endDate
        )
    }
}
