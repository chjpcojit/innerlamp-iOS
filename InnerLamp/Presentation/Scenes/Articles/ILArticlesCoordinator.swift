//
//  ILArticlesCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// Owner of the "All articles" flow. It pushes its own screen, forwards taps to the existing
/// `ILArticleCoordinator` (article detail), and pops + finishes on back. No delegate protocol:
/// the parent (`ILHomeCoordinator`) doesn't need a completion callback from this leaf flow.
final class ILArticlesCoordinator: Coordinator {

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
        let viewModel = container.makeArticlesViewModel()

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .back:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .openArticle(let id):
                    self.showArticle(id)
                }
            }
            .store(in: &cancellables)

        let viewController = ILArticlesViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    private func showArticle(_ articleID: String) {
        let coordinator = container.makeArticleCoordinator(
            navigationController: navigationController,
            articleID: articleID
        )
        addChild(coordinator)
        coordinator.start()
    }
}
