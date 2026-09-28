//
//  ILLoginUseCase.swift
//  InnerLamp
//

import Foundation

enum ILLoginError: Error, LocalizedError, Equatable {
    case invalidCredentials
    case invalidPhone
    case invalidPassword
    case invalidDevice
    /// `details.locked_until` from a 429 `LOGIN_LOCKED` — 5 consecutive failed attempts lock the
    /// number for 15 minutes (`Docs/Specs/API/openapi.yaml` v3.9).
    case loginLocked(lockedUntil: String?)
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
        case .invalidPhone:
            return "login.error.phoneInvalid".localized
        case .invalidPassword:
            return "login.error.passwordRequired".localized
        case .invalidDevice:
            return "login.error.invalidDevice".localized
        case .loginLocked(let lockedUntil):
            guard let formatted = ILUnlockTimeFormatter.displayString(from: lockedUntil) else {
                return "login.error.locked".localized
            }
            return String(format: "login.error.lockedUntil".localized, formatted)
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

    /// Trả về message lỗi (`nil` nếu hợp lệ). Chạy mỗi lần bấm "Đăng nhập", không chạy
    /// theo từng ký tự gõ. `nationalDigits`/`country` lấy từ `ILLoginStateModel` — cùng quy tắc
    /// với `ILSignUpUseCase.validatePhoneNumber`.
    func validatePhone(nationalDigits: String, country: ILCountry) -> String?
    func validatePassword(_ value: String) -> String?

    /// Đăng nhập bằng số điện thoại + mật khẩu. Thành công lưu luôn phiên đăng nhập (token vào
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

    func validatePhone(nationalDigits: String, country: ILCountry) -> String? {
        guard !nationalDigits.isEmpty else { return "login.error.phoneRequired".localized }
        guard country.isValidNationalDigitCount(nationalDigits.count) else {
            return "login.error.phoneInvalid".localized
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
