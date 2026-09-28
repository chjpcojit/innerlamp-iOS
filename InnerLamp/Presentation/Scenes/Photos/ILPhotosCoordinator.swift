//
//  ILPhotosCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// Màn lá — không có delegate: `ILPhotosNavEvent.back` chỉ pop màn và tự `finish()`, parent
/// (`ILHomeCoordinator`) không cần phản ứng gì thêm.
final class ILPhotosCoordinator: Coordinator {

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
        let viewModel = container.makePhotosViewModel()

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

        let viewController = ILPhotosViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
