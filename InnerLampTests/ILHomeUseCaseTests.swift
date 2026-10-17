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

    private func event(_ code: String, name: String, groups: [String] = ["buddhist"]) -> ILCalendarEventEntity {
        ILCalendarEventEntity(
            code: code, name: name, shortDescription: "", longDescription: "", guidance: "",
            imageURL: nil, groupCodes: groups, isPublicHoliday: false,
            isMajor: false, sortOrder: 0, recurrence: .solar
        )
    }

    private func occurrence(_ code: String, _ year: Int, _ month: Int, _ day: Int, lunarDay: Int, lunarMonth: Int, leap: Bool = false) -> ILCalendarOccurrenceEntity {
        ILCalendarOccurrenceEntity(
            eventCode: code,
            solarDate: calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date(),
            lunarDay: lunarDay, lunarMonth: lunarMonth, isLeapMonth: leap
        )
    }

    private func makeEventsSUT(_ repository: MockILCalendarEventRepository) -> ILHomeUseCaseImpl {
        ILHomeUseCaseImpl(calendarEventRepository: repository, sutraQuoteUseCase: MockILSutraQuoteUseCase(), templeRepository: MockILTempleRepository(), deityCatalogRepository: MockILDeityCatalogRepository(), articleRepository: MockILArticleRepository(), photosRepository: MockILPhotosRepository())
    }

    // MARK: - Buddhist event months (server)

    func test_loadBuddhistEventMonths_requestsTheYearOfTheGivenDate() async throws {
        let repository = MockILCalendarEventRepository()
        let sut = makeEventsSUT(repository)
        let midYear = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 9, day: 27)))

        _ = try await sut.loadBuddhistEventMonths(around: midYear)

        XCTAssertEqual(repository.requestedYears, [2026], "Whole calendar year, 1/1 → 31/12, in one call")
    }

    func test_loadBuddhistEventMonths_returnsEmpty_whenServerHasNoOccurrences() async throws {
        let sut = makeEventsSUT(MockILCalendarEventRepository())

        let months = try await sut.loadBuddhistEventMonths(around: Date())

        XCTAssertTrue(months.isEmpty)
    }

    func test_loadBuddhistEventMonths_groupsByMonthInChronologicalOrder_withLunarLabelAndTone() async throws {
        let repository = MockILCalendarEventRepository()
        repository.result = .success(ILCalendarEventsEntity(
            year: 2026,
            groups: [],
            events: [
                event("phat-dan", name: "Phật Đản"),
                event("ram", name: "Rằm", groups: ["buddhist", "folk"]),
                event("tet-duong-lich", name: "Tết Dương lịch", groups: ["vietnam"])
            ],
            occurrences: [
                occurrence("tet-duong-lich", 2026, 1, 1, lunarDay: 13, lunarMonth: 11),
                occurrence("ram", 2026, 5, 1, lunarDay: 15, lunarMonth: 3),
                occurrence("phat-dan", 2026, 5, 31, lunarDay: 15, lunarMonth: 4)
            ]
        ))
        let sut = makeEventsSUT(repository)
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 10)))

        let months = try await sut.loadBuddhistEventMonths(around: date)

        XCTAssertEqual(months.map(\.id), ["2026-05"], "BR-CAL-15: Buddhist group only")
        XCTAssertEqual(months[0].events.map(\.title), ["Rằm", "Phật Đản"])
        XCTAssertEqual(months[0].events.map(\.tone), [.gold, .gold])
        XCTAssertEqual(months[0].events.first?.lunarLabel, "lunarCalendar.day.fullMoon".localized + " · " + ILLunarCalendar.lunarMonthLabel(3, isLeap: false))
        XCTAssertEqual(Set(months[0].events.map(\.id)).count, 2, "Occurrences of the same event must keep distinct ids")
    }

    func test_loadBuddhistEventMonths_ordersMajorFirst_thenNamed_thenMonthly() async throws {
        func make(_ code: String, major: Bool, recurrence: ILCalendarRecurrence) -> ILCalendarEventEntity {
            ILCalendarEventEntity(
                code: code, name: code, shortDescription: "", longDescription: "", guidance: "",
                imageURL: nil, groupCodes: ["buddhist"], isPublicHoliday: false,
                isMajor: major, sortOrder: 0, recurrence: recurrence
            )
        }
        let repository = MockILCalendarEventRepository()
        repository.result = .success(ILCalendarEventsEntity(
            year: 2026, groups: [],
            events: [
                make("mung-1", major: false, recurrence: .lunarMonthly),
                make("van-thu", major: false, recurrence: .lunar),
                make("phat-dan", major: true, recurrence: .lunar)
            ],
            occurrences: [
                occurrence("mung-1", 2026, 5, 1, lunarDay: 15, lunarMonth: 3),
                occurrence("van-thu", 2026, 5, 10, lunarDay: 24, lunarMonth: 3),
                occurrence("phat-dan", 2026, 5, 31, lunarDay: 15, lunarMonth: 4)
            ]
        ))
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 10)))

        let months = try await makeEventsSUT(repository).loadBuddhistEventMonths(around: date)

        XCTAssertEqual(months[0].events.map(\.title), ["phat-dan", "van-thu", "mung-1"])
    }

    func test_loadBuddhistEventMonths_propagatesRepositoryFailure() async {
        let repository = MockILCalendarEventRepository()
        repository.result = .failure(ILCatalogError.offline)
        let sut = makeEventsSUT(repository)

        do {
            _ = try await sut.loadBuddhistEventMonths(around: Date())
            XCTFail("Expected the offline error to propagate")
        } catch {
            guard case .offline? = error as? ILCatalogError else { return XCTFail("Expected .offline, got \(error)") }
        }
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

    func test_getInitialState_leavesServerCarouselsEmpty() {
        let entity = makeSUT(sutraQuoteUseCase: MockILSutraQuoteUseCase()).getInitialState()

        XCTAssertTrue(entity.temples.isEmpty, "Temples are loaded asynchronously from the server")
        XCTAssertTrue(entity.deities.isEmpty, "Deities are loaded asynchronously from the server")
    }

    // MARK: - Server catalogs

    private func templeSummary(id: String, rank: ILTempleHeritageRank = .worldHeritage) -> ILTempleSummaryEntity {
        ILTempleSummaryEntity(
            id: id,
            name: "Chùa Bích Động",
            type: .chua,
            region: .north,
            thumbnailURL: nil,
            imageURL: nil,
            sect: "BẮC_TÔNG",
            heritageRank: rank,
            establishedYear: 1428,
            location: ILTempleLocationEntity(latitude: 20.2, longitude: 105.9, address: "Xã Ninh Hải, Tỉnh Ninh Bình")
        )
    }

    private func deitySummary(id: String, kind: ILDeityKind) -> ILDeitySummaryEntity {
        ILDeitySummaryEntity(
            id: id,
            kind: kind,
            nameVi: "name-\(id)",
            nameSanskrit: "",
            nameChinese: "",
            titleHonorific: "honorific-\(id)",
            thumbnailURL: "",
            imageURL: "",
            coreVirtue: "virtue-\(id)",
            pureLand: ""
        )
    }

    func test_loadTopTemples_mapsServerSummariesInOrder() async throws {
        let templeRepository = MockILTempleRepository()
        templeRepository.topResult = .success([templeSummary(id: "t1"), templeSummary(id: "t2", rank: .unranked)])
        let sut = makeSUT(sutraQuoteUseCase: MockILSutraQuoteUseCase(), templeRepository: templeRepository)

        let temples = try await sut.loadTopTemples()

        XCTAssertEqual(temples.map(\.id), ["t1", "t2"])
        XCTAssertEqual(temples.first?.name, "Chùa Bích Động")
        XCTAssertEqual(temples.first?.address, "Xã Ninh Hải, Tỉnh Ninh Bình")
        XCTAssertEqual(temples.first?.region, .north)
        XCTAssertEqual(temples.first?.heritageRank, .worldHeritage)
        XCTAssertEqual(temples.first?.establishedYear, 1428)
        XCTAssertEqual(temples.last?.heritageRank, .unranked)
    }

    func test_loadTopTemples_propagatesRepositoryError() async {
        let templeRepository = MockILTempleRepository()
        templeRepository.topResult = .failure(ILCatalogError.offline)
        let sut = makeSUT(sutraQuoteUseCase: MockILSutraQuoteUseCase(), templeRepository: templeRepository)

        do {
            _ = try await sut.loadTopTemples()
            XCTFail("Expected ILCatalogError.offline")
        } catch ILCatalogError.offline {
            // expected
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func test_loadTopDeities_mapsServerSummariesInOrder_withoutMemorialDay() async throws {
        let deityRepository = MockILDeityCatalogRepository()
        deityRepository.topResult = .success([
            deitySummary(id: "buddha_amitabha", kind: .buddha),
            deitySummary(id: "buddha_shakyamuni", kind: .buddha),
            deitySummary(id: "bodhisattva_manjushri", kind: .bodhisattva)
        ])
        let sut = makeSUT(sutraQuoteUseCase: MockILSutraQuoteUseCase(), deityCatalogRepository: deityRepository)

        let deities = try await sut.loadTopDeities()

        XCTAssertEqual(deities.map(\.id), ["buddha_amitabha", "buddha_shakyamuni", "bodhisattva_manjushri"])
        XCTAssertEqual(deities.first?.name, "name-buddha_amitabha")
        XCTAssertEqual(deities.first?.honorific, "honorific-buddha_amitabha")
        XCTAssertEqual(deities.first?.virtue, "virtue-buddha_amitabha")
        XCTAssertEqual(deities.last?.kind, .bodhisattva)
        XCTAssertTrue(deities.allSatisfy { $0.memorialDay == nil }, "Server summary has no memorial days — no bundled join")
    }

    func test_loadTopDeities_propagatesRepositoryError_withoutBundledFallback() async {
        let deityRepository = MockILDeityCatalogRepository()
        deityRepository.topResult = .failure(ILCatalogError.offline)
        let sut = makeSUT(sutraQuoteUseCase: MockILSutraQuoteUseCase(), deityCatalogRepository: deityRepository)

        do {
            _ = try await sut.loadTopDeities()
            XCTFail("Expected ILCatalogError.offline")
        } catch ILCatalogError.offline {
            // expected
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func test_loadTopArticles_mapsServerSummariesInOrder() async throws {
        let articleRepository = MockILArticleRepository()
        articleRepository.topResult = .success([
            ILArticleTestFixtures.summary(id: "a1", readMinutes: 6),
            ILArticleTestFixtures.summary(id: "a2", readMinutes: 4)
        ])
        let sut = makeSUT(sutraQuoteUseCase: MockILSutraQuoteUseCase(), articleRepository: articleRepository)

        let articles = try await sut.loadTopArticles()

        XCTAssertEqual(articles.map(\.id), ["a1", "a2"])
        XCTAssertEqual(articles.first?.title, "title-a1")
        XCTAssertEqual(articles.first?.category, "category-a1")
        XCTAssertEqual(articles.first?.author, "author-a1")
        XCTAssertEqual(articles.first?.readMinutes, 6)
    }

    func test_getInitialState_startsWithNoPhotos() {
        XCTAssertTrue(makeSUT(sutraQuoteUseCase: MockILSutraQuoteUseCase()).getInitialState().photos.isEmpty,
                      "Photos are loaded asynchronously from the server")
    }

    func test_loadTopPhotos_mapsServerPhotosInOrderWithThumbnails() async throws {
        let photosRepository = MockILPhotosRepository()
        photosRepository.topResult = .success([
            ILPhotosPhotoEntity(id: "g1", category: .temple, title: "A", place: "P", thumbnailURL: "http://h/t1.jpg", imageURL: "http://h/f1.jpg"),
            ILPhotosPhotoEntity(id: "g2", category: .festival, title: "B", place: "P", thumbnailURL: nil, imageURL: nil)
        ])
        let sut = makeSUT(sutraQuoteUseCase: MockILSutraQuoteUseCase(), photosRepository: photosRepository)

        let photos = try await sut.loadTopPhotos()

        XCTAssertEqual(photos, [
            ILHomePhotoEntity(id: "g1", thumbnailURL: "http://h/t1.jpg"),
            ILHomePhotoEntity(id: "g2", thumbnailURL: nil)
        ])
    }

    func test_loadTopPhotos_propagatesRepositoryError() async {
        let photosRepository = MockILPhotosRepository()
        photosRepository.topResult = .failure(ILCatalogError.offline)
        let sut = makeSUT(sutraQuoteUseCase: MockILSutraQuoteUseCase(), photosRepository: photosRepository)

        do {
            _ = try await sut.loadTopPhotos()
            XCTFail("Expected offline")
        } catch ILCatalogError.offline {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_loadTopArticles_propagatesRepositoryError() async {
        let articleRepository = MockILArticleRepository()
        articleRepository.topResult = .failure(ILCatalogError.offline)
        let sut = makeSUT(sutraQuoteUseCase: MockILSutraQuoteUseCase(), articleRepository: articleRepository)

        do {
            _ = try await sut.loadTopArticles()
            XCTFail("Expected ILCatalogError.offline")
        } catch ILCatalogError.offline {
            // expected
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func test_getInitialState_startsWithNoArticles() {
        let entity = makeSUT(sutraQuoteUseCase: MockILSutraQuoteUseCase()).getInitialState()

        XCTAssertTrue(entity.articles.isEmpty, "Articles are loaded asynchronously from the server")
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

    private func makeSUT(
        sutraQuoteUseCase: ILSutraQuoteUseCase,
        templeRepository: ILTempleRepository = MockILTempleRepository(),
        deityCatalogRepository: ILDeityCatalogRepository = MockILDeityCatalogRepository(),
        articleRepository: ILArticleRepository = MockILArticleRepository(),
        photosRepository: ILPhotosRepository = MockILPhotosRepository()
    ) -> ILHomeUseCaseImpl {
        ILHomeUseCaseImpl(
            calendarEventRepository: MockILCalendarEventRepository(),
            sutraQuoteUseCase: sutraQuoteUseCase,
            templeRepository: templeRepository,
            deityCatalogRepository: deityCatalogRepository,
            articleRepository: articleRepository,
            photosRepository: photosRepository
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

/// Stands in for the server event calendar; records the requested years.
private final class MockILCalendarEventRepository: ILCalendarEventRepository {

    var result: Result<ILCalendarEventsEntity, Error> = .success(
        ILCalendarEventsEntity(year: 0, groups: [], events: [], occurrences: [])
    )
    private(set) var requestedYears: [Int] = []

    func loadEvents(year: Int) async throws -> ILCalendarEventsEntity {
        requestedYears.append(year)
        return try result.get()
    }
}

/// Stands in for the server-backed temple catalog.
private final class MockILTempleRepository: ILTempleRepository {

    var topResult: Result<[ILTempleSummaryEntity], Error> = .success([])

    func loadTopTemples() async throws -> [ILTempleSummaryEntity] {
        try topResult.get()
    }

    func loadTemples(page: Int) async throws -> ILCatalogPageEntity<ILTempleSummaryEntity> {
        ILCatalogPageEntity(items: [], page: page, hasMore: false)
    }

    func loadTempleDetail(id: String) async throws -> ILTempleDetailEntity {
        throw ILCatalogError.notFound
    }
}

/// Stands in for the server-backed Buddha / Bodhisattva catalog.
private final class MockILDeityCatalogRepository: ILDeityCatalogRepository {

    var topResult: Result<[ILDeitySummaryEntity], Error> = .success([])

    func loadTopDeities() async throws -> [ILDeitySummaryEntity] {
        try topResult.get()
    }

    func loadDeities(page: Int) async throws -> ILCatalogPageEntity<ILDeitySummaryEntity> {
        ILCatalogPageEntity(items: [], page: page, hasMore: false)
    }

    func loadDeityDetail(id: String) async throws -> ILDeityEntity {
        throw ILCatalogError.notFound
    }
}
