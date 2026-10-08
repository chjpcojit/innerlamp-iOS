//
//  ILPhotosRepositoryTests.swift
//  InnerLampTests
//
//  Covers `ILPhotosRepositoryImpl` + `ILPhotosUseCaseImpl` below the ViewModel: endpoint
//  construction (page + type), DTO decoding of the real wire shape (snake_case envelope), mapping
//  and `NetworkError` → `ILCatalogError`.
//

import XCTest
@testable import InnerLamp

/// Records each gallery request and answers with a canned envelope (or error) per call, in order.
private final class MockGalleryNetworkService: NetworkService {
    var results: [Result<String, NetworkError>] = []
    private(set) var queries: [[String: String]] = []
    private(set) var paths: [String] = []

    func request<T: Decodable & Sendable>(endpoint: Endpoint, responseType: T.Type) async throws -> T {
        paths.append(endpoint.path)
        queries.append(endpoint.queryParameters ?? [:])
        let json = try results.removeFirst().get()
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let envelope = try decoder.decode(APIEnvelope<T>.self, from: Data(json.utf8))
        guard let data = envelope.data else { throw NetworkError.noData }
        return data
    }

    func request(endpoint: Endpoint) async throws {}
}

@MainActor
final class ILPhotosRepositoryTests: XCTestCase {

    private var network: MockGalleryNetworkService!
    private var repository: ILPhotosRepository!

    override func setUp() {
        super.setUp()
        network = MockGalleryNetworkService()
        repository = ILPhotosRepositoryImpl(networkService: network)
    }

    override func tearDown() {
        repository = nil
        network = nil
        super.tearDown()
    }

    // MARK: - Fixtures

