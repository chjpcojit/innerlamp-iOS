//
//  ILEditProfileCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// Edit Profile is a child screen of the "Tôi" tab, pushed onto the tab's navigation stack by
/// `ILProfileCoordinator` (Profile header "Sửa hồ sơ") or `ILSettingsCoordinator` (account card).
/// No delegate — leaving the screen is a plain pop, and the remaining destinations (avatar picker,
/// visibility picker, change password, delete account) are not built yet.
final class ILEditProfileCoordinator: Coordinator {

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
        let viewModel = container.makeEditProfileViewModel()

        viewModel.navigationEventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .goBack, .saved:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .changeAvatar:
                    // TODO: present the photo picker / camera once the avatar upload flow is designed.
                    break
                case .openVisibility:
                    // TODO: present a visibility picker (Công khai / Chỉ mình tôi / Ẩn danh) — not in the handoff yet.
                    break
                case .changePassword:
                    // TODO: navigate to Change Password once that screen is built.
                    break
                case .deleteAccount:
                    // TODO: confirm (destructive ILAlert) then run the delete-account flow once its API is confirmed.
                    break
                }
            }
            .store(in: &cancellables)

        let viewController = ILEditProfileViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
