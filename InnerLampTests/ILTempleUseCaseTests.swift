//
//  ILTempleUseCaseTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

final class ILTempleUseCaseTests: XCTestCase {

    private var repository: MockTempleDetailRepository!
    private var sut: ILTempleUseCaseImpl!

    override func setUp() {
        super.setUp()
        repository = MockTempleDetailRepository()
        sut = ILTempleUseCaseImpl(templeRepository: repository)
    }

    override func tearDown() {
        sut = nil
        repository = nil
        super.tearDown()
    }

    func test_loadTemple_returnsRepositoryDetailForID() async throws {
        let detail = ILTempleViewModelTests.makeDetail()
        repository.detailResult = .success(detail)

        let result = try await sut.loadTemple(id: "temple_fixture")

        XCTAssertEqual(result, detail)
        XCTAssertEqual(repository.requestedIDs, ["temple_fixture"])
    }

    func test_loadTemple_propagatesRepositoryError() async {
        repository.detailResult = .failure(ILCatalogError.notFound)

        do {
            _ = try await sut.loadTemple(id: "missing")
            XCTFail("expected an error")
        } catch ILCatalogError.notFound {
            // expected
        } catch {
            XCTFail("expected ILCatalogError.notFound, got \(error)")
        }
    }
}

private final class MockTempleDetailRepository: ILTempleRepository {

    var detailResult: Result<ILTempleDetailEntity, Error> = .failure(ILCatalogError.notFound)
    private(set) var requestedIDs: [String] = []

    func loadTopTemples() async throws -> [ILTempleSummaryEntity] { [] }

    func loadTemples(page: Int) async throws -> ILCatalogPageEntity<ILTempleSummaryEntity> {
        ILCatalogPageEntity(items: [], page: page, hasMore: false)
    }

    func loadTempleDetail(id: String) async throws -> ILTempleDetailEntity {
        requestedIDs.append(id)
        return try detailResult.get()
    }
}
