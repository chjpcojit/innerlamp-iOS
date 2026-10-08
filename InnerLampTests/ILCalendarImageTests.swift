//
//  ILCalendarImageTests.swift
//  InnerLampTests
//
//  Covers the calendar-image Data/Domain layers (`GET /v1/calendar/image`): endpoint query, DTO
//  decoding of the real wire shape (snake_case envelope), mapping, `NetworkError` →
//  `ILCatalogError`, and the use case's supported-year guard.
//

import XCTest
@testable import InnerLamp

/// Records each request and answers with a canned envelope (or error) per call, in order.
private final class MockCalendarImageNetworkService: NetworkService {
    var results: [Result<String, NetworkError>] = []
    private(set) var paths: [String] = []
    private(set) var queries: [[String: String]] = []
    private(set) var requiresAuthFlags: [Bool] = []

    func request<T: Decodable & Sendable>(endpoint: Endpoint, responseType: T.Type) async throws -> T {
        paths.append(endpoint.path)
        queries.append(endpoint.queryParameters ?? [:])
        requiresAuthFlags.append(endpoint.requiresAuth)
        let json = try results.removeFirst().get()
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let envelope = try decoder.decode(APIEnvelope<T>.self, from: Data(json.utf8))
        guard let data = envelope.data else { throw NetworkError.noData }
        return data
    }

    func request(endpoint: Endpoint) async throws {}
}

private final class MockCalendarImageRepository: ILCalendarImageRepository {
    var result: Result<ILCalendarImageEntity, Error> = .failure(NSError(domain: "unset", code: 0))
    private(set) var requestedDates: [Date] = []

    func loadImage(for date: Date) async throws -> ILCalendarImageEntity {
        requestedDates.append(date)
        return try result.get()
    }
}

@MainActor
final class ILCalendarImageTests: XCTestCase {

    private var network: MockCalendarImageNetworkService!
    private var repository: ILCalendarImageRepository!
    private let calendar = Calendar(identifier: .gregorian)

    override func setUp() {
        super.setUp()
        network = MockCalendarImageNetworkService()
        repository = ILCalendarImageRepositoryImpl(networkService: network)
    }

    override func tearDown() {
        repository = nil
        network = nil
        super.tearDown()
    }

    // MARK: - Fixtures

    private func imageJSON(
        imageURL: String = "http://h:8080/static/images/home-calendar/buddha_034.jpg",
        licenseURL: String = "https://commons.wikimedia.org/wiki/File:x.jpg",
        sourceURL: String = "https://commons.wikimedia.org/wiki/File:x.jpg"
    ) -> String {
        ILCatalogFixtures.envelope(
            #"{"date":"2026-10-07","id":"buddha_034","image_url":"\#(imageURL)","author":"Judgefloro","license":"Public domain","license_url":"\#(licenseURL)","source_url":"\#(sourceURL)"}"#
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 9))!
    }

    // MARK: - Repository

    func test_loadImage_sendsPublicRequestWithZeroPaddedSolarDate() async throws {
        network.results = [.success(imageJSON())]

        _ = try await repository.loadImage(for: date(2026, 1, 5))

        XCTAssertEqual(network.paths, ["/v1/calendar/image"])
        XCTAssertEqual(network.queries, [["date": "2026-01-05"]])
        XCTAssertEqual(network.requiresAuthFlags, [false])
    }

    func test_loadImage_mapsWireShapeAndKeepsImageURLVerbatim() async throws {
        network.results = [.success(imageJSON())]

        let image = try await repository.loadImage(for: date(2026, 10, 7))

        XCTAssertEqual(image.id, "buddha_034")
        XCTAssertEqual(image.imageURL, "http://h:8080/static/images/home-calendar/buddha_034.jpg")
        XCTAssertEqual(image.author, "Judgefloro")
        XCTAssertEqual(image.license, "Public domain")
        XCTAssertEqual(image.licenseURL, "https://commons.wikimedia.org/wiki/File:x.jpg")
        XCTAssertEqual(image.sourceURL, "https://commons.wikimedia.org/wiki/File:x.jpg")
    }

    func test_loadImage_blankLicenseAndSourceURLsMapToNil() async throws {
        network.results = [.success(imageJSON(licenseURL: " ", sourceURL: ""))]

        let image = try await repository.loadImage(for: date(2026, 10, 7))

        XCTAssertNil(image.licenseURL)
        XCTAssertNil(image.sourceURL)
    }

    func test_loadImage_blankImageURL_throwsLoadFailed() async {
        network.results = [.success(imageJSON(imageURL: "  "))]

        do {
            _ = try await repository.loadImage(for: date(2026, 10, 7))
            XCTFail("Expected loadFailed")
        } catch ILCatalogError.loadFailed {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_loadImage_noInternet_throwsOffline() async {
        network.results = [.failure(.noInternetConnection)]

        do {
            _ = try await repository.loadImage(for: date(2026, 10, 7))
            XCTFail("Expected offline")
        } catch ILCatalogError.offline {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_loadImage_invalidDate_throwsLoadFailed() async {
        network.results = [.failure(ILCatalogFixtures.apiError("INVALID_DATE"))]

        do {
            _ = try await repository.loadImage(for: date(2026, 10, 7))
            XCTFail("Expected loadFailed")
        } catch ILCatalogError.loadFailed {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Use case

    func test_useCase_yearsOutsideSupportedRange_returnNilWithoutRequest() async throws {
        let mock = MockCalendarImageRepository()
        let useCase = ILCalendarImageUseCaseImpl(repository: mock)

        let tooEarly = try await useCase.loadImage(for: date(1899, 12, 31))
        let tooLate = try await useCase.loadImage(for: date(2101, 1, 1))

        XCTAssertNil(tooEarly)
        XCTAssertNil(tooLate)
        XCTAssertTrue(mock.requestedDates.isEmpty)
    }

    func test_useCase_boundaryYears_areRequested() async throws {
        let mock = MockCalendarImageRepository()
        mock.result = .success(ILCalendarImageEntity(
            id: "a", imageURL: "http://h/a.jpg", author: "", license: "", licenseURL: nil, sourceURL: nil
        ))
        let useCase = ILCalendarImageUseCaseImpl(repository: mock)

        _ = try await useCase.loadImage(for: date(1900, 1, 1))
        _ = try await useCase.loadImage(for: date(2100, 12, 31))

        XCTAssertEqual(mock.requestedDates.count, 2)
    }

    func test_useCase_repositoryFailure_propagates() async {
        let mock = MockCalendarImageRepository()
        mock.result = .failure(ILCatalogError.offline)
        let useCase = ILCalendarImageUseCaseImpl(repository: mock)

        do {
            _ = try await useCase.loadImage(for: date(2026, 10, 7))
            XCTFail("Expected offline")
        } catch ILCatalogError.offline {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
