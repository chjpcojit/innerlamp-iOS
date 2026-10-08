//
//  ILArticleRepositoryTests.swift
//  InnerLampTests
//
//  Covers `ILArticleRepositoryImpl` below the Domain boundary: endpoint construction, DTO decoding
//  of the real wire shapes (snake_case envelope), mapping, and `NetworkError` → `ILCatalogError`.
//

import XCTest
@testable import InnerLamp

@MainActor
final class ILArticleRepositoryTests: XCTestCase {

    private var network: MockCatalogNetworkService!
    private var repository: ILArticleRepository!

    override func setUp() {
        super.setUp()
        network = MockCatalogNetworkService()
        repository = ILArticleRepositoryImpl(networkService: network)
    }

    override func tearDown() {
        repository = nil
        network = nil
        super.tearDown()
    }

    // MARK: - Fixtures

    private func summaryJSON(
        id: String,
        publishedDate: String? = "2026-09-18",
        imageURL: String? = nil
    ) -> String {
        let date = publishedDate.map { "\"\($0)\"" } ?? "null"
        let image = imageURL.map { "\"\($0)\"" } ?? "null"
        return #"""
        {"id":"\#(id)","title":"Tiêu đề \#(id)","category":"Thực hành","author":"Thầy Minh Đạo","author_initials":"MĐ","published_date":\#(date),"read_minutes":7,"summary":"Tóm tắt","tags":["thiền","chánh niệm"],"image_url":\#(image)}
        """#
    }

    private func detailJSON(id: String, sourceURL: String = "https://giacngo.vn/bai-goc") -> String {
        #"""
        {"id":"\#(id)","title":"Tiêu đề \#(id)","category":"Thực hành","author":"Thầy Minh Đạo","author_initials":"MĐ","published_date":null,"read_minutes":7,"summary":"Tóm tắt","tags":[],"image_url":null,"body_paragraphs":["Đoạn 1","Đoạn 2"],"quote":"Câu trích","quote_source":"Kinh Pháp Cú","language":"vi","source_name":"Báo Giác Ngộ","source_url":"\#(sourceURL)","license":"CC"}
        """#
    }

    private func pageJSON(page: Int, ids: [String], total: Int, totalPages: Int) -> String {
        ILCatalogFixtures.envelope(
            #"{"items":[\#(ids.map { summaryJSON(id: $0) }.joined(separator: ","))],"page":\#(page),"page_size":10,"total":\#(total),"total_pages":\#(totalPages)}"#
        )
    }

    // MARK: - Top

    func test_loadTopArticles_callsTopEndpointAndMapsInOrder() async throws {
        network.responses["/v1/articles/top"] = .success(
            ILCatalogFixtures.envelope(#"{"items":[\#(summaryJSON(id: "a1")),\#(summaryJSON(id: "a2", publishedDate: nil))]}"#)
        )

        let articles = try await repository.loadTopArticles()

        XCTAssertEqual(network.requestedRoutes, ["/v1/articles/top"])
        XCTAssertEqual(articles.map(\.id), ["a1", "a2"])
        XCTAssertEqual(articles.first?.title, "Tiêu đề a1")
        XCTAssertEqual(articles.first?.authorInitials, "MĐ")
        XCTAssertEqual(articles.first?.readMinutes, 7)
        XCTAssertNotNil(articles.first?.publishedDate)
        XCTAssertNil(articles.last?.publishedDate, "A null published_date maps to nil")
        XCTAssertNil(articles.first?.imageURL)
    }

    func test_loadTopArticles_offline_mapsToOffline() async {
        // No canned response → the mock throws `.noInternetConnection`.
        await assertThrows(ILCatalogError.offline) { _ = try await self.repository.loadTopArticles() }
    }

    func test_loadTopArticles_serverError_mapsToLoadFailed() async {
        network.responses["/v1/articles/top"] = .failure(ILCatalogFixtures.apiError("INTERNAL_ERROR"))

        do {
            _ = try await repository.loadTopArticles()
            XCTFail("Expected ILCatalogError.loadFailed")
        } catch ILCatalogError.loadFailed {
            // expected
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    // MARK: - Paged list

    func test_loadArticles_page1_mapsRowsTotalAndHasMore() async throws {
        network.responses["/v1/articles?page=1"] = .success(pageJSON(page: 1, ids: ["a1", "a2"], total: 30, totalPages: 3))

        let page = try await repository.loadArticles(page: 1)

        XCTAssertEqual(network.requestedRoutes, ["/v1/articles?page=1"])
        XCTAssertEqual(page.items.map(\.id), ["a1", "a2"])
        XCTAssertEqual(page.page, 1)
        XCTAssertEqual(page.totalCount, 30)
        XCTAssertTrue(page.hasMore)
    }

    func test_loadArticles_lastPage_hasMoreIsFalse() async throws {
        network.responses["/v1/articles?page=3"] = .success(pageJSON(page: 3, ids: ["a1"], total: 21, totalPages: 3))

        let page = try await repository.loadArticles(page: 3)

        XCTAssertFalse(page.hasMore, "page >= total_pages ends the list")
    }

    func test_loadArticles_emptyPagePastTheEnd_hasMoreIsFalse() async throws {
        network.responses["/v1/articles?page=9"] = .success(pageJSON(page: 9, ids: [], total: 30, totalPages: 3))

        let page = try await repository.loadArticles(page: 9)

        XCTAssertTrue(page.items.isEmpty)
        XCTAssertFalse(page.hasMore)
    }

    func test_loadArticles_pageBelowOne_throwsInvalidPageWithoutNetwork() async {
        await assertThrows(ILCatalogError.invalidPage) { _ = try await self.repository.loadArticles(page: 0) }
        XCTAssertTrue(network.requestedRoutes.isEmpty)
    }

    func test_loadArticles_serverInvalidPage_mapsToInvalidPage() async {
        network.responses["/v1/articles?page=1"] = .failure(ILCatalogFixtures.apiError("INVALID_PAGE"))

        await assertThrows(ILCatalogError.invalidPage) { _ = try await self.repository.loadArticles(page: 1) }
    }

    // MARK: - Detail

    func test_loadArticle_mapsDetailFields() async throws {
        network.responses["/v1/articles/vipassana-nghe-thuat-song"] = .success(
            ILCatalogFixtures.envelope(detailJSON(id: "vipassana-nghe-thuat-song"))
        )

        let article = try await repository.loadArticle(id: "vipassana-nghe-thuat-song")

        XCTAssertEqual(network.requestedRoutes, ["/v1/articles/vipassana-nghe-thuat-song"])
        XCTAssertEqual(article.id, "vipassana-nghe-thuat-song")
        XCTAssertEqual(article.bodyParagraphs, ["Đoạn 1", "Đoạn 2"])
        XCTAssertEqual(article.quote, "Câu trích")
        XCTAssertEqual(article.quoteSource, "Kinh Pháp Cú")
        XCTAssertEqual(article.sourceName, "Báo Giác Ngộ")
        XCTAssertEqual(article.sourceURL, "https://giacngo.vn/bai-goc")
        XCTAssertNil(article.publishedDate)
        XCTAssertNil(article.imageURL)
    }

    func test_loadArticle_nonHTTPSourceURL_isDropped() async throws {
        network.responses["/v1/articles/a1"] = .success(
            ILCatalogFixtures.envelope(detailJSON(id: "a1", sourceURL: "javascript:alert(1)"))
        )

        let article = try await repository.loadArticle(id: "a1")

        XCTAssertNil(article.sourceURL, "Only absolute http(s) links may be opened")
    }

    func test_loadArticle_notFound_mapsToNotFound() async {
        network.responses["/v1/articles/missing"] = .failure(ILCatalogFixtures.apiError("ARTICLE_NOT_FOUND"))

        await assertThrows(ILCatalogError.notFound) { _ = try await self.repository.loadArticle(id: "missing") }
    }

    // MARK: - Mapper

    func test_mapper_date_parsesDateOnlyInGMT() throws {
        let date = try XCTUnwrap(ILArticleMapper.date(from: "2026-09-18"))

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        XCTAssertEqual([components.year, components.month, components.day], [2026, 9, 18])
    }

    func test_mapper_date_malformedOrEmpty_isNil() {
        XCTAssertNil(ILArticleMapper.date(from: "18/09/2026"))
        XCTAssertNil(ILArticleMapper.date(from: ""))
        XCTAssertNil(ILArticleMapper.date(from: nil))
    }

    // MARK: - Helpers

    private func assertThrows(
        _ expected: ILCatalogError,
        _ operation: () async throws -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            try await operation()
            XCTFail("Expected \(expected)", file: file, line: line)
        } catch let error as ILCatalogError {
            XCTAssertEqual(String(describing: error), String(describing: expected), file: file, line: line)
        } catch {
            XCTFail("Unexpected error \(error)", file: file, line: line)
        }
    }
}
