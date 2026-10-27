//
//  AppCoordinator.swift
//  InnerLamp
//
//  Created by ChjpCoj on 10/9/26.
//

import UIKit
import Combine

final class AppCoordinator: Coordinator {
    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?
    private let container: DIContainer
    private var cancellables = Set<AnyCancellable>()
    
    init(navigationController: UINavigationController, container: DIContainer) {
        self.navigationController = navigationController
        self.container = container
    }
    
    func start() {
        observeSessionExpiry()
        showSplash()
    }

    /// `AuthSessionRefresher` posts this once a 401 could not be recovered by refreshing — the
    /// tokens are already gone from the Keychain, so all that is left is to leave the main area.
    private func observeSessionExpiry() {
        NotificationCenter.default.publisher(for: .authSessionDidExpire)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.handleSessionExpired() }
            .store(in: &cancellables)
    }

    private func handleSessionExpired() {
        // Only the main area holds a session; ignore a stray post while an auth screen is up.
        guard childCoordinators.contains(where: { $0 is ILMainTabCoordinator }) else { return }
        childCoordinators.removeAll { $0 is ILMainTabCoordinator }

        let userRepository = container.makeUserRepository()
        Task { try? await userRepository.deleteUser() }

        showLogin()
    }

    /// The Me tab already revoked the session and cleared the Keychain + local user; all that is
    /// left is to leave the main area. Same guard as `handleSessionExpired` — a 401 during the
    /// revoke call may have routed to Login already.
    private func handleLoggedOut() {
        guard childCoordinators.contains(where: { $0 is ILMainTabCoordinator }) else { return }
        childCoordinators.removeAll { $0 is ILMainTabCoordinator }
        showLogin()
    }

    private func showSplash() {
        let splashCoordinator = container.makeSplashCoordinator(navigationController: navigationController)
        splashCoordinator.delegate = self
        addChild(splashCoordinator)
        splashCoordinator.start()
    }

    /// Onboarding/Login dùng `setViewControllers` (thay toàn bộ stack), nên mọi coordinator của
    /// các màn đã bị gỡ khỏi stack (kể cả những cái cố tình không finish() vì VC còn sống lúc đó)
    /// giờ đã mồ côi — dọn đi để không rò rỉ.
    private func removeAuthFlowCoordinators() {
        childCoordinators.removeAll {
            $0 is ILOnboardingCoordinator
                || $0 is ILLoginCoordinator
                || $0 is ILSignUpCoordinator
                || $0 is ILForgotPasswordCoordinator
                || $0 is ILOtpCoordinator
        }
    }

    private func showOnboarding() {
        removeAuthFlowCoordinators()
        let onboardingCoordinator = container.makeOnboardingCoordinator(navigationController: navigationController)
        onboardingCoordinator.delegate = self
        addChild(onboardingCoordinator)
        onboardingCoordinator.start()
    }

    /// `asRoot`: SignUp là màn đầu tiên của luồng auth (từ Splash) — thay toàn bộ stack và ẩn nút back,
    /// vì phía sau không còn màn nào để quay lại.
    private func showSignUp(asRoot: Bool = false) {
        if asRoot { removeAuthFlowCoordinators() }
        let signUpCoordinator = container.makeSignUpCoordinator(navigationController: navigationController)
        signUpCoordinator.isRoot = asRoot
        signUpCoordinator.delegate = self
        addChild(signUpCoordinator)
        signUpCoordinator.start()
    }

    private func showLogin() {
        removeAuthFlowCoordinators()
        let loginCoordinator = container.makeLoginCoordinator(navigationController: navigationController)
        loginCoordinator.delegate = self
        addChild(loginCoordinator)
        loginCoordinator.start()
    }

    private func showOtp(email: String, otpExpiresInSeconds: Int, resendAfterSeconds: Int) {
        let otpCoordinator = container.makeOtpCoordinator(
            navigationController: navigationController,
            email: email,
            otpExpiresInSeconds: otpExpiresInSeconds,
            resendAfterSeconds: resendAfterSeconds
        )
        otpCoordinator.delegate = self
        addChild(otpCoordinator)
        otpCoordinator.start()
    }

    private func showForgotPassword() {
        let forgotPasswordCoordinator = container.makeForgotPasswordCoordinator(navigationController: navigationController)
        forgotPasswordCoordinator.delegate = self
        addChild(forgotPasswordCoordinator)
        forgotPasswordCoordinator.start()
    }

    /// Khu vực chính sau đăng nhập: tab bar 4 trang (Trang chủ / Thư viện / Đạo tràng / Tôi).
    private func showMain() {
        let mainTabCoordinator = container.makeMainTabCoordinator(navigationController: navigationController)
        mainTabCoordinator.onLogout = { [weak self] in self?.handleLoggedOut() }
        addChild(mainTabCoordinator)
        mainTabCoordinator.start()
    }
}

