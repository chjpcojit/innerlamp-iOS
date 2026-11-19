//
//  ILMemorialReminderPlannerTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

final class ILMemorialReminderPlannerTests: XCTestCase {

    private typealias Factory = ILMemorialTestFactory

    func test_plans_oneOccurrencePerEntry() {
        let entry = Factory.entry(
            id: "1", name: "Nguyễn Văn An", relationship: .father,
            calendarKind: .solar, day: 20, month: 11, deathYear: nil,
            reminder: ILMemorialReminder(leadDays: 1, hour: 7, minute: 0)
        )

        let plans = ILMemorialReminderPlanner.plans(
            entries: [entry],
            now: Factory.date(2026, 10, 14),
            calendar: Factory.calendar
        )

        XCTAssertEqual(plans.count, 1)
        XCTAssertEqual(Factory.calendar.component(.year, from: plans[0].fireDate), 2026)
    }

    func test_plans_areCappedAtSixtyEntries() {
        let entries = (0..<100).map { index in
            Factory.entry(
                id: "\(index)", calendarKind: .solar, day: 20, month: 11,
                reminder: ILMemorialReminder(leadDays: 1, hour: 7, minute: 0)
            )
        }

        let plans = ILMemorialReminderPlanner.plans(
            entries: entries,
            now: Factory.date(2026, 10, 14),
            calendar: Factory.calendar
        )

        XCTAssertEqual(plans.count, ILMemorialReminderPlanner.maxScheduled)
        XCTAssertEqual(plans.count, 60)
        XCTAssertEqual(Set(plans.map(\.entryID)).count, 60, "One pending notification per entry")
    }

    func test_fireMoment_isAnniversaryMinusLeadDaysAtTime() throws {
        let reminder = ILMemorialReminder(leadDays: 3, hour: 6, minute: 30)
        let moment = try XCTUnwrap(
            ILMemorialReminderPlanner.fireMoment(
                anniversary: Factory.date(2026, 11, 20),
                reminder: reminder,
                calendar: Factory.calendar
            )
        )

        XCTAssertEqual(Factory.calendar.component(.day, from: moment), 17)
        XCTAssertEqual(Factory.calendar.component(.hour, from: moment), 6)
        XCTAssertEqual(Factory.calendar.component(.minute, from: moment), 30)
    }

    func test_body_usesRelationship_only_neverTheName() {
        let entry = Factory.entry(
            name: "Nguyễn Văn An", relationship: .father,
            calendarKind: .solar, day: 20, month: 11,
            reminder: ILMemorialReminder(leadDays: 1, hour: 7, minute: 0)
        )

        let plans = ILMemorialReminderPlanner.plans(
            entries: [entry],
            now: Factory.date(2026, 10, 14),
            calendar: Factory.calendar
        )

        XCTAssertFalse(plans.isEmpty)
        for plan in plans {
            XCTAssertFalse(plan.body.contains(entry.name), "NFR-MEM-02: no name in a notification")
            XCTAssertTrue(plan.body.contains("cha"), plan.body)
        }
    }

    func test_body_otherRelationship_readsNguoiThan() {
        let body = ILMemorialReminderPlanner.body(leadDays: 1, relationship: .other)

        XCTAssertTrue(body.contains("người thân"), body)
    }

    func test_catchUp_whenMomentPassedToday_isScheduledOnce() {
        let entry = Factory.entry(
            id: "today", relationship: .mother, calendarKind: .solar, day: 14, month: 10,
            reminder: ILMemorialReminder(leadDays: 1, hour: 7, minute: 0)
        )
        let now = Factory.date(2026, 10, 14)

        let first = ILMemorialReminderPlanner.plans(
            entries: [entry], now: now, calendar: Factory.calendar
        )
        let catchUp = first.first { $0.isCatchUp }
        XCTAssertNotNil(catchUp)
        XCTAssertEqual(catchUp?.fireDate.timeIntervalSince(now), 5)

        let key = catchUp?.deliveredKey ?? ""
        let second = ILMemorialReminderPlanner.plans(
            entries: [entry], now: now, calendar: Factory.calendar, deliveredKeys: [key]
        )
        XCTAssertNil(second.first { $0.isCatchUp }, "A delivered key must suppress the catch-up")
    }

