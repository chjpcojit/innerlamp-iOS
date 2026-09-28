//
//  ILTalkCoordinator.swift
//  InnerLamp
//
//  Created by ChjpCoj on 27/9/26.
//

import UIKit
import Combine

/// Màn lá — không có delegate: `ILTalkNavEvent.back` chỉ pop màn và tự `finish()`, parent
/// (`ILLibraryCoordinator`) không cần phản ứng gì thêm. `.openMeditationSetup` present màn Chuẩn bị
/// thiền dạng modal full-screen (xem `ILMeditationSetupCoordinator`) làm child.
final class ILTalkCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?

    private let container: DIContainer
    private let talkID: String
    private var cancellables = Set<AnyCancellable>()

    init(
        navigationController: UINavigationController,
        container: DIContainer,
        talkID: String
    ) {
        self.navigationController = navigationController
        self.container = container
        self.talkID = talkID
    }

    func start() {
        let viewModel = container.makeTalkViewModel(talkID: talkID)

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .back:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .openMeditationSetup:
                    self.showMeditationSetup()
                }
            }
            .store(in: &cancellables)

        let viewController = ILTalkViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    /// Màn Chuẩn bị thiền tự present modal full-screen (xem `ILMeditationSetupCoordinator`).
    private func showMeditationSetup() {
        let coordinator = container.makeMeditationSetupCoordinator(navigationController: navigationController)
        addChild(coordinator)
        coordinator.start()
    }
}
