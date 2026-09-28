//
//  ILBuddhistEventUseCaseTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

/// Exercises the pure occurrence computation in `ILBuddhistEventUseCaseImpl.occurrences`.
///
/// The solar→lunar mapping comes from `ILLunarCalendar`, whose known dates (already pinned in
/// `ILLunarCalendarUseCaseTests`) are reused here: 2024-02-10 = mùng 1 tháng Giêng, 2024-02-24 =
/// rằm tháng Giêng, 2024-09-17 = rằm tháng Tám.
final class ILBuddhistEventUseCaseTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)

    private func makeSUT() -> ILBuddhistEventUseCaseImpl {
        ILBuddhistEventUseCaseImpl(repository: MockILBuddhistEventRepository())
    }

    private func template(
        id: String = "t",
        lunarDay: Int,
        lunarMonth: Int,
        tradition: ILBuddhistTradition = .universal,
        isLeapMonthEligible: Bool = false
    ) -> ILBuddhistEventTemplateEntity {
        ILBuddhistEventTemplateEntity(
            id: id,
            title: id,
            eventDescription: "",
            lunarDay: lunarDay,
            lunarMonth: lunarMonth,
            tradition: tradition,
            isLeapMonthEligible: isLeapMonthEligible
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    // MARK: - Matching

    func test_occurrences_matchesTemplateOnItsLunarDate() {
        // Tết Nguyên Đán (1/1) rơi đúng 2024-02-10.
        let tet = template(id: "tet", lunarDay: 1, lunarMonth: 1)

        let result = makeSUT().occurrences(
            of: [tet],
            from: date(2024, 2, 1),
            to: date(2024, 3, 1),
            calendar: calendar
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.template.id, "tet")
        XCTAssertEqual(result.first?.date, date(2024, 2, 10))
    }

    func test_occurrences_matchesMultipleTemplatesInChronologicalOrder() {
        let tet = template(id: "tet", lunarDay: 1, lunarMonth: 1)
        let ramGieng = template(id: "ram-gieng", lunarDay: 15, lunarMonth: 1)

        let result = makeSUT().occurrences(
            of: [ramGieng, tet],
            from: date(2024, 2, 1),
            to: date(2024, 3, 1),
            calendar: calendar
        )

        XCTAssertEqual(result.map(\.template.id), ["tet", "ram-gieng"])
        XCTAssertEqual(result.map(\.date), [date(2024, 2, 10), date(2024, 2, 24)])
    }

    func test_occurrences_returnsEmpty_whenNoTemplateMatches() {
        let phatDan = template(id: "phat-dan", lunarDay: 15, lunarMonth: 4)

        let result = makeSUT().occurrences(
            of: [phatDan],
            from: date(2024, 2, 1),
            to: date(2024, 3, 1),
            calendar: calendar
        )

        XCTAssertTrue(result.isEmpty)
    }

    func test_occurrences_respectsHalfOpenRange() {
        let tet = template(id: "tet", lunarDay: 1, lunarMonth: 1)

        // Khoảng [01/02, 10/02) không bao gồm ngày 10/02.
        let excluding = makeSUT().occurrences(
            of: [tet],
            from: date(2024, 2, 1),
            to: date(2024, 2, 10),
            calendar: calendar
        )
        XCTAssertTrue(excluding.isEmpty)

        // Khoảng [01/02, 11/02) bao gồm ngày 10/02.
        let including = makeSUT().occurrences(
            of: [tet],
            from: date(2024, 2, 1),
            to: date(2024, 2, 11),
            calendar: calendar
        )
        XCTAssertEqual(including.count, 1)
    }

    func test_occurrences_returnsEmpty_whenTemplatesEmpty() {
        let result = makeSUT().occurrences(
            of: [],
            from: date(2024, 2, 1),
            to: date(2024, 3, 1),
            calendar: calendar
        )
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Leap month rule

    func test_occurrences_skipsNonEligibleTemplateOnLeapMonthDay() throws {
        let leap = try XCTUnwrap(firstLeapMonthDate(inYear: 2023))

        let nonEligible = template(
            id: "fixed",
            lunarDay: leap.lunar.day,
            lunarMonth: leap.lunar.month,
            isLeapMonthEligible: false
        )
        let eligible = template(
            id: "leap-ok",
            lunarDay: leap.lunar.day,
            lunarMonth: leap.lunar.month,
            isLeapMonthEligible: true
        )

        let result = makeSUT().occurrences(
            of: [nonEligible, eligible],
            from: date(2023, 1, 1),
            to: date(2024, 1, 1),
            calendar: calendar
        )

        let idsOnLeapDay = result
            .filter { calendar.isDate($0.date, inSameDayAs: leap.date) }
            .map(\.template.id)
        XCTAssertEqual(idsOnLeapDay, ["leap-ok"], "Non-eligible template must not fire on a leap-month day")
    }

    // MARK: - Helpers

    /// Scans `year` for the first date whose lunar conversion reports a leap month, returning that
    /// solar date and its lunar (month, day). 2023 (nhuận tháng 2) is used by the leap-month test.
    private func firstLeapMonthDate(inYear year: Int) -> (date: Date, lunar: ILLunarCalendar.LunarDate)? {
        guard
            let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
            let end = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1))
        else { return nil }

        var day = start
        while day < end {
            let lunar = ILLunarCalendar.solarToLunar(date: day, calendar: calendar)
            if lunar.isLeapMonth { return (day, lunar) }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { return nil }
            day = next
        }
        return nil
    }
}

/// Repository is unused by the pure `occurrences` path but required by the `Impl` initializer.
private final class MockILBuddhistEventRepository: ILBuddhistEventRepository {
    func loadTemplates() async throws -> [ILBuddhistEventTemplateEntity] { [] }
}