    // MARK: - BR-MEM-13: catch up while the giỗ day is not over

    func test_catchUp_whenMomentFellYesterday_andTodayIsTheAnniversary() {
        let entry = Factory.entry(
            id: "anniversary-today", relationship: .mother,
            calendarKind: .solar, day: 15, month: 11,
            reminder: ILMemorialReminder(leadDays: 1, hour: 7, minute: 0)
        )
        // Moment: 14/11 07:00. Now: 15/11 09:00 — the giỗ day, its moment already gone.
        let now = Factory.date(2026, 11, 15)

        let plans = ILMemorialReminderPlanner.plans(
            entries: [entry], now: now, calendar: Factory.calendar
        )

        XCTAssertEqual(plans.count, 1)
        let catchUp = plans.first { $0.isCatchUp }
        XCTAssertNotNil(catchUp, "A moment that fell yesterday must catch up on the giỗ day")
        XCTAssertEqual(catchUp?.fireDate.timeIntervalSince(now), 5)
        XCTAssertEqual(catchUp?.deliveredKey, "anniversary-today:2026-11-15")
        XCTAssertTrue(catchUp?.body.contains("Hôm nay") == true, catchUp?.body ?? "")
    }

    func test_catchUp_whenMomentPassedToday_forTomorrowsAnniversary() {
        let entry = Factory.entry(
            id: "anniversary-tomorrow", relationship: .father,
            calendarKind: .solar, day: 16, month: 11,
            reminder: ILMemorialReminder(leadDays: 1, hour: 7, minute: 0)
        )
        // Moment: 15/11 07:00. Now: 15/11 09:00 — the giỗ day has not started, the moment is gone.
        let now = Factory.date(2026, 11, 15)

        let plans = ILMemorialReminderPlanner.plans(
            entries: [entry], now: now, calendar: Factory.calendar
        )

        let catchUp = plans.first { $0.isCatchUp }
        XCTAssertNotNil(catchUp, "A passed moment must catch up before the giỗ day is over")
        XCTAssertTrue(catchUp?.body.contains("Ngày mai") == true, catchUp?.body ?? "")
    }

    func test_noCatchUp_afterTheAnniversary_plansTheNextOccurrence() {
        let entry = Factory.entry(
            id: "anniversary-over", calendarKind: .solar, day: 10, month: 11,
            reminder: ILMemorialReminder(leadDays: 1, hour: 7, minute: 0)
        )
        // The 2026 giỗ was 10/11; now it is 15/11.
        let now = Factory.date(2026, 11, 15)

        let plans = ILMemorialReminderPlanner.plans(
            entries: [entry], now: now, calendar: Factory.calendar
        )

        XCTAssertEqual(plans.count, 1)
        XCTAssertFalse(plans[0].isCatchUp, "A giỗ day that is over is dropped, not caught up")
        XCTAssertEqual(Factory.calendar.component(.year, from: plans[0].fireDate), 2027)
        XCTAssertEqual(plans[0].deliveredKey, "anniversary-over:2027-11-10")
    }

    func test_catchUp_isEmittedOncePerEntryAndAnniversary() {
        let entry = Factory.entry(
            id: "once", calendarKind: .solar, day: 15, month: 11,
            reminder: ILMemorialReminder(leadDays: 1, hour: 7, minute: 0)
        )
        let now = Factory.date(2026, 11, 15)

        let first = ILMemorialReminderPlanner.plans(
            entries: [entry], now: now, calendar: Factory.calendar
        )
        XCTAssertEqual(first.count, 1, "One plan per entry and giỗ")

        let keys = Set(first.map(\.deliveredKey))
        let second = ILMemorialReminderPlanner.plans(
            entries: [entry], now: now, calendar: Factory.calendar, deliveredKeys: keys
        )
        XCTAssertTrue(second.isEmpty, "The same entry and giỗ must not fire twice")
    }

    func test_enterWithoutReminder_schedulesNothing() {
        let entry = Factory.entry(reminder: nil)

        let plans = ILMemorialReminderPlanner.plans(
            entries: [entry], now: Factory.date(2026, 10, 14), calendar: Factory.calendar
        )

        XCTAssertTrue(plans.isEmpty)
    }
}