// MARK: - ILSplashCoordinatorDelegate
extension AppCoordinator: ILSplashCoordinatorDelegate {
    func splashDidRequestOnboarding(_ coordinator: ILSplashCoordinator) {
        showOnboarding()
    }

    func splashDidRequestSignup(_ coordinator: ILSplashCoordinator) {
        showSignUp(asRoot: true)
    }

    func splashDidRequestMain(_ coordinator: ILSplashCoordinator) {
        showMain()
    }
}

// MARK: - ILOnboardingCoordinatorDelegate
extension AppCoordinator: ILOnboardingCoordinatorDelegate {
    func onboardingDidRequestSignup(_ coordinator: ILOnboardingCoordinator) {
        showSignUp()
    }

    func onboardingDidRequestLogin(_ coordinator: ILOnboardingCoordinator) {
        showLogin()
    }
}

// MARK: - ILSignUpCoordinatorDelegate
extension AppCoordinator: ILSignUpCoordinatorDelegate {
    func signUpDidRequestLogin(_ coordinator: ILSignUpCoordinator) {
        showLogin()
    }

    func signUpDidRequestVerification(
        _ coordinator: ILSignUpCoordinator,
        email: String,
        otpExpiresInSeconds: Int,
        resendAfterSeconds: Int
    ) {
        showOtp(
            email: email,
            otpExpiresInSeconds: otpExpiresInSeconds,
            resendAfterSeconds: resendAfterSeconds
        )
    }
}

// MARK: - ILOtpCoordinatorDelegate
extension AppCoordinator: ILOtpCoordinatorDelegate {
    func otpDidVerify(_ coordinator: ILOtpCoordinator, email: String) {
        showMain()
    }
}

// MARK: - ILLoginCoordinatorDelegate
extension AppCoordinator: ILLoginCoordinatorDelegate {
    func loginDidRequestOnboarding(_ coordinator: ILLoginCoordinator) {
        showOnboarding()
    }

    func loginDidRequestSignup(_ coordinator: ILLoginCoordinator) {
        showSignUp()
    }

    func loginDidRequestForgotPassword(_ coordinator: ILLoginCoordinator) {
        showForgotPassword()
    }

    func loginDidFinishLogin(_ coordinator: ILLoginCoordinator) {
        showMain()
    }

    func loginDidRequestGuestPreview(_ coordinator: ILLoginCoordinator) {
        showMain()
    }
}

// MARK: - ILForgotPasswordCoordinatorDelegate
extension AppCoordinator: ILForgotPasswordCoordinatorDelegate {
    func forgotPasswordDidRequestOtp(_ coordinator: ILForgotPasswordCoordinator, phoneNumber: String) {
        // EN: Reset by phone no longer exists (contract 3.0.0) and the code screen is registration-only,
        //     so it is not opened here. Reset by email code replaces this flow (Login tasks.md Phase 5).
        // VI: Đặt lại mật khẩu bằng số điện thoại không còn (contract 3.0.0) và màn nhập mã chỉ dành cho
        //     đăng ký, nên không mở ở đây. Luồng đặt lại bằng mã email sẽ thay thế (Login tasks.md Phase 5).
    }

    func forgotPasswordDidRequestEmailReset(_ coordinator: ILForgotPasswordCoordinator, email: String) {
        // Xác thực đặt lại mật khẩu qua email chưa có trong scope hiện tại.
        print("Forgot password requested email reset for \(email): Navigate to email verification")
    }
}
