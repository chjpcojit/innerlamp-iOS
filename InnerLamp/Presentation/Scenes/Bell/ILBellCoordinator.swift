//
//  ILBellCoordinator.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import UIKit
import Combine

/// Leaf screen — no delegate. `ILBellNavEvent.goBack` only pops the screen and calls `finish()`;
/// the parent (`ILHomeCoordinator`) needs no further reaction.
final class ILBellCoordinator: Coordinator {

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
        let viewModel = container.makeBellViewModel()

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .goBack:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                }
            }
            .store(in: &cancellables)

        let viewController = ILBellViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
