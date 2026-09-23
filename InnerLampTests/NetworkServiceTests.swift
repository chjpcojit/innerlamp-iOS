//
//  NetworkServiceTests.swift
//  InnerLampTests
//
//  Covers Docs/Specs/Networking/tasks.md Phase 1 (envelope), Phase 2 (auth header), and the
//  logging/classification behaviour that both phases route through.
//

import XCTest
@testable import InnerLamp

final class NetworkServiceTests: XCTestCase {

    private var mockLogger: MockNetworkLogging!
    private var mockAuthTokenProvider: MockAuthTokenProviding!

    override func setUp() {
        super.setUp()
        MockURLProtocol.requestHandler = nil
        mockLogger = MockNetworkLogging()
        mockAuthTokenProvider = MockAuthTokenProviding()
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        mockLogger = nil
        mockAuthTokenProvider = nil
        super.tearDown()
    }

    private func makeSUT() -> NetworkServiceImpl {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)

        return NetworkServiceImpl(
            session: session,
            authTokenProvider: mockAuthTokenProvider,
            logger: mockLogger
        )
    }

    // MARK: - Envelope matrix (Phase 1)

    func test_standardEnvelope_successWithData_returnsUnwrappedValue() async throws {
        let json = """
        {"success": true, "data": {"name": "Alice"}}
        """
        MockURLProtocol.stub(statusCode: 200, body: json)

        let sut = makeSUT()
        let value = try await sut.request(endpoint: TestEndpoint(), responseType: Person.self)

        XCTAssertEqual(value.name, "Alice")
        XCTAssertEqual(mockLogger.records.count, 1)
        XCTAssertNil(mockLogger.records.first?.failureClassification)
    }

    func test_standardEnvelope_successFalse_throwsApiError() async throws {
        let json = """
        {"success": false, "error": {"code": "ERR_1", "message": "bad", "type": "validation"}}
        """
        MockURLProtocol.stub(statusCode: 200, body: json)

        let sut = makeSUT()
        do {
            _ = try await sut.request(endpoint: TestEndpoint(), responseType: Person.self)
            XCTFail("Expected apiError")
        } catch NetworkError.apiError(let code, let message, let type, let details) {
            XCTAssertEqual(code, "ERR_1")
            XCTAssertEqual(message, "bad")
            XCTAssertEqual(type, "validation")
            XCTAssertNil(details)
        }

        XCTAssertEqual(mockLogger.records.first?.failureClassification, "apiError(ERR_1)")
    }

    func test_apiError_carriesEnvelopeDetails() async throws {
        let json = """
        {"success": false, "error": {"code": "OTP_LOCKED", "message": "locked", "type": "business"},
         "details": {"locked_until": "2026-09-22T10:30:00Z", "retry_after_seconds": 30}}
        """
        MockURLProtocol.stub(statusCode: 429, body: json)

        let sut = makeSUT()
        do {
            _ = try await sut.request(endpoint: TestEndpoint(), responseType: Person.self)
            XCTFail("Expected apiError")
        } catch NetworkError.apiError(let code, _, _, let details) {
            XCTAssertEqual(code, "OTP_LOCKED")
            XCTAssertEqual(details?["locked_until"]?.value as? String, "2026-09-22T10:30:00Z")
            XCTAssertEqual(details?["retry_after_seconds"]?.value as? Int, 30)
        }
    }

    func test_standardEnvelope_2xxUnparseableBody_throwsServerErrorWithNilMessage() async throws {
        MockURLProtocol.stub(statusCode: 200, body: "not json")

        let sut = makeSUT()
        do {
            _ = try await sut.request(endpoint: TestEndpoint(), responseType: Person.self)
            XCTFail("Expected serverError")
        } catch NetworkError.serverError(let statusCode, let message) {
            XCTAssertEqual(statusCode, 200)
            XCTAssertNil(message)
        }
    }

    func test_standardEnvelope_successTrueDataAbsent_throwsNoData() async throws {
        let json = """
        {"success": true}
        """
        MockURLProtocol.stub(statusCode: 200, body: json)

        let sut = makeSUT()
        do {
            _ = try await sut.request(endpoint: TestEndpoint(), responseType: Person.self)
            XCTFail("Expected noData")
        } catch NetworkError.noData {
            // expected
        }
    }

    func test_bareEnvelope_decodesDirectly() async throws {
        let json = """
        {"name": "Bob"}
        """
        MockURLProtocol.stub(statusCode: 200, body: json)

        let sut = makeSUT()
        let value = try await sut.request(endpoint: TestEndpoint(responseEnvelope: .bare), responseType: Person.self)

        XCTAssertEqual(value.name, "Bob")
    }

    func test_4xxWithEnvelopeBody_throwsApiError() async throws {
        let json = """
        {"success": false, "error": {"code": "NOT_FOUND", "message": "missing", "type": "not_found"}}
        """
        MockURLProtocol.stub(statusCode: 404, body: json)

        let sut = makeSUT()
        do {
            _ = try await sut.request(endpoint: TestEndpoint(), responseType: Person.self)
            XCTFail("Expected apiError")
        } catch NetworkError.apiError(let code, _, _, _) {
            XCTAssertEqual(code, "NOT_FOUND")
        }
    }

    func test_5xxWithoutEnvelopeBody_throwsServerError() async throws {
        MockURLProtocol.stub(statusCode: 500, body: "internal error")

        let sut = makeSUT()
        do {
            _ = try await sut.request(endpoint: TestEndpoint(), responseType: Person.self)
            XCTFail("Expected serverError")
        } catch NetworkError.serverError(let statusCode, let message) {
            XCTAssertEqual(statusCode, 500)
            XCTAssertNil(message)
        }
    }

    func test_401_throwsUnauthorizedBeforeEnvelopeDecoding() async throws {
        MockURLProtocol.stub(statusCode: 401, body: "")

        let sut = makeSUT()
        do {
            _ = try await sut.request(endpoint: TestEndpoint(), responseType: Person.self)
            XCTFail("Expected unauthorized")
        } catch NetworkError.unauthorized {
            // expected
        }
    }

    // MARK: - Auth header (Phase 2)

    func test_authHeader_tokenPresent_attachesBearerHeader() async throws {
        mockAuthTokenProvider.token = "secret-token"
        var capturedRequest: URLRequest?
        MockURLProtocol.stub(statusCode: 200, body: #"{"success": true, "data": {"name": "A"}}"#) { request in
            capturedRequest = request
        }

        let sut = makeSUT()
        _ = try await sut.request(endpoint: TestEndpoint(), responseType: Person.self)

        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer secret-token")
    }

    func test_authHeader_noToken_omitsHeaderAndStillSendsRequest() async throws {
        mockAuthTokenProvider.token = nil
        var capturedRequest: URLRequest?
        MockURLProtocol.stub(statusCode: 200, body: #"{"success": true, "data": {"name": "A"}}"#) { request in
            capturedRequest = request
        }

        let sut = makeSUT()
        let value = try await sut.request(endpoint: TestEndpoint(), responseType: Person.self)

        XCTAssertNil(capturedRequest?.value(forHTTPHeaderField: "Authorization"))
        XCTAssertEqual(value.name, "A")
    }

    func test_authHeader_endpointDeclaresOwnValue_winsOverStoredToken() async throws {
        mockAuthTokenProvider.token = "stored-token"
        var capturedRequest: URLRequest?
        MockURLProtocol.stub(statusCode: 200, body: #"{"success": true, "data": {"name": "A"}}"#) { request in
            capturedRequest = request
        }

        let sut = makeSUT()
        _ = try await sut.request(
            endpoint: TestEndpoint(headers: ["Authorization": "Custom own-value"]),
            responseType: Person.self
        )

        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Authorization"), "Custom own-value")
    }

    func test_authHeader_requiresAuthFalse_neverAttachesEvenWithValidToken() async throws {
        mockAuthTokenProvider.token = "stored-token"
        var capturedRequest: URLRequest?
        MockURLProtocol.stub(statusCode: 200, body: #"{"success": true, "data": {"name": "A"}}"#) { request in
            capturedRequest = request
        }

        let sut = makeSUT()
        _ = try await sut.request(endpoint: TestEndpoint(requiresAuth: false), responseType: Person.self)

        XCTAssertNil(capturedRequest?.value(forHTTPHeaderField: "Authorization"))
    }

    // MARK: - Logging

    func test_logging_bearerTokenNeverAppearsInEmittedRecord() async throws {
        mockAuthTokenProvider.token = "super-secret-token"
        MockURLProtocol.stub(statusCode: 200, body: #"{"success": true, "data": {"name": "A"}}"#)

        let sut = makeSUT()
        _ = try await sut.request(endpoint: TestEndpoint(), responseType: Person.self)

        XCTAssertFalse(mockLogger.records.contains { $0.path.contains("super-secret-token") })
    }

    func test_logging_failureLogsClassificationNotRawBody() async throws {
        MockURLProtocol.stub(statusCode: 500, body: "some raw body with sensitive info")

        let sut = makeSUT()
        _ = try? await sut.request(endpoint: TestEndpoint(), responseType: Person.self)

        XCTAssertEqual(mockLogger.records.first?.failureClassification, "serverError(500)")
    }

    // MARK: - Session configuration (Phase 3)

    func test_networkConfiguration_usesExplicitTimeoutsInsteadOfSharedDefaults() {
        let configuration = NetworkConfiguration.makeConfiguration()

        XCTAssertEqual(configuration.timeoutIntervalForRequest, 30)
        XCTAssertEqual(configuration.timeoutIntervalForResource, 60)
        XCTAssertFalse(configuration.waitsForConnectivity)
    }
}

