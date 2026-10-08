//
//  ILTempleRepositoryTests.swift
//  InnerLampTests
//
//  Covers `ILTempleRepositoryImpl` end to end below the Domain boundary: endpoint construction,
//  DTO decoding of real wire shapes, mapping, the Core Data cache (in-memory stack) and the
//  caching policy — local-first paging for the "show all" list, network-first with an offline
//  fallback for top / detail — plus `NetworkError` → `ILCatalogError` mapping.
//

import XCTest
@testable import InnerLamp

@MainActor
final class ILTempleRepositoryTests: XCTestCase {

    private var stack: CoreDataStack!
    private var network: MockCatalogNetworkService!
    private var repository: ILTempleRepository!

    override func setUp() {
        super.setUp()
        stack = CoreDataStack(inMemory: true)
        XCTAssertTrue(stack.isLoaded, "The in-memory store failed to load")
        network = MockCatalogNetworkService()
        repository = ILTempleRepositoryImpl(
            networkService: network,
            localDataSource: ILTempleLocalDataSourceImpl(stack: stack)
        )
    }

    override func tearDown() {
        repository = nil
        network = nil
        stack = nil
        super.tearDown()
    }

    // MARK: - "Show all" list: local-first paging

    func test_loadTemples_cacheMiss_fetchesServerPageAndMapsIt() async throws {
        network.responses["/v1/temples?page=1"] = .success(ILCatalogFixtures.templesPage(1, total: 25))

        let page = try await repository.loadTemples(page: 1)

        XCTAssertEqual(network.requestedRoutes, ["/v1/temples?page=1"])
        XCTAssertEqual(page.items.count, 20)
        XCTAssertEqual(page.items.first?.id, "t0")
        XCTAssertEqual(page.items.last?.id, "t19")
        XCTAssertTrue(page.hasMore)
    }

    func test_loadTemples_cachedPage_isServedWithoutNetwork() async throws {
        network.responses["/v1/temples?page=1"] = .success(ILCatalogFixtures.templesPage(1, total: 25))
        let fromServer = try await repository.loadTemples(page: 1)

        network.responses = [:] // offline from now on
        let fromCache = try await repository.loadTemples(page: 1)

        XCTAssertEqual(network.requestedRoutes, ["/v1/temples?page=1"], "Second read must not hit the server")
        XCTAssertEqual(fromCache.items, fromServer.items)
        XCTAssertTrue(fromCache.hasMore, "A cached page always lets the caller ask for the next one")
    }

    func test_loadTemples_partialLastPage_isServedFromCache() async throws {
        network.responses["/v1/temples?page=2"] = .success(ILCatalogFixtures.templesPage(2, total: 25))
        let fromServer = try await repository.loadTemples(page: 2)
        XCTAssertEqual(fromServer.items.count, 5)
        XCTAssertFalse(fromServer.hasMore, "page >= total_pages ends the list")

        let fromCache = try await repository.loadTemples(page: 2)

        XCTAssertEqual(network.requestedRoutes.count, 1)
        XCTAssertEqual(fromCache.items.map(\.id), ["t20", "t21", "t22", "t23", "t24"])
    }

    func test_loadTemples_pastLocalEnd_asksServer_emptyPageStops() async throws {
        network.responses["/v1/temples?page=2"] = .success(ILCatalogFixtures.templesPage(2, total: 25))
        network.responses["/v1/temples?page=3"] = .success(ILCatalogFixtures.templesPage(3, total: 25))
        _ = try await repository.loadTemples(page: 2)

        let past = try await repository.loadTemples(page: 3)

        XCTAssertEqual(network.requestedRoutes.last, "/v1/temples?page=3")
        XCTAssertTrue(past.items.isEmpty)
        XCTAssertFalse(past.hasMore)
    }

    func test_loadTemples_pastLocalEnd_serverHasMore_storesNewRows() async throws {
        network.responses["/v1/temples?page=1"] = .success(ILCatalogFixtures.templesPage(1, total: 20))
        _ = try await repository.loadTemples(page: 1)

        // The server grew since: page 2 now exists.
        network.responses["/v1/temples?page=2"] = .success(ILCatalogFixtures.templesPage(2, total: 23))
        let grown = try await repository.loadTemples(page: 2)
        XCTAssertEqual(grown.items.map(\.id), ["t20", "t21", "t22"])

        network.responses = [:]
        let cached = try await repository.loadTemples(page: 2)
        XCTAssertEqual(cached.items.map(\.id), ["t20", "t21", "t22"], "New rows must be persisted")
    }

