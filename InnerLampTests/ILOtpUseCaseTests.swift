//
//  ILOtpUseCaseTests.swift
//  InnerLampTests
//
//  Covers the Otp `ILOtpUseCaseImpl`: the real session-persistence path (the network boundary is
//  mocked, the Keychain and the local user store are real), the server-driven initial state, and
//  the deferred voice-call channel.
//

import XCTest
@testable import InnerLamp

final class ILOtpUseCaseTests: XCTestCase {

    private var repository: MockILOtpRepository!
    private var keychainService: KeychainService!
    private var stack: CoreDataStack!
    private var userRepository: ILUserRepository!
    private var sut: ILOtpUseCaseImpl!

    override func setUp() {
        super.setUp()
        repository = MockILOtpRepository()
        keychainService = KeychainServiceImpl()
        stack = CoreDataStack(inMemory: true)
        XCTAssertTrue(stack.isLoaded)
        userRepository = ILUserRepositoryImpl(localDataSource: ILUserLocalDataSourceImpl(stack: stack))

        sut = ILOtpUseCaseImpl(
            repository: repository,
            keychainService: keychainService,
            userRepository: userRepository
        )
    }

    override func tearDown() {
        try? keychainService.delete(key: KeychainAuthTokenProviding.accessTokenKey)
        try? keychainService.delete(key: ILOtpUseCaseImpl.refreshTokenKey)
        sut = nil
        userRepository = nil
        stack = nil
        keychainService = nil
        repository = nil
        super.tearDown()
    }

    // MARK: - getInitialState

    func test_getInitialState_seedsCountdownAndExpiryFromServerTiming() {
        let state = sut.getInitialState(phoneNumber: "0901234567", otpExpiresInSeconds: 90, resendAfterSeconds: 60)

        XCTAssertEqual(state.phoneNumber, "0901234567")
        XCTAssertEqual(state.otpExpiresInSeconds, 90)
        XCTAssertEqual(state.secondsRemaining, 60)
    }

    // MARK: - Verify

    func test_verifyCode_storesAccessTokenRefreshTokenAndUser() async throws {
        repository.verifyResult = ILAuthSessionEntity(
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

        try await sut.verifyCode(phoneNumber: "+84912345678", code: "123456")

        XCTAssertTrue(repository.verifyCalled)
        XCTAssertEqual(repository.verifyPhoneNumber, "+84912345678")
        XCTAssertEqual(repository.verifyCode, "123456")

        // The access token must land under the exact key NetworkService reads.
        let provided = KeychainAuthTokenProviding(keychainService: keychainService)
        XCTAssertEqual(provided.currentToken(), "access-1")
        XCTAssertEqual(try keychainService.loadString(key: ILOtpUseCaseImpl.refreshTokenKey), "refresh-1")

        let storedUser = try await userRepository.loadUser()
        XCTAssertEqual(storedUser?.id, 42)
        XCTAssertEqual(storedUser?.dharmaName, "Diệu Tâm")
    }

    func test_verifyCode_whenRepositoryFails_propagatesTheFeatureError() async {
        repository.verifyError = ILOtpError.invalidCode

        do {
            try await sut.verifyCode(phoneNumber: "+84912345678", code: "000000")
            XCTFail("Expected invalidCode")
        } catch let error as ILOtpError {
            XCTAssertEqual(error, .invalidCode)
        } catch {
            XCTFail("Expected ILOtpError, got \(error)")
        }

        let provided = KeychainAuthTokenProviding(keychainService: keychainService)
        XCTAssertNil(provided.currentToken())
    }

    // MARK: - Resend

    func test_resendCode_sms_returnsServerTiming() async throws {
        repository.resendResult = ILOtpTimingEntity(expiresInSeconds: 90, resendAfterSeconds: 60)

        let timing = try await sut.resendCode(phoneNumber: "+84912345678", channel: .sms)

        XCTAssertEqual(timing, ILOtpTimingEntity(expiresInSeconds: 90, resendAfterSeconds: 60))
        XCTAssertTrue(repository.resendCalled)
        XCTAssertEqual(repository.resendPhoneNumber, "+84912345678")
    }

    func test_resendCode_voiceCall_throwsWithoutCallingTheBackend() async {
        do {
            _ = try await sut.resendCode(phoneNumber: "+84912345678", channel: .voiceCall)
            XCTFail("Expected voiceCallUnsupported")
        } catch let error as ILOtpError {
            XCTAssertEqual(error, .voiceCallUnsupported)
        } catch {
            XCTFail("Expected ILOtpError, got \(error)")
        }

        XCTAssertFalse(repository.resendCalled)
    }
}

// MARK: - Mock ILOtpRepository

final class MockILOtpRepository: ILOtpRepository {

    // MARK: Verify
    var verifyCalled = false
    var verifyPhoneNumber: String?
    var verifyCode: String?
    var verifyResult: ILAuthSessionEntity = .empty
    var verifyError: Error?

    // MARK: Resend
    var resendCalled = false
    var resendPhoneNumber: String?
    var resendResult: ILOtpTimingEntity = .empty
    var resendError: Error?

    func verifyRegistrationOTP(phoneNumber: String, code: String) async throws -> ILAuthSessionEntity {
        verifyCalled = true
        verifyPhoneNumber = phoneNumber
        self.verifyCode = code
        if let verifyError {
            throw verifyError
        }
        return verifyResult
    }

    func resendRegistrationOTP(phoneNumber: String) async throws -> ILOtpTimingEntity {
        resendCalled = true
        resendPhoneNumber = phoneNumber
        if let resendError {
            throw resendError
        }
        return resendResult
    }
}
