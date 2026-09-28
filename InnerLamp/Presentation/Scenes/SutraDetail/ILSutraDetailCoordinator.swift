//
//  ILSutraDetailCoordinator.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import UIKit
import Combine

/// Màn lá — không có delegate: `ILSutraDetailNavEvent.back` chỉ pop màn và tự `finish()`, parent
/// (`ILLibraryCoordinator`) không cần phản ứng gì thêm. `.openReader` đẩy màn Tụng kinh, `.openPlayer`
/// đẩy trình phát toàn màn; `.download` chưa có màn đích (màn `downloads` chưa build) nên tạm để TODO.
final class ILSutraDetailCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?

    private let container: DIContainer
    private let sutraID: String
    private var cancellables = Set<AnyCancellable>()

    init(
        navigationController: UINavigationController,
        container: DIContainer,
        sutraID: String
    ) {
        self.navigationController = navigationController
        self.container = container
        self.sutraID = sutraID
    }

    func start() {
        let viewModel = container.makeSutraDetailViewModel(sutraID: sutraID)

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .back:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .openReader:
                    self.showReader()
                case .download:
                    // TODO: mở màn nghe không cần mạng (màn `downloads` chưa build).
                    break
                case .openPlayer:
                    self.showPlayer()
                }
            }
            .store(in: &cancellables)

        let viewController = ILSutraDetailViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    private func showReader() {
        let readerCoordinator = container.makeReaderCoordinator(
            navigationController: navigationController,
            sutraID: sutraID
        )
        addChild(readerCoordinator)
        readerCoordinator.start()
    }

    /// Mở trình phát toàn màn cho bộ kinh này (nút "Mở trình phát" ở hero).
    private func showPlayer() {
        let coordinator = container.makePlayerCoordinator(
            navigationController: navigationController,
            sutraID: sutraID
        )
        addChild(coordinator)
        coordinator.start()
    }
}
