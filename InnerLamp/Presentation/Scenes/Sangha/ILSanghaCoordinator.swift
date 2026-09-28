//
//  ILSanghaCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILSanghaCoordinator: Coordinator {

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
        let viewModel = container.makeSanghaViewModel()

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                switch event {
                case .openFindSangha:
                    // TODO: mở màn danh sách/tìm đạo tràng (chưa build — không phải Trang chùa).
                    break
                case .startSitting:
                    // TODO: điều hướng sang Chuẩn bị thiền (`setup`) khi có luồng Đèn.
                    break
                case .openCompose:
                    // TODO: present màn Viết bài (`compose`, modal) khi có coordinator.
                    break
                case .openEvents:
                    self?.showEvents()
                case .openCommunity(let id):
                    self?.showTemple(id)
                case .openPost(let id):
                    self?.showPost(id: id)
                }
            }
            .store(in: &cancellables)

        let viewController = ILSanghaViewController(viewModel: viewModel)
        navigationController.setViewControllers([viewController], animated: false)
    }

    private func showPost(id: String) {
        let coordinator = container.makePostCoordinator(navigationController: navigationController, postID: id)
        addChild(coordinator)
        coordinator.start()
    }

    private func showEvents() {
        let coordinator = container.makeEventsCoordinator(navigationController: navigationController)
        addChild(coordinator)
        coordinator.start()
    }

    private func showTemple(_ templeID: String) {
        let coordinator = container.makeTempleCoordinator(navigationController: navigationController, templeID: templeID)
        addChild(coordinator)
        coordinator.start()
    }
}
