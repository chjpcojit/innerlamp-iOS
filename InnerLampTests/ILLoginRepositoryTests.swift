//
//  ILLoginRepositoryTests.swift
//  InnerLampTests
//
//  Covers the Data-layer pieces `data-builder` added for Login: the request DTO's
//  snake_case encoding (including the nested `device` object), the response DTO's decoding under
//  `.convertFromSnakeCase`, the Entity <-> DTO mapper, and the exhaustive `NetworkError` ->
//  `ILLoginError` mapping.
//

import XCTest
@testable import InnerLamp

final class ILLoginRepositoryTests: XCTestCase {

    // MARK: - ILLoginError.from(NetworkError)

    func test_from_noInternet_mapsToNetworkUnavailable() {
        XCTAssertEqual(ILLoginError.from(.noInternetConnection), .networkUnavailable)
    }

    func test_from_timeout_mapsToTimedOut() {
        XCTAssertEqual(ILLoginError.from(.timeout), .timedOut)
    }

    func test_from_invalidCredentials_mapsToInvalidCredentials() {
        XCTAssertEqual(ILLoginError.from(apiError("INVALID_CREDENTIALS")), .invalidCredentials)
    }

    func test_from_invalidPhone_mapsToInvalidPhone() {
        XCTAssertEqual(ILLoginError.from(apiError("INVALID_PHONE")), .invalidPhone)
    }

    func test_from_invalidPassword_mapsToInvalidPassword() {
        XCTAssertEqual(ILLoginError.from(apiError("INVALID_PASSWORD")), .invalidPassword)
    }

    func test_from_invalidDevice_mapsToInvalidDevice() {
        XCTAssertEqual(ILLoginError.from(apiError("INVALID_DEVICE")), .invalidDevice)
    }

    func test_from_loginLocked_carriesLockedUntilFromDetails() {
        let error = ILLoginError.from(apiError(
            "LOGIN_LOCKED",
            details: ["locked_until": AnyCodable(value: "2026-09-22T10:30:00Z")]
        ))

        XCTAssertEqual(error, .loginLocked(lockedUntil: "2026-09-22T10:30:00Z"))
    }

    func test_from_loginLockedWithoutDetails_leavesTimingNil() {
        XCTAssertEqual(ILLoginError.from(apiError("LOGIN_LOCKED")), .loginLocked(lockedUntil: nil))
    }

    func test_from_validationCodes_mapToInvalidInput() {
        for code in ["VALIDATION_ERROR", "PAYLOAD_TOO_LARGE"] {
            XCTAssertEqual(ILLoginError.from(apiError(code)), .invalidInput, "code: \(code)")
        }
    }

    func test_from_unknownApiCode_mapsToServer() {
        XCTAssertEqual(ILLoginError.from(apiError("SOMETHING_NEW")), .server)
    }

    func test_from_transportFailures_mapToServer() {
        XCTAssertEqual(ILLoginError.from(.unauthorized), .server)
        XCTAssertEqual(ILLoginError.from(.invalidURL), .server)
        XCTAssertEqual(ILLoginError.from(.noData), .server)
        XCTAssertEqual(ILLoginError.from(.serverError(statusCode: 500, message: nil)), .server)
        XCTAssertEqual(ILLoginError.from(.unknown(NSError(domain: "x", code: 1))), .server)
    }

    // MARK: - Message wording

    func test_loginLocked_withParsableTime_differsFromFallbackMessage() {
        let withTime = ILLoginError.loginLocked(lockedUntil: "2026-09-22T10:30:00Z")
        let withoutTime = ILLoginError.loginLocked(lockedUntil: nil)

        XCTAssertNotNil(withTime.errorDescription)
        XCTAssertNotEqual(withTime.errorDescription, withoutTime.errorDescription)
    }

    func test_loginLocked_withUnparsableTime_fallsBackToGenericMessage() {
        let unparsable = ILLoginError.loginLocked(lockedUntil: "not-a-date")

        XCTAssertEqual(unparsable.errorDescription, ILLoginError.loginLocked(lockedUntil: nil).errorDescription)
    }

    // MARK: - Mapper

    func test_mapper_mapsEntityAndDeviceToTheRequestDTO() {
        let entity = ILLoginEntity(phone: "+84 912 345 678", password: "secret12")
        let device = ILLoginDeviceDTO(
            platform: "ios",
            deviceModel: "iPhone",
            osVersion: "17.0",
            appVersion: "1.0.0",
            deviceName: nil
        )

        let dto = ILLoginMapper.toDTO(entity, device: device)

        XCTAssertEqual(dto.phoneNumber, "+84 912 345 678")
        XCTAssertEqual(dto.password, "secret12")
        XCTAssertEqual(dto.device.platform, "ios")
        XCTAssertEqual(dto.device.deviceModel, "iPhone")
        XCTAssertEqual(dto.device.osVersion, "17.0")
        XCTAssertEqual(dto.device.appVersion, "1.0.0")
        XCTAssertNil(dto.device.deviceName)
    }

