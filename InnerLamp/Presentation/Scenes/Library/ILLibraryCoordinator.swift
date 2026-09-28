//
//  ILLibraryCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILLibraryCoordinator: Coordinator {

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
        let viewModel = container.makeLibraryViewModel()

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .openSearch:
                    // TODO: điều hướng sang màn Tìm kiếm khi có ILSearchCoordinator.
                    break
                case .openItem(let id, let kind):
                    switch kind {
                    case .sutra:
                        // Luồng đúng theo design handoff: lib → `detail` (SutraDetail) → `reader`.
                        self.showSutraDetail(id)
                    case .talk:
                        self.showTalk(id)
                    case .meditation:
                        // TODO: điều hướng sang Thiền dẫn khi màn đó có coordinator — xem
                        // "Pending" trong Docs/Specs/Library/requirements.md.
                        break
                    }
                }
            }
            .store(in: &cancellables)

        let viewController = ILLibraryViewController(viewModel: viewModel)
        navigationController.setViewControllers([viewController], animated: false)
    }

    /// Mở màn Chi tiết bài kinh cho 1 bộ kinh (luồng lib → `detail` → `reader` theo design handoff).
    private func showSutraDetail(_ sutraID: String) {
        let coordinator = container.makeSutraDetailCoordinator(
            navigationController: navigationController,
            sutraID: sutraID
        )
        addChild(coordinator)
        coordinator.start()
    }

    /// Mở màn Pháp thoại cho 1 bài pháp thoại (thẻ nổi bật hoặc hàng trong nhóm Pháp thoại).
    private func showTalk(_ talkID: String) {
        let coordinator = container.makeTalkCoordinator(
            navigationController: navigationController,
            talkID: talkID
        )
        addChild(coordinator)
        coordinator.start()
    }
}
