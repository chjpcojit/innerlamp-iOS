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

    func test_from_registrationInProgress_carriesRetryAfterSecondsFromDetails() {
        let error = ILSignUpError.from(apiError(
            "REGISTRATION_IN_PROGRESS",
            details: ["retry_after_seconds": AnyCodable(value: 412)]
        ))

        XCTAssertEqual(error, .registrationInProgress(retryAfterSeconds: 412))
    }

    func test_from_rateLimited_carriesRetryAfterSecondsFromDetails() {
        let error = ILSignUpError.from(apiError(
            "RATE_LIMITED",
            details: ["retry_after_seconds": AnyCodable(value: 60)]
        ))

        XCTAssertEqual(error, .rateLimited(retryAfterSeconds: 60))
    }

    func test_from_fieldCodes_mapToTheirOwnFieldCases() {
        XCTAssertEqual(ILSignUpError.from(apiError("INVALID_EMAIL")), .invalidEmail)
        XCTAssertEqual(ILSignUpError.from(apiError("INVALID_PHONE")), .invalidPhone)
        XCTAssertEqual(ILSignUpError.from(apiError("INVALID_PASSWORD")), .invalidPassword)
        XCTAssertEqual(ILSignUpError.from(apiError("INVALID_FULL_NAME")), .invalidFullName)
        XCTAssertEqual(ILSignUpError.from(apiError("INVALID_DHARMA_NAME")), .invalidDharmaName)
    }

    func test_from_structuralCodes_mapToInvalidInput() {
        for code in ["VALIDATION_ERROR", "PAYLOAD_TOO_LARGE"] {
            XCTAssertEqual(ILSignUpError.from(apiError(code)), .invalidInput, "code: \(code)")
        }
    }

    func test_from_retiredAndMailCodes_mapToServer() {
        // EN: `EMAIL_TAKEN` and `SMS_SEND_FAILED` no longer exist; `EMAIL_SEND_FAILED` is a generic error.
        // VI: `EMAIL_TAKEN` và `SMS_SEND_FAILED` không còn; `EMAIL_SEND_FAILED` là lỗi chung.
        for code in ["EMAIL_TAKEN", "SMS_SEND_FAILED", "EMAIL_SEND_FAILED"] {
            XCTAssertEqual(ILSignUpError.from(apiError(code)), .server, "code: \(code)")
        }
    }

    func test_from_invalidTemple_mapsToItsOwnCaseWithAPickAgainMessage() {
        let error = ILSignUpError.from(apiError("INVALID_TEMPLE"))

        XCTAssertEqual(error, .invalidTemple)
        XCTAssertNotEqual(error.errorDescription, ILSignUpError.invalidInput.errorDescription)
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

    func test_registrationInProgress_withSeconds_differsFromFallbackMessage() {
        let withSeconds = ILSignUpError.registrationInProgress(retryAfterSeconds: 30)
        let withoutSeconds = ILSignUpError.registrationInProgress(retryAfterSeconds: nil)

        XCTAssertNotNil(withSeconds.errorDescription)
        XCTAssertNotEqual(withSeconds.errorDescription, withoutSeconds.errorDescription)
    }

    // MARK: - Mapper

    func test_mapper_mapsEveryEntityFieldToTheRequestDTO() {
        let entity = ILSignUpEntity(
            fullName: "Nguyễn Bình An",
            displayName: "Diệu Tâm",
            ordinationTempleID: "temple_north_011",
            phoneCountry: "VN",
            phoneNumber: "912345678",
            email: "phapdanh@email.com",
            password: "secret12"
        )

        let dto = ILSignUpMapper.toDTO(entity)

        XCTAssertEqual(dto.fullName, "Nguyễn Bình An")
        XCTAssertEqual(dto.dharmaName, "Diệu Tâm")
        XCTAssertEqual(dto.ordinationTempleId, "temple_north_011")
        XCTAssertEqual(dto.phoneCountry, "VN")
        XCTAssertEqual(dto.phoneNumber, "912345678")
        XCTAssertEqual(dto.email, "phapdanh@email.com")
        XCTAssertEqual(dto.password, "secret12")
    }

    func test_mapper_emptyDharmaName_isOmittedFromTheRequest() {
        let entity = ILSignUpEntity(fullName: "Nguyễn Bình An", displayName: "", phoneCountry: "VN", phoneNumber: "912345678")

        XCTAssertNil(ILSignUpMapper.toDTO(entity).dharmaName)
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
            fullName: "Nguyễn Bình An",
            dharmaName: "Diệu Tâm",
            ordinationTempleId: "temple_north_011",
            phoneCountry: "VN",
            phoneNumber: "912345678",
            email: "phapdanh@email.com",
            password: "secret12"
        )

        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: try JSONEncoder().encode(dto)) as? [String: Any]
        )

        XCTAssertEqual(json["full_name"] as? String, "Nguyễn Bình An")
        XCTAssertNil(json["fullName"])
        XCTAssertEqual(json["dharma_name"] as? String, "Diệu Tâm")
        XCTAssertEqual(json["ordination_temple_id"] as? String, "temple_north_011")
        XCTAssertNil(json["ordination_place"], "The server rejects the retired field")
        XCTAssertEqual(json["phone_country"] as? String, "VN")
        XCTAssertEqual(json["phone_number"] as? String, "912345678")
        XCTAssertEqual(json["email"] as? String, "phapdanh@email.com")
        XCTAssertEqual(json["password"] as? String, "secret12")
        XCTAssertNil(json["dharmaName"])
    }

    func test_requestDTO_withoutTemple_omitsTheTempleField() throws {
        let dto = ILSignUpRequestOTPRequestDTO(
            fullName: "Nguyễn Bình An",
            dharmaName: "Diệu Tâm",
            ordinationTempleId: nil,
            phoneCountry: "VN",
            phoneNumber: "912345678",
            email: "phapdanh@email.com",
            password: "secret12"
        )

        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: try JSONEncoder().encode(dto)) as? [String: Any]
        )

        XCTAssertNil(json["ordination_temple_id"], "Absent field = no temple; the server also rejects unknown keys")
    }

    func test_requestDTO_withoutDharmaName_omitsTheDharmaNameField() throws {
        let dto = ILSignUpRequestOTPRequestDTO(
            fullName: "Nguyễn Bình An",
            dharmaName: nil,
            ordinationTempleId: nil,
            phoneCountry: "VN",
            phoneNumber: "912345678",
            email: "phapdanh@email.com",
            password: "secret12"
        )

        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: try JSONEncoder().encode(dto)) as? [String: Any]
        )

        XCTAssertNil(json["dharma_name"])
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
            fullName: "Nguyễn Bình An",
            dharmaName: "Diệu Tâm",
            ordinationTempleId: nil,
            phoneCountry: "VN",
            phoneNumber: "912345678",
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
