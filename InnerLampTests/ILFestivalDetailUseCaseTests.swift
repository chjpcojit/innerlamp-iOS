//
//  ILFestivalDetailUseCaseTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

final class ILFestivalDetailUseCaseTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)

    private func day(_ year: Int, _ month: Int, _ dayOfMonth: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: dayOfMonth))!
    }

    private func makeSUT(
        events: [ILCalendarEventEntity],
        occurrences: [ILCalendarOccurrenceEntity],
        error: Error? = nil
    ) -> (ILFestivalDetailUseCaseImpl, FestivalDetailCalendarEventRepositoryStub) {
        let repository = FestivalDetailCalendarEventRepositoryStub()
        repository.error = error
        repository.result = ILCalendarEventsEntity(
            year: 2026,
            groups: [ILCalendarGroupEntity(code: "buddhist", name: "Phật giáo")],
            events: events,
            occurrences: occurrences
        )
        return (ILFestivalDetailUseCaseImpl(calendarEventRepository: repository), repository)
    }

    private func event(_ code: String) -> ILCalendarEventEntity {
        ILCalendarEventEntity(
            code: code, name: "Lễ \(code)", shortDescription: "ngắn", longDescription: "dài",
            guidance: "việc", imageURL: nil, groupCodes: ["buddhist", "unknown"], isPublicHoliday: false
        )
    }

    private func occurrence(_ code: String, on date: Date) -> ILCalendarOccurrenceEntity {
        ILCalendarOccurrenceEntity(eventCode: code, solarDate: date, lunarDay: 15, lunarMonth: 7, isLeapMonth: false)
    }

    func test_loadDetail_mergesEventOccurrenceAndGroups() async throws {
        let target = day(2026, 8, 28)
        let (sut, repository) = makeSUT(
            events: [event("vu-lan"), event("khac")],
            occurrences: [occurrence("khac", on: target), occurrence("vu-lan", on: target)]
        )

        let detail = try await sut.loadDetail(code: "vu-lan", date: target, today: day(2026, 8, 25))

        XCTAssertEqual(repository.requestedYears, [2026])
        XCTAssertEqual(detail.code, "vu-lan")
        XCTAssertEqual(detail.name, "Lễ vu-lan")
        XCTAssertEqual(detail.groupNames, ["Phật giáo"])
        XCTAssertEqual(detail.lunarDay, 15)
        XCTAssertEqual(detail.lunarMonth, 7)
        XCTAssertEqual(detail.daysUntil, 3)
    }

    func test_loadDetail_pastDate_hasNegativeDaysUntil() async throws {
        let target = day(2026, 8, 28)
        let (sut, _) = makeSUT(events: [event("vu-lan")], occurrences: [occurrence("vu-lan", on: target)])

        let detail = try await sut.loadDetail(code: "vu-lan", date: target, today: day(2026, 8, 30))

        XCTAssertEqual(detail.daysUntil, -2)
    }

    func test_loadDetail_unknownEvent_throwsNotFound() async {
        let target = day(2026, 8, 28)
        let (sut, _) = makeSUT(events: [event("vu-lan")], occurrences: [occurrence("vu-lan", on: target)])

        do {
            _ = try await sut.loadDetail(code: "khong-co", date: target, today: target)
            XCTFail("expected notFound")
        } catch {
            guard case ILCatalogError.notFound = error else { return XCTFail("unexpected \(error)") }
        }
    }

    func test_loadDetail_noOccurrenceOnThatDay_throwsNotFound() async {
        let (sut, _) = makeSUT(
            events: [event("vu-lan")],
            occurrences: [occurrence("vu-lan", on: day(2026, 8, 28))]
        )

        do {
            _ = try await sut.loadDetail(code: "vu-lan", date: day(2026, 8, 29), today: day(2026, 8, 29))
            XCTFail("expected notFound")
        } catch {
            guard case ILCatalogError.notFound = error else { return XCTFail("unexpected \(error)") }
        }
    }

    func test_loadDetail_repositoryError_isPropagated() async {
        let (sut, _) = makeSUT(events: [], occurrences: [], error: ILCatalogError.offline)

        do {
            _ = try await sut.loadDetail(code: "vu-lan", date: day(2026, 8, 28), today: day(2026, 8, 28))
            XCTFail("expected offline")
        } catch {
            guard case ILCatalogError.offline = error else { return XCTFail("unexpected \(error)") }
        }
    }
}

private final class FestivalDetailCalendarEventRepositoryStub: ILCalendarEventRepository {
    var result: ILCalendarEventsEntity?
    var error: Error?
    private(set) var requestedYears: [Int] = []

    func loadEvents(year: Int) async throws -> ILCalendarEventsEntity {
        requestedYears.append(year)
        if let error { throw error }
        guard let result else { throw ILCatalogError.notFound }
        return result
    }
}
