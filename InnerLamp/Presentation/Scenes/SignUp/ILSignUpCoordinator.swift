//
//  ILSignUpCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

protocol ILSignUpCoordinatorDelegate: AnyObject {
    /// Người dùng đã có tài khoản, muốn sang luồng Đăng nhập.
    func signUpDidRequestLogin(_ coordinator: ILSignUpCoordinator)
    /// Đã gửi mã OTP tới `phoneNumber` — điều hướng sang màn xác thực, kèm timing server trả về
    /// (`expires_in_seconds`/`resend_after_seconds`) để màn OTP khởi tạo countdown/hạn mã.
    func signUpDidRequestVerification(
        _ coordinator: ILSignUpCoordinator,
        phoneNumber: String,
        otpExpiresInSeconds: Int,
        resendAfterSeconds: Int
    )
}

final class ILSignUpCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?
    weak var delegate: ILSignUpCoordinatorDelegate?

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
        let viewModel = container.makeSignUpViewModel()

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .goBack:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .goToLogin:
                    self.delegate?.signUpDidRequestLogin(self)
                    self.finish()
                case .didRequestVerification(let phoneNumber, let otpExpiresInSeconds, let resendAfterSeconds):
                    // Không finish() ở đây kẻo coordinator bị dealloc trong khi VC còn sống, làm
                    // nút back/"Tôi đã có tài khoản" hết tác dụng nếu người dùng quay lại từ OTP.
                    self.delegate?.signUpDidRequestVerification(
                        self,
                        phoneNumber: phoneNumber,
                        otpExpiresInSeconds: otpExpiresInSeconds,
                        resendAfterSeconds: resendAfterSeconds
                    )
                }
            }
            .store(in: &cancellables)

        let viewController = ILSignUpViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
