//
//  ILMeditationSetupCoordinator.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import UIKit
import Combine

/// Màn Chuẩn bị thiền (`setup` trong design handoff) — được trình bày dạng **modal full-screen**
/// từ nút Đèn ở giữa thanh tab (xem `ILMainTabCoordinator`), vì design dùng nút ✕ (`showClose`)
/// thay vì back (`showBack`). Coordinator tự tạo một `BaseNavigationController` để bọc màn, sẵn
/// sàng cho các màn kế tiếp của luồng thực hành (phiên thiền → hoàn thành → nhật ký) push vào.
///
/// Acts as the section coordinator of the practice flow: it starts `ILMeditationSessionCoordinator`
/// on its own presented stack, so parents (`ILMainTabCoordinator`, `ILHomeCoordinator`) only open
/// and forget this flow — no delegate needed.
final class ILMeditationSetupCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?

    private let container: DIContainer
    private var cancellables = Set<AnyCancellable>()
    private var presentedNavigationController: UINavigationController?

    init(
        navigationController: UINavigationController,
        container: DIContainer
    ) {
        self.navigationController = navigationController
        self.container = container
    }

    func start() {
        let viewModel = container.makeMeditationSetupViewModel()

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .startSession(let durationMinutes, let guided):
                    self.showMeditationSession(durationMinutes: durationMinutes, guided: guided)
                case .close:
                    self.closeFlow()
                }
            }
            .store(in: &cancellables)

        let viewController = ILMeditationSetupViewController(viewModel: viewModel)
        let navigation = BaseNavigationController(rootViewController: viewController)
        navigation.modalPresentationStyle = .fullScreen
        presentedNavigationController = navigation
        navigationController.present(navigation, animated: true)
    }

    private func showMeditationSession(durationMinutes: Int, guided: Bool) {
        guard let presentedNavigationController else { return }
        let coordinator = container.makeMeditationSessionCoordinator(
            navigationController: presentedNavigationController,
            durationMinutes: durationMinutes,
            isGuided: guided
        )
        coordinator.delegate = self
        addChild(coordinator)
        coordinator.start()
    }

    /// Dismisses the whole practice-flow modal (setup and anything pushed on top of it).
    private func closeFlow() {
        presentedNavigationController?.dismiss(animated: true)
        finish()
    }
}

// MARK: - ILMeditationSessionCoordinatorDelegate
extension ILMeditationSetupCoordinator: ILMeditationSessionCoordinatorDelegate {
    func meditationSessionDidFinish(_ coordinator: ILMeditationSessionCoordinator, elapsedSeconds: Int) {
        // "Hoàn thành" (`done`) is not built yet — close the practice flow for now instead of
        // leaving the user on a stopped session. See `MeditationSession/README.md` Known gaps.
        print("TODO: navigate to meditation done screen (elapsedSeconds=\(elapsedSeconds))")
        closeFlow()
    }
}
