//
//  ILOtpRepositoryTests.swift
//  InnerLampTests
//
//  Covers the Otp Data-layer pieces: the request DTOs' snake_case encoding, the response DTOs'
//  decoding under `.convertFromSnakeCase`, the DTO→Entity mapper, and the operation-aware
//  `NetworkError` → `ILOtpError` mapping.
//

import XCTest
@testable import InnerLamp

final class ILOtpRepositoryTests: XCTestCase {

    // MARK: - Error mapping: shared / transport

    func test_from_noInternet_mapsToNetworkUnavailable() {
        XCTAssertEqual(ILOtpError.from(.noInternetConnection, operation: .verify), .networkUnavailable)
        XCTAssertEqual(ILOtpError.from(.noInternetConnection, operation: .resend), .networkUnavailable)
    }

    func test_from_timeout_mapsToTimedOut() {
        XCTAssertEqual(ILOtpError.from(.timeout, operation: .verify), .timedOut)
    }

    func test_from_phoneTaken_mapsToPhoneTaken() {
        XCTAssertEqual(ILOtpError.from(apiError("PHONE_TAKEN"), operation: .verify), .phoneTaken)
        XCTAssertEqual(ILOtpError.from(apiError("PHONE_TAKEN"), operation: .resend), .phoneTaken)
    }

    func test_from_emailTaken_mapsToEmailTaken() {
        XCTAssertEqual(ILOtpError.from(apiError("EMAIL_TAKEN"), operation: .verify), .emailTaken)
    }

    func test_from_otpLocked_carriesLockedUntilOnBothOperations() {
        let error = ILOtpError.from(
            apiError("OTP_LOCKED", details: ["locked_until": AnyCodable(value: "2026-09-23T10:30:00Z")]),
            operation: .verify
        )
        XCTAssertEqual(error, .otpLocked(lockedUntil: "2026-09-23T10:30:00Z"))
    }

    func test_from_validationCodes_mapToInvalidInput() {
        for code in ["VALIDATION_ERROR", "INVALID_EMAIL", "INVALID_PHONE", "INVALID_PASSWORD", "PAYLOAD_TOO_LARGE"] {
            XCTAssertEqual(ILOtpError.from(apiError(code), operation: .verify), .invalidInput, "code: \(code)")
        }
    }

    func test_from_transportFailures_mapToServer() {
        XCTAssertEqual(ILOtpError.from(.unauthorized, operation: .verify), .server)
        XCTAssertEqual(ILOtpError.from(.serverError(statusCode: 500, message: nil), operation: .resend), .server)
    }

    // MARK: - Error mapping: verify-only codes

    func test_from_verify_otpInvalid_mapsToInvalidCode() {
        XCTAssertEqual(ILOtpError.from(apiError("OTP_INVALID"), operation: .verify), .invalidCode)
    }

    func test_from_verify_otpExpired_mapsToCodeExpired() {
        XCTAssertEqual(ILOtpError.from(apiError("OTP_EXPIRED"), operation: .verify), .codeExpired)
    }

    func test_from_verify_pendingRegistrationExpired_mapsToRegistrationExpired() {
        XCTAssertEqual(ILOtpError.from(apiError("PENDING_REGISTRATION_EXPIRED"), operation: .verify), .registrationExpired)
    }

    // MARK: - Error mapping: resend-only codes

    /// The trap this mapping exists for: the same `OTP_INVALID` code is a wrong code on verify,
    /// but "no pending registration" on resend.
    func test_from_resend_otpInvalid_mapsToRegistrationExpired() {
        XCTAssertEqual(ILOtpError.from(apiError("OTP_INVALID"), operation: .resend), .registrationExpired)
    }

    func test_from_resend_pendingRegistrationExpired_mapsToRegistrationExpired() {
        XCTAssertEqual(ILOtpError.from(apiError("PENDING_REGISTRATION_EXPIRED"), operation: .resend), .registrationExpired)
    }

    func test_from_resend_tooSoon_carriesRetryAfterSeconds() {
        let error = ILOtpError.from(
            apiError("OTP_RESEND_TOO_SOON", details: ["retry_after_seconds": AnyCodable(value: 30)]),
            operation: .resend
        )
        XCTAssertEqual(error, .resendTooSoon(retryAfterSeconds: 30))
    }

    func test_from_resend_sendLimited_carriesLockedUntil() {
        let error = ILOtpError.from(
            apiError("OTP_SEND_LIMITED", details: ["locked_until": AnyCodable(value: "2026-09-23T10:30:00Z")]),
            operation: .resend
        )
        XCTAssertEqual(error, .sendLimited(lockedUntil: "2026-09-23T10:30:00Z"))
    }

