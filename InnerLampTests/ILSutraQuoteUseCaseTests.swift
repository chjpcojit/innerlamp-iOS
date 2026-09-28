//
//  ILSutraQuoteUseCaseTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

final class ILSutraQuoteUseCaseTests: XCTestCase {

    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? .current
        self.calendar = calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? Date()
    }

    private func makeQuotes(_ count: Int) -> [ILSutraQuoteEntity] {
        (1...max(count, 1)).prefix(count).map {
            ILSutraQuoteEntity(id: $0, sutraName: "Kinh", translator: "Dịch giả", chapterNumber: "I",
                               chapterName: "Phẩm", verseNumber: $0, content: "Câu \($0)")
        }
    }

    // MARK: - quoteIndex (pure)

    func test_quoteIndex_usesOneBasedDayOfYearModuloCount() {
        XCTAssertEqual(ILSutraQuoteUseCaseImpl.quoteIndex(for: date(2026, 1, 1), totalCount: 300, calendar: calendar), 1)
        XCTAssertEqual(ILSutraQuoteUseCaseImpl.quoteIndex(for: date(2026, 2, 1), totalCount: 300, calendar: calendar), 32)
        // Day 300 of 2026 is 27 Oct → wraps to 0.
        XCTAssertEqual(ILSutraQuoteUseCaseImpl.quoteIndex(for: date(2026, 10, 27), totalCount: 300, calendar: calendar), 0)
        XCTAssertEqual(ILSutraQuoteUseCaseImpl.quoteIndex(for: date(2026, 12, 31), totalCount: 300, calendar: calendar), 65)
        // Leap year: 31 Dec is day 366.
        XCTAssertEqual(ILSutraQuoteUseCaseImpl.quoteIndex(for: date(2028, 12, 31), totalCount: 300, calendar: calendar), 66)
    }

    func test_quoteIndex_returnsNilForEmptyCatalog() {
        XCTAssertNil(ILSutraQuoteUseCaseImpl.quoteIndex(for: date(2026, 1, 1), totalCount: 0, calendar: calendar))
    }

    // MARK: - quote(for:)

    func test_quoteForDate_returnsQuoteAtRotationIndex() async throws {
        let repository = MockSutraQuoteRepository(quotes: makeQuotes(300))
        let useCase = ILSutraQuoteUseCaseImpl(repository: repository, calendar: calendar)

        let quote = try await useCase.quote(for: date(2026, 2, 1))

        XCTAssertEqual(quote?.id, 33, "Index 32 in id order is stt 33")
    }

    func test_quoteForDate_isStableForTheSameDay() async throws {
        let useCase = ILSutraQuoteUseCaseImpl(repository: MockSutraQuoteRepository(quotes: makeQuotes(300)), calendar: calendar)
        let morning = calendar.date(from: DateComponents(year: 2026, month: 9, day: 28, hour: 0, minute: 5)) ?? Date()
        let night = calendar.date(from: DateComponents(year: 2026, month: 9, day: 28, hour: 23, minute: 55)) ?? Date()

        let first = try await useCase.quote(for: morning)
        let second = try await useCase.quote(for: night)

        XCTAssertEqual(first, second)
    }

    func test_quoteForDate_returnsNilWhenCatalogEmpty() async throws {
        let useCase = ILSutraQuoteUseCaseImpl(repository: MockSutraQuoteRepository(quotes: []), calendar: calendar)

        let quote = try await useCase.quote(for: date(2026, 1, 1))

        XCTAssertNil(quote)
    }

    // MARK: - Random

    func test_randomQuote_returnsQuoteFromCatalog() async throws {
        let quotes = makeQuotes(5)
        let useCase = ILSutraQuoteUseCaseImpl(repository: MockSutraQuoteRepository(quotes: quotes), calendar: calendar)

        let quote = try await useCase.randomQuote()

        XCTAssertNotNil(quote)
        XCTAssertTrue(quotes.contains { $0 == quote })
    }

    func test_randomQuote_returnsNilWhenCatalogEmpty() async throws {
        let useCase = ILSutraQuoteUseCaseImpl(repository: MockSutraQuoteRepository(quotes: []), calendar: calendar)

        let quote = try await useCase.randomQuote()

        XCTAssertNil(quote)
    }

    func test_randomQuotes_returnsDistinctQuotesCappedAtCatalogSize() async throws {
        let useCase = ILSutraQuoteUseCaseImpl(repository: MockSutraQuoteRepository(quotes: makeQuotes(5)), calendar: calendar)

        let three = try await useCase.randomQuotes(count: 3)
        let tooMany = try await useCase.randomQuotes(count: 10)
        let none = try await useCase.randomQuotes(count: 0)

        XCTAssertEqual(three.count, 3)
        XCTAssertEqual(Set(three.map(\.id)).count, 3)
        XCTAssertEqual(tooMany.count, 5)
        XCTAssertTrue(none.isEmpty)
    }

    // MARK: - prepare

    func test_prepare_seedsRepository() async throws {
        let repository = MockSutraQuoteRepository(quotes: [])
        let useCase = ILSutraQuoteUseCaseImpl(repository: repository, calendar: calendar)

        try await useCase.prepare()

        XCTAssertEqual(repository.seedCallCount, 1)
    }
}

// MARK: - Mock

private final class MockSutraQuoteRepository: ILSutraQuoteRepository, @unchecked Sendable {

    private let quotes: [ILSutraQuoteEntity]
    private(set) var seedCallCount = 0

    init(quotes: [ILSutraQuoteEntity]) {
        self.quotes = quotes.sorted { $0.id < $1.id }
    }

    func seedIfNeeded() async throws {
        seedCallCount += 1
    }

    func count() async throws -> Int {
        quotes.count
    }

    func quote(at index: Int) async throws -> ILSutraQuoteEntity? {
        quotes.indices.contains(index) ? quotes[index] : nil
    }

    func loadAll() async throws -> [ILSutraQuoteEntity] {
        quotes
    }
}
