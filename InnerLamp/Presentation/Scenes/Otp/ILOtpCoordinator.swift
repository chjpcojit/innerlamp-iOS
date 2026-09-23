//
//  ILOtpCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

protocol ILOtpCoordinatorDelegate: AnyObject {
    /// Xác thực mã thành công cho `phoneNumber`.
    func otpDidVerify(_ coordinator: ILOtpCoordinator, phoneNumber: String)
}

final class ILOtpCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?
    weak var delegate: ILOtpCoordinatorDelegate?

    private let container: DIContainer
    private let phoneNumber: String
    private let otpExpiresInSeconds: Int
    private let resendAfterSeconds: Int
    private var cancellables = Set<AnyCancellable>()

    init(
        navigationController: UINavigationController,
        container: DIContainer,
        phoneNumber: String,
        otpExpiresInSeconds: Int,
        resendAfterSeconds: Int
    ) {
        self.navigationController = navigationController
        self.container = container
        self.phoneNumber = phoneNumber
        self.otpExpiresInSeconds = otpExpiresInSeconds
        self.resendAfterSeconds = resendAfterSeconds
    }

    func start() {
        let viewModel = container.makeOtpViewModel(
            phoneNumber: phoneNumber,
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
                case .didVerify(let phoneNumber):
                    self.delegate?.otpDidVerify(self, phoneNumber: phoneNumber)
                    self.finish()
                }
            }
            .store(in: &cancellables)

        let viewController = ILOtpViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
