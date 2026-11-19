//
//  ILMemorialReminderContentTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

/// G1 item 5 (NFR-MEM-02): a lock-screen notification identifies the entry but never the person.
final class ILMemorialReminderContentTests: XCTestCase {

    private typealias Factory = ILMemorialTestFactory

    func test_content_hasOnlyEntryID_andRelationshipCopyWithoutName() throws {
        let entry = Factory.entry(
            id: "42", name: "Nguyễn Văn An", relationship: .father,
            calendarKind: .solar, day: 20, month: 11,
            reminder: ILMemorialReminder(leadDays: 1, hour: 7, minute: 0)
        )
        let plan = try XCTUnwrap(
            ILMemorialReminderPlanner.plans(
                entries: [entry],
                now: Factory.date(2026, 10, 14),
                calendar: Factory.calendar
            ).first
        )

        let content = ILLocalMemorialReminderScheduler.makeContent(for: plan)

        XCTAssertEqual(content.userInfo.keys.compactMap { $0 as? String }, ["entryId"])
        XCTAssertEqual(content.userInfo["entryId"] as? String, "42")
        XCTAssertEqual(content.categoryIdentifier, "memorial")
        XCTAssertFalse(content.title.contains(entry.name))
        XCTAssertFalse(content.body.contains(entry.name))
        XCTAssertTrue(content.body.contains("cha"), content.body)
    }
}
