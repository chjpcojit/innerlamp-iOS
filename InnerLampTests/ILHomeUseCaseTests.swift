//
//  ILHomeUseCaseTests.swift
//  InnerLampTests
//
//

import XCTest
@testable import InnerLamp

/// Exercises `ILHomeUseCaseImpl` — the parts that are pure business logic rather than the mock
/// dashboard content. Covers the "Sự kiện Phật giáo" carousel range: it must span the full current
/// calendar year (Jan 1 → Dec 31), not the previous 3-month window.
final class ILHomeUseCaseTests: XCTestCase {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // Monday, matching the implementation
        return calendar
    }

    private var template: ILBuddhistEventTemplateEntity {
        ILBuddhistEventTemplateEntity(
            id: "tet",
            title: "Tết Nguyên Đán",
            eventDescription: "",
            lunarDay: 1,
            lunarMonth: 1,
            tradition: .universal,
            isLeapMonthEligible: false
        )
    }

    // MARK: - Buddhist event months range

    func test_loadBuddhistEventMonths_spansFullCalendarYear() async throws {
        let mock = MockILBuddhistEventUseCase()
        mock.templates = [template]
        let sut = ILHomeUseCaseImpl(keychainService: KeychainServiceImpl(), buddhistEventUseCase: mock, deityUseCase: ILDeityUseCaseImpl(), sutraQuoteUseCase: MockILSutraQuoteUseCase())

        let date = calendar.date(from: DateComponents(year: 2026, month: 9, day: 27))
        let midYear = try XCTUnwrap(date)

        _ = try await sut.loadBuddhistEventMonths(around: midYear)

        let yearInterval = calendar.dateInterval(of: .year, for: midYear)
        XCTAssertEqual(mock.lastFrom, yearInterval?.start, "Range must start at Jan 1 of the current year")
        XCTAssertEqual(mock.lastTo, yearInterval?.end, "Range must end at Jan 1 of the following year")
    }

    func test_loadBuddhistEventMonths_returnsEmpty_whenNoTemplates() async throws {
        let mock = MockILBuddhistEventUseCase()
        mock.templates = []
        let sut = ILHomeUseCaseImpl(keychainService: KeychainServiceImpl(), buddhistEventUseCase: mock, deityUseCase: ILDeityUseCaseImpl(), sutraQuoteUseCase: MockILSutraQuoteUseCase())

        let date = calendar.date(from: DateComponents(year: 2026, month: 9, day: 27))
        let midYear = try XCTUnwrap(date)

        let months = try await sut.loadBuddhistEventMonths(around: midYear)

        XCTAssertTrue(months.isEmpty)
        XCTAssertNil(mock.lastFrom, "occurrences must not be called when templates are empty")
    }

    // MARK: - Deity carousel

    func test_primaryMemorialDay_prefersBirthdayOverEarlierDays() {
        let days = [
            ILDeityMemorialDayEntity(lunarDay: 8, lunarMonth: 2, eventName: "Ngày Xuất gia"),
            ILDeityMemorialDayEntity(lunarDay: 15, lunarMonth: 4, eventName: "Ngày Đại lễ Phật Đản (Tam Hợp)")
        ]

        let day = ILHomeUseCaseImpl.primaryMemorialDay(of: days)

        XCTAssertEqual(day?.lunarDay, 15)
        XCTAssertEqual(day?.lunarMonth, 4)
    }

    func test_primaryMemorialDay_fallsBackToFirstDay_whenNoBirthdayOrVia() {
        let days = [
            ILDeityMemorialDayEntity(lunarDay: 15, lunarMonth: 1, eventName: "Ngày Lễ Cầu Trí Tuệ Thượng Nguyên"),
            ILDeityMemorialDayEntity(lunarDay: 8, lunarMonth: 4, eventName: "Ngày Lễ Hộ Pháp Chư Thiên")
        ]

        XCTAssertEqual(ILHomeUseCaseImpl.primaryMemorialDay(of: days)?.lunarDay, 15)
        XCTAssertNil(ILHomeUseCaseImpl.primaryMemorialDay(of: []))
    }

    func test_getInitialState_mapsFullDeityCatalog() {
        let deityUseCase = ILDeityUseCaseImpl()
        let sut = ILHomeUseCaseImpl(
            keychainService: KeychainServiceImpl(),
            buddhistEventUseCase: MockILBuddhistEventUseCase(),
            deityUseCase: deityUseCase,
            sutraQuoteUseCase: MockILSutraQuoteUseCase()
        )

        let entity = sut.getInitialState()

        XCTAssertEqual(entity.deities.map(\.id), deityUseCase.getAllDeities().map(\.id))
        XCTAssertEqual(entity.deities.first?.memorialDay?.lunarDay, 15, "Thích Ca → Phật Đản 15/4")
    }

    // MARK: - Lunar hero verse

    private var quote: ILSutraQuoteEntity {
        ILSutraQuoteEntity(
            id: 1,
            sutraName: "Kinh Pháp Cú (Dhammapada)",
            translator: "Hòa thượng Thích Minh Châu",
            chapterNumber: "I",
            chapterName: "Phẩm Song Yếu",
            verseNumber: 5,
            content: "Với hận diệt hận thù, Ðời này không có được. Không hận diệt hận thù, Là định luật ngàn thu"
        )
    }

    private func makeSUT(sutraQuoteUseCase: ILSutraQuoteUseCase) -> ILHomeUseCaseImpl {
        ILHomeUseCaseImpl(
            keychainService: KeychainServiceImpl(),
            buddhistEventUseCase: MockILBuddhistEventUseCase(),
            deityUseCase: ILDeityUseCaseImpl(),
            sutraQuoteUseCase: sutraQuoteUseCase
        )
    }

    func test_loadRandomVerse_mapsRandomQuoteFromCatalog() async {
        let mock = MockILSutraQuoteUseCase()
        mock.randomResult = quote

        let verse = await makeSUT(sutraQuoteUseCase: mock).loadRandomVerse()

        XCTAssertEqual(mock.randomQuoteCallCount, 1)
        XCTAssertEqual(verse, ILHomeUseCaseImpl.makeVerse(from: quote))
        XCTAssertEqual(verse.lines, [
            "Với hận diệt hận thù,",
            "Ðời này không có được.",
            "Không hận diệt hận thù,",
            "Là định luật ngàn thu"
        ])
        XCTAssertTrue(verse.source.contains(quote.sutraName))
        XCTAssertTrue(verse.source.contains("5"))
    }

    func test_loadRandomVerse_fallsBackToStaticVerse_whenCatalogEmpty() async {
        let mock = MockILSutraQuoteUseCase()
        mock.randomResult = nil

        let verse = await makeSUT(sutraQuoteUseCase: mock).loadRandomVerse()

        XCTAssertEqual(verse, ILHomeUseCaseImpl.fallbackVerse)
    }

    func test_loadRandomVerse_fallsBackToStaticVerse_whenLoadFails() async {
        let mock = MockILSutraQuoteUseCase()
        mock.error = ILSutraQuoteError.loadFailed(NSError(domain: "test", code: 1))

        let verse = await makeSUT(sutraQuoteUseCase: mock).loadRandomVerse()

        XCTAssertEqual(verse, ILHomeUseCaseImpl.fallbackVerse)
    }

    func test_getInitialState_leavesVerseEmpty_andSelectDayKeepsLoadedVerse() throws {
        let sut = makeSUT(sutraQuoteUseCase: MockILSutraQuoteUseCase())
        var entity = sut.getInitialState()
        XCTAssertTrue(entity.lunarDate.verse.lines.isEmpty, "Verse is loaded asynchronously, not seeded statically")

        let loaded = ILHomeUseCaseImpl.makeVerse(from: quote)
        entity.lunarDate.verse = loaded
        let otherDay = try XCTUnwrap(entity.weekPages.flatMap(\.days).first { $0.id != entity.selectedDayID })

        let updated = sut.selectDay(id: otherDay.id, in: entity)

        XCTAssertEqual(updated.lunarDate.verse, loaded)
    }
}

