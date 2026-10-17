//
//  ILCalendarEventsTests.swift
//  InnerLampTests
//
//  Covers the calendar-events Data layer (`GET /v1/calendar/events`): endpoint query + auth,
//  decoding of the real wire shape (snake_case envelope), mapping, and `NetworkError` →
//  `ILCatalogError`.
//

import XCTest
@testable import InnerLamp

private final class MockCalendarEventsNetworkService: NetworkService {
    var result: Result<String, NetworkError> = .failure(.noData)
    private(set) var paths: [String] = []
    private(set) var queries: [[String: String]] = []
    private(set) var requiresAuthFlags: [Bool] = []

    func request<T: Decodable & Sendable>(endpoint: Endpoint, responseType: T.Type) async throws -> T {
        paths.append(endpoint.path)
        queries.append(endpoint.queryParameters ?? [:])
        requiresAuthFlags.append(endpoint.requiresAuth)
        let json = try result.get()
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let envelope = try decoder.decode(APIEnvelope<T>.self, from: Data(json.utf8))
        guard let data = envelope.data else { throw NetworkError.noData }
        return data
    }

    func request(endpoint: Endpoint) async throws {}
}

@MainActor
final class ILCalendarEventsTests: XCTestCase {

    private var network: MockCalendarEventsNetworkService!
    private var repository: ILCalendarEventRepository!

    override func setUp() {
        super.setUp()
        network = MockCalendarEventsNetworkService()
        repository = ILCalendarEventRepositoryImpl(networkService: network)
    }

    /// Trimmed copy of the real dev-server answer for 2026, plus one occurrence of an unknown event
    /// and one with a malformed date (both must be dropped).
    private let json = """
    {"success": true, "data": {
      "year": 2026,
      "groups": [{"code": "buddhist", "name": "Phật giáo"}, {"code": "folk", "name": "Dân gian"}],
      "events": [
        {"code": "tet-nguyen-dan", "name": "Tết Nguyên Đán", "short_description": "s", "long_description": "l",
         "guidance": "g", "image_url": null, "groups": ["vietnam", "folk"], "is_public_holiday": true,
         "is_major": true, "sort_order": 3, "recurrence": "future_kind"}
      ],
      "occurrences": [
        {"event_code": "tet-nguyen-dan", "solar_date": "2026-02-17",
         "lunar_date": {"day": 1, "month": 1, "year": 2026, "is_leap_month": false}},
        {"event_code": "ghost", "solar_date": "2026-03-01",
         "lunar_date": {"day": 12, "month": 1, "year": 2026, "is_leap_month": false}},
        {"event_code": "tet-nguyen-dan", "solar_date": "not-a-date",
         "lunar_date": {"day": 1, "month": 1, "year": 2026, "is_leap_month": false}}
      ]
    }}
    """

    func test_loadEvents_sendsYearQuery_toPublicEndpoint() async throws {
        network.result = .success(json)

        _ = try await repository.loadEvents(year: 2026)

        XCTAssertEqual(network.paths, ["/v1/calendar/events"])
        XCTAssertEqual(network.queries, [["year": "2026"]])
        XCTAssertEqual(network.requiresAuthFlags, [false], "FR-CAL-001: guests read the calendar")
    }

    func test_loadEvents_mapsEventsAndDropsUnusableOccurrences() async throws {
        network.result = .success(json)

        let result = try await repository.loadEvents(year: 2026)

        XCTAssertEqual(result.year, 2026)
        XCTAssertEqual(result.groups.map(\.code), ["buddhist", "folk"])
        XCTAssertEqual(result.events.map(\.code), ["tet-nguyen-dan"])
        XCTAssertNil(result.events.first?.imageURL)
        XCTAssertEqual(result.events.first?.groupCodes, ["vietnam", "folk"])
        XCTAssertEqual(result.events.first?.isPublicHoliday, true)
        XCTAssertEqual(result.events.first?.isMajor, true)
        XCTAssertEqual(result.events.first?.sortOrder, 3)
        XCTAssertEqual(result.events.first?.recurrence, .other, "Unknown recurrence decodes as .other")

        XCTAssertEqual(result.occurrences.count, 1)
        let occurrence = try XCTUnwrap(result.occurrences.first)
        let parts = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: occurrence.solarDate)
        XCTAssertEqual([parts.year, parts.month, parts.day], [2026, 2, 17])
        XCTAssertEqual(occurrence.lunarDay, 1)
        XCTAssertEqual(occurrence.lunarMonth, 1)
        XCTAssertFalse(occurrence.isLeapMonth)
    }

    func test_loadEvents_mapsRateLimited_withRetryAfter() async {
        network.result = .failure(.apiError(
            code: "RATE_LIMITED", message: "", type: "",
            details: ["retry_after_seconds": AnyCodable(value: 30)]
        ))
        do {
            _ = try await repository.loadEvents(year: 2026)
            XCTFail("Expected .rateLimited")
        } catch {
            guard case .rateLimited(let seconds)? = error as? ILCatalogError else { return XCTFail("Got \(error)") }
            XCTAssertEqual(seconds, 30)
        }
    }

    func test_recurrence_decodesKnownValues() {
        XCTAssertEqual(ILCalendarRecurrence(rawValue: "lunar_monthly"), .lunarMonthly)
        XCTAssertEqual(ILCalendarRecurrence(rawValue: "solar_term"), .solarTerm)
        XCTAssertEqual(ILCalendarRecurrence(rawValue: "x"), .other)
    }

    func test_loadEvents_mapsOfflineAndServerFailures() async {
        network.result = .failure(.noInternetConnection)
        do {
            _ = try await repository.loadEvents(year: 2026)
            XCTFail("Expected .offline")
        } catch {
            guard case .offline? = error as? ILCatalogError else { return XCTFail("Got \(error)") }
        }

        network.result = .failure(.noData)
        do {
            _ = try await repository.loadEvents(year: 2026)
            XCTFail("Expected .loadFailed")
        } catch {
            guard case .loadFailed? = error as? ILCatalogError else { return XCTFail("Got \(error)") }
        }
    }
}
