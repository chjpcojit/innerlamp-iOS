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

final class ILMemorialRepositoryTests: XCTestCase {

    private typealias Factory = ILMemorialTestFactory

    private var stack: CoreDataStack!
    private var network: MockMemorialNetworkService!
    private var repository: ILMemorialRepository!

    override func setUp() {
        super.setUp()
        stack = CoreDataStack(inMemory: true)
        XCTAssertTrue(stack.isLoaded, "The in-memory store failed to load — is the `Memorial` entity in the current model version?")
        network = MockMemorialNetworkService()
        repository = ILMemorialRepositoryImpl(
            networkService: network,
            localDataSource: ILMemorialLocalDataSourceImpl(stack: stack)
        )
    }

    override func tearDown() {
        repository = nil
        network = nil
        stack = nil
        super.tearDown()
    }

    // MARK: - Fixtures

    private static func json(id: Int, name: String = "Nguyễn Văn An", extra: String = "") -> String {
        #"{"id":\#(id),"full_name":"\#(name)","relationship":"FATHER","death_date":null,"death_calendar":"lunar","death_day":15,"death_month":7,"death_leap_month":false,"note":null,"photo_url":null,"reminder":{"days_before":1,"time":"07:00","timezone":"Asia/Ho_Chi_Minh"},"add_to_os_reminder":true,"created_at":"2026-10-01T00:00:00Z","updated_at":"2026-10-01T00:00:00Z"\#(extra)}"#
    }

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
        let local = ILMemorialLocalDataSourceImpl(stack: stack)
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
        let local = ILMemorialLocalDataSourceImpl(stack: stack)
        try await local.upsert(Factory.entry(id: "legacy-uuid"))
        try await local.upsert(Factory.entry(id: "12"))

        let entries = try await repository.loadAll()

        XCTAssertEqual(entries.map(\.id), ["12"])
    }

    func test_loadAll_unauthorized_doesNotServeCache() async throws {
        try await ILMemorialLocalDataSourceImpl(stack: stack).upsert(Factory.entry(id: "12"))
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
        let cached = try await ILMemorialLocalDataSourceImpl(stack: stack).fetchAll()
        XCTAssertEqual(cached.map(\.id), ["42"])
    }

    func test_save_serverID_updatesViaPUT() async throws {
        network.responses["PUT /v1/memorials/42"] = .success(Self.envelope(Self.json(id: 42, name: "Sau")))

        try await repository.save(serverEntry(id: "42", name: "Sau"))

        XCTAssertEqual(network.requests.map(\.route), ["PUT /v1/memorials/42"])
        let cached = try await ILMemorialLocalDataSourceImpl(stack: stack).fetchAll()
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
        let cached = try await ILMemorialLocalDataSourceImpl(stack: stack).fetchAll()
        XCTAssertTrue(cached.isEmpty)
    }

    // MARK: - delete

    func test_delete_callsServerAndDropsFromCache() async throws {
        let local = ILMemorialLocalDataSourceImpl(stack: stack)
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
}
