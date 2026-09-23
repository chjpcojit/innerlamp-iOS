//
//  ILProfileCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILProfileCoordinator: Coordinator {

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
        let viewModel = container.makeProfileViewModel()

        viewModel.navigationEventPublisher
            .sink { event in
                switch event {
                case .editProfile:
                    // TODO: điều hướng sang Chỉnh sửa hồ sơ (`edit`) khi có coordinator.
                    break
                case .openStats:
                    // TODO: điều hướng sang Tiến trình tu tập (`stats`) khi có coordinator.
                    break
                case .openAwards:
                    // TODO: điều hướng sang Dấu ấn tu tập (`awards`) khi có coordinator.
                    break
                case .openOffering:
                    // TODO: điều hướng sang Cúng dường (`offer`) khi có coordinator.
                    break
                case .openPaywall:
                    // TODO: present màn gói Sen Vàng (`paywall`, modal) khi có coordinator.
                    break
                case .openReminder:
                    // TODO: điều hướng sang Chuông tỉnh thức (`remind`) khi có coordinator.
                    break
                case .openSettings:
                    // TODO: điều hướng sang Cài đặt (`settings`) khi có coordinator.
                    break
                case .openNotifications:
                    // TODO: điều hướng sang Thông báo (`notif`) khi có coordinator.
                    break
                case .openCommunity:
                    // TODO: điều hướng sang Trang chùa (`temple`) theo id khi có coordinator.
                    break
                }
            }
            .store(in: &cancellables)

        let viewController = ILProfileViewController(viewModel: viewModel)
        navigationController.setViewControllers([viewController], animated: false)
    }
}
