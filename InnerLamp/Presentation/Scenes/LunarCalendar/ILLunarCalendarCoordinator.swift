//
//  ILLunarCalendarCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// Chạm 1 ngày trong lưới tháng → parent (`ILHomeCoordinator`) mở màn "Chi tiết ngày âm".
protocol ILLunarCalendarCoordinatorDelegate: AnyObject {
    func lunarCalendarDidRequestDayDetail(_ coordinator: ILLunarCalendarCoordinator, date: Date)
}

final class ILLunarCalendarCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?

    weak var delegate: ILLunarCalendarCoordinatorDelegate?

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
        let viewModel = container.makeLunarCalendarViewModel()

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .close:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .openDayDetail(let date):
                    self.delegate?.lunarCalendarDidRequestDayDetail(self, date: date)
                }
            }
            .store(in: &cancellables)

        let viewController = ILLunarCalendarViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
