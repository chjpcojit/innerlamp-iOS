//
//  ILSignUpRepositoryTests.swift
//  InnerLampTests
//
//  Covers the Data-layer pieces `data-builder` added for SignUp: the request DTO's
//  snake_case encoding, the response DTO's decoding under `.convertFromSnakeCase`, the
//  Entity→DTO mapper, and the exhaustive `NetworkError` → `ILSignUpError` mapping.
//

import XCTest
@testable import InnerLamp

final class ILSignUpRepositoryTests: XCTestCase {

    // MARK: - ILSignUpError.from(NetworkError)

    func test_from_noInternet_mapsToNetworkUnavailable() {
        XCTAssertEqual(ILSignUpError.from(.noInternetConnection), .networkUnavailable)
    }

    func test_from_timeout_mapsToTimedOut() {
        XCTAssertEqual(ILSignUpError.from(.timeout), .timedOut)
    }

    func test_from_phoneTaken_mapsToPhoneAlreadyRegistered() {
        XCTAssertEqual(ILSignUpError.from(apiError("PHONE_TAKEN")), .phoneAlreadyRegistered)
    }

    func test_from_emailTaken_mapsToEmailTaken() {
        XCTAssertEqual(ILSignUpError.from(apiError("EMAIL_TAKEN")), .emailTaken)
    }

    func test_from_otpLocked_carriesLockedUntilFromDetails() {
        let error = ILSignUpError.from(apiError(
            "OTP_LOCKED",
            details: ["locked_until": AnyCodable(value: "2026-09-22T10:30:00Z")]
        ))

        XCTAssertEqual(error, .otpLocked(lockedUntil: "2026-09-22T10:30:00Z"))
    }

    func test_from_otpSendLimited_carriesLockedUntilFromDetails() {
        let error = ILSignUpError.from(apiError(
            "OTP_SEND_LIMITED",
            details: ["locked_until": AnyCodable(value: "2026-09-22T10:30:00Z")]
        ))

        XCTAssertEqual(error, .otpSendLimited(lockedUntil: "2026-09-22T10:30:00Z"))
    }

    func test_from_otpResendTooSoon_carriesRetryAfterSecondsFromDetails() {
        let error = ILSignUpError.from(apiError(
            "OTP_RESEND_TOO_SOON",
            details: ["retry_after_seconds": AnyCodable(value: 30)]
        ))

        XCTAssertEqual(error, .otpResendTooSoon(retryAfterSeconds: 30))
    }

    func test_from_otpLockedWithoutDetails_leavesTimingNil() {
        XCTAssertEqual(ILSignUpError.from(apiError("OTP_LOCKED")), .otpLocked(lockedUntil: nil))
    }

    func test_from_smsSendFailed_mapsToSmsSendFailed() {
        XCTAssertEqual(ILSignUpError.from(apiError("SMS_SEND_FAILED")), .smsSendFailed)
    }

    func test_from_validationCodes_mapToInvalidInput() {
        for code in ["VALIDATION_ERROR", "INVALID_EMAIL", "INVALID_PHONE", "INVALID_PASSWORD", "PAYLOAD_TOO_LARGE"] {
            XCTAssertEqual(ILSignUpError.from(apiError(code)), .invalidInput, "code: \(code)")
        }
    }

    func test_from_unknownApiCode_mapsToServer() {
        XCTAssertEqual(ILSignUpError.from(apiError("SOMETHING_NEW")), .server)
    }

    func test_from_transportFailures_mapToServer() {
        XCTAssertEqual(ILSignUpError.from(.unauthorized), .server)
        XCTAssertEqual(ILSignUpError.from(.invalidURL), .server)
        XCTAssertEqual(ILSignUpError.from(.noData), .server)
        XCTAssertEqual(ILSignUpError.from(.serverError(statusCode: 500, message: nil)), .server)
        XCTAssertEqual(ILSignUpError.from(.unknown(NSError(domain: "x", code: 1))), .server)
    }

    // MARK: - Message wording

