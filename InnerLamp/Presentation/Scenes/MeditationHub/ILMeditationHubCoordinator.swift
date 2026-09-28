//
//  ILMeditationHubCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// Owner của màn "Thiền định" (design handoff `medhub`). Đây là màn con của Thư viện — được
/// `ILLibraryCoordinator` mở khi chạm ô truy cập nhanh "Thiền định". Coordinator push màn của
/// mình, mở luồng thực hành (Chuẩn bị thiền — modal full-screen) cho bài "Thiền dẫn", mở Thống kê,
/// và pop + finish khi back. Không cần delegate protocol: luồng này không trả kết quả về cha.
final class ILMeditationHubCoordinator: Coordinator {

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
        let viewModel = container.makeMeditationHubViewModel()

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .goBack:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .openTimerConfig(let presetID):
                    // Màn cấu hình đồng hồ & chuông (`medtimer`) chưa được dựng.
                    print("TODO: open meditation timer config screen (medtimer) — presetID=\(presetID ?? "nil")")
                case .startGuidedSession(let sessionID):
                    self.showMeditationSetup(sessionID: sessionID)
                case .openStats:
                    self.showStats()
                }
            }
            .store(in: &cancellables)

        let viewController = ILMeditationHubViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    /// Mở luồng thực hành có hướng dẫn — `ILMeditationSetupCoordinator` tự present modal full-screen
    /// (màn `setup` dùng nút ✕), nên chỉ cần tạo child + start.
    private func showMeditationSetup(sessionID: String) {
        print("TODO: pass guided session \(sessionID) into the setup flow (ILMeditationSetupCoordinator does not accept a session id yet)")
        let coordinator = container.makeMeditationSetupCoordinator(navigationController: navigationController)
        addChild(coordinator)
        coordinator.start()
    }

    /// Mở Thống kê (`stats`) khi chạm thẻ tổng quan.
    private func showStats() {
        let coordinator = container.makeStatsCoordinator(navigationController: navigationController)
        addChild(coordinator)
        coordinator.start()
    }
}
