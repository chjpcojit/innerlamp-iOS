//
//  ILProfileLogoutTests.swift
//  InnerLampTests
//
//  `POST /v1/auth/logout`: endpoint shape, repository call, and `ILProfileUseCaseImpl.logout()` —
//  best-effort revoke, then the stored tokens and local user are cleared (real Keychain, in-memory
//  Core Data; the network boundary is stubbed).
//

import XCTest
@testable import InnerLamp

@MainActor
final class ILProfileLogoutTests: XCTestCase {

    private var keychainService: KeychainService!
    private var userRepository: ILUserRepository!
    private var memorialDataSource: ILMemorialLocalDataSource!
    private var birthProfileDataSource: ILUserBirthProfileLocalDataSource!
    private var lampDataSource: ILLampLocalDataSource!
    private var defaults: UserDefaultsService!
    private let defaultsKey = "test.logout.accountScopedKey"
    private var logoutRepository: SpyLogoutRepository!
    private var sut: ILProfileUseCaseImpl!

    override func setUp() async throws {
        try await super.setUp()
        keychainService = KeychainServiceImpl()
        let stack = CoreDataStack(inMemory: true)
        XCTAssertTrue(stack.isLoaded)
        userRepository = ILUserRepositoryImpl(localDataSource: ILUserLocalDataSourceImpl(stack: stack))
        memorialDataSource = ILMemorialLocalDataSourceImpl(stack: stack)
        birthProfileDataSource = ILUserBirthProfileLocalDataSourceImpl(stack: stack)
        lampDataSource = ILLampLocalDataSourceImpl(stack: stack)
        defaults = UserDefaultsServiceImpl()
        logoutRepository = SpyLogoutRepository()
        sut = ILProfileUseCaseImpl(
            accountRepository: UnusedAccountRepository(),
            logoutRepository: logoutRepository,
            keychainService: keychainService,
            sessionDataCleaner: ILSessionDataCleanerImpl(stack: stack),
            userDefaultsService: defaults,
            accountScopedDefaultsKeys: [defaultsKey]
        )
    }

    override func tearDown() async throws {
        try? keychainService.delete(key: KeychainAuthTokenProviding.accessTokenKey)
        try? keychainService.delete(key: KeychainAuthTokenProviding.refreshTokenKey)
        defaults.remove(key: defaultsKey)
        sut = nil
        logoutRepository = nil
        userRepository = nil
        keychainService = nil
        try await super.tearDown()
    }

    private func storeSession() async throws {
        try keychainService.save(key: KeychainAuthTokenProviding.accessTokenKey, value: "access-1")
        try keychainService.save(key: KeychainAuthTokenProviding.refreshTokenKey, value: "refresh-1")
        try await userRepository.saveUser(ILUserEntity(
            id: 42, email: "an@example.com", phoneNumber: "+84912345678", dharmaName: "Diệu Tâm", ordinationTempleID: ""
        ))
        try await memorialDataSource.upsert(ILMemorialTestFactory.entry())
        try await birthProfileDataSource.saveBirthProfile(ILUserBirthProfileEntity(
            solarBirthDate: Date(timeIntervalSince1970: 1_000_000_000),
            lunarYear: 1990, canIndex: 6, chiIndex: 6, element: .tho
        ))
        try await lampDataSource.upsert(ILLampEntity(
            id: "lamp-1", kind: .oil, intention: .peace, target: "", vow: "",
            durationDays: 7, litAt: Date(timeIntervalSince1970: 1_000_000_000)
        ))
        defaults.save(key: defaultsKey, value: "temple-123")
    }

    // MARK: - Endpoint / repository

    func test_endpoint_isAuthenticatedPostOnAuthLogout() {
        let endpoint = LogoutEndpoint()

        XCTAssertEqual(endpoint.path, "/v1/auth/logout")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertTrue(endpoint.requiresAuth)
        XCTAssertNil(endpoint.body)
    }

    func test_repository_postsToLogoutPath() async throws {
        let network = MockCatalogNetworkService()

        try await ILLogoutRepositoryImpl(networkService: network).revokeSession()

        XCTAssertEqual(network.requestedRoutes, ["/v1/auth/logout"])
    }

    // MARK: - Use case

    func test_logout_revokesThenClearsTokensAndLocalUser() async throws {
        try await storeSession()

        try await sut.logout()

        XCTAssertEqual(logoutRepository.revokeCallCount, 1)
        XCTAssertNil(KeychainAuthTokenProviding(keychainService: keychainService).currentToken())
        XCTAssertNil(try? keychainService.loadString(key: KeychainAuthTokenProviding.refreshTokenKey))
        let storedUser = try await userRepository.loadUser()
        XCTAssertNil(storedUser)
    }

    func test_logout_clearsAccountScopedLocalData() async throws {
        try await storeSession()

        try await sut.logout()

        let memorials = try await memorialDataSource.fetchAll()
        let birthProfile = try await birthProfileDataSource.fetchBirthProfile()
        XCTAssertTrue(memorials.isEmpty)
        let lamps = try await lampDataSource.fetchAll()
        XCTAssertNil(birthProfile)
        XCTAssertTrue(lamps.isEmpty)
        XCTAssertFalse(defaults.exists(key: defaultsKey))
    }

    func test_logout_whenRevokeFails_stillClearsTheLocalSession() async throws {
        try await storeSession()
        logoutRepository.error = NetworkError.noInternetConnection

        try await sut.logout()

        XCTAssertEqual(logoutRepository.revokeCallCount, 1)
        XCTAssertNil(KeychainAuthTokenProviding(keychainService: keychainService).currentToken())
        let storedUser = try await userRepository.loadUser()
        XCTAssertNil(storedUser)
    }

    func test_logout_withoutStoredSession_skipsRevokeAndSucceeds() async throws {
        try await sut.logout()

        XCTAssertEqual(logoutRepository.revokeCallCount, 0)
    }
}

private final class SpyLogoutRepository: ILLogoutRepository {
    var error: Error?
    private(set) var revokeCallCount = 0

    func revokeSession() async throws {
        revokeCallCount += 1
        if let error { throw error }
    }
}

private struct UnusedAccountRepository: ILAccountProfileRepository {
    func loadAccountProfile() async throws -> ILAccountProfileEntity { throw ILAccountProfileError.loadFailed }
}
