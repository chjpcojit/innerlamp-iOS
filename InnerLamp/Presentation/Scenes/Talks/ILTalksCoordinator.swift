//
//  ILTalksCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// Owner of the "Pháp thoại" list flow. It pushes its own screen, forwards taps to the existing
/// `ILTalkCoordinator`, and pops + finishes on back. No delegate protocol: the parent
/// (`ILLibraryCoordinator`) doesn't need a completion callback from this leaf flow.
final class ILTalksCoordinator: Coordinator {

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
        let viewModel = container.makeTalksViewModel()

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .back:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .openTalk(let id):
                    self.showTalk(id)
                }
            }
            .store(in: &cancellables)

        let viewController = ILTalksViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    private func showTalk(_ talkID: String) {
        let coordinator = container.makeTalkCoordinator(
            navigationController: navigationController,
            talkID: talkID
        )
        addChild(coordinator)
        coordinator.start()
    }
}
