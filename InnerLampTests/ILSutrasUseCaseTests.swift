//
//  ILSutrasUseCaseTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

final class ILSutrasUseCaseTests: XCTestCase {

    private var repository: MockILSutraRepository!
    private var sut: ILSutrasUseCaseImpl!

    override func setUp() {
        super.setUp()
        repository = MockILSutraRepository()
        sut = ILSutrasUseCaseImpl(sutraRepository: repository)
    }

    override func tearDown() {
        sut = nil
        repository = nil
        super.tearDown()
    }

    func test_loadFirstPage_requestsPageOneWithFilter() async throws {
        let filter = ILSutraFilter(category: .dailyChant, length: .upTo5)

        let entity = try await sut.loadFirstPage(filter: filter)

        XCTAssertEqual(repository.listCalls.map(\.page), [1])
        XCTAssertEqual(repository.listCalls.first?.filter, filter)
        XCTAssertEqual(entity.sutras.map(\.id), ["s0", "s1"])
        XCTAssertEqual(entity.totalCount, 4)
        XCTAssertEqual(entity.lastLoadedPage, 1)
        XCTAssertTrue(entity.hasMore)
    }

    func test_loadNextPage_appendsAndAdvancesPage() async throws {
        let first = try await sut.loadFirstPage(filter: ILSutraFilter())

        let merged = try await sut.loadNextPage(after: first, filter: ILSutraFilter())

        XCTAssertEqual(repository.listCalls.map(\.page), [1, 2])
        XCTAssertEqual(merged.sutras.map(\.id), ["s0", "s1", "s2", "s3"])
        XCTAssertEqual(merged.lastLoadedPage, 2)
        XCTAssertFalse(merged.hasMore)
    }

    func test_loadNextPage_whenNoMore_returnsEntityWithoutRequest() async throws {
        let done = ILSutrasEntity(sutras: [ILSutraFixtures.sutra(id: "x")], totalCount: 1, lastLoadedPage: 1, hasMore: false)

        let result = try await sut.loadNextPage(after: done, filter: ILSutraFilter())

        XCTAssertEqual(result, done)
        XCTAssertEqual(repository.listCalls.count, 0)
    }

    func test_loadNextPage_skipsRowsAlreadyLoaded() async throws {
        repository.onLoadSutras = { page, _ in
            ILSutraPageEntity(
                items: [ILSutraFixtures.sutra(id: "s1"), ILSutraFixtures.sutra(id: "s9")],
                page: page, totalCount: 10, hasMore: true
            )
        }
        let first = ILSutrasEntity(
            sutras: [ILSutraFixtures.sutra(id: "s0"), ILSutraFixtures.sutra(id: "s1")],
            totalCount: 10, lastLoadedPage: 1, hasMore: true
        )

        let merged = try await sut.loadNextPage(after: first, filter: ILSutraFilter())

        XCTAssertEqual(merged.sutras.map(\.id), ["s0", "s1", "s9"])
    }
}
