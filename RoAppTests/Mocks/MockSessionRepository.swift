import Foundation
@testable import RoApp

final class MockSessionRepository: SessionRepositoryProtocol {

    private(set) var savedSessions: [(mode: TimerMode, duration: TimeInterval, tag: SessionTag)] = []
    var sessionsToReturn: [MockFocusSessionData] = []
    var shouldThrow = false

    func save(mode: TimerMode, duration: TimeInterval, tag: SessionTag) throws {
        if shouldThrow { throw MockError.saveFailed }
        savedSessions.append((mode, duration, tag))
    }

    func fetchAll() throws -> [FocusSession] {
        if shouldThrow { throw MockError.fetchFailed }
        return sessionsToReturn.map { $0.toFocusSession() }
    }

}

struct MockFocusSessionData {
    let mode: TimerMode
    let duration: TimeInterval
    let completedAt: Date
    let tag: SessionTag

    init(mode: TimerMode, duration: TimeInterval, completedAt: Date, tag: SessionTag = .none) {
        self.mode = mode
        self.duration = duration
        self.completedAt = completedAt
        self.tag = tag
    }

    func toFocusSession() -> FocusSession {
        let session = FocusSession(mode: mode, duration: duration, tag: tag)
        session.completedAt = completedAt
        return session
    }
}

enum MockError: Error {
    case saveFailed
    case fetchFailed
}
