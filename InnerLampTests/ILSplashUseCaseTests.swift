//
//  ILSplashUseCaseTests.swift
//  InnerLampTests
//
//  Covers `hasSession()` and the fresh-install Keychain wipe (TD-Splash-001). Uses a dedicated
//  Keychain service name so a dev build's real session is never touched.
//

import XCTest
@testable import InnerLamp

final class ILSplashUseCaseTests: XCTestCase {

    private var keychain: KeychainService!
    private var defaults: InMemorySplashDefaults!
    private var sut: ILSplashUseCaseImpl!

    override func setUp() {
        super.setUp()
        keychain = KeychainServiceImpl(service: "tests.vn.weedigital.InnerLamp.splash")
        defaults = InMemorySplashDefaults()
        sut = ILSplashUseCaseImpl(
            onboardingUseCase: ILOnboardingUseCaseImpl(userDefaultsService: defaults),
            keychainService: keychain,
            userDefaultsService: defaults
        )
        clearSession()
    }

    override func tearDown() {
        clearSession()
        sut = nil
        defaults = nil
        keychain = nil
        super.tearDown()
    }

    func test_hasSession_freshInstallWithLeftoverKeychainToken_returnsFalseAndWipesIt() throws {
        try keychain.save(key: KeychainAuthTokenProviding.accessTokenKey, value: "leftover")
        try keychain.save(key: KeychainAuthTokenProviding.refreshTokenKey, value: "leftover")

        XCTAssertFalse(sut.hasSession())
        XCTAssertFalse(keychain.exists(key: KeychainAuthTokenProviding.refreshTokenKey))
    }

    func test_hasSession_afterFirstLaunch_keepsStoredSession() throws {
        XCTAssertFalse(sut.hasSession())   // first launch sets the flag
        try keychain.save(key: KeychainAuthTokenProviding.accessTokenKey, value: "token")

        XCTAssertTrue(sut.hasSession())
    }

    func test_hasSession_removesLegacyPendingSignUpCredentials() throws {
        let legacyKey = "signup_pending_credentials"
        try keychain.save(key: legacyKey, value: #"{"displayName":"A","phoneNumber":"0900000000","password":"secret"}"#)
        XCTAssertTrue(keychain.exists(key: legacyKey))

        _ = sut.hasSession()

        XCTAssertFalse(keychain.exists(key: legacyKey))
    }

    func test_hasSession_noToken_returnsFalse() {
        XCTAssertFalse(sut.hasSession())
        XCTAssertFalse(sut.hasSession())
    }

    private func clearSession() {
        try? keychain.delete(key: KeychainAuthTokenProviding.accessTokenKey)
        try? keychain.delete(key: KeychainAuthTokenProviding.refreshTokenKey)
        try? keychain.delete(key: "signup_pending_credentials")
    }
}

final class InMemorySplashDefaults: UserDefaultsService {
    private var store: [String: Data] = [:]

    func save<T: Codable>(key: String, value: T) { store[key] = try? JSONEncoder().encode(value) }
    func load<T: Codable>(key: String, type: T.Type) -> T? {
        store[key].flatMap { try? JSONDecoder().decode(T.self, from: $0) }
    }
    func remove(key: String) { store[key] = nil }
    func exists(key: String) -> Bool { store[key] != nil }
}
