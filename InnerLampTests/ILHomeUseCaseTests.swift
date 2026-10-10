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
            category: .folk,
            isLeapMonthEligible: false
        )
    }

    // MARK: - Buddhist event months range

    func test_loadBuddhistEventMonths_spansFullCalendarYear() async throws {
        let mock = MockILBuddhistEventUseCase()
        mock.templates = [template]
        let sut = ILHomeUseCaseImpl(buddhistEventUseCase: mock, sutraQuoteUseCase: MockILSutraQuoteUseCase(), templeRepository: MockILTempleRepository(), deityCatalogRepository: MockILDeityCatalogRepository(), articleRepository: MockILArticleRepository(), photosRepository: MockILPhotosRepository())

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
        let sut = ILHomeUseCaseImpl(buddhistEventUseCase: mock, sutraQuoteUseCase: MockILSutraQuoteUseCase(), templeRepository: MockILTempleRepository(), deityCatalogRepository: MockILDeityCatalogRepository(), articleRepository: MockILArticleRepository(), photosRepository: MockILPhotosRepository())

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
            buddhistEventUseCase: MockILBuddhistEventUseCase(),
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
