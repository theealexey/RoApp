import SwiftData
import Foundation

protocol SessionRepositoryProtocol {
    func save(mode: TimerMode, duration: TimeInterval) throws
    func fetchAll() throws -> [FocusSession]
    func totalFocusTime() throws -> TimeInterval
    func sessionsToday() throws -> [FocusSession]
}

final class SessionRepository: SessionRepositoryProtocol {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(mode: TimerMode, duration: TimeInterval) throws {
        let session = FocusSession(mode: mode, duration: duration)
        context.insert(session)
        try context.save()
    }

    func fetchAll() throws -> [FocusSession] {
        let descriptor = FetchDescriptor<FocusSession>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func totalFocusTime() throws -> TimeInterval {
        try fetchAll()
            .filter { $0.mode == .focus }
            .reduce(0) { $0 + $1.duration }
    }

    func sessionsToday() throws -> [FocusSession] {
        let start = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate { $0.completedAt >= start },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
}
