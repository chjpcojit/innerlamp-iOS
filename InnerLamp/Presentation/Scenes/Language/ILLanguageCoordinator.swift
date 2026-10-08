//
//  ILLanguageCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// Language & display is a child screen of Settings (`ILSettingsCoordinator`), pushed onto the
/// Profile tab's navigation stack. No delegate — leaving the screen is a plain pop; Settings
/// refreshes its summary rows itself on `viewWillAppear`.
final class ILLanguageCoordinator: Coordinator {

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
        let viewModel = container.makeLanguageViewModel()

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

        let viewController = ILLanguageViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
