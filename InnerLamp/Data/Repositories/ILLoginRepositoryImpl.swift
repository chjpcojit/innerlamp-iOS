//
//  ILLoginRepositoryImpl.swift
//  InnerLamp
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Data-layer implementation of `ILLoginRepository`.
///
/// This is the only place a DTO may exist above `NetworkService`: it derives the contract's
/// required `device` object from `UIDevice`/`Bundle` (keeping platform details out of Domain, per
/// `Docs/Specs/Login/design.md` gap #1), converts the Entity via `ILLoginMapper`, and maps
/// `NetworkError` → `ILLoginError`, so nothing in `Domain/` or `Presentation/` imports
/// `Core/Networking`.
nonisolated final class ILLoginRepositoryImpl: ILLoginRepository {

    private let networkService: NetworkService

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    func login(_ entity: ILLoginEntity) async throws -> ILAuthSessionEntity {
        let device = Self.currentDevice()
        let request = ILLoginMapper.toDTO(entity, device: device)

        do {
            let response = try await networkService.request(
                endpoint: LoginEndpoint(request: request),
                responseType: ILLoginResponseDTO.self
            )
            return ILLoginMapper.toDomain(response)
        } catch let error as NetworkError {
            throw ILLoginError.from(error)
        }
    }

    /// Builds the `device` object the contract requires (`platform` + `device_model` at minimum).
    /// `os_version`/`app_version` are sent best-effort; the contract marks them optional.
    @MainActor
    private static func currentDevice() -> ILLoginDeviceDTO {
        #if canImport(UIKit)
        let deviceModel = UIDevice.current.model
        let osVersion = UIDevice.current.systemVersion
        #else
        let deviceModel = "unknown"
        let osVersion: String? = nil
        #endif
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

        return ILLoginDeviceDTO(
            platform: "ios",
            deviceModel: deviceModel,
            osVersion: osVersion,
            appVersion: appVersion,
            deviceName: nil
        )
    }
}

extension ILLoginError {

    /// Maps the transport's error into the feature's own vocabulary so the ViewModel's `catch`
    /// keeps working unchanged and no `NetworkError` crosses this boundary.
    ///
    /// The 429 timing case reads the envelope's `details.locked_until` that `NetworkService`
    /// forwards through `NetworkError.apiError` — same mechanism as `ILSignUpError`/`ILOtpError`.
    static func from(_ error: NetworkError) -> ILLoginError {
        switch error {
        case .noInternetConnection:
            return .networkUnavailable
        case .timeout:
            return .timedOut
        case .apiError(let code, _, _, let details):
            // `code` is the discriminator — never the human-readable message.
            switch code {
            case "INVALID_CREDENTIALS":
                return .invalidCredentials
            case "INVALID_PHONE":
                return .invalidPhone
            case "INVALID_PASSWORD":
                return .invalidPassword
            case "INVALID_DEVICE":
                return .invalidDevice
            case "LOGIN_LOCKED":
                return .loginLocked(lockedUntil: details?["locked_until"]?.value as? String)
            case "VALIDATION_ERROR", "PAYLOAD_TOO_LARGE":
                return .invalidInput
            default:
                return .server
            }
        case .serverError, .unauthorized, .invalidURL, .noData, .decodingError, .encodingError,
             .unknown:
            return .server
        }
    }
}