    func test_loadTemples_serverTotalChanged_invalidatesOldLayout() async throws {
        network.responses["/v1/temples?page=1"] = .success(ILCatalogFixtures.templesPage(1, total: 25))
        network.responses["/v1/temples?page=2"] = .success(ILCatalogFixtures.templesPage(2, total: 26))
        _ = try await repository.loadTemples(page: 1)
        _ = try await repository.loadTemples(page: 2) // reports a different total

        _ = try await repository.loadTemples(page: 1)

        XCTAssertEqual(
            network.requestedRoutes,
            ["/v1/temples?page=1", "/v1/temples?page=2", "/v1/temples?page=1"],
            "Page 1 was laid out for the old total and must be refetched"
        )
    }

    func test_loadTemples_offlineWithoutCache_throwsOffline() async {
        await assertThrows(.offline) { try await self.repository.loadTemples(page: 1) }
    }

    func test_loadTemples_pageZero_throwsInvalidPageWithoutNetwork() async {
        await assertThrows(.invalidPage) { try await self.repository.loadTemples(page: 0) }
        XCTAssertTrue(network.requestedRoutes.isEmpty)
    }

    func test_loadTemples_serverInvalidPage_mapsToInvalidPage() async {
        network.responses["/v1/temples?page=1"] = .failure(ILCatalogFixtures.apiError("INVALID_PAGE"))
        await assertThrows(.invalidPage) { try await self.repository.loadTemples(page: 1) }
    }

    // MARK: - Top: network-first, cached fallback

    func test_loadTopTemples_online_returnsServerOrder() async throws {
        network.responses["/v1/temples/top"] = .success(ILCatalogFixtures.topTemples(ids: ["a", "b", "c"]))

        let top = try await repository.loadTopTemples()

        XCTAssertEqual(top.map(\.id), ["a", "b", "c"])
    }

    func test_loadTopTemples_offline_fallsBackToCache() async throws {
        network.responses["/v1/temples/top"] = .success(ILCatalogFixtures.topTemples(ids: ["a", "b", "c"]))
        _ = try await repository.loadTopTemples()
        network.responses["/v1/temples/top"] = .success(ILCatalogFixtures.topTemples(ids: ["c", "d"]))
        _ = try await repository.loadTopTemples() // the top list is replaced, not appended

        network.responses = [:]
        let top = try await repository.loadTopTemples()

        XCTAssertEqual(top.map(\.id), ["c", "d"])
    }

    func test_loadTopTemples_offlineWithoutCache_throwsOffline() async {
        await assertThrows(.offline) { try await self.repository.loadTopTemples() }
    }

    // MARK: - Detail: network-first, cached fallback

    func test_loadTempleDetail_mapsEveryField() async throws {
        network.responses["/v1/temples/temple_north_011"] = .success(ILCatalogFixtures.templeDetail)

        let detail = try await repository.loadTempleDetail(id: "temple_north_011")

        XCTAssertEqual(detail.summary.name, "Chùa Bích Động")
        XCTAssertEqual(detail.summary.type, .chua)
        XCTAssertEqual(detail.summary.region, .north)
        XCTAssertEqual(detail.summary.heritageRank, .worldHeritage)
        XCTAssertNil(detail.summary.thumbnailURL)
        XCTAssertEqual(detail.summary.establishedYear, 1428)
        XCTAssertEqual(detail.summary.location.latitude, 20.2185)
        XCTAssertEqual(detail.aliases, ["Bạch Ngọc Thạch Sơn Động"])
        XCTAssertEqual(detail.currentAbbot, "Thích Đức Lợi")
        XCTAssertEqual(detail.operatingHours, "07:00 - 18:00")
        XCTAssertEqual(detail.facilities, ILTempleFacilitiesEntity(
            hasCarParking: true, hasMotorbikeParking: true,
            servesVegetarianMeals: false, hasSummerRetreat: false
        ))
        XCTAssertEqual(detail.introduction, "Chùa Bích Động nằm ở Ninh Bình.")
        XCTAssertEqual(detail.architectureHeritage, "Chùa gồm ba ngôi Hạ, Trung, Thượng.")
        XCTAssertEqual(
            detail.visitingNotes, ["Đường lên chùa có nhiều bậc đá.", "Trang phục kín đáo."],
            "Whitespace-only notes are dropped"
        )
    }

