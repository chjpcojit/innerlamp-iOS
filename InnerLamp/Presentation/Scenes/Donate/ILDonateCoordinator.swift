//
//  ILDonateCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// "Ủng hộ InnerLamp" flow — one modal screen with three steps. Presented over the Profile
/// navigation controller; `.close` dismisses the modal and finishes the flow.
final class ILDonateCoordinator: Coordinator {

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
        startModal()
    }

    func startModal() {
        let viewModel = container.makeDonateViewModel()
        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .close:
                    self.navigationController.dismiss(animated: true)
                    self.finish()
                }
            }
            .store(in: &cancellables)

        let viewController = ILDonateViewController(viewModel: viewModel)
        let modalNavigation = BaseNavigationController(rootViewController: viewController)
        modalNavigation.modalPresentationStyle = .fullScreen
        navigationController.present(modalNavigation, animated: true)
    }
}
