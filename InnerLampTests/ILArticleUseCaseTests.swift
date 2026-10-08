//
//  ILArticleUseCaseTests.swift
//  InnerLampTests
//
//  Covers `ILArticleUseCaseImpl` ("Đọc tiếp" derivation, save toggle) and `ILArticlesUseCaseImpl`
//  (paging) on top of a mock `ILArticleRepository`. Also hosts the shared mock + fixtures.
//

import XCTest
@testable import InnerLamp

// MARK: - Shared fixtures

enum ILArticleTestFixtures {

    static func summary(id: String, readMinutes: Int = 5, publishedDate: Date? = nil) -> ILArticleSummaryEntity {
        ILArticleSummaryEntity(
            id: id,
            category: "category-\(id)",
            title: "title-\(id)",
            author: "author-\(id)",
            authorInitials: "I\(id)",
            readMinutes: readMinutes,
            publishedDate: publishedDate,
            imageURL: nil
        )
    }

    static func detail(
        id: String,
        publishedDate: Date? = nil,
        sourceName: String = "Báo Giác Ngộ",
        sourceURL: String? = "https://example.com/original"
    ) -> ILArticleItemEntity {
        ILArticleItemEntity(
            id: id,
            category: "category-\(id)",
            title: "title-\(id)",
            author: "author-\(id)",
            authorInitials: "I\(id)",
            publishedDate: publishedDate,
            readMinutes: 6,
            bodyParagraphs: ["\(id)-p0", "\(id)-p1"],
            quote: "\(id)-quote",
            quoteSource: "\(id)-src",
            sourceName: sourceName,
            sourceURL: sourceURL,
            imageURL: nil
        )
    }

    static func page(_ number: Int, ids: [String], total: Int, hasMore: Bool) -> ILArticlePageEntity {
        ILArticlePageEntity(items: ids.map { summary(id: $0) }, page: number, totalCount: total, hasMore: hasMore)
    }
}

// MARK: - Mock repository

/// Stands in for the server-backed article catalog.
final class MockILArticleRepository: ILArticleRepository {

    var topResult: Result<[ILArticleSummaryEntity], Error> = .success([])
    var pageResults: [Int: Result<ILArticlePageEntity, Error>] = [:]
    var detailResults: [String: Result<ILArticleItemEntity, Error>] = [:]

    private(set) var requestedPages: [Int] = []
    private(set) var requestedDetailIDs: [String] = []
    private(set) var topCallCount = 0

    func loadTopArticles() async throws -> [ILArticleSummaryEntity] {
        topCallCount += 1
        return try topResult.get()
    }

    func loadArticles(page: Int) async throws -> ILArticlePageEntity {
        requestedPages.append(page)
        guard let result = pageResults[page] else { throw ILCatalogError.offline }
        return try result.get()
    }

    func loadArticle(id: String) async throws -> ILArticleItemEntity {
        requestedDetailIDs.append(id)
        guard let result = detailResults[id] else { throw ILCatalogError.notFound }
        return try result.get()
    }
}

// MARK: - ILArticleUseCaseImpl

final class ILArticleUseCaseTests: XCTestCase {

    private var repository: MockILArticleRepository!
    private var sut: ILArticleUseCaseImpl!

    override func setUp() {
        super.setUp()
        repository = MockILArticleRepository()
        sut = ILArticleUseCaseImpl(articleRepository: repository)
    }

    override func tearDown() {
        sut = nil
        repository = nil
        super.tearDown()
    }

    func test_getInitialState_holdsIdWithNothingLoaded() {
        let entity = sut.getInitialState(articleID: "a1")

        XCTAssertEqual(entity.currentArticleID, "a1")
        XCTAssertNil(entity.article)
        XCTAssertTrue(entity.nextArticles.isEmpty)
        XCTAssertTrue(entity.savedArticleIDs.isEmpty)
    }

    func test_loadArticle_returnsRepositoryArticle() async throws {
        repository.detailResults["a1"] = .success(ILArticleTestFixtures.detail(id: "a1"))

        let article = try await sut.loadArticle(id: "a1")

        XCTAssertEqual(article.id, "a1")
        XCTAssertEqual(repository.requestedDetailIDs, ["a1"])
    }