    func test_from_resend_smsSendFailed_mapsToSmsSendFailed() {
        XCTAssertEqual(ILOtpError.from(apiError("SMS_SEND_FAILED"), operation: .resend), .smsSendFailed)
    }

    // MARK: - Mapper

    func test_mapper_verifyResponse_mapsToAuthSession() {
        let dto = ILOtpVerifyResponseDTO(
            accessToken: "access-1",
            refreshToken: "refresh-1",
            user: ILOtpUserDTO(
                id: 42,
                email: "an@example.com",
                phoneNumber: "+84912345678",
                dharmaName: "Diệu Tâm",
                ordinationPlace: "Chùa Linh Ứng"
            )
        )

        let session = ILOtpMapper.toDomain(dto)

        XCTAssertEqual(session.accessToken, "access-1")
        XCTAssertEqual(session.refreshToken, "refresh-1")
        XCTAssertEqual(session.user.id, 42)
        XCTAssertEqual(session.user.email, "an@example.com")
        XCTAssertEqual(session.user.phoneNumber, "+84912345678")
        XCTAssertEqual(session.user.dharmaName, "Diệu Tâm")
        XCTAssertEqual(session.user.ordinationPlace, "Chùa Linh Ứng")
    }

    func test_mapper_verifyResponse_withOmittedOptionalNames_defaultsToEmptyStrings() {
        let dto = ILOtpVerifyResponseDTO(
            accessToken: "a",
            refreshToken: "r",
            user: ILOtpUserDTO(id: 1, email: "e", phoneNumber: "p", dharmaName: nil, ordinationPlace: nil)
        )

        let session = ILOtpMapper.toDomain(dto)

        XCTAssertEqual(session.user.dharmaName, "")
        XCTAssertEqual(session.user.ordinationPlace, "")
    }

    func test_mapper_resendResponse_mapsToTiming() {
        let dto = ILOtpResendResponseDTO(message: "sent", expiresInSeconds: 90, resendAfterSeconds: 60)

        XCTAssertEqual(
            ILOtpMapper.toDomain(dto),
            ILOtpTimingEntity(expiresInSeconds: 90, resendAfterSeconds: 60)
        )
    }

    // MARK: - Wire shapes

