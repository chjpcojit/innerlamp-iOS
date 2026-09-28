//
//  ILSettingsCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// Màn Cài đặt là màn con của tab Tôi (`ILProfileCoordinator`), push lên nav của tab đó. Các màn
/// con tiếp theo (chọn tiếng chuông, ngôn ngữ, trợ giúp, tải dữ liệu, ngoại tuyến) chưa build nên
/// giữ TODO. Không cần delegate — mọi điều hướng ra ngoài hiện chỉ là pop hoặc chưa có đích.
final class ILSettingsCoordinator: Coordinator {

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
        let viewModel = container.makeSettingsViewModel()

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .goBack:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .openProfile:
                    self.showEditProfile()
                case .openBellSound:
                    // TODO: điều hướng sang chọn tiếng chuông khi có coordinator.
                    break
                case .openDarkMode, .openLanguage:
                    // TODO: điều hướng sang Ngôn ngữ & hiển thị (`lang`) khi có coordinator.
                    break
                case .openDownloads:
                    // TODO: điều hướng sang Nghe không cần mạng (`downloads`) khi có coordinator.
                    break
                case .openHelp:
                    // TODO: điều hướng sang Trợ giúp & câu hỏi thường gặp (`faq`) khi có coordinator.
                    break
                case .openExportData:
                    // TODO: tải dữ liệu tu tập của tôi (export) khi có coordinator.
                    break
                case .openOffline:
                    // TODO: điều hướng sang trạng thái ngoại tuyến (`offline`) khi có coordinator.
                    break
                }
            }
            .store(in: &cancellables)

        let viewController = ILSettingsViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    private func showEditProfile() {
        let coordinator = container.makeEditProfileCoordinator(navigationController: navigationController)
        addChild(coordinator)
        coordinator.start()
    }
}
