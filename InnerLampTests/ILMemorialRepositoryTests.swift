//
//  ILMemorialRepositoryTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

/// Routes by `"METHOD path"` to canned envelope JSON and decodes it like `NetworkServiceImpl`
/// does (`.convertFromSnakeCase`). An unrouted request throws `.noInternetConnection`, which
/// doubles as "the device is offline".
private final class MockMemorialNetworkService: NetworkService {
    var responses: [String: Result<String, NetworkError>] = [:]
    private(set) var requests: [(route: String, body: [String: Any]?)] = []

    func request<T: Decodable & Sendable>(endpoint: Endpoint, responseType: T.Type) async throws -> T {
        let result = try record(endpoint)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let envelope = try decoder.decode(APIEnvelope<T>.self, from: Data(try result.get().utf8))
        guard let data = envelope.data else { throw NetworkError.noData }
        return data
    }

    func request(endpoint: Endpoint) async throws {
        _ = try record(endpoint).get()
    }

    private func record(_ endpoint: Endpoint) throws -> Result<String, NetworkError> {
        let route = "\(endpoint.method.rawValue) \(endpoint.path)"
        let body = endpoint.body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
        requests.append((route, body))
        guard let result = responses[route] else { throw NetworkError.noInternetConnection }
        return result
    }
}

/// Records the multipart form and returns a canned envelope, like the real uploader does.
private final class MockMemorialMultipartUploader: MultipartUploading {
    var result: Result<String, NetworkError> = .failure(.noInternetConnection)
    private(set) var requests: [(path: String, contentType: String, body: Data)] = []

    func upload<T: Decodable & Sendable>(
        endpoint: Endpoint,
        form: MultipartFormData,
        responseType: T.Type
    ) async throws -> T {
        requests.append((endpoint.path, form.contentType, form.body))
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let envelope = try decoder.decode(APIEnvelope<T>.self, from: Data(try result.get().utf8))
        guard let data = envelope.data else { throw NetworkError.noData }
        return data
    }
}

final class ILMemorialRepositoryTests: XCTestCase {

    private typealias Factory = ILMemorialTestFactory

    private var stack: CoreDataStack!
    private var network: MockMemorialNetworkService!
    private var uploader: MockMemorialMultipartUploader!
    private var repository: ILMemorialRepository!

    override func setUp() {
        super.setUp()
        stack = CoreDataStack(inMemory: true)
        XCTAssertTrue(stack.isLoaded, "The in-memory store failed to load — is the `Memorial` entity in the current model version?")
        network = MockMemorialNetworkService()
        uploader = MockMemorialMultipartUploader()
        repository = ILMemorialRepositoryImpl(
            networkService: network,
            multipartUploader: uploader,
            localDataSource: ILMemorialLocalDataSourceImpl(stack: stack, accountIdentity: ILMemorialTestFactory.identity())
        )
    }

    override func tearDown() {
        repository = nil
        network = nil
        uploader = nil
        stack = nil
        super.tearDown()
    }

    // MARK: - Fixtures

    // swiftlint:disable line_length
    private static func json(id: Int, name: String = "Nguyễn Văn An", extra: String = "") -> String {
        #"{"id":\#(id),"full_name":"\#(name)","relationship":"FATHER","death_date":null,"death_calendar":"lunar","death_day":15,"death_month":7,"death_leap_month":false,"note":null,"photo_url":null,"reminder":{"days_before":1,"time":"07:00","timezone":"Asia/Ho_Chi_Minh"},"add_to_os_reminder":true,"created_at":"2026-10-01T00:00:00Z","updated_at":"2026-10-01T00:00:00Z"\#(extra)}"#
    }

    private static func photoJSON() -> String {
        #"{"id":42,"full_name":"Nguyễn Văn An","relationship":"FATHER","death_date":null,"death_calendar":"lunar","death_day":15,"death_month":7,"death_leap_month":false,"note":null,"photo_url":"https://example.com/p.jpg?sig=1","reminder":null,"created_at":"2026-10-01T00:00:00Z","updated_at":"2026-10-01T00:00:00Z"}"#
    }

    // swiftlint:enable line_length

