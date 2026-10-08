//
//  ILMemorialUseCaseTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

final class ILMemorialUseCaseTests: XCTestCase {

    private typealias Factory = ILMemorialTestFactory

    private var repository: FakeILMemorialRepository!
    private var sut: ILMemorialUseCaseImpl!

    override func setUp() {
        super.setUp()
        repository = FakeILMemorialRepository()
        sut = ILMemorialUseCaseImpl(repository: repository, calendar: Factory.calendar)
    }

    override func tearDown() {
        sut = nil
        repository = nil
        super.tearDown()
    }

    private let now = ILMemorialTestFactory.date(2026, 10, 3)

    // MARK: - Solar entries

    func test_solar_laterThisYear() throws {
        let next = try XCTUnwrap(sut.nextAnniversary(for: Factory.entry(calendarKind: .solar, day: 15, month: 11), now: now))

        XCTAssertEqual(Factory.calendar.dateComponents([.year, .month, .day], from: next.date), DateComponents(year: 2026, month: 11, day: 15))
        XCTAssertEqual(next.daysUntil, 43)
    }

    func test_solar_alreadyPassed_rollsToNextYear() throws {
        let next = try XCTUnwrap(sut.nextAnniversary(for: Factory.entry(calendarKind: .solar, day: 1, month: 1), now: now))

        XCTAssertEqual(Factory.calendar.dateComponents([.year, .month, .day], from: next.date), DateComponents(year: 2027, month: 1, day: 1))
        XCTAssertEqual(next.daysUntil, 90)
    }

    func test_solar_today_isZeroDays() throws {
        let next = try XCTUnwrap(sut.nextAnniversary(for: Factory.entry(calendarKind: .solar, day: 3, month: 10), now: now))

        XCTAssertEqual(next.daysUntil, 0)
    }

    func test_solar_feb29_inNonLeapYear_fallsOnFeb28() throws {
        let januaryNow = Factory.date(2026, 1, 10)
        let next = try XCTUnwrap(sut.nextAnniversary(for: Factory.entry(calendarKind: .solar, day: 29, month: 2), now: januaryNow))

        XCTAssertEqual(Factory.calendar.dateComponents([.year, .month, .day], from: next.date), DateComponents(year: 2026, month: 2, day: 28))
    }

    func test_solar_day31_inThirtyDayMonth_fallsOnLastDay() throws {
        let next = try XCTUnwrap(sut.nextAnniversary(for: Factory.entry(calendarKind: .solar, day: 31, month: 11), now: now))

        XCTAssertEqual(Factory.calendar.dateComponents([.year, .month, .day], from: next.date), DateComponents(year: 2026, month: 11, day: 30))
    }

    // MARK: - Ordinal

    func test_ordinal_isYearsSinceDeath() throws {
        let first = try XCTUnwrap(sut.nextAnniversary(for: Factory.entry(calendarKind: .solar, day: 15, month: 11, deathYear: 2025), now: now))
        let second = try XCTUnwrap(sut.nextAnniversary(for: Factory.entry(calendarKind: .solar, day: 15, month: 11, deathYear: 2024), now: now))
        let fifth = try XCTUnwrap(sut.nextAnniversary(for: Factory.entry(calendarKind: .solar, day: 15, month: 11, deathYear: 2021), now: now))

        XCTAssertEqual(first.ordinal, 1)
        XCTAssertEqual(second.ordinal, 2)
        XCTAssertEqual(fifth.ordinal, 5)
    }

    func test_ordinal_isNil_whenYearUnknownOrNotBeforeNextGio() throws {
        let unknown = try XCTUnwrap(sut.nextAnniversary(for: Factory.entry(calendarKind: .solar, deathYear: nil), now: now))
        let sameYear = try XCTUnwrap(sut.nextAnniversary(for: Factory.entry(calendarKind: .solar, deathYear: 2026), now: now))

        XCTAssertNil(unknown.ordinal)
        XCTAssertNil(sameYear.ordinal)
    }

    // MARK: - Lunar entries

    func test_lunar_tet2025_fromNewYearsDay() throws {
        let newYear = Factory.date(2025, 1, 1)
        let entry = Factory.entry(calendarKind: .lunar, day: 1, month: 1, deathYear: 2020)

        let next = try XCTUnwrap(sut.nextAnniversary(for: entry, now: newYear))

        XCTAssertEqual(Factory.calendar.dateComponents([.year, .month, .day], from: next.date), DateComponents(year: 2025, month: 1, day: 29))
        XCTAssertEqual(next.daysUntil, 28)
        XCTAssertEqual(next.ordinal, 5, "lunar year 2025 − death year 2020")
        XCTAssertEqual(next.lunarDay, 1)
        XCTAssertEqual(next.lunarMonth, 1)
    }

