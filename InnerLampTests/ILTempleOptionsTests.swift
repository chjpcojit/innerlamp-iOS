//
//  ILTempleOptionsTests.swift
//  InnerLampTests
//
//  Covers the temple options contract end to end below the Presentation layer:
//  `GET /v1/temples/options` request building, DTO decoding of the wire shape, mapping, paging
//  flags, error mapping and the ordination-place use case; plus the `POST /v1/temple-suggestions`
//  request shape.
//

import XCTest
@testable import InnerLamp

@MainActor
final class ILTempleOptionsTests: XCTestCase {

    // MARK: - Endpoint

    func test_optionsEndpoint_isPublicGetOnOptionsPath() {
        let endpoint = TempleOptionsEndpoint(page: 2)

        XCTAssertEqual(endpoint.path, "/v1/temples/options")
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertFalse(endpoint.requiresAuth)
        XCTAssertEqual(endpoint.queryParameters, ["page": "2"])
    }

    func test_optionsEndpoint_blankQuery_isLeftOutBecauseServerRejectsEmptyQ() {
        XCTAssertEqual(TempleOptionsEndpoint(page: 1, query: nil).queryParameters, ["page": "1"])
        XCTAssertEqual(TempleOptionsEndpoint(page: 1, query: "").queryParameters, ["page": "1"])
        XCTAssertEqual(TempleOptionsEndpoint(page: 1, query: " \n ").queryParameters, ["page": "1"])
    }

    func test_optionsEndpoint_query_isTrimmedAndCappedAtServerLimit() {
        XCTAssertEqual(TempleOptionsEndpoint(page: 1, query: "  Từ Quang ").queryParameters?["q"], "Từ Quang")

        let long = String(repeating: "a", count: 150)
        XCTAssertEqual(TempleOptionsEndpoint(page: 1, query: long).queryParameters?["q"]?.count, 100)
    }

