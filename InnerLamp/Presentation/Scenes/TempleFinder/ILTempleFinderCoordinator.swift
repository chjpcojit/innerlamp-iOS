//
//  ILTempleFinderCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// Màn "Chọn chùa tu tập" — được đẩy lên từ tab Chùa ("Đổi chùa"). Không có delegate: `.back` và
/// `.picked` đều pop màn và tự `finish()`; tab Chùa tự tải lại khi hiện lại. Chạm 1 hàng chùa mở
/// Trang chùa.
final class ILTempleFinderCoordinator: Coordinator {

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
        let viewModel = container.makeTempleFinderViewModel()

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .back, .picked:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .openTemple(let id):
                    self.showTemple(id)
                }
            }
            .store(in: &cancellables)

        let viewController = ILTempleFinderViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    private func showTemple(_ templeID: String) {
        let coordinator = container.makeTempleCoordinator(navigationController: navigationController, templeID: templeID)
        addChild(coordinator)
        coordinator.start()
    }
}
