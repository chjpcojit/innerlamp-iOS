//
//  AuthSessionRefresherTests.swift
//  InnerLampTests
//
//  Covers TD-Core-001: 401 → refresh → single retry in `NetworkServiceImpl`, and the single-flight
//  / expiry behaviour of `AuthSessionRefresher`. Uses a dedicated Keychain service name so the
//  real session keys of a dev build are never touched.
//

import XCTest
@testable import InnerLamp

final class AuthSessionRefresherTests: XCTestCase {

    private var keychain: KeychainService!
    private var counter: RequestCounter!
    private var expiredNotifications = 0
    private var observer: NSObjectProtocol?

    override func setUp() {
        super.setUp()
        MockURLProtocol.requestHandler = nil
        MockURLProtocol.onRequest = nil
        keychain = KeychainServiceImpl(service: "tests.vn.weedigital.InnerLamp.refresh")
        counter = RequestCounter()
        expiredNotifications = 0
        observer = NotificationCenter.default.addObserver(
            forName: .authSessionDidExpire, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.expiredNotifications += 1 }
        }
        clearSession()
    }

    override func tearDown() {
        clearSession()
        if let observer { NotificationCenter.default.removeObserver(observer) }
        MockURLProtocol.requestHandler = nil
        MockURLProtocol.onRequest = nil
        super.tearDown()
    }

    // MARK: - Refresher

    func test_refresh_success_storesRotatedPair() async throws {
        seedSession(access: "old-access", refresh: "old-refresh")
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/v1/auth/refresh")
            XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
            return (200, Self.refreshBody(access: "new-access", refresh: "new-refresh"))
        }

        try await makeRefresher().refreshSession(afterRejectedToken: "old-access")

        XCTAssertEqual(try keychain.loadString(key: KeychainAuthTokenProviding.accessTokenKey), "new-access")
        XCTAssertEqual(try keychain.loadString(key: KeychainAuthTokenProviding.refreshTokenKey), "new-refresh")
        XCTAssertEqual(expiredNotifications, 0)
    }

    func test_refresh_rejected401_clearsSessionAndPostsNotification() async throws {
        seedSession(access: "old-access", refresh: "old-refresh")
        MockURLProtocol.stub(statusCode: 401, body: #"{"success":false,"error":{"code":"REFRESH_TOKEN_INVALID","message":"x","type":"business"}}"#)

        do {
            try await makeRefresher().refreshSession(afterRejectedToken: "old-access")
            XCTFail("Expected unauthorized")
        } catch NetworkError.unauthorized {
            // expected
        }

        XCTAssertFalse(keychain.exists(key: KeychainAuthTokenProviding.accessTokenKey))
        XCTAssertFalse(keychain.exists(key: KeychainAuthTokenProviding.refreshTokenKey))
        await Task.yield()
        XCTAssertEqual(expiredNotifications, 1)
    }

    func test_refresh_serverError_keepsSessionAndDoesNotExpire() async throws {
        seedSession(access: "old-access", refresh: "old-refresh")
        MockURLProtocol.stub(statusCode: 500, body: "boom")

        do {
            try await makeRefresher().refreshSession(afterRejectedToken: "old-access")
            XCTFail("Expected serverError")
        } catch NetworkError.serverError {
            // expected
        }

        XCTAssertEqual(try keychain.loadString(key: KeychainAuthTokenProviding.refreshTokenKey), "old-refresh")
        XCTAssertEqual(expiredNotifications, 0)
    }

    func test_refresh_noRefreshToken_expiresWithoutCallingServer() async throws {
        MockURLProtocol.stub(statusCode: 200, body: "{}", onRequest: { [counter] _ in counter?.increment() })

        do {
            try await makeRefresher().refreshSession(afterRejectedToken: "whatever")
            XCTFail("Expected unauthorized")
        } catch NetworkError.unauthorized {
            // expected
        }

        XCTAssertEqual(counter.value, 0)
        await Task.yield()
        XCTAssertEqual(expiredNotifications, 1)
    }

    func test_refresh_tokenAlreadyReplaced_skipsServerCall() async throws {
        seedSession(access: "newer-access", refresh: "newer-refresh")
        MockURLProtocol.stub(statusCode: 200, body: "{}", onRequest: { [counter] _ in counter?.increment() })

        try await makeRefresher().refreshSession(afterRejectedToken: "stale-access")

        XCTAssertEqual(counter.value, 0)
    }

    func test_refresh_concurrentCalls_shareOneServerCall() async throws {
        seedSession(access: "old-access", refresh: "old-refresh")
        MockURLProtocol.stub(
            statusCode: 200,
            body: Self.refreshBody(access: "new-access", refresh: "new-refresh"),
            onRequest: { [counter] _ in counter?.increment() }
        )
        let refresher = makeRefresher()

        async let first: Void = refresher.refreshSession(afterRejectedToken: "old-access")
        async let second: Void = refresher.refreshSession(afterRejectedToken: "old-access")
        _ = try await (first, second)

        XCTAssertEqual(counter.value, 1)
    }

    // MARK: - NetworkServiceImpl integration

    func test_network_401_refreshesThenRetriesOnceWithNewToken() async throws {
        seedSession(access: "old-access", refresh: "old-refresh")
        MockURLProtocol.requestHandler = { request in
            if request.url?.path == "/v1/auth/refresh" {
                return (200, Self.refreshBody(access: "new-access", refresh: "new-refresh"))
            }
            switch request.value(forHTTPHeaderField: "Authorization") {
            case "Bearer new-access":
                return (200, #"{"success": true, "data": {"name": "Alice"}}"#)
            default:
                return (401, "")
            }
        }

        let value = try await makeNetworkService().request(endpoint: AuthTestEndpoint(), responseType: AuthTestPerson.self)

        XCTAssertEqual(value.name, "Alice")
    }

    func test_network_401AfterRetry_throwsUnauthorizedWithoutLooping() async throws {
        seedSession(access: "old-access", refresh: "old-refresh")
        MockURLProtocol.requestHandler = { request in
            if request.url?.path == "/v1/auth/refresh" {
                return (200, Self.refreshBody(access: "new-access", refresh: "new-refresh"))
            }
            self.counter.increment()
            return (401, "")
        }

        do {
            _ = try await makeNetworkService().request(endpoint: AuthTestEndpoint(), responseType: AuthTestPerson.self)
            XCTFail("Expected unauthorized")
        } catch NetworkError.unauthorized {
            // expected
        }

        XCTAssertEqual(counter.value, 2, "original request + exactly one retry")
    }

    func test_network_401_refreshRejected_throwsUnauthorizedAndDoesNotRetry() async throws {
        seedSession(access: "old-access", refresh: "old-refresh")
        MockURLProtocol.requestHandler = { request in
            if request.url?.path != "/v1/auth/refresh" { self.counter.increment() }
            return (401, "")
        }

        do {
            _ = try await makeNetworkService().request(endpoint: AuthTestEndpoint(), responseType: AuthTestPerson.self)
            XCTFail("Expected unauthorized")
        } catch NetworkError.unauthorized {
            // expected
        }

        XCTAssertEqual(counter.value, 1)
        XCTAssertFalse(keychain.exists(key: KeychainAuthTokenProviding.accessTokenKey))
    }

    func test_network_401_publicEndpoint_neverRefreshes() async throws {
        seedSession(access: "old-access", refresh: "old-refresh")
        MockURLProtocol.requestHandler = { request in
            self.counter.increment()
            return (401, "")
        }

        do {
            _ = try await makeNetworkService().request(
                endpoint: AuthTestEndpoint(requiresAuth: false),
                responseType: AuthTestPerson.self
            )
            XCTFail("Expected unauthorized")
        } catch NetworkError.unauthorized {
            // expected
        }

        XCTAssertEqual(counter.value, 1)
        XCTAssertEqual(try keychain.loadString(key: KeychainAuthTokenProviding.refreshTokenKey), "old-refresh")
    }

    func test_network_401_noStoredToken_neverRefreshes() async throws {
        MockURLProtocol.requestHandler = { request in
            self.counter.increment()
            return (401, "")
        }

        do {
            _ = try await makeNetworkService().request(endpoint: AuthTestEndpoint(), responseType: AuthTestPerson.self)
            XCTFail("Expected unauthorized")
        } catch NetworkError.unauthorized {
            // expected
        }

        XCTAssertEqual(counter.value, 1)
        XCTAssertEqual(expiredNotifications, 0)
    }

    // MARK: - Helpers

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func makeRefresher() -> AuthSessionRefresher {
        AuthSessionRefresher(
            keychainService: keychain,
            networkService: NetworkServiceImpl(
                session: makeSession(),
                authTokenProvider: KeychainAuthTokenProviding(keychainService: keychain),
                logger: MockNetworkLogging()
            )
        )
    }

    private func makeNetworkService() -> NetworkServiceImpl {
        let tokenProvider = KeychainAuthTokenProviding(keychainService: keychain)
        return NetworkServiceImpl(
            session: makeSession(),
            authTokenProvider: tokenProvider,
            logger: MockNetworkLogging(),
            sessionRefresher: makeRefresher()
        )
    }

    private func seedSession(access: String, refresh: String) {
        try? keychain.save(key: KeychainAuthTokenProviding.accessTokenKey, value: access)
        try? keychain.save(key: KeychainAuthTokenProviding.refreshTokenKey, value: refresh)
    }

    private func clearSession() {
        try? keychain.delete(key: KeychainAuthTokenProviding.accessTokenKey)
        try? keychain.delete(key: KeychainAuthTokenProviding.refreshTokenKey)
    }

    private static func refreshBody(access: String, refresh: String) -> String {
        #"{"success": true, "data": {"access_token": "\#(access)", "refresh_token": "\#(refresh)"}}"#
    }
}

private struct AuthTestPerson: Decodable, Sendable {
    let name: String
}

private struct AuthTestEndpoint: Endpoint {
    var baseURL: String = "https://example.com"
    var path: String = "/test"
    var method: HTTPMethod = .get
    var requiresAuth: Bool = true
}

/// Request handlers run on `URLProtocol`'s own thread, so the count needs a lock.
private final class RequestCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    func increment() {
        lock.lock(); defer { lock.unlock() }
        count += 1
    }

    var value: Int {
        lock.lock(); defer { lock.unlock() }
        return count
    }
}
