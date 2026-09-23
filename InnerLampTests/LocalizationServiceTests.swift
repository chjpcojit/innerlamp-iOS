//
//  LocalizationServiceTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

final class LocalizationServiceTests: XCTestCase {

    private var mockNetworkService: MockLocalizationNetworkService!
    private var mockFileStorage: MockLocalizationFileStorage!

    override func setUp() {
        super.setUp()
        mockNetworkService = MockLocalizationNetworkService()
        mockFileStorage = MockLocalizationFileStorage()
    }

    override func tearDown() {
        mockNetworkService = nil
        mockFileStorage = nil
        super.tearDown()
    }

    private func makeSUT() -> LocalizationServiceImpl {
        LocalizationServiceImpl(
            networkService: mockNetworkService,
            fileStorage: mockFileStorage,
            language: "vi"
        )
    }

    func test_string_prefersCachedFileOverBundled() {
        mockFileStorage.bundled = LocalizedStringsFile(version: "1.0.0", language: "vi", strings: ["k": "bundled"])
        mockFileStorage.cached = LocalizedStringsFile(version: "1.0.1", language: "vi", strings: ["k": "cached"])

        let sut = makeSUT()

        XCTAssertEqual(sut.string(for: "k"), "cached")
    }

    func test_string_fallsBackToBundledWhenNoCache() {
        mockFileStorage.bundled = LocalizedStringsFile(version: "1.0.0", language: "vi", strings: ["k": "bundled"])

        let sut = makeSUT()

        XCTAssertEqual(sut.string(for: "k"), "bundled")
    }

    func test_string_returnsKeyItselfWhenMissing() {
        let sut = makeSUT()

        XCTAssertEqual(sut.string(for: "missing.key"), "missing.key")
    }

    func test_syncRemoteIfNeeded_downloadsAndSavesWhenVersionDiffers() async {
        mockFileStorage.bundled = LocalizedStringsFile(version: "1.0.0", language: "vi", strings: ["k": "old"])
        mockNetworkService.versionResponse = LocalizationVersionResponse(version: "1.0.1")
        mockNetworkService.contentResponse = LocalizedStringsFile(version: "1.0.1", language: "vi", strings: ["k": "new"])

        let sut = makeSUT()
        await sut.syncRemoteIfNeeded()

        XCTAssertEqual(sut.string(for: "k"), "new")
        XCTAssertEqual(mockFileStorage.savedFile?.version, "1.0.1")
    }

    func test_syncRemoteIfNeeded_skipsDownloadWhenVersionMatches() async {
        mockFileStorage.bundled = LocalizedStringsFile(version: "1.0.0", language: "vi", strings: ["k": "old"])
        mockNetworkService.versionResponse = LocalizationVersionResponse(version: "1.0.0")

        let sut = makeSUT()
        await sut.syncRemoteIfNeeded()

        XCTAssertEqual(sut.string(for: "k"), "old")
        XCTAssertNil(mockFileStorage.savedFile)
    }

    func test_syncRemoteIfNeeded_keepsLocalFileOnNetworkFailure() async {
        mockFileStorage.bundled = LocalizedStringsFile(version: "1.0.0", language: "vi", strings: ["k": "old"])
        mockNetworkService.errorToThrow = NetworkError.noInternetConnection

        let sut = makeSUT()
        await sut.syncRemoteIfNeeded()

        XCTAssertEqual(sut.string(for: "k"), "old")
        XCTAssertNil(mockFileStorage.savedFile)
    }
}

// MARK: - Mocks

final class MockLocalizationFileStorage: LocalizationFileStorage {
    var bundled: LocalizedStringsFile?
    var cached: LocalizedStringsFile?
    var savedFile: LocalizedStringsFile?
    var saveError: Error?

    func loadBundled(language: String) -> LocalizedStringsFile? { bundled }
    func loadCached(language: String) -> LocalizedStringsFile? { cached }

    func save(_ file: LocalizedStringsFile) throws {
        if let saveError { throw saveError }
        savedFile = file
    }
}

final class MockLocalizationNetworkService: NetworkService {
    var versionResponse: LocalizationVersionResponse?
    var contentResponse: LocalizedStringsFile?
    var errorToThrow: Error?

    func request<T>(endpoint: Endpoint, responseType: T.Type) async throws -> T where T: Decodable {
        if let errorToThrow { throw errorToThrow }
        if let versionResponse, let result = versionResponse as? T { return result }
        if let contentResponse, let result = contentResponse as? T { return result }
        throw NetworkError.noData
    }

    func request(endpoint: Endpoint) async throws {}
}
