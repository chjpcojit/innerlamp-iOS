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

    func test_validateEmail_emptyOrWhitespace_returnsRequiredError() {
        XCTAssertNotNil(sut.validateEmail(""))
        XCTAssertNotNil(sut.validateEmail("   "))
    }

    func test_validateEmail_nonEmpty_passesWithoutFormatCheck() {
        // EN: Criterion 2 only checks emptiness; the server answers INVALID_EMAIL for a bad format.
        // VI: Tiêu chí 2 chỉ kiểm tra rỗng; server trả INVALID_EMAIL khi sai định dạng.
        XCTAssertNil(sut.validateEmail("an@example.com"))
        XCTAssertNil(sut.validateEmail("not-an-email"))
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
                ordinationTempleID: "temple_north_011"
            )
        )

        let credential = ILLoginEntity(email: "an@example.com", password: "secret12")
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
            try await sut.login(ILLoginEntity(email: "an@example.com", password: "wrongpass"))
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