// MARK: - Test fixtures

private struct Person: Decodable {
    let name: String
}

private struct TestEndpoint: Endpoint {
    var baseURL: String = "https://example.com"
    var path: String = "/test"
    var method: HTTPMethod = .get
    var headers: [String: String]? = nil
    var responseEnvelope: ResponseEnvelope = .standard
    var requiresAuth: Bool = true
}

// MARK: - Mocks

final class MockAuthTokenProviding: AuthTokenProviding {
    var token: String?
    func currentToken() -> String? { token }
}

final class MockNetworkLogging: NetworkLogging {
    struct Record {
        let method: String
        let path: String
        let statusCode: Int?
        let duration: TimeInterval
        let failureClassification: String?
    }

    private(set) var records: [Record] = []

    func log(method: String, path: String, statusCode: Int?, duration: TimeInterval, failureClassification: String?) {
        records.append(Record(method: method, path: path, statusCode: statusCode, duration: duration, failureClassification: failureClassification))
    }
}

/// Intercepts `URLSession` requests in tests so no live network call is made — substitutes both
/// the response and (via `onRequest`) lets a test inspect the outgoing `URLRequest` (e.g. headers).
final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) -> (Int, String))?
    static var onRequest: ((URLRequest) -> Void)?

    static func stub(statusCode: Int, body: String, onRequest: ((URLRequest) -> Void)? = nil) {
        requestHandler = { _ in (statusCode, body) }
        self.onRequest = onRequest
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.onRequest?(request)

        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        let (statusCode, body) = handler(request)
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body.data(using: .utf8)!)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