    func test_mapper_mapsResponseDTOToAuthSessionEntity() {
        let dto = ILLoginResponseDTO(
            accessToken: "access-1",
            refreshToken: "refresh-1",
            user: ILLoginUserDTO(
                id: 42,
                email: "an@example.com",
                phoneNumber: "+84912345678",
                dharmaName: "Diệu Tâm",
                ordinationPlace: "Chùa Linh Ứng"
            )
        )

        let entity = ILLoginMapper.toDomain(dto)

        XCTAssertEqual(entity.accessToken, "access-1")
        XCTAssertEqual(entity.refreshToken, "refresh-1")
        XCTAssertEqual(entity.user.id, 42)
        XCTAssertEqual(entity.user.email, "an@example.com")
        XCTAssertEqual(entity.user.phoneNumber, "+84912345678")
        XCTAssertEqual(entity.user.dharmaName, "Diệu Tâm")
        XCTAssertEqual(entity.user.ordinationPlace, "Chùa Linh Ứng")
    }

    func test_mapper_responseWithNilOptionalUserFields_defaultsToEmptyString() {
        let dto = ILLoginResponseDTO(
            accessToken: "access-1",
            refreshToken: "refresh-1",
            user: ILLoginUserDTO(
                id: 1,
                email: "an@example.com",
                phoneNumber: "+84912345678",
                dharmaName: nil,
                ordinationPlace: nil
            )
        )

        let entity = ILLoginMapper.toDomain(dto)

        XCTAssertEqual(entity.user.dharmaName, "")
        XCTAssertEqual(entity.user.ordinationPlace, "")
    }

    // MARK: - Wire shapes

    func test_requestDTO_encodesExplicitSnakeCaseKeysIncludingNestedDevice() throws {
        let dto = ILLoginRequestDTO(
            phoneNumber: "+84 912 345 678",
            password: "secret12",
            device: ILLoginDeviceDTO(
                platform: "ios",
                deviceModel: "iPhone 15",
                osVersion: "17.0",
                appVersion: "1.0.0",
                deviceName: "An's iPhone"
            )
        )

        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: try JSONEncoder().encode(dto)) as? [String: Any]
        )

        XCTAssertEqual(json["phone_number"] as? String, "+84 912 345 678")
        XCTAssertEqual(json["password"] as? String, "secret12")
        let device = try XCTUnwrap(json["device"] as? [String: Any])
        XCTAssertEqual(device["platform"] as? String, "ios")
        XCTAssertEqual(device["device_model"] as? String, "iPhone 15")
        XCTAssertEqual(device["os_version"] as? String, "17.0")
        XCTAssertEqual(device["app_version"] as? String, "1.0.0")
        XCTAssertEqual(device["device_name"] as? String, "An's iPhone")
        XCTAssertNil(json["phoneNumber"])
    }

    func test_requestDTO_encodesNilOptionalDeviceFieldsAsNull() throws {
        let dto = ILLoginRequestDTO(
            phoneNumber: "+84 912 345 678",
            password: "secret12",
            device: ILLoginDeviceDTO(platform: "ios", deviceModel: "iPhone", osVersion: nil, appVersion: nil, deviceName: nil)
        )

        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: try JSONEncoder().encode(dto)) as? [String: Any]
        )
        let device = try XCTUnwrap(json["device"] as? [String: Any])

        XCTAssertTrue(device["os_version"] is NSNull)
        XCTAssertTrue(device["app_version"] is NSNull)
        XCTAssertTrue(device["device_name"] is NSNull)
    }

    func test_responseDTO_decodesSnakeCaseBodyUnderConvertFromSnakeCase() throws {
        let json = """
        {
            "access_token": "access-1",
            "refresh_token": "refresh-1",
            "user": {
                "id": 42,
                "email": "an@example.com",
                "phone_number": "+84912345678",
                "dharma_name": "Diệu Tâm",
                "ordination_place": "Chùa Linh Ứng"
            }
        }
        """
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let dto = try decoder.decode(ILLoginResponseDTO.self, from: Data(json.utf8))

        XCTAssertEqual(dto.accessToken, "access-1")
        XCTAssertEqual(dto.refreshToken, "refresh-1")
        XCTAssertEqual(dto.user.id, 42)
        XCTAssertEqual(dto.user.dharmaName, "Diệu Tâm")
    }

    func test_endpoint_isPublicPostWithBodyAndLoginPath() throws {
        let dto = ILLoginRequestDTO(
            phoneNumber: "+84 912 345 678",
            password: "secret12",
            device: ILLoginDeviceDTO(platform: "ios", deviceModel: "iPhone", osVersion: nil, appVersion: nil, deviceName: nil)
        )

        let endpoint = LoginEndpoint(request: dto)

        XCTAssertEqual(endpoint.path, "/v1/auth/login")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertFalse(endpoint.requiresAuth)
        XCTAssertNotNil(endpoint.body)
    }

    // MARK: - Helpers

    private func apiError(_ code: String, details: [String: AnyCodable]? = nil) -> NetworkError {
        .apiError(code: code, message: "server message", type: "business", details: details)
    }
}
