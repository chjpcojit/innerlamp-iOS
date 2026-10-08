//
//  ILReaderCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// Leaf screen — no delegate: `ILReaderNavEvent.back` just pops the screen and calls `finish()`;
/// the parent (`ILSutraDetailCoordinator` / `ILLibraryCoordinator`) needs no further reaction.
final class ILReaderCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?

    private let container: DIContainer
    private let sutraID: String
    private var cancellables = Set<AnyCancellable>()

    init(
        navigationController: UINavigationController,
        container: DIContainer,
        sutraID: String
    ) {
        self.navigationController = navigationController
        self.container = container
        self.sutraID = sutraID
    }

    func start() {
        let viewModel = container.makeReaderViewModel(sutraID: sutraID)

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .back:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                }
            }
            .store(in: &cancellables)

        let viewController = ILReaderViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
