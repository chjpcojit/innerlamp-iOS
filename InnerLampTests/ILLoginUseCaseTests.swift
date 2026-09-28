//
//  ILLoginUseCaseTests.swift
//  InnerLampTests
//
//  Covers the Login `ILLoginUseCaseImpl`: the real session-persistence path (the network boundary
//  is mocked via `MockILLoginRepository`, the Keychain and the local user store are real) and
//  error propagation when the repository call fails. `ILLoginViewModelTests` keeps covering
//  validation/navigation via `MockILLoginUseCase`.
//

import XCTest
@testable import InnerLamp

final class ILLoginUseCaseTests: XCTestCase {

    private var repository: MockILLoginRepository!
    private var keychainService: KeychainService!
    private var stack: CoreDataStack!
    private var userRepository: ILUserRepository!
    private var sut: ILLoginUseCaseImpl!

    override func setUp() {
        super.setUp()
        repository = MockILLoginRepository()
        keychainService = KeychainServiceImpl()
        stack = CoreDataStack(inMemory: true)
        XCTAssertTrue(stack.isLoaded)
        userRepository = ILUserRepositoryImpl(localDataSource: ILUserLocalDataSourceImpl(stack: stack))

        sut = ILLoginUseCaseImpl(
            repository: repository,
            keychainService: keychainService,
            userRepository: userRepository
        )
    }

    override func tearDown() {
        try? keychainService.delete(key: KeychainAuthTokenProviding.accessTokenKey)
        try? keychainService.delete(key: KeychainAuthTokenProviding.refreshTokenKey)
        sut = nil
        userRepository = nil
        stack = nil
        keychainService = nil
        repository = nil
        super.tearDown()
    }

    // MARK: - Validation (pure, no repository call)

    func test_validatePhone_empty_returnsRequiredError() {
        XCTAssertNotNil(sut.validatePhone(nationalDigits: "", country: .default))
    }

    func test_validatePassword_empty_returnsRequiredError() {
        XCTAssertNotNil(sut.validatePassword(""))
    }

    // MARK: - Login

    func test_login_storesAccessTokenRefreshTokenAndUser() async throws {
        repository.loginResult = ILAuthSessionEntity(
            accessToken: "access-1",
            refreshToken: "refresh-1",
            user: ILUserEntity(
                id: 42,
                email: "an@example.com",
                phoneNumber: "+84912345678",
                dharmaName: "Diệu Tâm",
                ordinationPlace: "Chùa Linh Ứng"
            )
        )

        let credential = ILLoginEntity(phone: "+84 912 345 678", password: "secret12")
        try await sut.login(credential)

        XCTAssertTrue(repository.loginCalled)
        XCTAssertEqual(repository.loggedInEntity, credential)

        // The access token must land under the exact key NetworkService reads.
        let provided = KeychainAuthTokenProviding(keychainService: keychainService)
        XCTAssertEqual(provided.currentToken(), "access-1")
        XCTAssertEqual(try keychainService.loadString(key: KeychainAuthTokenProviding.refreshTokenKey), "refresh-1")

        let storedUser = try await userRepository.loadUser()
        XCTAssertEqual(storedUser?.id, 42)
        XCTAssertEqual(storedUser?.dharmaName, "Diệu Tâm")
    }

    func test_login_whenRepositoryFails_propagatesTheFeatureErrorWithoutStoringASession() async {
        repository.loginError = ILLoginError.invalidCredentials

        do {
            try await sut.login(ILLoginEntity(phone: "+84 912 345 678", password: "wrongpass"))
            XCTFail("Expected invalidCredentials")
        } catch let error as ILLoginError {
            XCTAssertEqual(error, .invalidCredentials)
        } catch {
            XCTFail("Expected ILLoginError, got \(error)")
        }

        let provided = KeychainAuthTokenProviding(keychainService: keychainService)
        XCTAssertNil(provided.currentToken())
    }
}

// MARK: - Mock ILLoginRepository

final class MockILLoginRepository: ILLoginRepository {
    var loginCalled = false
    var loggedInEntity: ILLoginEntity?
    var loginResult: ILAuthSessionEntity = .empty
    var loginError: Error?

    func login(_ entity: ILLoginEntity) async throws -> ILAuthSessionEntity {
        loginCalled = true
        loggedInEntity = entity
        if let loginError {
            throw loginError
        }
        return loginResult
    }
}
