//
//  ILStatsCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// Stats ("Tiến trình tu tập") is a child screen of the Me tab (`ILProfileCoordinator`), pushed on
/// that tab's navigation stack. The next screen (mindfulness bell reminder, `remind`) is not built
/// yet, so it stays a TODO. No delegate needed — every outgoing navigation is either a pop or has
/// no destination yet.
final class ILStatsCoordinator: Coordinator {

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
        let viewModel = container.makeStatsViewModel()

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .goBack:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .openReminder:
                    // TODO: navigate to the mindfulness bell reminder (`remind`) once its coordinator exists.
                    break
                }
            }
            .store(in: &cancellables)

        let viewController = ILStatsViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
