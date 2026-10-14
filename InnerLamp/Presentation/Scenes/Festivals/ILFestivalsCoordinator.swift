//
//  ILFestivalsCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// Màn "Lịch lễ Phật giáo" — được đẩy lên từ Trang chủ ("Tất cả" / chạm 1 lễ ở mục "Sự kiện Phật
/// giáo"). Không có delegate: `.goBack` pop màn và tự `finish()`; chạm 1 ngày lễ mở màn Chi tiết
/// ngày lễ (child coordinator).
final class ILFestivalsCoordinator: Coordinator {

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
        let viewModel = container.makeFestivalsViewModel()

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .goBack:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .openFestivalDetail(let code, let date):
                    self.showFestivalDetail(eventCode: code, date: date)
                }
            }
            .store(in: &cancellables)

        let viewController = ILFestivalsViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    private func showFestivalDetail(eventCode: String, date: Date) {
        let coordinator = container.makeFestivalDetailCoordinator(
            navigationController: navigationController,
            eventCode: eventCode,
            date: date
        )
        addChild(coordinator)
        coordinator.start()
    }
}
