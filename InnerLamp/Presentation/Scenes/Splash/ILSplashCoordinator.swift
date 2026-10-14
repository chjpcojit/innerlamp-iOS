//
//  ILSplashCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

protocol ILSplashCoordinatorDelegate: AnyObject {
    func splashDidRequestOnboarding(_ coordinator: ILSplashCoordinator)
    func splashDidRequestSignup(_ coordinator: ILSplashCoordinator)
    func splashDidRequestMain(_ coordinator: ILSplashCoordinator)
}

final class ILSplashCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?
    weak var delegate: ILSplashCoordinatorDelegate?

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
        let viewModel = container.makeSplashViewModel()

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .goToOnboarding:
                    self.delegate?.splashDidRequestOnboarding(self)
                    self.finish()
                case .goToSignup:
                    self.delegate?.splashDidRequestSignup(self)
                    self.finish()
                case .goToMain:
                    self.delegate?.splashDidRequestMain(self)
                    self.finish()
                }
            }
            .store(in: &cancellables)

        let viewController = ILSplashViewController(viewModel: viewModel)
        navigationController.setViewControllers([viewController], animated: false)
    }
}
