//
//  ILLoginCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

protocol ILLoginCoordinatorDelegate: AnyObject {
    /// Người dùng bấm back trên header — quay lại Onboarding.
    func loginDidRequestOnboarding(_ coordinator: ILLoginCoordinator)
    /// Người dùng chưa có tài khoản, muốn sang luồng Đăng ký.
    func loginDidRequestSignup(_ coordinator: ILLoginCoordinator)
    /// Người dùng bấm "Quên?" cạnh mật khẩu — sang luồng Quên mật khẩu.
    func loginDidRequestForgotPassword(_ coordinator: ILLoginCoordinator)
    /// Đăng nhập thành công — điều hướng sang luồng chính (chưa có trong scope hiện tại).
    func loginDidFinishLogin(_ coordinator: ILLoginCoordinator)
    /// Người dùng bấm "Xem trước, đăng nhập sau" — vào luồng chính không cần đăng nhập.
    func loginDidRequestGuestPreview(_ coordinator: ILLoginCoordinator)
}

final class ILLoginCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?
    weak var delegate: ILLoginCoordinatorDelegate?

    private let container: DIContainer
    private var cancellables = Set<AnyCancellable>()

    init(
        navigationController: UINavigationController,
        container: DIContainer
    ) {
        self.navigationController = navigationController
        self.container = container
    }

    func start() {
        let viewModel = container.makeLoginViewModel()

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .goToOnboarding:
                    self.delegate?.loginDidRequestOnboarding(self)
                    self.finish()
                case .goToSignup:
                    // SignUp được PUSH lên trên Login — Login VC vẫn còn trên stack và người dùng
                    // có thể quay lại bằng nút back, nên không finish() kẻo coordinator bị dealloc
                    // và các nút (Đăng ký, back về Onboarding, Quên?) hết tác dụng.
                    self.delegate?.loginDidRequestSignup(self)
                case .goToForgotPassword:
                    // Login dùng `setViewControllers`, không phải push, nên vẫn là root của
                    // stack — Forgot sẽ được push lên trên. Không finish() ở đây kẻo coordinator
                    // bị dealloc trong khi Login VC còn sống bên dưới.
                    self.delegate?.loginDidRequestForgotPassword(self)
                case .didLoginSuccessfully:
                    self.delegate?.loginDidFinishLogin(self)
                    self.finish()
                case .goToGuestPreview:
                    self.delegate?.loginDidRequestGuestPreview(self)
                    self.finish()
                }
            }
            .store(in: &cancellables)

        let viewController = ILLoginViewController(viewModel: viewModel)
        navigationController.setViewControllers([viewController], animated: true)
    }
}
