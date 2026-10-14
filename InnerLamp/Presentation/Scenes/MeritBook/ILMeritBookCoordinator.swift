//
//  ILMeritBookCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// "Sổ công đức" is a pushed child of the "Tôi" tab (`ILProfileCoordinator`). The only exit besides
/// back is the donation flow, which is not built yet, so it stays a TODO.
final class ILMeritBookCoordinator: Coordinator {

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
        let viewModel = container.makeMeritBookViewModel()

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .goBack:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .openDonate:
                    // TODO: open the donation flow (`donate`) when its coordinator exists.
                    break
                }
            }
            .store(in: &cancellables)

        let viewController = ILMeritBookViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
