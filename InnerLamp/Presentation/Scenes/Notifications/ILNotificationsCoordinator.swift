//
//  ILNotificationsCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// Màn Thông báo là màn con của tab Tôi (`ILProfileCoordinator`), push lên nav của tab đó. Màn con
/// tiếp theo (chuẩn bị thiền `setup` từ nút "Ngồi ngay") chưa build nên giữ TODO. Không cần
/// delegate — mọi điều hướng ra ngoài hiện chỉ là pop hoặc chưa có đích.
final class ILNotificationsCoordinator: Coordinator {

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
        let viewModel = container.makeNotificationsViewModel()

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .goBack:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .openSetup:
                    // TODO: điều hướng sang chuẩn bị thiền (`setup`) khi có coordinator.
                    break
                }
            }
            .store(in: &cancellables)

        let viewController = ILNotificationsViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
