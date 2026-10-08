//
//  ILSutrasCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// Owner of the "Kinh sách" list flow. It pushes its own screen, forwards taps to the existing
/// `ILSutraDetailCoordinator`, and pops + finishes on back. No delegate protocol: the parent
/// (`ILLibraryCoordinator`) doesn't need a completion callback from this leaf flow.
final class ILSutrasCoordinator: Coordinator {

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
        let viewModel = container.makeSutrasViewModel()

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .back:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .openSutra(let id):
                    self.showSutraDetail(id)
                }
            }
            .store(in: &cancellables)

        let viewController = ILSutrasViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    private func showSutraDetail(_ sutraID: String) {
        let coordinator = container.makeSutraDetailCoordinator(
            navigationController: navigationController,
            sutraID: sutraID
        )
        addChild(coordinator)
        coordinator.start()
    }
}
