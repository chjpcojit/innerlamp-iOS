//
//  ILFestivalDetailCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// Màn "Chi tiết ngày lễ" — đẩy lên từ carousel "Sự kiện Phật giáo" ở Trang chủ hoặc từ danh
/// sách Lịch lễ Phật giáo. Không có delegate: `.back` pop màn và tự `finish()`.
final class ILFestivalDetailCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?

    private let container: DIContainer
    private let eventCode: String
    private let date: Date
    private var cancellables = Set<AnyCancellable>()

    init(
        navigationController: UINavigationController,
        container: DIContainer,
        eventCode: String,
        date: Date
    ) {
        self.navigationController = navigationController
        self.container = container
        self.eventCode = eventCode
        self.date = date
    }

    func start() {
        let viewModel = container.makeFestivalDetailViewModel(eventCode: eventCode, date: date)

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .back:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                }
            }
            .store(in: &cancellables)

        let viewController = ILFestivalDetailViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
