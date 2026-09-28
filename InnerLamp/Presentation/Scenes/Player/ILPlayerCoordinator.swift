//
//  ILPlayerCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// Leaf screen — no delegate: `ILPlayerNavEvent.back` just pops and `finish()`s, the parent
/// (`ILReaderCoordinator` / `ILSutraDetailCoordinator`) needs no further reaction.
/// `.openTableOfContents` (the "Mục lục" pill) is still a TODO — the chapter-list destination
/// (màn `detail` / `SutraDetail`) is reached through a different flow that hasn't been wired to the
/// player yet.
final class ILPlayerCoordinator: Coordinator {

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
        let viewModel = container.makePlayerViewModel(sutraID: sutraID)

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .back:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .openTableOfContents:
                    // TODO: open the chapter list (SutraDetail / màn `detail`). Not wired yet —
                    // the player is pushed on top of the reader/detail stack, so opening the table
                    // of contents needs a dedicated navigation decision.
                    break
                }
            }
            .store(in: &cancellables)

        let viewController = ILPlayerViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
