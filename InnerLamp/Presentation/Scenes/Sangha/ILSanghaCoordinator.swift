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
            .sink { event in
                switch event {
                case .openFindSangha:
                    // TODO: điều hướng sang Trang chùa (`temple`) khi có coordinator.
                    break
                case .startSitting:
                    // TODO: điều hướng sang Chuẩn bị thiền (`setup`) khi có luồng Đèn.
                    break
                case .openCompose:
                    // TODO: present màn Viết bài (`compose`, modal) khi có coordinator.
                    break
                case .openEvents:
                    // TODO: điều hướng sang Sự kiện & khóa học (`events`) khi có coordinator.
                    break
                case .openCommunity:
                    // TODO: điều hướng sang Trang chùa (`temple`) theo id khi có coordinator.
                    break
                case .openPost:
                    // TODO: điều hướng sang Bài đăng (`post`) theo id khi có coordinator.
                    break
                }
            }
            .store(in: &cancellables)

        let viewController = ILSanghaViewController(viewModel: viewModel)
        navigationController.setViewControllers([viewController], animated: false)
    }
}