    func test_optionsEndpoint_buildsRequestWithBothQueryItems() throws {
        let request = try TempleOptionsEndpoint(page: 3, query: "tu quang").buildURLRequest()
        let items = URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false)?.queryItems

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.url?.path, "/v1/temples/options")
        XCTAssertEqual(Set(items?.map { "\($0.name)=\($0.value ?? "")" } ?? []), ["page=3", "q=tu quang"])
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
    }

    // MARK: - Repository

    func test_repository_decodesWireShapeAndMapsRows() async throws {
        let network = MockCatalogNetworkService()
        network.responses["/v1/temples/options?page=1"] = .success(ILCatalogFixtures.envelope(
            #"{"items":[{"id":"temple_north_011","name":"Chùa Một Cột","province":"Hà Nội","province_code":"01"},{"id":"temple_south_002","name":"Chùa Vĩnh Tràng","province":"Tiền Giang","province_code":null}],"page":1,"page_size":100,"total":2,"total_pages":1}"#
        ))
        let repository = ILTempleOptionRepositoryImpl(networkService: network)

        let page = try await repository.loadTempleOptions(query: nil, page: 1)

        XCTAssertEqual(page.items, [
            ILTempleOptionEntity(id: "temple_north_011", name: "Chùa Một Cột", province: "Hà Nội", provinceCode: "01"),
            ILTempleOptionEntity(id: "temple_south_002", name: "Chùa Vĩnh Tràng", province: "Tiền Giang", provinceCode: nil)
        ])
        XCTAssertEqual(page.page, 1)
        XCTAssertFalse(page.hasMore, "page >= total_pages")
    }

    func test_repository_hasMore_whileBeforeLastPage_andFalseOnEmptyPage() async throws {
        let network = MockCatalogNetworkService()
        network.responses["/v1/temples/options?page=1"] = .success(ILCatalogFixtures.envelope(
            #"{"items":[{"id":"t1","name":"Chùa 1","province":"A","province_code":"01"}],"page":1,"page_size":100,"total":101,"total_pages":2}"#
        ))
        network.responses["/v1/temples/options?page=3"] = .success(ILCatalogFixtures.envelope(
            #"{"items":[],"page":3,"page_size":100,"total":101,"total_pages":2}"#
        ))
        let repository = ILTempleOptionRepositoryImpl(networkService: network)

        let first = try await repository.loadTempleOptions(query: nil, page: 1)
        let pastEnd = try await repository.loadTempleOptions(query: nil, page: 3)

        XCTAssertTrue(first.hasMore)
        XCTAssertFalse(pastEnd.hasMore)
        XCTAssertTrue(pastEnd.items.isEmpty)
    }

    func test_repository_pageBelowOne_failsLocallyWithoutNetwork() async {
        let network = MockCatalogNetworkService()
        let repository = ILTempleOptionRepositoryImpl(networkService: network)

        do {
            _ = try await repository.loadTempleOptions(query: nil, page: 0)
            XCTFail("Expected invalidPage")
        } catch {
            guard case ILCatalogError.invalidPage = error else { return XCTFail("Unexpected error \(error)") }
        }
        XCTAssertTrue(network.requestedRoutes.isEmpty)
    }

    func test_repository_offline_mapsToOfflineError() async {
        let network = MockCatalogNetworkService() // no canned response → noInternetConnection
        let repository = ILTempleOptionRepositoryImpl(networkService: network)

        do {
            _ = try await repository.loadTempleOptions(query: "tu", page: 1)
            XCTFail("Expected offline")
        } catch {
            guard case ILCatalogError.offline = error else { return XCTFail("Unexpected error \(error)") }
        }
    }

    // MARK: - Use case

    func test_useCase_mapsProvinceToSubtitle_dropsDuplicateIDs_andKeepsPaging() async throws {
        let repository = MockTempleOptionRepository()
        repository.result = ILCatalogPageEntity(
            items: [
                ILTempleOptionEntity(id: "t1", name: "Chùa Một Cột", province: "Hà Nội", provinceCode: "01"),
                ILTempleOptionEntity(id: "t1", name: "Chùa Một Cột", province: "Hà Nội", provinceCode: "01"),
                ILTempleOptionEntity(id: "t2", name: "Chùa Bái Đính", province: "Ninh Bình", provinceCode: nil)
            ],
            page: 2,
            hasMore: true
        )
        let useCase = ILOrdinationPlaceUseCaseImpl(templeOptionRepository: repository)

        let page = try await useCase.loadPlaces(query: "chùa", page: 2)

        XCTAssertEqual(page.items, [
            ILOrdinationPlaceEntity(id: "t1", name: "Chùa Một Cột", subtitle: "Hà Nội"),
            ILOrdinationPlaceEntity(id: "t2", name: "Chùa Bái Đính", subtitle: "Ninh Bình")
        ])
        XCTAssertEqual(page.page, 2)
        XCTAssertTrue(page.hasMore)
        XCTAssertEqual(repository.receivedQuery, "chùa")
        XCTAssertEqual(repository.receivedPage, 2)
    }

    func test_useCase_blankQuery_isSentAsNil() async throws {
        let repository = MockTempleOptionRepository()
        let useCase = ILOrdinationPlaceUseCaseImpl(templeOptionRepository: repository)

        _ = try await useCase.loadPlaces(query: "   ", page: 1)

        XCTAssertNil(repository.receivedQuery)
    }

    // MARK: - Suggestion endpoint

    func test_suggestionEndpoint_isPublicPostWithSnakeCaseBodyAndNoAPIKey() throws {
        let endpoint = TempleSuggestionEndpoint(request: ILTempleSuggestionRequestDTO(
            name: "Chùa Pháp Hoa",
            provinceCode: "48",
            wardCode: "20194",
            address: "12 Lê Lợi"
        ))

        XCTAssertEqual(endpoint.path, "/v1/temple-suggestions")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertFalse(endpoint.requiresAuth)
        XCTAssertNil(endpoint.headers, "X-API-Key is web-only; a wrong value is 401")

        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: try XCTUnwrap(endpoint.body)) as? [String: Any]
        )
        XCTAssertEqual(Set(json.keys), ["name", "province_code", "ward_code", "address"], "The server rejects unknown fields")
        XCTAssertEqual(json["province_code"] as? String, "48")
        XCTAssertEqual(json["ward_code"] as? String, "20194")
    }

    func test_suggestionResponseDTO_decodesPendingSuggestion() throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let dto = try decoder.decode(
            ILTempleSuggestionResponseDTO.self,
            from: Data(#"{"id":"sug_01","status":"pending"}"#.utf8)
        )

        XCTAssertEqual(dto.id, "sug_01")
        XCTAssertEqual(dto.status, "pending")
    }
}

nonisolated final class MockTempleOptionRepository: ILTempleOptionRepository {
    var result = ILCatalogPageEntity<ILTempleOptionEntity>(items: [], page: 1, hasMore: false)
    private(set) var receivedQuery: String?
    private(set) var receivedPage: Int?

    func loadTempleOptions(query: String?, page: Int) async throws -> ILCatalogPageEntity<ILTempleOptionEntity> {
        receivedQuery = query
        receivedPage = page
        return result
    }
}
