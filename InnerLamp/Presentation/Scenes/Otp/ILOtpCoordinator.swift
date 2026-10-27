//
//  ILOtpCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

protocol ILOtpCoordinatorDelegate: AnyObject {
    /// Xác thực mã thành công cho `email`.
    func otpDidVerify(_ coordinator: ILOtpCoordinator, email: String)
}

final class ILOtpCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?
    weak var delegate: ILOtpCoordinatorDelegate?

    private let container: DIContainer
    private let email: String
    private let otpExpiresInSeconds: Int
    private let resendAfterSeconds: Int
    private var cancellables = Set<AnyCancellable>()

    init(
        navigationController: UINavigationController,
        container: DIContainer,
        email: String,
        otpExpiresInSeconds: Int,
        resendAfterSeconds: Int
    ) {
        self.navigationController = navigationController
        self.container = container
        self.email = email
        self.otpExpiresInSeconds = otpExpiresInSeconds
        self.resendAfterSeconds = resendAfterSeconds
    }

    func start() {
        let viewModel = container.makeOtpViewModel(
            email: email,
            otpExpiresInSeconds: otpExpiresInSeconds,
            resendAfterSeconds: resendAfterSeconds
        )

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .goBack:
                    // Quay lại SignUp (VC vẫn còn trên stack, coordinator của nó chưa finish) —
                    // pop rồi finish() chính coordinator OTP này, không đụng tới SignUp.
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .didVerify(let email):
                    self.delegate?.otpDidVerify(self, email: email)
                    self.finish()
                }
            }
            .store(in: &cancellables)

        let viewController = ILOtpViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
