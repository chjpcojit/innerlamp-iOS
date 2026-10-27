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
            // EN: Contract 3.0.0 has no `EMAIL_TAKEN` (an existing email answers 200 like a new one)
            //     and no SMS; each invalid field has its own code so the error lands under that field.
            // VI: Contract 3.0.0 không còn `EMAIL_TAKEN` (email đã có tài khoản vẫn nhận 200 như email
            //     mới) và không còn SMS; mỗi field sai có mã riêng để lỗi hiện dưới đúng field đó.
            case "PHONE_TAKEN":
                return .phoneAlreadyRegistered
            case "REGISTRATION_IN_PROGRESS":
                return .registrationInProgress(retryAfterSeconds: details?["retry_after_seconds"]?.value as? Int)
            case "RATE_LIMITED":
                return .rateLimited(retryAfterSeconds: details?["retry_after_seconds"]?.value as? Int)
            case "INVALID_TEMPLE":
                return .invalidTemple
            case "INVALID_EMAIL":
                return .invalidEmail
            case "INVALID_PHONE":
                return .invalidPhone
            case "INVALID_PASSWORD":
                return .invalidPassword
            case "INVALID_FULL_NAME":
                return .invalidFullName
            case "INVALID_DHARMA_NAME":
                return .invalidDharmaName
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