/// Stands in for the Core Data-backed sutra quote use case.
private final class MockILSutraQuoteUseCase: ILSutraQuoteUseCase {

    var randomResult: ILSutraQuoteEntity?
    var error: Error?
    private(set) var randomQuoteCallCount = 0

    func prepare() async throws {}

    func quote(for date: Date) async throws -> ILSutraQuoteEntity? { nil }

    func randomQuote() async throws -> ILSutraQuoteEntity? {
        randomQuoteCallCount += 1
        if let error { throw error }
        return randomResult
    }

    func randomQuotes(count: Int) async throws -> [ILSutraQuoteEntity] { [] }
}

/// Records the range passed to `occurrences` so the test can assert it, while standing in for the
/// real Buddhist-event use case.
private final class MockILBuddhistEventUseCase: ILBuddhistEventUseCase {

    var templates: [ILBuddhistEventTemplateEntity] = []
    var lastFrom: Date?
    var lastTo: Date?

    func loadTemplates() async throws -> [ILBuddhistEventTemplateEntity] {
        templates
    }

    func occurrences(
        of templates: [ILBuddhistEventTemplateEntity],
        from start: Date,
        to end: Date,
        calendar: Calendar
    ) -> [ILBuddhistEventOccurrenceEntity] {
        lastFrom = start
        lastTo = end
        return []
    }
}
