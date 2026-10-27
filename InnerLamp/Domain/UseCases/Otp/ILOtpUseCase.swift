//
//  ILOtpUseCase.swift
//  InnerLamp
//

import Foundation

/// Which server call produced a `NetworkError` — the two calls share `ApiResponse` error codes
/// that mean different things in each context (`OTP_INVALID` is a wrong code on verify, but
/// "no pending registration" on resend).
enum ILOtpOperation {
    case verify
    case resend
}

enum ILOtpError: Error, LocalizedError, Equatable {
    case invalidCode
    case codeExpired
    case registrationExpired
    case phoneTaken
    /// EN: `INVALID_TEMPLE` from `verify-otp` — the picked temple was removed while the code was pending.
    /// VI: `INVALID_TEMPLE` từ `verify-otp` — chùa đã chọn bị gỡ trong lúc mã đang chờ.
    case invalidTemple
    case otpLocked(lockedUntil: String?)
    case sendLimited(lockedUntil: String?)
    case resendTooSoon(retryAfterSeconds: Int?)
    case rateLimited(retryAfterSeconds: Int?)
    case invalidInput
    case server
    case networkUnavailable
    case timedOut
    /// The session returned by a successful `verify-otp` could not be written to the Keychain /
    /// local user store.
    case storageFailed

    var errorDescription: String? {
        switch self {
        case .invalidCode:
            return "otp.error.invalidCode".localized
        case .codeExpired:
            return "otp.error.expiredCode".localized
        case .registrationExpired:
            return "otp.error.registrationExpired".localized
        // The codes below are shared with SignUp's submit call and already have identical
        // messages under `signup.error.*` — reused rather than duplicated.
        case .phoneTaken:
            return "signup.error.phoneTaken".localized
        case .invalidTemple:
            return "signup.error.invalidTemple".localized
        case .otpLocked(let lockedUntil):
            guard let formatted = ILUnlockTimeFormatter.displayString(from: lockedUntil) else {
                return "otp.error.locked".localized
            }
            return String(format: "otp.error.lockedUntil".localized, formatted)
        case .sendLimited(let lockedUntil):
            guard let formatted = ILUnlockTimeFormatter.displayString(from: lockedUntil) else {
                return "otp.error.sendLimited".localized
            }
            return String(format: "otp.error.sendLimitedUntil".localized, formatted)
        case .resendTooSoon(let retryAfterSeconds):
            guard let retryAfterSeconds else {
                return "otp.error.resendTooSoon".localized
            }
            return String(format: "otp.error.resendTooSoonSeconds".localized, retryAfterSeconds)
        case .rateLimited(let retryAfterSeconds):
            return ILRateLimitMessage.text(retryAfterSeconds: retryAfterSeconds)
        case .invalidInput:
            return "signup.error.invalidInput".localized
        case .server:
            return "error.generic".localized
        case .networkUnavailable:
            return "error.no_internet".localized
        case .timedOut:
            return "signup.error.timedOut".localized
        case .storageFailed:
            return "otp.error.storageFailed".localized
        }
    }
}

protocol ILOtpUseCase {
    /// State ban đầu cho màn OTP. `otpExpiresInSeconds`/`resendAfterSeconds` là timing thật từ
    /// server (response của `request-otp`), dùng để khởi tạo countdown "Gửi lại" và câu hiển thị
    /// hạn mã — không còn hardcode như trước.
    func getInitialState(email: String, otpExpiresInSeconds: Int, resendAfterSeconds: Int) -> ILOtpStateModel

    /// EN: Resends the code to `email` (`POST /v1/auth/register/resend-otp`) and returns the new timing.
    /// VI: Gửi lại mã tới `email` (`POST /v1/auth/register/resend-otp`) và trả về timing mới.
    func resendCode(email: String) async throws -> ILOtpTimingEntity

    /// Xác thực `code` với mã đã gửi tới `email`. Thành công lưu luôn phiên đăng nhập
    /// (token vào Keychain, user vào `ILUserRepository`) — xem `Docs/Specs/Onboarding/design.md`.
    func verifyCode(email: String, code: String) async throws
}

final class ILOtpUseCaseImpl: ILOtpUseCase {

    private let repository: ILOtpRepository
    private let keychainService: KeychainService
    private let userRepository: ILUserRepository

    init(
        repository: ILOtpRepository,
        keychainService: KeychainService,
        userRepository: ILUserRepository
    ) {
        self.repository = repository
        self.keychainService = keychainService
        self.userRepository = userRepository
    }

    func getInitialState(email: String, otpExpiresInSeconds: Int, resendAfterSeconds: Int) -> ILOtpStateModel {
        var state = ILOtpStateModel.initial
        state.email = email
        state.otpExpiresInSeconds = otpExpiresInSeconds
        state.secondsRemaining = resendAfterSeconds
        return state
    }

    func resendCode(email: String) async throws -> ILOtpTimingEntity {
        try await repository.resendRegistrationOTP(email: email)
    }

    func verifyCode(email: String, code: String) async throws {
        let session = try await repository.verifyRegistrationOTP(email: email, code: code)

        // Store the session last: the account and pending_registration are already gone
        // server-side, so a storage failure cannot be recovered by retrying this call — it is
        // surfaced as its own case so the message can say so.
        do {
            try keychainService.save(
                key: KeychainAuthTokenProviding.accessTokenKey,
                value: session.accessToken
            )
            try keychainService.save(key: KeychainAuthTokenProviding.refreshTokenKey, value: session.refreshToken)
            try await userRepository.saveUser(session.user)
        } catch {
            throw ILOtpError.storageFailed
        }
    }
}
