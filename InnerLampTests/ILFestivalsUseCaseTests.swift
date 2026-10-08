//
//  ILFestivalsUseCaseTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

/// Festivals are built from the Core Data catalog (via `ILBuddhistEventUseCase`) plus Rằm/Mùng Một
/// observances computed from the lunar calendar. Known dates (see `ILBuddhistEventUseCaseTests`):
/// 2024-02-10 = 1/1, 2024-02-24 = 15/1, 2024-03-10 = 1/2, 2024-03-25 = 15/2.
final class ILFestivalsUseCaseTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    private func template(
        id: String,
        lunarDay: Int,
        lunarMonth: Int,
        tradition: ILBuddhistTradition = .mahayana,
        category: ILBuddhistEventCategory = .commemoration
    ) -> ILBuddhistEventTemplateEntity {
        ILBuddhistEventTemplateEntity(
            id: id, title: "title-\(id)", eventDescription: "",
            lunarDay: lunarDay, lunarMonth: lunarMonth,
            tradition: tradition, category: category, isLeapMonthEligible: false
        )
    }

    private func makeSUT(templates: [ILBuddhistEventTemplateEntity]) -> ILFestivalsUseCaseImpl {
        ILFestivalsUseCaseImpl(
            buddhistEventUseCase: ILBuddhistEventUseCaseImpl(repository: StubRepository(templates: templates))
        )
    }

    func test_loadMonths_usesStoredTemplatesAsFestivals() async throws {
        let sut = makeSUT(templates: [
            template(id: "tet", lunarDay: 1, lunarMonth: 1),
            template(id: "ram", lunarDay: 15, lunarMonth: 1)
        ])

        let months = try await sut.loadMonths(from: date(2024, 2, 1))

        let february = try XCTUnwrap(months.first { $0.id == "2024-02" })
        XCTAssertEqual(february.days.map(\.title), ["title-tet", "title-ram"])
        XCTAssertEqual(february.days.map(\.kind), [.festival, .festival])
        XCTAssertEqual(february.days.map(\.daysUntil), [9, 23])
    }

    func test_loadMonths_excludesFolkAndTheravadaTemplates() async throws {
        let sut = makeSUT(templates: [
            template(id: "buddhist", lunarDay: 1, lunarMonth: 1),
            template(id: "folk", lunarDay: 15, lunarMonth: 1, tradition: .universal, category: .folk),
            template(id: "nam-tong", lunarDay: 15, lunarMonth: 2, tradition: .theravada, category: .major)
        ])

        let months = try await sut.loadMonths(from: date(2024, 2, 1))

        let titles = months.flatMap(\.days).filter { $0.kind == .festival }.map(\.title)
        XCTAssertTrue(titles.contains("title-buddhist"))
        XCTAssertFalse(titles.contains("title-folk"))
        XCTAssertFalse(titles.contains("title-nam-tong"))
        // 15/1 and 15/2 fall back to observances once their templates are filtered out.
        let feb24 = months.flatMap(\.days).first { $0.date == date(2024, 2, 24) }
        XCTAssertEqual(feb24?.kind, .observance)
    }

    func test_loadMonths_dayWithoutTemplate_isObservanceForNewAndFullMoon() async throws {
        let sut = makeSUT(templates: [template(id: "tet", lunarDay: 1, lunarMonth: 1)])

        let months = try await sut.loadMonths(from: date(2024, 2, 1))

        let march = try XCTUnwrap(months.first { $0.id == "2024-03" })
        XCTAssertEqual(march.days.first?.kind, .observance) // 1/2
        XCTAssertEqual(march.days.first?.date, date(2024, 3, 10))
        XCTAssertTrue(march.days.contains { $0.date == date(2024, 3, 25) && $0.kind == .observance }) // 15/2
    }

    func test_loadMonths_emptyCatalog_yieldsOnlyObservances() async throws {
        let sut = makeSUT(templates: [])

        let months = try await sut.loadMonths(from: date(2024, 2, 1))

        XCTAssertFalse(months.isEmpty)
        XCTAssertTrue(months.flatMap(\.days).allSatisfy { $0.kind == .observance })
    }

    func test_loadMonths_twoTemplatesOnSameDay_produceTwoEntriesWithDistinctIDs() async throws {
        let sut = makeSUT(templates: [
            template(id: "a", lunarDay: 1, lunarMonth: 1),
            template(id: "b", lunarDay: 1, lunarMonth: 1)
        ])

        let months = try await sut.loadMonths(from: date(2024, 2, 1))

        let entries = try XCTUnwrap(months.first { $0.id == "2024-02" }).days.filter { $0.date == date(2024, 2, 10) }
        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(Set(entries.map(\.id)).count, 2)
    }

    func test_loadMonths_coversCurrentYearFromJanuaryPlusTwoYearsAndLabelsOtherYear() async throws {
        let sut = makeSUT(templates: [])

        let months = try await sut.loadMonths(from: date(2024, 2, 1))

        XCTAssertEqual(months.first?.id, "2024-01")
        XCTAssertEqual(months.first?.label, String(format: "festivals.month.label".localized, 1))
        XCTAssertEqual(months.last?.id, "2026-12")
        XCTAssertEqual(months.last?.label, String(format: "festivals.month.labelYear".localized, 12, 2026))
        XCTAssertEqual(months.count, 36)
    }

    func test_loadMonths_pastDaysHaveNegativeDaysUntil() async throws {
        let sut = makeSUT(templates: [])

        let months = try await sut.loadMonths(from: date(2024, 2, 1))

        let january = try XCTUnwrap(months.first { $0.id == "2024-01" })
        XCTAssertTrue(january.days.allSatisfy { $0.daysUntil < 0 })
    }

    func test_loadMonths_propagatesRepositoryFailure() async {
        let sut = ILFestivalsUseCaseImpl(
            buddhistEventUseCase: ILBuddhistEventUseCaseImpl(repository: StubRepository(error: NSError(domain: "t", code: 1)))
        )

        do {
            _ = try await sut.loadMonths(from: date(2024, 2, 1))
            XCTFail("Expected loadMonths to throw")
        } catch {
            XCTAssertEqual((error as NSError).code, 1)
        }
    }
}

private final class StubRepository: ILBuddhistEventRepository {
    let templates: [ILBuddhistEventTemplateEntity]
    let error: Error?

    init(templates: [ILBuddhistEventTemplateEntity] = [], error: Error? = nil) {
        self.templates = templates
        self.error = error
    }

    func loadTemplates() async throws -> [ILBuddhistEventTemplateEntity] {
        if let error { throw error }
        return templates
    }
}
