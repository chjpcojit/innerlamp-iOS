//
//  ILProfileCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILProfileCoordinator: Coordinator {

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
        let viewModel = container.makeProfileViewModel()

        viewModel.navigationEventPublisher
            .sink { event in
                switch event {
                case .editProfile:
                    self.showEditProfile()
                case .openStats:
                    self.showStats()
                case .openAwards:
                    // TODO: điều hướng sang Dấu ấn tu tập (`awards`) khi có coordinator.
                    break
                case .openOffering:
                    // TODO: điều hướng sang Cúng dường (`offer`) khi có coordinator.
                    break
                case .openPaywall:
                    // TODO: present màn gói Sen Vàng (`paywall`, modal) khi có coordinator.
                    break
                case .openReminder:
                    // TODO: điều hướng sang Chuông tỉnh thức (`remind`) khi có coordinator.
                    break
                case .openSettings:
                    self.showSettings()
                case .openNotifications:
                    self.showNotifications()
                case .openFamilyTree:
                    self.showFamilyTree()
                case .openCommunity:
                    // TODO: điều hướng sang Trang chùa (`temple`) theo id khi có coordinator.
                    break
                }
            }
            .store(in: &cancellables)

        let viewController = ILProfileViewController(viewModel: viewModel)
        navigationController.setViewControllers([viewController], animated: false)
    }

    private func showSettings() {
        let coordinator = container.makeSettingsCoordinator(navigationController: navigationController)
        addChild(coordinator)
        coordinator.start()
    }

    private func showEditProfile() {
        let coordinator = container.makeEditProfileCoordinator(navigationController: navigationController)
        addChild(coordinator)
        coordinator.start()
    }

    private func showStats() {
        let coordinator = container.makeStatsCoordinator(navigationController: navigationController)
        addChild(coordinator)
        coordinator.start()
    }

    private func showFamilyTree() {
        let coordinator = container.makeFamilyTreeCoordinator(navigationController: navigationController)
        addChild(coordinator)
        coordinator.start()
    }

    private func showNotifications() {
        let coordinator = container.makeNotificationsCoordinator(navigationController: navigationController)
        addChild(coordinator)
        coordinator.start()
    }
}
