//
//  ILEventsCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// Màn Sự kiện & khóa học — được đẩy lên từ tab Đạo tràng (`ILSanghaCoordinator`). Không có
/// delegate: `.goBack` chỉ pop màn và tự `finish()`; `.openRegister` còn TODO vì màn Ghi danh
/// (`register`) chưa được dựng.
final class ILEventsCoordinator: Coordinator {

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
        let viewModel = container.makeEventsViewModel()

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .goBack:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .openRegister:
                    // TODO: điều hướng sang màn Ghi danh (`register`) khi có coordinator.
                    break
                }
            }
            .store(in: &cancellables)

        let viewController = ILEventsViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
