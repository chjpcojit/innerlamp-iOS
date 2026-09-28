//
//  ILReaderCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// Màn lá — không có delegate: `ILReaderNavEvent.back` chỉ pop màn và tự `finish()`, parent
/// (`ILLibraryCoordinator`) không cần phản ứng gì thêm. `.openPlayer` đẩy trình phát toàn màn;
/// các đích còn lại (cỡ chữ, chia sẻ, tải offline) chưa build nên tạm để TODO.
final class ILReaderCoordinator: Coordinator {

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
        let viewModel = container.makeReaderViewModel(sutraID: sutraID)

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .back:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .openFontSize:
                    // TODO: mở tùy chỉnh cỡ chữ kinh văn (màn `settings`/cỡ chữ chưa build).
                    break
                case .share:
                    // TODO: mở modal chia sẻ câu kinh (màn `share` chưa build — xem README design
                    // handoff, "chia sẻ câu kinh (3 kiểu thiệp)").
                    break
                case .download:
                    // TODO: mở màn nghe không cần mạng (màn `downloads` chưa build).
                    break
                case .openPlayer:
                    self.showPlayer()
                }
            }
            .store(in: &cancellables)

        let viewController = ILReaderViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    /// Mở trình phát toàn màn cho bộ kinh đang tụng (nút tốc độ "1.0×" trên thanh phát).
    private func showPlayer() {
        let coordinator = container.makePlayerCoordinator(
            navigationController: navigationController,
            sutraID: sutraID
        )
        addChild(coordinator)
        coordinator.start()
    }
}
