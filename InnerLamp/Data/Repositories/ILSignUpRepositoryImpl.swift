//
//  ILSignUpRepositoryImpl.swift
//  InnerLamp
//

import Foundation

/// Data-layer implementation of `ILSignUpRepository`.
///
/// This is the only place a DTO may exist above `NetworkService`: it converts the Entity at the
/// boundary via `ILSignUpMapper` and maps `NetworkError` → `ILSignUpError`, so nothing in
/// `Domain/` or `Presentation/` imports `Core/Networking`.
nonisolated final class ILSignUpRepositoryImpl: ILSignUpRepository {

    private let networkService: NetworkService

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    func requestRegistrationOTP(_ entity: ILSignUpEntity) async throws -> ILSignUpOTPEntity {
        let request = ILSignUpMapper.toDTO(entity)

        do {
            let response = try await networkService.request(
                endpoint: RequestRegistrationOTPEndpoint(request: request),
                responseType: ILSignUpRequestOTPResponseDTO.self
            )
            return ILSignUpMapper.toDomain(response)
        } catch let error as NetworkError {
            throw ILSignUpError.from(error)
        }
    }
}

extension ILSignUpError {

    /// Maps the transport's error into the feature's own vocabulary so the ViewModel's `catch`
    /// keeps working unchanged and no `NetworkError` crosses this boundary.
    ///
    /// The 429 timing cases read the envelope's `details` (`locked_until` /
    /// `retry_after_seconds`) that `NetworkService` now forwards through `NetworkError.apiError`.
    static func from(_ error: NetworkError) -> ILSignUpError {
        switch error {
        case .noInternetConnection:
            return .networkUnavailable
        case .timeout:
            return .timedOut
        case .apiError(let code, _, _, let details):
            // `code` is the discriminator — never the human-readable message.
            switch code {
            case "PHONE_TAKEN":
                return .phoneAlreadyRegistered
            case "EMAIL_TAKEN":
                return .emailTaken
            case "OTP_LOCKED":
                return .otpLocked(lockedUntil: details?["locked_until"]?.value as? String)
            case "OTP_SEND_LIMITED":
                return .otpSendLimited(lockedUntil: details?["locked_until"]?.value as? String)
            case "OTP_RESEND_TOO_SOON":
                return .otpResendTooSoon(retryAfterSeconds: details?["retry_after_seconds"]?.value as? Int)
            case "SMS_SEND_FAILED":
                return .smsSendFailed
            case "VALIDATION_ERROR", "INVALID_EMAIL", "INVALID_PHONE", "INVALID_PASSWORD",
                 "PAYLOAD_TOO_LARGE":
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