    func test_verifyRequestDTO_encodesExplicitSnakeCaseKeys() throws {
        let dto = ILOtpVerifyRequestDTO(phoneNumber: "+84912345678", otpCode: "123456")

        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: try JSONEncoder().encode(dto)) as? [String: Any]
        )

        XCTAssertEqual(json["phone_number"] as? String, "+84912345678")
        XCTAssertEqual(json["otp_code"] as? String, "123456")
        XCTAssertNil(json["phoneNumber"])
    }

    func test_resendRequestDTO_encodesExplicitSnakeCaseKeysAndPurpose() throws {
        let dto = ILOtpResendRequestDTO(phoneNumber: "+84912345678", purpose: ILOtpPurpose.registration)

        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: try JSONEncoder().encode(dto)) as? [String: Any]
        )

        XCTAssertEqual(json["phone_number"] as? String, "+84912345678")
        XCTAssertEqual(json["purpose"] as? String, "register")
    }

    func test_verifyResponseDTO_decodesSnakeCaseBodyUnderConvertFromSnakeCase() throws {
        let json = """
        {"access_token":"a","refresh_token":"r","user":{
          "id":7,"email":"an@example.com","phone_number":"+84912345678",
          "dharma_name":"Diệu Tâm","ordination_place":null
        }}
        """
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let dto = try decoder.decode(ILOtpVerifyResponseDTO.self, from: Data(json.utf8))

        XCTAssertEqual(dto.accessToken, "a")
        XCTAssertEqual(dto.refreshToken, "r")
        XCTAssertEqual(dto.user.id, 7)
        XCTAssertEqual(dto.user.phoneNumber, "+84912345678")
        XCTAssertEqual(dto.user.dharmaName, "Diệu Tâm")
        XCTAssertNil(dto.user.ordinationPlace)
    }

    func test_resendResponseDTO_decodesSnakeCaseBodyUnderConvertFromSnakeCase() throws {
        let json = #"{"message":"sent","expires_in_seconds":90,"resend_after_seconds":60}"#
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let dto = try decoder.decode(ILOtpResendResponseDTO.self, from: Data(json.utf8))

        XCTAssertEqual(dto.expiresInSeconds, 90)
        XCTAssertEqual(dto.resendAfterSeconds, 60)
    }

    func test_endpoints_arePublicPostsWithConfirmedPaths() {
        let verify = VerifyRegistrationOTPEndpoint(
            request: ILOtpVerifyRequestDTO(phoneNumber: "+84", otpCode: "123456")
        )
        let resend = ResendOTPEndpoint(
            request: ILOtpResendRequestDTO(phoneNumber: "+84", purpose: "register")
        )

        XCTAssertEqual(verify.path, "/v1/auth/register/verify-otp")
        XCTAssertEqual(verify.method, .post)
        XCTAssertFalse(verify.requiresAuth)
        XCTAssertNotNil(verify.body)

        XCTAssertEqual(resend.path, "/v1/auth/resend-otp")
        XCTAssertEqual(resend.method, .post)
        XCTAssertFalse(resend.requiresAuth)
        XCTAssertNotNil(resend.body)
    }

    // MARK: - RepositoryImpl (end-to-end through a fake NetworkService)

    func test_repositoryImpl_verify_sendsVerifyPathAndMapsTheResponse() async throws {
        let service = MockOtpNetworkService()
        service.responseToReturn = ILOtpVerifyResponseDTO(
            accessToken: "access-1",
            refreshToken: "refresh-1",
            user: ILOtpUserDTO(id: 7, email: "e", phoneNumber: "p", dharmaName: nil, ordinationPlace: nil)
        )
        let repository = ILOtpRepositoryImpl(networkService: service)

        let session = try await repository.verifyRegistrationOTP(phoneNumber: "+84912345678", code: "123456")

        XCTAssertEqual(session.accessToken, "access-1")
        XCTAssertEqual(service.capturedEndpoint?.path, "/v1/auth/register/verify-otp")
        XCTAssertEqual(service.capturedEndpoint?.method, .post)
    }

    func test_repositoryImpl_resend_sendsPurposeRegisterAndMapsTiming() async throws {
        let service = MockOtpNetworkService()
        service.responseToReturn = ILOtpResendResponseDTO(message: "sent", expiresInSeconds: 90, resendAfterSeconds: 60)
        let repository = ILOtpRepositoryImpl(networkService: service)

        let timing = try await repository.resendRegistrationOTP(phoneNumber: "+84912345678")

        XCTAssertEqual(timing, ILOtpTimingEntity(expiresInSeconds: 90, resendAfterSeconds: 60))
        XCTAssertEqual(service.capturedEndpoint?.path, "/v1/auth/resend-otp")

        let body = try XCTUnwrap(service.capturedEndpoint?.body)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["purpose"] as? String, "register")
        XCTAssertEqual(json["phone_number"] as? String, "+84912345678")
    }

    func test_repositoryImpl_mapsNetworkErrorToFeatureError() async {
        let service = MockOtpNetworkService()
        service.errorToThrow = NetworkError.apiError(code: "OTP_INVALID", message: "m", type: "business", details: nil)
        let repository = ILOtpRepositoryImpl(networkService: service)

        do {
            _ = try await repository.verifyRegistrationOTP(phoneNumber: "+84912345678", code: "000000")
            XCTFail("Expected invalidCode")
        } catch let error as ILOtpError {
            XCTAssertEqual(error, .invalidCode)
        } catch {
            XCTFail("Expected ILOtpError, got \(error)")
        }
    }

    // MARK: - Helpers

    private func apiError(_ code: String, details: [String: AnyCodable]? = nil) -> NetworkError {
        .apiError(code: code, message: "server message", type: "business", details: details)
    }
}

// MARK: - Mock NetworkService

/// Captures the Endpoint a repository sends and returns a canned decoded value, so the
/// `ILOtpRepositoryImpl` path (endpoint construction, request encoding, response mapping, error
/// mapping) is exercised without a live network.
final class MockOtpNetworkService: NetworkService {
    var capturedEndpoint: Endpoint?
    var responseToReturn: Any?
    var errorToThrow: Error?

    func request<T: Decodable>(endpoint: Endpoint, responseType: T.Type) async throws -> T {
        capturedEndpoint = endpoint
        if let errorToThrow {
            throw errorToThrow
        }
        guard let value = responseToReturn as? T else {
            throw NetworkError.noData
        }
        return value
    }

    func request(endpoint: Endpoint) async throws {
        capturedEndpoint = endpoint
        if let errorToThrow {
            throw errorToThrow
        }
    }
}