    func test_loadArticle_notFound_propagates() async {
        repository.detailResults["missing"] = .failure(ILCatalogError.notFound)

        do {
            _ = try await sut.loadArticle(id: "missing")
            XCTFail("Expected ILCatalogError.notFound")
        } catch ILCatalogError.notFound {
            // expected
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func test_loadNextArticles_excludesCurrentAndKeepsTwoInServerOrder() async {
        repository.topResult = .success(["a1", "a2", "a3", "a4", "a5"].map { ILArticleTestFixtures.summary(id: $0) })

        let next = await sut.loadNextArticles(excluding: "a1")

        XCTAssertEqual(next.map(\.id), ["a2", "a3"])
    }

    func test_loadNextArticles_currentNotInTop_returnsFirstTwo() async {
        repository.topResult = .success(["a1", "a2", "a3"].map { ILArticleTestFixtures.summary(id: $0) })

        let next = await sut.loadNextArticles(excluding: "other")

        XCTAssertEqual(next.map(\.id), ["a1", "a2"])
    }

    func test_loadNextArticles_failure_returnsEmptyInsteadOfThrowing() async {
        repository.topResult = .failure(ILCatalogError.offline)

        let next = await sut.loadNextArticles(excluding: "a1")

        XCTAssertTrue(next.isEmpty)
    }

    func test_toggleSave_addsThenRemoves() {
        let entity = sut.getInitialState(articleID: "a1")

        let saved = sut.toggleSave("a1", in: entity)
        XCTAssertEqual(saved.savedArticleIDs, ["a1"])

        let unsaved = sut.toggleSave("a1", in: saved)
        XCTAssertTrue(unsaved.savedArticleIDs.isEmpty)
    }
}

// MARK: - ILArticlesUseCaseImpl

final class ILArticlesUseCaseTests: XCTestCase {

    private var repository: MockILArticleRepository!
    private var sut: ILArticlesUseCaseImpl!

    override func setUp() {
        super.setUp()
        repository = MockILArticleRepository()
        sut = ILArticlesUseCaseImpl(articleRepository: repository)
    }

    override func tearDown() {
        sut = nil
        repository = nil
        super.tearDown()
    }

    func test_loadFirstPage_requestsPage1AndMapsRows() async throws {
        repository.pageResults[1] = .success(ILArticleTestFixtures.page(1, ids: ["a1", "a2"], total: 30, hasMore: true))

        let entity = try await sut.loadFirstPage()

        XCTAssertEqual(repository.requestedPages, [1])
        XCTAssertEqual(entity.articles.map(\.id), ["a1", "a2"])
        XCTAssertEqual(entity.articles.first?.title, "title-a1")
        XCTAssertEqual(entity.loadedCount, 2)
        XCTAssertEqual(entity.totalCount, 30)
        XCTAssertEqual(entity.lastLoadedPage, 1)
        XCTAssertTrue(entity.hasMore)
    }

    func test_loadNextPage_appendsPageAfterLastLoaded() async throws {
        repository.pageResults[1] = .success(ILArticleTestFixtures.page(1, ids: ["a1", "a2"], total: 4, hasMore: true))
        repository.pageResults[2] = .success(ILArticleTestFixtures.page(2, ids: ["a3", "a4"], total: 4, hasMore: false))
        let first = try await sut.loadFirstPage()

        let merged = try await sut.loadNextPage(after: first)

        XCTAssertEqual(repository.requestedPages, [1, 2])
        XCTAssertEqual(merged.articles.map(\.id), ["a1", "a2", "a3", "a4"])
        XCTAssertEqual(merged.loadedCount, 4)
        XCTAssertEqual(merged.lastLoadedPage, 2)
        XCTAssertFalse(merged.hasMore, "The server's last page ends the list")
    }

    func test_loadNextPage_dropsRowsAlreadyLoaded() async throws {
        repository.pageResults[1] = .success(ILArticleTestFixtures.page(1, ids: ["a1", "a2"], total: 3, hasMore: true))
        repository.pageResults[2] = .success(ILArticleTestFixtures.page(2, ids: ["a2", "a3"], total: 3, hasMore: false))
        let first = try await sut.loadFirstPage()

        let merged = try await sut.loadNextPage(after: first)

        XCTAssertEqual(merged.articles.map(\.id), ["a1", "a2", "a3"])
        XCTAssertEqual(merged.loadedCount, 3)
    }

    func test_loadNextPage_whenNoMore_doesNotCallRepository() async throws {
        repository.pageResults[1] = .success(ILArticleTestFixtures.page(1, ids: ["a1"], total: 1, hasMore: false))
        let first = try await sut.loadFirstPage()

        let same = try await sut.loadNextPage(after: first)

        XCTAssertEqual(same, first)
        XCTAssertEqual(repository.requestedPages, [1])
    }

    func test_loadFirstPage_failure_propagates() async {
        repository.pageResults[1] = .failure(ILCatalogError.offline)

        do {
            _ = try await sut.loadFirstPage()
            XCTFail("Expected ILCatalogError.offline")
        } catch ILCatalogError.offline {
            // expected
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
}
