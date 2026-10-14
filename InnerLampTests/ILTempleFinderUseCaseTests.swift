//
//  ILTempleFinderUseCaseTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

final class ILTempleFinderUseCaseTests: XCTestCase {

    private var repository: MockTemplePagesRepository!
    private var sanghaUseCase: MockILSanghaUseCase!
    private var sut: ILTempleFinderUseCaseImpl!

    override func setUp() {
        super.setUp()
        repository = MockTemplePagesRepository()
        sanghaUseCase = MockILSanghaUseCase()
        sut = ILTempleFinderUseCaseImpl(templeRepository: repository, sanghaUseCase: sanghaUseCase)
    }

    override func tearDown() {
        sut = nil
        sanghaUseCase = nil
        repository = nil
        super.tearDown()
    }

    func test_loadTemples_readsEveryPageUntilHasMoreIsFalse() async throws {
        repository.pages = [
            [Self.makeTemple(id: "a"), Self.makeTemple(id: "b")],
            [Self.makeTemple(id: "c")]
        ]

        let temples = try await sut.loadTemples()

        XCTAssertEqual(temples.map(\.id), ["a", "b", "c"])
        XCTAssertEqual(repository.requestedPages, [1, 2])
    }

    func test_loadTemples_dropsRowsRepeatedAcrossPageBoundaries() async throws {
        repository.pages = [
            [Self.makeTemple(id: "a"), Self.makeTemple(id: "b")],
            [Self.makeTemple(id: "b"), Self.makeTemple(id: "c")]
        ]

        let temples = try await sut.loadTemples()

        XCTAssertEqual(temples.map(\.id), ["a", "b", "c"])
    }

    func test_loadTemples_propagatesRepositoryError() async {
        repository.error = ILCatalogError.offline

        do {
            _ = try await sut.loadTemples()
            XCTFail("expected an error")
        } catch ILCatalogError.offline {
            // expected
        } catch {
            XCTFail("expected ILCatalogError.offline, got \(error)")
        }
    }

    func test_loadMyTemple_returnsIDAndNameOfTheChosenTemple() async {
        sanghaUseCase.myTempleID = "temple_1"

        let mine = await sut.loadMyTemple()

        XCTAssertEqual(mine?.id, "temple_1")
        XCTAssertEqual(mine?.name, "Chùa Từ Quang")
    }

    func test_loadMyTemple_withoutChosenTemple_returnsNil() async {
        let mine = await sut.loadMyTemple()
        XCTAssertNil(mine)
    }

    func test_selectMyTemple_forwardsToTheSanghaUseCase() {
        sut.selectMyTemple(Self.makeTemple(id: "picked"))

        XCTAssertEqual(sanghaUseCase.myTempleID, "picked")
    }

    // MARK: - Fixtures
    static func makeTemple(
        id: String,
        name: String = "Chùa Mẫu",
        address: String = "Quận 1, TP. Hồ Chí Minh",
        region: ILTempleRegion = .south,
        imageURL: String? = nil
    ) -> ILTempleSummaryEntity {
        ILTempleSummaryEntity(
            id: id, name: name, type: .chua, region: region, thumbnailURL: nil, imageURL: imageURL,
            sect: "BẮC_TÔNG", heritageRank: .unranked, establishedYear: 1900,
            location: ILTempleLocationEntity(latitude: 10.78, longitude: 106.70, address: address)
        )
    }
}

/// Serves `pages` one by one (1-based); `hasMore` is true until the last page.
final class MockTemplePagesRepository: ILTempleRepository {

    var pages: [[ILTempleSummaryEntity]] = []
    var error: Error?
    private(set) var requestedPages: [Int] = []

    func loadTopTemples() async throws -> [ILTempleSummaryEntity] { [] }

    func loadTemples(page: Int) async throws -> ILCatalogPageEntity<ILTempleSummaryEntity> {
        requestedPages.append(page)
        if let error { throw error }
        let items = page <= pages.count ? pages[page - 1] : []
        return ILCatalogPageEntity(items: items, page: page, hasMore: page < pages.count)
    }

    func loadTempleDetail(id: String) async throws -> ILTempleDetailEntity {
        throw ILCatalogError.notFound
    }
}
