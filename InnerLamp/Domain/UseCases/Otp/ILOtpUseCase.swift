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

/// `otp_codes.purpose` values. US-001 implements only `.registration`; the server rejects the
/// other enum values with `UNSUPPORTED_OTP_PURPOSE`.
enum ILOtpPurpose {
    static let registration = "register"
}

enum ILOtpError: Error, LocalizedError, Equatable {
    case invalidCode
    case codeExpired
    case registrationExpired
    case phoneTaken
    case emailTaken
    case otpLocked(lockedUntil: String?)
    case sendLimited(lockedUntil: String?)
    case resendTooSoon(retryAfterSeconds: Int?)
    case smsSendFailed
    case invalidInput
    case server
    case networkUnavailable
    case timedOut
    /// The session returned by a successful `verify-otp` could not be written to the Keychain /
    /// local user store.
    case storageFailed
    /// The voice-call OTP channel has no confirmed backend contract yet.
    case voiceCallUnsupported

    var errorDescription: String? {
        switch self {
        case .invalidCode:
            return "otp.error.invalidCode".localized
        case .codeExpired:
            return "otp.error.expiredCode".localized
        case .registrationExpired:
            return "otp.error.registrationExpired".localized
        // The OTP-related codes below are shared with SignUp's submit call and already have
        // identical messages under `signup.error.*` — reused rather than duplicated.
        case .phoneTaken:
            return "signup.error.phoneTaken".localized
        case .emailTaken:
            return "signup.error.emailTaken".localized
        case .otpLocked(let lockedUntil):
            guard let formatted = ILUnlockTimeFormatter.displayString(from: lockedUntil) else {
                return "signup.error.otpLocked".localized
            }
            return String(format: "signup.error.otpLockedUntil".localized, formatted)
        case .sendLimited(let lockedUntil):
            guard let formatted = ILUnlockTimeFormatter.displayString(from: lockedUntil) else {
                return "signup.error.otpSendLimited".localized
            }
            return String(format: "signup.error.otpSendLimitedUntil".localized, formatted)
        case .resendTooSoon(let retryAfterSeconds):
            guard let retryAfterSeconds else {
                return "signup.error.otpResendTooSoon".localized
            }
            return String(format: "signup.error.otpResendTooSoonSeconds".localized, retryAfterSeconds)
        case .smsSendFailed:
            return "signup.error.smsSendFailed".localized
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
        case .voiceCallUnsupported:
            return "otp.error.voiceCallUnsupported".localized
        }
    }
}

/// Kênh gửi mã OTP — SMS (mặc định) hoặc cuộc gọi thoại (khi người dùng không nhận được SMS,
/// xem banner "nhận mã qua cuộc gọi thoại" trong design handoff).
enum ILOtpChannel {
    case sms
    case voiceCall
}

protocol ILOtpUseCase {
    /// State ban đầu cho màn OTP. `otpExpiresInSeconds`/`resendAfterSeconds` là timing thật từ
    /// server (response của `request-otp`), dùng để khởi tạo countdown "Gửi lại" và câu hiển thị
    /// hạn mã — không còn hardcode như trước.
    func getInitialState(phoneNumber: String, otpExpiresInSeconds: Int, resendAfterSeconds: Int) -> ILOtpStateModel

    /// Gửi lại mã cho `phoneNumber` — trả về timing mới của server để màn hình đếm lại từ đó.
    ///
    /// `.voiceCall` **chưa được hỗ trợ**: hợp đồng `resend-otp` đã xác nhận không có tham số kênh,
    /// nên ném `ILOtpError.voiceCallUnsupported` mà không gọi mạng. Xem `Docs/Specs/Otp/`.
    func resendCode(phoneNumber: String, channel: ILOtpChannel) async throws -> ILOtpTimingEntity

    /// Xác thực `code` với mã đã gửi cho `phoneNumber`. Thành công lưu luôn phiên đăng nhập
    /// (token vào Keychain, user vào `ILUserRepository`) — xem `Docs/Specs/Otp/design.md`.
    func verifyCode(phoneNumber: String, code: String) async throws
}

final class ILOtpUseCaseImpl: ILOtpUseCase {

    /// Keychain key the refresh token is stored under. Token refresh is not implemented yet, so
    /// nothing reads it back; when that flow lands this constant should move next to
    /// `KeychainAuthTokenProviding.accessTokenKey`, the single place that owns the access-token key.
    static let refreshTokenKey = "refresh_token"

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

    func getInitialState(phoneNumber: String, otpExpiresInSeconds: Int, resendAfterSeconds: Int) -> ILOtpStateModel {
        var state = ILOtpStateModel.initial
        state.phoneNumber = phoneNumber
        state.otpExpiresInSeconds = otpExpiresInSeconds
        state.secondsRemaining = resendAfterSeconds
        return state
    }

    func resendCode(phoneNumber: String, channel: ILOtpChannel) async throws -> ILOtpTimingEntity {
        // The confirmed resend-otp contract has no channel field. Refuse rather than silently
        // sending an SMS for a "call me instead" request — see Docs/Specs/Otp/requirements.md.
        guard channel == .sms else {
            throw ILOtpError.voiceCallUnsupported
        }
        return try await repository.resendRegistrationOTP(phoneNumber: phoneNumber)
    }

    func verifyCode(phoneNumber: String, code: String) async throws {
        let session = try await repository.verifyRegistrationOTP(phoneNumber: phoneNumber, code: code)

        // Store the session last: the account and pending_registration are already gone
        // server-side, so a storage failure cannot be recovered by retrying this call — it is
        // surfaced as its own case so the message can say so.
        do {
            try keychainService.save(
                key: KeychainAuthTokenProviding.accessTokenKey,
                value: session.accessToken
            )
            try keychainService.save(key: Self.refreshTokenKey, value: session.refreshToken)
            try await userRepository.saveUser(session.user)
        } catch {
            throw ILOtpError.storageFailed
        }
    }
}