    func test_otpLocked_withParsableTime_differsFromFallbackMessage() {
        let withTime = ILSignUpError.otpLocked(lockedUntil: "2026-09-22T10:30:00Z")
        let withoutTime = ILSignUpError.otpLocked(lockedUntil: nil)

        XCTAssertNotNil(withTime.errorDescription)
        XCTAssertNotEqual(withTime.errorDescription, withoutTime.errorDescription)
    }

    func test_otpLocked_withUnparsableTime_fallsBackToGenericMessage() {
        let unparsable = ILSignUpError.otpLocked(lockedUntil: "not-a-date")

        XCTAssertEqual(unparsable.errorDescription, ILSignUpError.otpLocked(lockedUntil: nil).errorDescription)
    }

    // MARK: - Mapper

    func test_mapper_mapsEveryEntityFieldToTheRequestDTO() {
        let entity = ILSignUpEntity(
            displayName: "Diệu Tâm",
            ordinationPlace: "Chùa Hoa Nghiêm",
            phoneNumber: "+84 912 345 678",
            email: "phapdanh@email.com",
            password: "secret12"
        )

        let dto = ILSignUpMapper.toDTO(entity)

        XCTAssertEqual(dto.dharmaName, "Diệu Tâm")
        XCTAssertEqual(dto.ordinationPlace, "Chùa Hoa Nghiêm")
        XCTAssertEqual(dto.phoneNumber, "+84 912 345 678")
        XCTAssertEqual(dto.email, "phapdanh@email.com")
        XCTAssertEqual(dto.password, "secret12")
    }

    func test_mapper_mapsResponseDTOToOTPEntity() {
        let dto = ILSignUpRequestOTPResponseDTO(message: "OTP sent", expiresInSeconds: 90, resendAfterSeconds: 60)

        XCTAssertEqual(
            ILSignUpMapper.toDomain(dto),
            ILSignUpOTPEntity(message: "OTP sent", expiresInSeconds: 90, resendAfterSeconds: 60)
        )
    }

    // MARK: - Wire shapes

    func test_requestDTO_encodesExplicitSnakeCaseKeys() throws {
        let dto = ILSignUpRequestOTPRequestDTO(
            dharmaName: "Diệu Tâm",
            ordinationPlace: "Chùa Hoa Nghiêm",
            phoneNumber: "+84 912 345 678",
            email: "phapdanh@email.com",
            password: "secret12"
        )

        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: try JSONEncoder().encode(dto)) as? [String: Any]
        )

        XCTAssertEqual(json["dharma_name"] as? String, "Diệu Tâm")
        XCTAssertEqual(json["ordination_place"] as? String, "Chùa Hoa Nghiêm")
        XCTAssertEqual(json["phone_number"] as? String, "+84 912 345 678")
        XCTAssertEqual(json["email"] as? String, "phapdanh@email.com")
        XCTAssertEqual(json["password"] as? String, "secret12")
        XCTAssertNil(json["dharmaName"])
    }

    func test_responseDTO_decodesSnakeCaseBodyUnderConvertFromSnakeCase() throws {
        let json = #"{"message":"OTP sent","expires_in_seconds":90,"resend_after_seconds":60}"#
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let dto = try decoder.decode(ILSignUpRequestOTPResponseDTO.self, from: Data(json.utf8))

        XCTAssertEqual(dto.message, "OTP sent")
        XCTAssertEqual(dto.expiresInSeconds, 90)
        XCTAssertEqual(dto.resendAfterSeconds, 60)
    }

    func test_endpoint_isPublicPostWithBodyAndRegistrationPath() throws {
        let dto = ILSignUpRequestOTPRequestDTO(
            dharmaName: "Diệu Tâm",
            ordinationPlace: "",
            phoneNumber: "+84 912 345 678",
            email: "phapdanh@email.com",
            password: "secret12"
        )

        let endpoint = RequestRegistrationOTPEndpoint(request: dto)

        XCTAssertEqual(endpoint.path, "/v1/auth/register/request-otp")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertFalse(endpoint.requiresAuth)
        XCTAssertNotNil(endpoint.body)
    }

    // MARK: - Helpers

    private func apiError(_ code: String, details: [String: AnyCodable]? = nil) -> NetworkError {
        .apiError(code: code, message: "server message", type: "business", details: details)
    }
}
