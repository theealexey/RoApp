import Testing
import Foundation
@testable import RoApp

@Suite("SessionTag")
struct SessionTagTests {

    // MARK: - Raw Values

    @Test("all raw values are lowercase strings")
    func rawValues() {
        #expect(SessionTag.work.rawValue == "work")
        #expect(SessionTag.study.rawValue == "study")
        #expect(SessionTag.personal.rawValue == "personal")
        #expect(SessionTag.health.rawValue == "health")
        #expect(SessionTag.creative.rawValue == "creative")
        #expect(SessionTag.none.rawValue == "none")
    }

    // MARK: - CaseIterable

    @Test("allCases has 6 cases")
    func caseCount() {
        #expect(SessionTag.allCases.count == 6)
    }

    @Test("selectable excludes .none")
    func selectableExcludesNone() {
        #expect(!SessionTag.selectable.contains(.none))
        #expect(SessionTag.selectable.count == 5)
    }

    // MARK: - Labels

    @Test("every tag has a non-empty label")
    func labelsNotEmpty() {
        for tag in SessionTag.allCases {
            #expect(!tag.label.isEmpty, "Tag \(tag.rawValue) has empty label")
        }
    }

    // MARK: - Icons

    @Test("every tag has a non-empty icon")
    func iconsNotEmpty() {
        for tag in SessionTag.allCases {
            #expect(!tag.icon.isEmpty, "Tag \(tag.rawValue) has empty icon")
        }
    }

    // MARK: - Colors

    @Test("every selectable tag has a unique color distinct from gray")
    func colorsAreUnique() {
        let colors = SessionTag.selectable.map { "\($0.color)" }
        let unique = Set(colors)
        #expect(unique.count == SessionTag.selectable.count)
    }

    // MARK: - Identifiable

    @Test("id matches rawValue")
    func identifiable() {
        for tag in SessionTag.allCases {
            #expect(tag.id == tag.rawValue)
        }
    }

    // MARK: - Codable round-trip

    @Test("Codable encodes and decodes correctly")
    func codable() throws {
        for tag in SessionTag.allCases {
            let data = try JSONEncoder().encode(tag)
            let decoded = try JSONDecoder().decode(SessionTag.self, from: data)
            #expect(decoded == tag)
        }
    }

    // MARK: - FocusSession integration

    @Test("FocusSession stores nil for .none tag")
    func sessionNoneTag() {
        let session = FocusSession(mode: .focus, duration: 1500, tag: .none)
        #expect(session.tagRaw == nil)
        #expect(session.tag == .none)
    }

    @Test("FocusSession stores raw value for real tags")
    func sessionRealTag() {
        let session = FocusSession(mode: .focus, duration: 1500, tag: .work)
        #expect(session.tagRaw == "work")
        #expect(session.tag == .work)
    }

    @Test("FocusSession defaults to .none when tagRaw is nil")
    func sessionNilFallback() {
        let session = FocusSession(mode: .focus, duration: 1500)
        #expect(session.tag == .none)
    }

    @Test("FocusSession defaults to .none for unknown tagRaw")
    func sessionUnknownTag() {
        let session = FocusSession(mode: .focus, duration: 1500)
        session.tagRaw = "invalid_tag_xyz"
        #expect(session.tag == .none)
    }
}
