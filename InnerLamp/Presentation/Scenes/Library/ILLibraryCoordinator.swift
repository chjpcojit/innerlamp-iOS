//
//  ILLibraryCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILLibraryCoordinator: Coordinator {

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
        let viewModel = container.makeLibraryViewModel()

        viewModel.navigationEventPublisher
            .sink { event in
                switch event {
                case .openSearch:
                    // TODO: điều hướng sang màn Tìm kiếm khi có ILSearchCoordinator.
                    break
                case .openItem:
                    // TODO: điều hướng theo `kind` (chi tiết kinh / thiền dẫn / pháp thoại) khi các
                    // màn đó có coordinator — xem "Pending" trong Docs/Specs/Library/requirements.md.
                    break
                }
            }
            .store(in: &cancellables)

        let viewController = ILLibraryViewController(viewModel: viewModel)
        navigationController.setViewControllers([viewController], animated: false)
    }
}
