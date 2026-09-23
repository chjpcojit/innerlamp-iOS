//
//  ILMalaCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// Màn lá — không có delegate: `ILMalaNavEvent.goBack` chỉ pop màn và tự `finish()`, parent
/// (`ILHomeCoordinator`) không cần phản ứng gì thêm.
final class ILMalaCoordinator: Coordinator {

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
        let viewModel = container.makeMalaViewModel()

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .goBack:
                    ilDebugLog("MALA-COORD goBack top=\(String(describing: navigationController.topViewController)) count=\(navigationController.viewControllers.count)")
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                }
            }
            .store(in: &cancellables)

        let viewController = ILMalaViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
