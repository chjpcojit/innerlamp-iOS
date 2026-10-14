//
//  ILTemplesCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// Owner of the "Tất cả chùa" list flow. Pushes its own screen, forwards taps to the existing
/// `ILTempleCoordinator` (detail), and pops + finishes on back. Leaf flow: no delegate.
final class ILTemplesCoordinator: Coordinator {

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
        let viewModel = container.makeTemplesViewModel()

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .back:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .openTemple(let id):
                    self.showTemple(id)
                }
            }
            .store(in: &cancellables)

        let viewController = ILTemplesViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    private func showTemple(_ templeID: String) {
        let coordinator = container.makeTempleCoordinator(navigationController: navigationController, templeID: templeID)
        addChild(coordinator)
        coordinator.start()
    }
}
