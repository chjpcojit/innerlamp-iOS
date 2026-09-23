//
//  ILOtpRepositoryImpl.swift
//  InnerLamp
//

import Foundation

/// Data-layer implementation of `ILOtpRepository`.
///
/// The only place a DTO may exist above `NetworkService`: it owns the two Endpoints and the
/// Mapper, and converts `NetworkError` into `ILOtpError` so nothing in `Domain/` or
/// `Presentation/` imports `Core/Networking`.
nonisolated final class ILOtpRepositoryImpl: ILOtpRepository {

    private let networkService: NetworkService

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    func verifyRegistrationOTP(phoneNumber: String, code: String) async throws -> ILAuthSessionEntity {
        let request = ILOtpVerifyRequestDTO(phoneNumber: phoneNumber, otpCode: code)
        do {
            let response = try await networkService.request(
                endpoint: VerifyRegistrationOTPEndpoint(request: request),
                responseType: ILOtpVerifyResponseDTO.self
            )
            return ILOtpMapper.toDomain(response)
        } catch let error as NetworkError {
            throw ILOtpError.from(error, operation: .verify)
        }
    }

    func resendRegistrationOTP(phoneNumber: String) async throws -> ILOtpTimingEntity {
        let request = await ILOtpResendRequestDTO(phoneNumber: phoneNumber, purpose: ILOtpPurpose.registration)
        do {
            let response = try await networkService.request(
                endpoint: ResendOTPEndpoint(request: request),
                responseType: ILOtpResendResponseDTO.self
            )
            return ILOtpMapper.toDomain(response)
        } catch let error as NetworkError {
            throw ILOtpError.from(error, operation: .resend)
        }
    }
}

extension ILOtpError {

    /// Maps the transport's error into the feature's own vocabulary.
    ///
    /// `operation` disambiguates the codes the two calls share — `OTP_INVALID` is a wrong code on
    /// verify, but "no pending registration" on resend, and the user-facing message differs.
    static func from(_ error: NetworkError, operation: ILOtpOperation) -> ILOtpError {
        switch error {
        case .noInternetConnection:
            return .networkUnavailable
        case .timeout:
            return .timedOut
        case .apiError(let code, _, _, let details):
            // `code` is the discriminator — never the human-readable message.
            switch code {
            case "PHONE_TAKEN":
                return .phoneTaken
            case "EMAIL_TAKEN":
                return .emailTaken
            case "OTP_LOCKED":
                return .otpLocked(lockedUntil: details?["locked_until"]?.value as? String)
            case "SMS_SEND_FAILED":
                return .smsSendFailed
            case "VALIDATION_ERROR", "INVALID_EMAIL", "INVALID_PHONE", "INVALID_PASSWORD",
                 "PAYLOAD_TOO_LARGE":
                return .invalidInput
            default:
                return operationError(code: code, details: details, operation: operation)
            }
        case .serverError, .unauthorized, .invalidURL, .noData, .decodingError, .encodingError,
             .unknown:
            return .server
        }
    }

    private static func operationError(
        code: String,
        details: [String: AnyCodable]?,
        operation: ILOtpOperation
    ) -> ILOtpError {
        switch operation {
        case .verify:
            switch code {
            case "OTP_INVALID":
                return .invalidCode
            case "OTP_EXPIRED":
                return .codeExpired
            case "PENDING_REGISTRATION_EXPIRED":
                return .registrationExpired
            default:
                return .server
            }
        case .resend:
            switch code {
            // On resend this code means "no live pending registration", not a wrong code.
            case "OTP_INVALID", "PENDING_REGISTRATION_EXPIRED":
                return .registrationExpired
            case "OTP_RESEND_TOO_SOON":
                return .resendTooSoon(retryAfterSeconds: details?["retry_after_seconds"]?.value as? Int)
            case "OTP_SEND_LIMITED":
                return .sendLimited(lockedUntil: details?["locked_until"]?.value as? String)
            default:
                return .server
            }
        }
    }
}
