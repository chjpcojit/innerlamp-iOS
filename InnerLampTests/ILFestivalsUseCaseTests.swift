//
//  ILFestivalsUseCaseTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

/// Festivals come from the server calendar (`ILCalendarEventRepository`) plus Rằm/Mùng Một
/// observances computed from the lunar calendar for days the server has no event on.
/// Known dates: 2024-02-10 = 1/1, 2024-02-24 = 15/1, 2024-03-10 = 1/2, 2024-03-25 = 15/2.
final class ILFestivalsUseCaseTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    private func event(_ code: String) -> ILCalendarEventEntity {
        ILCalendarEventEntity(
            code: code, name: "name-\(code)", shortDescription: "", longDescription: "", guidance: "",
            imageURL: nil, groupCodes: ["buddhist"], isPublicHoliday: false
        )
    }

    private func occurrence(
        _ code: String, _ solar: Date, lunarDay: Int, lunarMonth: Int
    ) -> ILCalendarOccurrenceEntity {
        ILCalendarOccurrenceEntity(
            eventCode: code, solarDate: solar, lunarDay: lunarDay, lunarMonth: lunarMonth, isLeapMonth: false
        )
    }

    private func makeSUT(
        events: [ILCalendarEventEntity] = [],
        occurrences: [ILCalendarOccurrenceEntity] = []
    ) -> (ILFestivalsUseCaseImpl, StubCalendarEventRepository) {
        let repository = StubCalendarEventRepository(events: events, occurrences: occurrences)
        return (ILFestivalsUseCaseImpl(calendarEventRepository: repository), repository)
    }

    func test_loadMonths_requestsTheGivenYearFromServer() async throws {
        let (sut, repository) = makeSUT()

        _ = try await sut.loadMonths(year: 2025, today: date(2024, 2, 1))

        XCTAssertEqual(repository.requestedYears, [2025])
    }

    func test_loadMonths_usesServerOccurrencesAsFestivalsWithServerLunarDate() async throws {
        let (sut, _) = makeSUT(
            events: [event("tet"), event("ram")],
            occurrences: [
                occurrence("tet", date(2024, 2, 10), lunarDay: 1, lunarMonth: 1),
                occurrence("ram", date(2024, 2, 24), lunarDay: 15, lunarMonth: 1)
            ]
        )

        let months = try await sut.loadMonths(year: 2024, today: date(2024, 2, 1))

        let february = try XCTUnwrap(months.first { $0.id == "2024-02" })
        XCTAssertEqual(february.days.map(\.title), ["name-tet", "name-ram"])
        XCTAssertEqual(february.days.map(\.kind), [.festival, .festival])
        XCTAssertEqual(february.days.map(\.daysUntil), [9, 23])
        XCTAssertEqual(february.days.map(\.lunarDay), [1, 15])
        XCTAssertEqual(february.days.map(\.lunarMonth), [1, 1])
    }

    func test_loadMonths_occurrenceWithUnknownEventCode_isSkipped() async throws {
        let (sut, _) = makeSUT(
            events: [event("tet")],
            occurrences: [occurrence("ghost", date(2024, 2, 10), lunarDay: 1, lunarMonth: 1)]
        )

        let months = try await sut.loadMonths(year: 2024, today: date(2024, 2, 1))

        XCTAssertFalse(months.flatMap(\.days).contains { $0.title == "name-ghost" })
    }

    func test_loadMonths_dayWithoutServerEvent_isObservanceForNewAndFullMoon() async throws {
        let (sut, _) = makeSUT(
            events: [event("tet")],
            occurrences: [occurrence("tet", date(2024, 2, 10), lunarDay: 1, lunarMonth: 1)]
        )

        let months = try await sut.loadMonths(year: 2024, today: date(2024, 2, 1))

        let march = try XCTUnwrap(months.first { $0.id == "2024-03" })
        XCTAssertEqual(march.days.first?.kind, .observance) // 1/2
        XCTAssertEqual(march.days.first?.date, date(2024, 3, 10))
        XCTAssertEqual(march.days.first?.lunarDay, 1)
        XCTAssertEqual(march.days.first?.lunarMonth, 2)
        XCTAssertTrue(march.days.contains { $0.date == date(2024, 3, 25) && $0.kind == .observance }) // 15/2
    }

    func test_loadMonths_noServerEvents_yieldsOnlyObservances() async throws {
        let (sut, _) = makeSUT()

        let months = try await sut.loadMonths(year: 2024, today: date(2024, 2, 1))

        XCTAssertFalse(months.isEmpty)
        XCTAssertTrue(months.flatMap(\.days).allSatisfy { $0.kind == .observance })
    }

    func test_loadMonths_twoEventsOnSameDay_produceTwoEntriesWithDistinctIDs() async throws {
        let (sut, _) = makeSUT(
            events: [event("a"), event("b")],
            occurrences: [
                occurrence("a", date(2024, 2, 10), lunarDay: 1, lunarMonth: 1),
                occurrence("b", date(2024, 2, 10), lunarDay: 1, lunarMonth: 1)
            ]
        )

        let months = try await sut.loadMonths(year: 2024, today: date(2024, 2, 1))

        let entries = try XCTUnwrap(months.first { $0.id == "2024-02" }).days.filter { $0.date == date(2024, 2, 10) }
        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(Set(entries.map(\.id)).count, 2)
    }

    func test_loadMonths_coversOnlyRequestedYearJanuaryToDecember() async throws {
        let (sut, _) = makeSUT()

        let months = try await sut.loadMonths(year: 2024, today: date(2024, 2, 1))

        XCTAssertEqual(months.first?.id, "2024-01")
        XCTAssertEqual(months.first?.label, String(format: "festivals.month.label".localized, 1))
        XCTAssertEqual(months.last?.id, "2024-12")
        XCTAssertEqual(months.count, 12)
    }

    func test_loadMonths_nextYear_labelsMonthsWithYearAndCountsDaysFromToday() async throws {
        let (sut, _) = makeSUT()

        let months = try await sut.loadMonths(year: 2025, today: date(2024, 2, 1))

        XCTAssertEqual(months.first?.id, "2025-01")
        XCTAssertEqual(months.first?.label, String(format: "festivals.month.labelYear".localized, 1, 2025))
        XCTAssertEqual(months.count, 12)
        XCTAssertTrue(months.flatMap(\.days).allSatisfy { $0.daysUntil > 0 })
    }

    func test_loadMonths_pastDaysHaveNegativeDaysUntil() async throws {
        let (sut, _) = makeSUT()

        let months = try await sut.loadMonths(year: 2024, today: date(2024, 2, 1))

        let january = try XCTUnwrap(months.first { $0.id == "2024-01" })
        XCTAssertTrue(january.days.allSatisfy { $0.daysUntil < 0 })
    }

    func test_loadMonths_propagatesRepositoryFailure() async {
        let repository = StubCalendarEventRepository(error: ILCatalogError.offline)
        let sut = ILFestivalsUseCaseImpl(calendarEventRepository: repository)

        do {
            _ = try await sut.loadMonths(year: 2024, today: date(2024, 2, 1))
            XCTFail("Expected loadMonths to throw")
        } catch {
            guard case ILCatalogError.offline = error else { return XCTFail("Unexpected error \(error)") }
        }
    }
}

private final class StubCalendarEventRepository: ILCalendarEventRepository {
    let events: [ILCalendarEventEntity]
    let occurrences: [ILCalendarOccurrenceEntity]
    let error: Error?
    private(set) var requestedYears: [Int] = []

    init(
        events: [ILCalendarEventEntity] = [],
        occurrences: [ILCalendarOccurrenceEntity] = [],
        error: Error? = nil
    ) {
        self.events = events
        self.occurrences = occurrences
        self.error = error
    }

    func loadEvents(year: Int) async throws -> ILCalendarEventsEntity {
        requestedYears.append(year)
        if let error { throw error }
        return ILCalendarEventsEntity(year: year, groups: [], events: events, occurrences: occurrences)
    }
}