    func test_lunar_resultIsOnOrAfterToday_andMatchesLunarDate() throws {
        let entry = Factory.entry(calendarKind: .lunar, day: 15, month: 8)

        let next = try XCTUnwrap(sut.nextAnniversary(for: entry, now: now))

        XCTAssertGreaterThanOrEqual(next.date, Factory.calendar.startOfDay(for: now))
        let lunar = ILLunarCalendar.solarToLunar(date: next.date, calendar: Factory.calendar)
        XCTAssertEqual(lunar.day, 15)
        XCTAssertEqual(lunar.month, 8)
        XCTAssertFalse(lunar.isLeapMonth)
    }

    func test_lunar_day30_neverLeavesItsMonth() throws {
        for month in 1...12 {
            let entry = Factory.entry(calendarKind: .lunar, day: 30, month: month)
            let next = try XCTUnwrap(sut.nextAnniversary(for: entry, now: now), "month \(month)")
            let lunar = ILLunarCalendar.solarToLunar(date: next.date, calendar: Factory.calendar)
            XCTAssertEqual(lunar.month, month)
            XCTAssertTrue([29, 30].contains(lunar.day))
        }
    }

    // MARK: - loadItems

    func test_loadItems_sortsBySoonestFirst() async throws {
        repository.entries = [
            Factory.entry(id: "late", name: "Late", calendarKind: .solar, day: 1, month: 1),
            Factory.entry(id: "soon", name: "Soon", calendarKind: .solar, day: 5, month: 10),
            Factory.entry(id: "mid", name: "Mid", calendarKind: .solar, day: 15, month: 11)
        ]

        let items = try await sut.loadItems(now: now)

        XCTAssertEqual(items.map(\.id), ["soon", "mid", "late"])
        XCTAssertEqual(items.map(\.next.daysUntil), [2, 43, 90])
    }

    func test_loadItems_tiesBreakByName() async throws {
        repository.entries = [
            Factory.entry(id: "b", name: "Bình", calendarKind: .solar, day: 15, month: 11),
            Factory.entry(id: "a", name: "An", calendarKind: .solar, day: 15, month: 11)
        ]

        let items = try await sut.loadItems(now: now)

        XCTAssertEqual(items.map(\.id), ["a", "b"])
    }

    func test_loadItems_empty() async throws {
        let items = try await sut.loadItems(now: now)

        XCTAssertTrue(items.isEmpty)
    }

    // MARK: - Validation / defaults

    func test_isValid_requiresNonWhitespaceName() {
        XCTAssertTrue(sut.isValid(name: "An"))
        XCTAssertTrue(sut.isValid(name: "  An  "))
        XCTAssertFalse(sut.isValid(name: ""))
        XCTAssertFalse(sut.isValid(name: "   \n "))
    }

    func test_makeNewEntry_hasFormDefaults() {
        let entry = sut.makeNewEntry()

        XCTAssertEqual(entry.name, "")
        XCTAssertEqual(entry.relationship, .paternalGrandfather)
        XCTAssertEqual(entry.calendarKind, .lunar)
        XCTAssertEqual(entry.day, 1)
        XCTAssertEqual(entry.month, 1)
        XCTAssertNil(entry.deathYear)
        XCTAssertEqual(entry.reminder, ILMemorialReminder(leadDays: 1, hour: 7, minute: 0))
        XCTAssertTrue(entry.syncToReminders)
    }

    func test_makeNewEntry_ids_areUnique() {
        XCTAssertNotEqual(sut.makeNewEntry().id, sut.makeNewEntry().id)
    }

    // MARK: - Save / delete

    func test_save_trimsNameBeforePersisting() async throws {
        try await sut.save(Factory.entry(name: "  Nguyễn Văn An \n"))

        XCTAssertEqual(repository.saved.first?.name, "Nguyễn Văn An")
    }

    func test_delete_forwardsIDToRepository() async throws {
        repository.entries = [Factory.entry(id: "x")]

        try await sut.delete(id: "x")

        XCTAssertEqual(repository.deletedIDs, ["x"])
        XCTAssertTrue(repository.entries.isEmpty)
    }
}
