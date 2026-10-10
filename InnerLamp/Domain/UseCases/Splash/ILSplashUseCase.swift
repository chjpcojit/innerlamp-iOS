//
//  ILSplashUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILSplashUseCase {
    func getInitialState() -> ILSplashStateModel
    /// Đã hoàn thành onboarding chưa — quyết định Splash sẽ chuyển tới Onboarding hay Main.
    func isOnboardingCompleted() -> Bool
    /// Có phiên đăng nhập đã lưu (access token trong Keychain) hay không — quyết định Splash vào
    /// thẳng Main. Chỉ kiểm tra token tồn tại, không kiểm tra hạn: token hết hạn sẽ bị server
    /// trả 401 ở request đầu tiên.
    func hasSession() -> Bool
}

/// Không tự lưu trữ gì — Splash chỉ cần đọc lại trạng thái onboarding đã có sẵn ở
/// `ILOnboardingUseCase` để quyết định điểm đến kế tiếp, tránh trùng key UserDefaults.
final class ILSplashUseCaseImpl: ILSplashUseCase {

    private let onboardingUseCase: ILOnboardingUseCase
    private let keychainService: KeychainService
    private let userDefaultsService: UserDefaultsService

    /// UserDefaults is wiped with the app, the Keychain is not — a missing flag therefore means
    /// "fresh install", whatever the Keychain still holds from a previous install.
    private static let hasLaunchedBeforeKey = "has_launched_before"

    /// Item của bản dev cũ (mock đăng ký) từng lưu `{displayName, phoneNumber, password}` dạng thô
    /// trong Keychain. Không còn code nào ghi nó, nhưng Keychain sống sót qua cập nhật và cài lại —
    /// xoá ở mọi lần khởi động để mật khẩu không nằm lại trên máy.
    private static let legacyPendingSignUpKey = "signup_pending_credentials"

    init(
        onboardingUseCase: ILOnboardingUseCase,
        keychainService: KeychainService,
        userDefaultsService: UserDefaultsService
    ) {
        self.onboardingUseCase = onboardingUseCase
        self.keychainService = keychainService
        self.userDefaultsService = userDefaultsService
    }

    func getInitialState() -> ILSplashStateModel {
        ILSplashStateModel.initial
    }

    func isOnboardingCompleted() -> Bool {
        onboardingUseCase.isOnboardingCompleted()
    }

    func hasSession() -> Bool {
        purgeLegacyCredentials()
        discardKeychainSessionOnFreshInstall()
        return keychainService.exists(key: KeychainAuthTokenProviding.accessTokenKey)
    }

    /// Xoá không cần xác thực và không lỗi khi item không tồn tại, nên gọi mỗi lần là an toàn.
    private func purgeLegacyCredentials() {
        try? keychainService.delete(key: Self.legacyPendingSignUpKey)
    }

    private func discardKeychainSessionOnFreshInstall() {
        guard !userDefaultsService.loadBool(key: Self.hasLaunchedBeforeKey) else { return }
        try? keychainService.delete(key: KeychainAuthTokenProviding.accessTokenKey)
        try? keychainService.delete(key: KeychainAuthTokenProviding.refreshTokenKey)
        userDefaultsService.saveBool(key: Self.hasLaunchedBeforeKey, value: true)
    }
}
