//
//  ILOnboardingCoordinator.swift
//  InnerLamp
//
//  Created by ChjpCoj on 12/9/26.
//

import UIKit
import Combine

protocol ILOnboardingCoordinatorDelegate: AnyObject {
    func onboardingDidRequestSignup(_ coordinator: ILOnboardingCoordinator)
    func onboardingDidRequestLogin(_ coordinator: ILOnboardingCoordinator)
}

final class ILOnboardingCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?
    weak var delegate: ILOnboardingCoordinatorDelegate?

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
        let viewModel = container.makeOnboardingViewModel()

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .goToSignup:
                    // SignUp được PUSH lên trên (không thay stack) — Onboarding VC vẫn còn trên
                    // stack và có thể quay lại bằng nút back, nên coordinator này phải sống tiếp
                    // để còn nhận sự kiện. finish() ở đây sẽ làm nó bị dealloc, khiến subscription
                    // (weak self) chết theo và nút bấm ở Onboarding hết tác dụng.
                    self.delegate?.onboardingDidRequestSignup(self)
                case .goToLogin:
                    // Login dùng setViewControllers (thay toàn bộ stack) nên Onboarding VC không
                    // còn đường quay lại — an toàn để finish() ngay.
                    self.delegate?.onboardingDidRequestLogin(self)
                    self.finish()
                }
            }
            .store(in: &cancellables)

        let viewController = ILOnboardingViewController(viewModel: viewModel)
        navigationController.setViewControllers([viewController], animated: true)
    }
}
