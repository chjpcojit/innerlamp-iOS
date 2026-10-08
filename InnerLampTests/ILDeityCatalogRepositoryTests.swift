//
//  ILDeityCatalogRepositoryTests.swift
//  InnerLampTests
//
//  Covers `ILDeityCatalogRepositoryImpl`: the same caching policy as the temple catalog (see
//  `ILTempleRepositoryTests` for the exhaustive paging cases), plus the deity-specific parts —
//  the summary DTO, reuse of `ILDeityDTO` for the detail, and the detail payload round-trip.
//

import XCTest
@testable import InnerLamp

@MainActor
final class ILDeityCatalogRepositoryTests: XCTestCase {

    private var stack: CoreDataStack!
    private var network: MockCatalogNetworkService!
    private var repository: ILDeityCatalogRepository!

    override func setUp() {
        super.setUp()
        stack = CoreDataStack(inMemory: true)
        XCTAssertTrue(stack.isLoaded, "The in-memory store failed to load")
        network = MockCatalogNetworkService()
        repository = ILDeityCatalogRepositoryImpl(
            networkService: network,
            localDataSource: ILDeityCatalogLocalDataSourceImpl(stack: stack)
        )
    }

    override func tearDown() {
        repository = nil
        network = nil
        stack = nil
        super.tearDown()
    }

    // MARK: - Deities page (Buddhas + Bodhisattvas)

    func test_loadDeitiesPage_singlePartialPage_cachedThenServedLocally() async throws {
        let ids = (0..<6).map { "buddha_\($0)" } + (0..<12).map { "bodhisattva_\($0)" }
        network.responses["/v1/deities?page=1"] = .success(
            ILCatalogFixtures.deitiesPage(1, ids: ids, total: 18)
        )

        let fromServer = try await repository.loadDeities(page: 1)
        XCTAssertEqual(fromServer.items.map(\.id), ids)
        XCTAssertEqual(fromServer.items.first?.kind, .buddha)
        XCTAssertEqual(fromServer.items.last?.kind, .bodhisattva)
        XCTAssertFalse(fromServer.hasMore, "total_pages == 1")

        network.responses = [:]
        let fromCache = try await repository.loadDeities(page: 1)
        XCTAssertEqual(fromCache.items, fromServer.items)
        XCTAssertEqual(network.requestedRoutes, ["/v1/deities?page=1"])
    }

    func test_loadDeitiesPage_pastLocalEnd_emptyServerPageStops() async throws {
        network.responses["/v1/deities?page=1"] = .success(
            ILCatalogFixtures.deitiesPage(1, ids: ["a", "b"], total: 2)
        )
        network.responses["/v1/deities?page=2"] = .success(
            ILCatalogFixtures.deitiesPage(2, ids: [], total: 2)
        )
        _ = try await repository.loadDeities(page: 1)

        let page2 = try await repository.loadDeities(page: 2)

        XCTAssertTrue(page2.items.isEmpty)
        XCTAssertFalse(page2.hasMore)
    }

    func test_loadDeitiesPage_mapsSummaryFields() async throws {
        network.responses["/v1/deities?page=1"] = .success(
            ILCatalogFixtures.deitiesPage(1, ids: ["bodhisattva_avalokiteshvara"], total: 1)
        )

        let page = try await repository.loadDeities(page: 1)
        let item = try XCTUnwrap(page.items.first)

        XCTAssertEqual(item.nameVi, "Vị bodhisattva_avalokiteshvara")
        XCTAssertEqual(item.thumbnailURL, "assets/images/buddhas/thumbnails/bodhisattva_avalokiteshvara.webp")
        XCTAssertEqual(item.coreVirtue, "V")
        XCTAssertEqual(item.pureLand, "P")
    }

    // MARK: - Top

    func test_loadTopDeities_offline_fallsBackToCache() async throws {
        network.responses["/v1/deities/top"] = .success(ILCatalogFixtures.topDeities(ids: ["buddha_a", "buddha_b"]))
        _ = try await repository.loadTopDeities()

        network.responses = [:]
        let top = try await repository.loadTopDeities()

        XCTAssertEqual(top.map(\.id), ["buddha_a", "buddha_b"])
        XCTAssertEqual(top.first?.kind, .buddha)
    }

    // MARK: - Detail

    func test_loadDeityDetail_mapsRealServerPayload() async throws {
        network.responses["/v1/deities/buddha_amitabha"] = .success(ILCatalogFixtures.deityDetail)

        let deity = try await repository.loadDeityDetail(id: "buddha_amitabha")

        XCTAssertEqual(deity.kind, .buddha)
        XCTAssertEqual(deity.nameVi, "A Di Đà Phật")
        XCTAssertEqual(deity.memorialDays, [
            ILDeityMemorialDayEntity(lunarDay: 17, lunarMonth: 11, eventName: "Ngày Vía Đức Phật A Di Đà")
        ])
        XCTAssertEqual(deity.iconography.sacredArtifacts.count, 2)
        XCTAssertEqual(deity.greatVows.count, 2)
        XCTAssertEqual(deity.mantra.dharaniName, "Chú Vãng Sanh")
    }

    func test_loadDeityDetail_offline_cachedPayloadRoundTripsLosslessly() async throws {
        network.responses["/v1/deities/buddha_amitabha"] = .success(ILCatalogFixtures.deityDetail)
        let online = try await repository.loadDeityDetail(id: "buddha_amitabha")

        network.responses = [:]
        let offline = try await repository.loadDeityDetail(id: "buddha_amitabha")

        XCTAssertEqual(offline, online)
    }

    func test_loadDeityDetail_notFound_mapsToNotFound() async {
        network.responses["/v1/deities/nope"] = .failure(ILCatalogFixtures.apiError("DEITY_NOT_FOUND"))

        do {
            _ = try await repository.loadDeityDetail(id: "nope")
            XCTFail("Expected notFound")
        } catch let error as ILCatalogError {
            guard case .notFound = error else { return XCTFail("Unexpected \(error)") }
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func test_endpoints_matchContract() {
        XCTAssertEqual(TopDeitiesEndpoint().path, "/v1/deities/top")
        XCTAssertEqual(DeitiesPageEndpoint(page: 2).path, "/v1/deities")
        XCTAssertEqual(DeitiesPageEndpoint(page: 2).queryParameters, ["page": "2"])
        XCTAssertEqual(DeityDetailEndpoint(id: "buddha_amitabha").path, "/v1/deities/buddha_amitabha")
        XCTAssertFalse(DeityDetailEndpoint(id: "x").requiresAuth)
    }
}
