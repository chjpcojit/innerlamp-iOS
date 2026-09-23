//
//  ILForgotPasswordCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

protocol ILForgotPasswordCoordinatorDelegate: AnyObject {
    /// Đã gửi hướng dẫn tới số điện thoại — mượn lại luồng OTP xác thực đã có.
    func forgotPasswordDidRequestOtp(_ coordinator: ILForgotPasswordCoordinator, phoneNumber: String)
    /// Đã gửi hướng dẫn qua email — xác thực đặt lại mật khẩu qua email (chưa có trong scope hiện tại).
    func forgotPasswordDidRequestEmailReset(_ coordinator: ILForgotPasswordCoordinator, email: String)
}

final class ILForgotPasswordCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?
    weak var delegate: ILForgotPasswordCoordinatorDelegate?

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
        let viewModel = container.makeForgotPasswordViewModel()

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .goBack:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .goToOtp(let phoneNumber):
                    // Mượn lại luồng OTP xác thực số điện thoại đã có (giống SignUp → OTP). Màn
                    // Forgot vẫn đứng yên dưới OTP trên stack nên không finish() ở đây.
                    self.delegate?.forgotPasswordDidRequestOtp(self, phoneNumber: phoneNumber)
                case .didRequestEmailReset(let email):
                    // Xác thực đặt lại mật khẩu qua email chưa có màn riêng trong scope hiện tại —
                    // Forgot VC vẫn đứng yên, không finish() kẻo coordinator bị dealloc trong khi
                    // VC còn sống.
                    self.delegate?.forgotPasswordDidRequestEmailReset(self, email: email)
                }
            }
            .store(in: &cancellables)

        let viewController = ILForgotPasswordViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