    /// A v1.0 payload (server response or a detail cached before v1.1) must still decode — the
    /// editorial fields come back empty instead of failing the screen or the offline fallback.
    func test_loadTempleDetail_v1_0Payload_decodesWithEmptyEditorialFields() async throws {
        network.responses["/v1/temples/temple_north_011"] = .success(ILCatalogFixtures.templeDetailV1_0)
        let online = try await repository.loadTempleDetail(id: "temple_north_011")

        XCTAssertEqual(online.introduction, "")
        XCTAssertEqual(online.architectureHeritage, "")
        XCTAssertEqual(online.visitingNotes, [])

        network.responses = [:]
        let offline = try await repository.loadTempleDetail(id: "temple_north_011")
        XCTAssertEqual(offline, online)
    }

    func test_loadTempleDetail_offline_returnsCachedCopy() async throws {
        network.responses["/v1/temples/temple_north_011"] = .success(ILCatalogFixtures.templeDetail)
        let online = try await repository.loadTempleDetail(id: "temple_north_011")

        network.responses = [:]
        let offline = try await repository.loadTempleDetail(id: "temple_north_011")

        XCTAssertEqual(offline, online)
    }

    func test_loadTempleDetail_notFound_isNotMaskedByCache() async throws {
        network.responses["/v1/temples/temple_north_011"] = .success(ILCatalogFixtures.templeDetail)
        _ = try await repository.loadTempleDetail(id: "temple_north_011")

        network.responses["/v1/temples/temple_north_011"] = .failure(ILCatalogFixtures.apiError("TEMPLE_NOT_FOUND"))
        await assertThrows(.notFound) { try await self.repository.loadTempleDetail(id: "temple_north_011") }
    }

    func test_loadTempleDetail_notFound_evictsCachedCopy() async throws {
        network.responses["/v1/temples/temple_north_011"] = .success(ILCatalogFixtures.templeDetail)
        _ = try await repository.loadTempleDetail(id: "temple_north_011")

        network.responses["/v1/temples/temple_north_011"] = .failure(ILCatalogFixtures.apiError("TEMPLE_NOT_FOUND"))
        await assertThrows(.notFound) { try await self.repository.loadTempleDetail(id: "temple_north_011") }

        // The stale copy is gone: offline now has nothing to fall back to.
        network.responses = [:]
        await assertThrows(.offline) { try await self.repository.loadTempleDetail(id: "temple_north_011") }
    }

    func test_detailFetch_doesNotDisturbListCache() async throws {
        network.responses["/v1/temples?page=1"] = .success(ILCatalogFixtures.templesPage(1, total: 20))
        network.responses["/v1/temples/t3"] = .success(ILCatalogFixtures.templeDetail.replacingOccurrences(
            of: "temple_north_011", with: "t3"
        ))
        _ = try await repository.loadTemples(page: 1)
        _ = try await repository.loadTempleDetail(id: "t3")

        network.responses = [:]
        let page = try await repository.loadTemples(page: 1)

        XCTAssertEqual(page.items.count, 20)
        XCTAssertEqual(page.items[3].name, "Chùa Bích Động", "Detail refreshes the row's summary in place")
    }

    // MARK: - Mapping & endpoints

    func test_mapper_unknownEnumValues_mapToOther() {
        let dto = ILTempleSummaryDTO(
            id: "x", name: "x", type: "NEW_TYPE", region: "islands", thumbnailUrl: nil, imageUrl: nil,
            sect: "s", heritageRank: "NEW_RANK", establishedYear: 1,
            location: ILTempleLocationDTO(lat: 0, lng: 0, address: "")
        )
        let entity = ILTempleMapper.toDomain(dto)

        XCTAssertEqual(entity.type, .other("NEW_TYPE"))
        XCTAssertEqual(entity.region, .other("islands"))
        XCTAssertEqual(entity.heritageRank, .other("NEW_RANK"))
    }

    func test_endpoints_matchContract() throws {
        XCTAssertEqual(TopTemplesEndpoint().path, "/v1/temples/top")
        XCTAssertEqual(TemplesPageEndpoint(page: 3).queryParameters, ["page": "3"])
        XCTAssertEqual(TempleDetailEndpoint(id: "a/b?c").path, "/v1/temples/a%2Fb%3Fc")
        XCTAssertFalse(TemplesPageEndpoint(page: 1).requiresAuth)
        XCTAssertEqual(TemplesPageEndpoint(page: 1).method, .get)
    }

    // MARK: - Helpers

    private func assertThrows<T>(
        _ expected: ILCatalogError,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ operation: () async throws -> T
    ) async {
        do {
            _ = try await operation()
            XCTFail("Expected \(expected)", file: file, line: line)
        } catch let error as ILCatalogError {
            XCTAssertEqual(String(describing: error), String(describing: expected), file: file, line: line)
        } catch {
            XCTFail("Unexpected \(error)", file: file, line: line)
        }
    }
}
