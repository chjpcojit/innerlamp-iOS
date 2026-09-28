//
//  ILMalaCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// Màn lá — không có delegate: `ILMalaNavEvent.goBack` chỉ pop màn và tự `finish()`, parent
/// (`ILHomeCoordinator` / `ILDeityCoordinator`) không cần phản ứng gì thêm.
final class ILMalaCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?

    private let container: DIContainer
    private let mantraText: String?
    private var cancellables = Set<AnyCancellable>()

    init(
        navigationController: UINavigationController,
        container: DIContainer,
        mantraText: String? = nil
    ) {
        self.navigationController = navigationController
        self.container = container
        self.mantraText = mantraText
    }

    func start() {
        let viewModel = container.makeMalaViewModel(mantraText: mantraText)

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
