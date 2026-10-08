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
                case .openQuickAccess(let kind):
                    switch kind {
                    case .buddhas:
                        // Ô "Phật & Bồ Tát" — mở màn danh sách "Chư Phật & Bồ Tát".
                        self.showDeities()
                    case .meditation:
                        // Ô "Thiền định" — mở Trung tâm thiền (`medhub`).
                        self.showMeditationHub()
                    case .sutras:
                        // Ô "Kinh sách" và link "Xem tất cả" ở nhóm Kinh thường tụng — mở màn `sutras`.
                        self.showSutras()
                    case .talk:
                        // Ô "Pháp thoại" — mở màn danh sách `Talks`.
                        self.showTalks()
                    }
                case .openDeity(let id):
                    self.showDeity(id)
                case .openDeities:
                    // Link "Xem tất cả" ở khối "Chư Phật & Bồ Tát" — màn danh sách đầy đủ.
                    self.showDeities()
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

    /// Mở màn danh sách "Kinh sách" — từ ô truy cập nhanh hoặc link "Xem tất cả".
    private func showSutras() {
        let coordinator = container.makeSutrasCoordinator(navigationController: navigationController)
        addChild(coordinator)
        coordinator.start()
    }

    /// Mở màn danh sách "Pháp thoại" — từ ô truy cập nhanh "Pháp thoại".
    private func showTalks() {
        let coordinator = container.makeTalksCoordinator(navigationController: navigationController)
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

    /// Mở màn chi tiết 1 vị Phật / Bồ Tát (thẻ trong carousel "Chư Phật & Bồ Tát") — cùng
    /// coordinator với carousel "Thư viện Phật & Bồ Tát" ở Trang chủ (`ILHomeCoordinator.showDeity`).
    private func showDeity(_ deityID: String) {
        let coordinator = container.makeDeityCoordinator(navigationController: navigationController, deityID: deityID)
        addChild(coordinator)
        coordinator.start()
    }

    /// Mở màn danh sách "Chư Phật & Bồ Tát" — từ ô truy cập nhanh hoặc link "Xem tất cả".
    private func showDeities() {
        let coordinator = container.makeDeitiesCoordinator(navigationController: navigationController)
        addChild(coordinator)
        coordinator.start()
    }

    /// Mở màn "Thiền định" (Trung tâm thiền, `medhub`) — từ ô truy cập nhanh "Thiền định".
    private func showMeditationHub() {
        let coordinator = container.makeMeditationHubCoordinator(navigationController: navigationController)
        addChild(coordinator)
        coordinator.start()
    }
}
