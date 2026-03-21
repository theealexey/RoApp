import Foundation
import os.log

enum AppGroup {
    static let id = "group.com.ro.app"

    static var containerURL: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: id
        )
    }

    static var stateURL: URL? {
        containerURL?.appendingPathComponent("timerState.json")
    }

    static func save(_ state: SharedTimerState) {
        guard let url = stateURL else { return }

        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: url, options: .atomic)
        } catch {
            Logger.appGroup.error("Failed to save shared timer state: \(error.localizedDescription)")
        }
    }

    static func load() -> SharedTimerState {
        guard
            let url = stateURL,
            let data = try? Data(contentsOf: url),
            let state = try? JSONDecoder().decode(SharedTimerState.self, from: data)
        else {
            return .empty
        }

        return state
    }
}

extension Logger {
    static let appGroup = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.ro.app", category: "AppGroup")
}
