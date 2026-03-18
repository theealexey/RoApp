import Foundation
@testable import RoApp

final class MockSessionRepository: SessionRepositoryProtocol {

    private(set) var savedSessions: [(mode: TimerMode, duration: TimeInterval)] = []
    var sessionsToReturn: [MockFocusSessionData] = []
    var shouldThrow = false

    func save(mode: TimerMode, duration: TimeInterval) throws {
        if shouldThrow { throw MockError.saveFailed }
        savedSessions.append((mode, duration))
    }

    func fetchAll() throws -> [FocusSession] {
        if shouldThrow { throw MockError.fetchFailed }
        return sessionsToReturn.map { $0.toFocusSession() }
    }

    func totalFocusTime() throws -> TimeInterval {
        try fetchAll()
            .filter { $0.mode == .focus }
            .reduce(0) { $0 + $1.duration }
    }

    func sessionsToday() throws -> [FocusSession] {
        let start = Calendar.current.startOfDay(for: Date())
        return try fetchAll().filter { $0.completedAt >= start }
    }
}

struct MockFocusSessionData {
    let mode: TimerMode
    let duration: TimeInterval
    let completedAt: Date

    func toFocusSession() -> FocusSession {
        let session = FocusSession(mode: mode, duration: duration)
        session.completedAt = completedAt
        return session
    }
}

enum MockError: Error {
    case saveFailed
    case fetchFailed
}