    private func itemJSON(id: String, type: String = "CHUA", thumbnail: String = "http://h/thumb.jpg") -> String {
        #"""
        {"id":"\#(id)","type":"\#(type)","title":"Tiêu đề \#(id)","location":"Hà Nội, Việt Nam","thumbnail_url":"\#(thumbnail)","image_url":"http://h/full/\#(id).jpg"}
        """#
    }

    private func pageJSON(page: Int, items: [String], total: Int, totalPages: Int) -> String {
        ILCatalogFixtures.envelope(
            #"{"items":[\#(items.joined(separator: ","))],"page":\#(page),"page_size":20,"total":\#(total),"total_pages":\#(totalPages)}"#
        )
    }

    // MARK: - Repository

    func test_loadPhotos_allCategories_sendsOnlyPageAndMapsItems() async throws {
        network.results = [.success(pageJSON(
            page: 1,
            items: [itemJSON(id: "g1"), itemJSON(id: "g2", type: "TUONG_PHAT")],
            total: 86,
            totalPages: 5
        ))]

        let page = try await repository.loadPhotos(category: nil, page: 1)

        XCTAssertEqual(network.paths, ["/v1/gallery"])
        XCTAssertEqual(network.queries, [["page": "1"]])
        XCTAssertEqual(page.items.map(\.id), ["g1", "g2"])
        XCTAssertEqual(page.items.map(\.category), [.temple, .buddhaStatue])
        XCTAssertEqual(page.items.first?.title, "Tiêu đề g1")
        XCTAssertEqual(page.items.first?.place, "Hà Nội, Việt Nam")
        XCTAssertEqual(page.items.first?.thumbnailURL, "http://h/thumb.jpg")
        XCTAssertEqual(page.items.first?.imageURL, "http://h/full/g1.jpg")
        XCTAssertEqual(page.totalCount, 86)
        XCTAssertTrue(page.hasMore)
    }

    func test_loadPhotos_sendsServerTypeForEachCategory() async throws {
        let expected: [ILPhotosCategory: String] = [
            .temple: "CHUA", .buddhaStatue: "TUONG_PHAT", .meditation: "THIEN", .festival: "LE_HOI"
        ]
        for (category, type) in expected {
            network.results = [.success(pageJSON(page: 2, items: [itemJSON(id: "g1")], total: 12, totalPages: 3))]
            _ = try await repository.loadPhotos(category: category, page: 2)
            XCTAssertEqual(network.queries.last, ["page": "2", "type": type])
        }
    }

    func test_loadPhotos_lastPage_hasMoreIsFalse() async throws {
        network.results = [.success(pageJSON(page: 5, items: [itemJSON(id: "g1")], total: 81, totalPages: 5))]

        let page = try await repository.loadPhotos(category: nil, page: 5)

        XCTAssertFalse(page.hasMore)
    }

    func test_loadPhotos_emptyPage_hasMoreIsFalse() async throws {
        network.results = [.success(pageJSON(page: 9, items: [], total: 86, totalPages: 5))]

        let page = try await repository.loadPhotos(category: nil, page: 9)

        XCTAssertTrue(page.items.isEmpty)
        XCTAssertFalse(page.hasMore)
    }

    func test_loadPhotos_unknownTypeIsDroppedButPageStillHasMore() async throws {
        network.results = [.success(pageJSON(
            page: 1,
            items: [itemJSON(id: "g1", type: "XYZ")],
            total: 40,
            totalPages: 2
        ))]

        let page = try await repository.loadPhotos(category: nil, page: 1)

        XCTAssertTrue(page.items.isEmpty)
        XCTAssertTrue(page.hasMore, "A page whose items were all dropped is not the end of the list")
    }

    func test_loadPhotos_blankThumbnailMapsToNil() async throws {
        network.results = [.success(pageJSON(page: 1, items: [itemJSON(id: "g1", thumbnail: "  ")], total: 1, totalPages: 1))]

        let page = try await repository.loadPhotos(category: nil, page: 1)

        XCTAssertNil(page.items.first?.thumbnailURL)
    }

    func test_loadPhotos_pageBelowOne_throwsInvalidPageWithoutRequest() async {
        do {
            _ = try await repository.loadPhotos(category: nil, page: 0)
            XCTFail("Expected invalidPage")
        } catch ILCatalogError.invalidPage {
            XCTAssertTrue(network.paths.isEmpty)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_loadPhotos_noInternet_throwsOffline() async {
        network.results = [.failure(.noInternetConnection)]
        do {
            _ = try await repository.loadPhotos(category: nil, page: 1)
            XCTFail("Expected offline")
        } catch ILCatalogError.offline {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_loadPhotos_invalidPageApiError_throwsInvalidPage() async {
        network.results = [.failure(ILCatalogFixtures.apiError("INVALID_PAGE"))]
        do {
            _ = try await repository.loadPhotos(category: nil, page: 1)
            XCTFail("Expected invalidPage")
        } catch ILCatalogError.invalidPage {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_loadPhotos_invalidGalleryType_throwsLoadFailed() async {
        network.results = [.failure(ILCatalogFixtures.apiError("INVALID_GALLERY_TYPE"))]
        do {
            _ = try await repository.loadPhotos(category: .temple, page: 1)
            XCTFail("Expected loadFailed")
        } catch ILCatalogError.loadFailed {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_loadTopPhotos_callsTopEndpointAndMapsInOrder() async throws {
        network.results = [.success(ILCatalogFixtures.envelope(
            #"{"items":[\#(itemJSON(id: "g1")),\#(itemJSON(id: "g2", type: "XYZ")),\#(itemJSON(id: "g3", type: "LE_HOI"))]}"#
        ))]

        let photos = try await repository.loadTopPhotos()

        XCTAssertEqual(network.paths, ["/v1/gallery/top"])
        XCTAssertEqual(network.queries, [[:]])
        XCTAssertEqual(photos.map(\.id), ["g1", "g3"], "An item with an unknown type is dropped")
        XCTAssertEqual(photos.first?.thumbnailURL, "http://h/thumb.jpg")
    }

    func test_loadTopPhotos_noInternet_throwsOffline() async {
        network.results = [.failure(.noInternetConnection)]
        do {
            _ = try await repository.loadTopPhotos()
            XCTFail("Expected offline")
        } catch ILCatalogError.offline {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - UseCase

    func test_useCase_loadFirstThenNextPage_mergesAndDeDuplicates() async throws {
        network.results = [
            .success(pageJSON(page: 1, items: [itemJSON(id: "g1"), itemJSON(id: "g2")], total: 3, totalPages: 2)),
            .success(pageJSON(page: 2, items: [itemJSON(id: "g2"), itemJSON(id: "g3")], total: 3, totalPages: 2))
        ]
        let useCase = ILPhotosUseCaseImpl(photosRepository: repository)

        let first = try await useCase.loadFirstPage(category: .temple)
        let merged = try await useCase.loadNextPage(after: first)

        XCTAssertEqual(network.queries, [["page": "1", "type": "CHUA"], ["page": "2", "type": "CHUA"]])
        XCTAssertEqual(merged.photos.map(\.id), ["g1", "g2", "g3"])
        XCTAssertEqual(merged.selectedCategory, .temple)
        XCTAssertEqual(merged.lastLoadedPage, 2)
        XCTAssertFalse(merged.hasMore)
    }

    func test_useCase_loadNextPage_whenNoMore_returnsEntityWithoutRequest() async throws {
        let useCase = ILPhotosUseCaseImpl(photosRepository: repository)
        let entity = ILPhotosEntity(photos: [], selectedCategory: nil, totalCount: 0, lastLoadedPage: 5, hasMore: false)

        let result = try await useCase.loadNextPage(after: entity)

        XCTAssertEqual(result, entity)
        XCTAssertTrue(network.paths.isEmpty)
    }
}

// MARK: - Mock ILPhotosRepository
/// Canned `loadTopPhotos()` for the Home use case tests (shared with `ILHomeUseCaseTests`).
final class MockILPhotosRepository: ILPhotosRepository {
    var topResult: Result<[ILPhotosPhotoEntity], Error> = .success([])

    func loadTopPhotos() async throws -> [ILPhotosPhotoEntity] {
        try topResult.get()
    }

    func loadPhotos(category: ILPhotosCategory?, page: Int) async throws -> ILPhotosPageEntity {
        ILPhotosPageEntity(items: [], page: page, totalCount: 0, hasMore: false)
    }
}
