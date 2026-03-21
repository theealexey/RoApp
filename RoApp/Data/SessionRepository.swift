import SwiftData
import Foundation

protocol SessionRepositoryProtocol {
    func save(mode: TimerMode, duration: TimeInterval, tag: SessionTag) throws
    func fetchAll() throws -> [FocusSession]
}

final class SessionRepository: SessionRepositoryProtocol {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(mode: TimerMode, duration: TimeInterval, tag: SessionTag) throws {
        let session = FocusSession(mode: mode, duration: duration, tag: tag)
        context.insert(session)
        try context.save()
    }

    func fetchAll() throws -> [FocusSession] {
        let descriptor = FetchDescriptor<FocusSession>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

}
