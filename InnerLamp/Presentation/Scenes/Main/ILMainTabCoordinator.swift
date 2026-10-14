//
//  ILMainTabCoordinator.swift
//  InnerLamp
//

import UIKit

/// Sở hữu `ILMainTabBarController` và coordinator của từng tab. `navigationController` là nav
/// gốc của app (do `AppCoordinator` truyền vào) — tab bar được đặt làm màn duy nhất của nó;
/// mỗi tab có `BaseNavigationController` riêng để push màn con mà không ảnh hưởng tab khác.
final class ILMainTabCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?

    /// Called when the user signed out from the Me tab — the app owner leaves the main area for Login.
    var onLogout: (() -> Void)?

    private let container: DIContainer

    init(navigationController: UINavigationController, container: DIContainer) {
        self.navigationController = navigationController
        self.container = container
    }

    func start() {
        let tabBarController = ILMainTabBarController()

        let homeNavigation = BaseNavigationController()
        let homeCoordinator = container.makeHomeCoordinator(navigationController: homeNavigation)
        addChild(homeCoordinator)
        homeCoordinator.onOpenProfile = { [weak tabBarController] in
            tabBarController?.selectTab(.me)
        }
        homeCoordinator.start()

        let libraryNavigation = BaseNavigationController()
        let libraryCoordinator = container.makeLibraryCoordinator(navigationController: libraryNavigation)
        addChild(libraryCoordinator)
        libraryCoordinator.start()

        let sanghaNavigation = BaseNavigationController()
        let sanghaCoordinator = container.makeSanghaCoordinator(navigationController: sanghaNavigation)
        addChild(sanghaCoordinator)
        sanghaCoordinator.start()

        let meNavigation = BaseNavigationController()
        let profileCoordinator = container.makeProfileCoordinator(navigationController: meNavigation)
        addChild(profileCoordinator)
        profileCoordinator.onLogout = { [weak self] in self?.onLogout?() }
        profileCoordinator.start()

        // Thứ tự phải khớp `ILMainTabBarController.tabOrder`.
        tabBarController.setViewControllers(
            [homeNavigation, libraryNavigation, sanghaNavigation, meNavigation],
            animated: false
        )

        // Nút Đèn giữa bar — present màn Thắp đèn (modal full-screen, phủ tab bar).
        tabBarController.onLampTapped = { [weak self] in self?.showLightLamp() }

        navigationController.setNavigationBarHidden(true, animated: false)
        navigationController.setViewControllers([tabBarController], animated: true)
    }

    private func showLightLamp() {
        let coordinator = container.makeLightLampCoordinator(navigationController: navigationController)
        addChild(coordinator)
        coordinator.startModal()
    }
}
