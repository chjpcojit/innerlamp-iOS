//
//  ILLoginUseCase.swift
//  InnerLamp
//

import Foundation

enum ILLoginError: Error, LocalizedError, Equatable {
    case invalidCredentials
    /// EN: `INVALID_EMAIL` — the server could not read the email.
    /// VI: `INVALID_EMAIL` — server không đọc được email.
    case invalidEmail
    case invalidPassword
    case invalidDevice
    /// `details.locked_until` from a 429 `LOGIN_LOCKED` — 5 consecutive failed attempts lock the
    /// email for 15 minutes (innerlamp-be `docs/specs/api/openapi.yaml`).
    case loginLocked(lockedUntil: String?)
    /// EN: `429 RATE_LIMITED` on the per-IP limit, with `details.retry_after_seconds`.
    /// VI: `429 RATE_LIMITED` khi vượt giới hạn theo IP, kèm `details.retry_after_seconds`.
    case rateLimited(retryAfterSeconds: Int?)
    case invalidInput
    case server
    case networkUnavailable
    case timedOut
    /// The session returned by a successful login could not be written to the Keychain / local
    /// user store — same precedent as `ILOtpError.storageFailed`.
    case storageFailed

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "login.error.invalidCredentials".localized
        case .invalidEmail:
            return "login.error.emailInvalid".localized
        case .invalidPassword:
            return "login.error.passwordRequired".localized
        case .invalidDevice:
            return "login.error.invalidDevice".localized
        case .loginLocked(let lockedUntil):
            guard let formatted = ILUnlockTimeFormatter.displayString(from: lockedUntil) else {
                return "login.error.locked".localized
            }
            return String(format: "login.error.lockedUntil".localized, formatted)
        case .rateLimited(let retryAfterSeconds):
            return ILRateLimitMessage.text(retryAfterSeconds: retryAfterSeconds)
        case .invalidInput:
            return "login.error.invalidInput".localized
        case .server:
            return "error.generic".localized
        case .networkUnavailable:
            return "error.no_internet".localized
        case .timedOut:
            return "login.error.timedOut".localized
        case .storageFailed:
            return "login.error.storageFailed".localized
        }
    }
}

protocol ILLoginUseCase {
    func getInitialState() -> ILLoginStateModel

    /// EN: Error message (`nil` when valid), run on each "Đăng nhập" tap. Only emptiness is checked
    ///     (criterion 2); the server answers `INVALID_EMAIL` for a malformed address.
    /// VI: Message lỗi (`nil` nếu hợp lệ), chạy mỗi lần bấm "Đăng nhập". Chỉ kiểm tra rỗng
    ///     (tiêu chí 2); email sai định dạng do server trả `INVALID_EMAIL`.
    func validateEmail(_ value: String) -> String?
    func validatePassword(_ value: String) -> String?

    /// Đăng nhập bằng email + mật khẩu. Thành công lưu luôn phiên đăng nhập (token vào
    /// Keychain, user vào `ILUserRepository`) — cùng pattern với `ILOtpUseCase.verifyCode`, xem
    /// `Docs/Specs/Login/design.md`.
    func login(_ credential: ILLoginEntity) async throws
}

final class ILLoginUseCaseImpl: ILLoginUseCase {

    private let repository: ILLoginRepository
    private let keychainService: KeychainService
    private let userRepository: ILUserRepository

    init(
        repository: ILLoginRepository,
        keychainService: KeychainService,
        userRepository: ILUserRepository
    ) {
        self.repository = repository
        self.keychainService = keychainService
        self.userRepository = userRepository
    }

    func getInitialState() -> ILLoginStateModel {
        ILLoginStateModel.initial
    }

    func validateEmail(_ value: String) -> String? {
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "login.error.emailRequired".localized
        }
        return nil
    }

    func validatePassword(_ value: String) -> String? {
        guard !value.isEmpty else { return "login.error.passwordRequired".localized }
        return nil
    }

    func login(_ credential: ILLoginEntity) async throws {
        let session = try await repository.login(credential)

        // Store the session last: the server already authenticated the credential, so a storage
        // failure cannot be recovered by retrying login — surfaced as its own case so the message
        // can say so (same precedent as `ILOtpUseCaseImpl.verifyCode`).
        do {
            try keychainService.save(
                key: KeychainAuthTokenProviding.accessTokenKey,
                value: session.accessToken
            )
            try keychainService.save(key: KeychainAuthTokenProviding.refreshTokenKey, value: session.refreshToken)
            try await userRepository.saveUser(session.user)
        } catch {
            throw ILLoginError.storageFailed
        }
    }
}