    private static func envelope(_ data: String) -> String { #"{"success":true,"data":\#(data)}"# }

    private static func listJSON(_ ids: [Int]) -> String {
        envelope(#"{"items":[\#(ids.map { json(id: $0) }.joined(separator: ","))]}"#)
    }

    private static func apiError(_ code: String) -> NetworkError {
        .apiError(code: code, message: "server message", type: "business", details: nil)
    }

    private func serverEntry(id: String, name: String = "Nguyễn Văn An") -> ILMemorialEntity {
        Factory.entry(id: id, name: name, relationship: .father, calendarKind: .lunar, day: 15, month: 7)
    }

    // MARK: - loadAll

    func test_loadAll_mapsServerListAndRefreshesCache() async throws {
        network.responses["GET /v1/memorials"] = .success(Self.listJSON([7, 8]))

        let entries = try await repository.loadAll()

        XCTAssertEqual(entries.map(\.id), ["7", "8"])
        XCTAssertEqual(entries.first?.relationship, .father)
        XCTAssertEqual(entries.first?.reminder, ILMemorialReminder(leadDays: 1, hour: 7, minute: 0))
        XCTAssertEqual(entries.first?.note, "")

        network.responses = [:] // offline from now on
        let cached = try await repository.loadAll()
        XCTAssertEqual(Set(cached.map(\.id)), ["7", "8"])
    }

    func test_loadAll_freshServerList_replacesStaleCacheIncludingLegacyEntries() async throws {
        let local = ILMemorialLocalDataSourceImpl(stack: stack, accountIdentity: ILMemorialTestFactory.identity())
        try await local.upsert(Factory.entry(id: "legacy-uuid"))
        network.responses["GET /v1/memorials"] = .success(Self.listJSON([1]))

        _ = try await repository.loadAll()
        let rows = try await local.fetchAll()

        XCTAssertEqual(rows.map(\.id), ["1"])
    }

    func test_loadAll_offlineWithEmptyCache_throwsOffline() async {
        do {
            _ = try await repository.loadAll()
            XCTFail("Expected an error")
        } catch {
            guard case .offline? = error as? ILMemorialError else { return XCTFail("Got \(error)") }
        }
    }

    func test_loadAll_offline_skipsLegacyEntriesWithoutNumericID() async throws {
        let local = ILMemorialLocalDataSourceImpl(stack: stack, accountIdentity: ILMemorialTestFactory.identity())
        try await local.upsert(Factory.entry(id: "legacy-uuid"))
        try await local.upsert(Factory.entry(id: "12"))

        let entries = try await repository.loadAll()

        XCTAssertEqual(entries.map(\.id), ["12"])
    }

    func test_loadAll_unauthorized_doesNotServeCache() async throws {
        try await ILMemorialLocalDataSourceImpl(stack: stack, accountIdentity: ILMemorialTestFactory.identity()).upsert(Factory.entry(id: "12"))
        network.responses["GET /v1/memorials"] = .failure(.unauthorized)

        do {
            _ = try await repository.loadAll()
            XCTFail("Expected an error")
        } catch {
            guard case .unauthorized? = error as? ILMemorialError else { return XCTFail("Got \(error)") }
        }
    }

    // MARK: - save

    func test_save_localUUID_createsViaPOST_andCachesServerEntry() async throws {
        network.responses["POST /v1/memorials"] = .success(Self.envelope(Self.json(id: 42)))

        try await repository.save(serverEntry(id: UUID().uuidString))

        XCTAssertEqual(network.requests.map(\.route), ["POST /v1/memorials"])
        let cached = try await ILMemorialLocalDataSourceImpl(stack: stack, accountIdentity: ILMemorialTestFactory.identity()).fetchAll()
        XCTAssertEqual(cached.map(\.id), ["42"])
    }

    func test_save_serverID_updatesViaPUT() async throws {
        network.responses["PUT /v1/memorials/42"] = .success(Self.envelope(Self.json(id: 42, name: "Sau")))

        try await repository.save(serverEntry(id: "42", name: "Sau"))

        XCTAssertEqual(network.requests.map(\.route), ["PUT /v1/memorials/42"])
        let cached = try await ILMemorialLocalDataSourceImpl(stack: stack, accountIdentity: ILMemorialTestFactory.identity()).fetchAll()
        XCTAssertEqual(cached.map(\.name), ["Sau"])
    }

    func test_save_sendsContractBody() async throws {
        network.responses["POST /v1/memorials"] = .success(Self.envelope(Self.json(id: 1)))

        try await repository.save(serverEntry(id: "uuid"))

        let body = try XCTUnwrap(network.requests.first?.body)
        XCTAssertEqual(body["full_name"] as? String, "Nguyễn Văn An")
        XCTAssertEqual(body["relationship"] as? String, "FATHER")
        XCTAssertEqual(body["death_calendar"] as? String, "lunar")
        XCTAssertEqual(body["death_day"] as? Int, 15)
        XCTAssertEqual(body["death_month"] as? Int, 7)
        XCTAssertNil(body["death_date"])
        XCTAssertNil(body["id"], "The server rejects unknown fields, including id")
    }

    func test_save_serverRejections_mapToDomainErrors() async {
        let cases: [(String, (ILMemorialError) -> Bool)] = [
            ("MEMORIAL_LIMIT_REACHED", { if case .limitReached = $0 { return true } else { return false } }),
            ("VALIDATION_ERROR", { if case .invalidInput = $0 { return true } else { return false } }),
            ("MEMORIAL_NOT_FOUND", { if case .notFound = $0 { return true } else { return false } }),
        ]
        for (code, matches) in cases {
            network.responses["POST /v1/memorials"] = .failure(Self.apiError(code))
            do {
                try await repository.save(serverEntry(id: "uuid"))
                XCTFail("Expected \(code) to throw")
            } catch {
                XCTAssertTrue((error as? ILMemorialError).map(matches) ?? false, "\(code) → \(error)")
            }
        }
    }

    func test_save_nonexistentSolarDate_throwsInvalidInputWithoutNetwork() async {
        let entry = Factory.entry(id: "uuid", calendarKind: .solar, day: 31, month: 4, deathYear: 2020)

        do {
            try await repository.save(entry)
            XCTFail("Expected an error")
        } catch {
            guard case .invalidInput? = error as? ILMemorialError else { return XCTFail("Got \(error)") }
        }
        XCTAssertTrue(network.requests.isEmpty)
    }

    func test_save_offline_throwsOfflineAndCachesNothing() async throws {
        do {
            try await repository.save(serverEntry(id: "uuid"))
            XCTFail("Expected an error")
        } catch {
            guard case .offline? = error as? ILMemorialError else { return XCTFail("Got \(error)") }
        }
        let cached = try await ILMemorialLocalDataSourceImpl(stack: stack, accountIdentity: ILMemorialTestFactory.identity()).fetchAll()
        XCTAssertTrue(cached.isEmpty)
    }

    // MARK: - delete

    func test_delete_callsServerAndDropsFromCache() async throws {
        let local = ILMemorialLocalDataSourceImpl(stack: stack, accountIdentity: ILMemorialTestFactory.identity())
        try await local.upsert(Factory.entry(id: "5"))
        network.responses["DELETE /v1/memorials/5"] = .success(#"{"success":true}"#)

        try await repository.delete(id: "5")

        XCTAssertEqual(network.requests.map(\.route), ["DELETE /v1/memorials/5"])
        let cached = try await local.fetchAll()
        XCTAssertTrue(cached.isEmpty)
    }

    func test_delete_alreadyGoneOnServer_isNotAnError() async throws {
        network.responses["DELETE /v1/memorials/5"] = .failure(Self.apiError("MEMORIAL_NOT_FOUND"))

        try await repository.delete(id: "5")
    }

    func test_delete_offline_throwsOffline() async {
        do {
            try await repository.delete(id: "5")
            XCTFail("Expected an error")
        } catch {
            guard case .offline? = error as? ILMemorialError else { return XCTFail("Got \(error)") }
        }
    }

    // MARK: - photo (contract §3.6/§3.7, flag off by default)

    func test_uploadPhoto_success_sendsSinglePartAndReturnsSignedURL() async throws {
        uploader.result = .success(Self.envelope(Self.photoJSON()))
        let jpeg = Data([0xFF, 0xD8, 0xFF, 0xD9])

        let saved = try await repository.uploadPhoto(entryID: "42", jpegData: jpeg)

        XCTAssertEqual(uploader.requests.map(\.path), ["/v1/memorials/42/photo"])
        XCTAssertEqual(saved.photoURL?.absoluteString, "https://example.com/p.jpg?sig=1")
        let request = try XCTUnwrap(uploader.requests.first)
        XCTAssertTrue(request.contentType.hasPrefix("multipart/form-data; boundary="))
        let body = String(decoding: request.body, as: UTF8.self)
        XCTAssertTrue(body.contains("name=\"photo\""))
        XCTAssertTrue(body.contains("Content-Type: image/jpeg"))
    }

    func test_uploadPhoto_413_mapsToPhotoTooLarge() async {
        uploader.result = .failure(Self.apiError("PHOTO_TOO_LARGE"))

        await XCTAssertThrowsPhotoError(.photoTooLarge) {
            _ = try await self.repository.uploadPhoto(entryID: "42", jpegData: Data([0x01]))
        }
    }

    func test_uploadPhoto_415_mapsToPhotoUnsupported() async {
        uploader.result = .failure(Self.apiError("PHOTO_UNSUPPORTED_TYPE"))

        await XCTAssertThrowsPhotoError(.photoUnsupported) {
            _ = try await self.repository.uploadPhoto(entryID: "42", jpegData: Data([0x01]))
        }
    }

    func test_uploadPhoto_overFiveMiB_isRejectedOnDevice() async {
        let oversized = Data(repeating: 0x01, count: ILMemorialRepositoryImpl.maxPhotoBytes + 1)

        await XCTAssertThrowsPhotoError(.photoTooLarge) {
            _ = try await self.repository.uploadPhoto(entryID: "42", jpegData: oversized)
        }
        XCTAssertTrue(uploader.requests.isEmpty, "An oversized image must not reach the network")
    }

    func test_deletePhoto_callsRouteAndClearsPhoto() async throws {
        // swiftlint:disable line_length
        network.responses["DELETE /v1/memorials/42/photo"] = .success(
            Self.envelope(#"{"id":42,"full_name":"Nguyễn Văn An","relationship":"FATHER","death_date":null,"death_calendar":"lunar","death_day":15,"death_month":7,"death_leap_month":false,"note":null,"photo_url":null,"reminder":null,"created_at":"2026-10-01T00:00:00Z","updated_at":"2026-10-01T00:00:00Z"}"#)
        )
        // swiftlint:enable line_length

        let saved = try await repository.deletePhoto(entryID: "42")

        XCTAssertNil(saved.photoURL)
        XCTAssertEqual(network.requests.map(\.route), ["DELETE /v1/memorials/42/photo"])
    }

    func test_uploadPhoto_404_mapsToNotFound() async {
        uploader.result = .failure(Self.apiError("MEMORIAL_NOT_FOUND"))

        do {
            _ = try await repository.uploadPhoto(entryID: "42", jpegData: Data([0xFF, 0xD8]))
            XCTFail("Expected notFound")
        } catch {
            guard case .notFound? = error as? ILMemorialError else { return XCTFail("Got \(error)") }
        }
    }

    func test_loadAll_keepsSignedPhotoURLOnlyInMemory() async throws {
        let list = Self.listJSON([7]).replacingOccurrences(
            of: #""photo_url":null"#,
            with: #""photo_url":"https://example.com/p.jpg?sig=1""#
        )
        network.responses["GET /v1/memorials"] = .success(list)

        let entries = try await repository.loadAll()
        XCTAssertEqual(entries.first?.photoURL?.absoluteString, "https://example.com/p.jpg?sig=1")

        let cached = try await ILMemorialLocalDataSourceImpl(
            stack: stack,
            accountIdentity: ILMemorialTestFactory.identity()
        ).fetchAll()
        XCTAssertNil(cached.first?.photoURL, "D8: signed URL must not be cached")
    }

    // MARK: - Account scope (G1 item 2)

    func test_loadAll_offline_doesNotServeAnotherAccountsCache() async throws {
        let identity = ILFixedAccountIdentityProvider(accountID: "account-a")
        let local = ILMemorialLocalDataSourceImpl(stack: stack, accountIdentity: identity)
        let scoped = ILMemorialRepositoryImpl(
            networkService: network,
            multipartUploader: uploader,
            localDataSource: local
        )
        network.responses["GET /v1/memorials"] = .success(Self.listJSON([7]))
        _ = try await scoped.loadAll()

        identity.accountID = "account-b"
        network.responses = [:]

        do {
            _ = try await scoped.loadAll()
            XCTFail("B must not read A's cache")
        } catch {
            guard case .offline? = error as? ILMemorialError else { return XCTFail("Got \(error)") }
        }
    }
}

private enum PhotoErrorExpectation {
    case photoTooLarge
    case photoUnsupported
}

private extension XCTestCase {
    func XCTAssertThrowsPhotoError(
        _ expected: PhotoErrorExpectation,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ operation: () async throws -> Void
    ) async {
        do {
            try await operation()
            XCTFail("Expected a photo error", file: file, line: line)
        } catch {
            guard case let .some(memorialError) = error as? ILMemorialError else {
                return XCTFail("Got \(error)", file: file, line: line)
            }
            switch (expected, memorialError) {
            case (.photoTooLarge, .photoTooLarge), (.photoUnsupported, .photoUnsupported):
                break
            default:
                XCTFail("Got \(memorialError)", file: file, line: line)
            }
        }
    }

}
