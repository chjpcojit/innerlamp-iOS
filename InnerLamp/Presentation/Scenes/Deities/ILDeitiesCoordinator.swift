//
//  ILDeitiesCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// Owner of the "Chư Phật & Bồ Tát" list flow. It pushes its own screen, forwards taps to the
/// existing `ILDeityCoordinator` (detail), and pops + finishes on back. No delegate protocol: the
/// parent (`ILHomeCoordinator` or `ILLibraryCoordinator`) doesn't need a completion callback from
/// this leaf flow.
final class ILDeitiesCoordinator: Coordinator {

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
        let viewModel = container.makeDeitiesViewModel()

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .back:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .openDeity(let id):
                    self.showDeity(id)
                }
            }
            .store(in: &cancellables)

        let viewController = ILDeitiesViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    private func showDeity(_ deityID: String) {
        let coordinator = container.makeDeityCoordinator(
            navigationController: navigationController,
            deityID: deityID
        )
        addChild(coordinator)
        coordinator.start()
    }
}
