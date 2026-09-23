//
//  ILHomeCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILHomeCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?

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
        let viewModel = container.makeHomeViewModel()

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                switch event {
                case .openMala:
                    self?.showMala()
                case .openLunarCalendar:
                    self?.showLunarCalendar()
                }
            }
            .store(in: &cancellables)

        let viewController = ILHomeViewController(viewModel: viewModel)
        navigationController.setViewControllers([viewController], animated: false)
    }

    private func showLunarCalendar() {
        let coordinator = container.makeLunarCalendarCoordinator(navigationController: navigationController)
        addChild(coordinator)
        coordinator.start()
    }

    private func showMala() {
        let coordinator = container.makeMalaCoordinator(navigationController: navigationController)
        addChild(coordinator)
        coordinator.start()
    }
}
