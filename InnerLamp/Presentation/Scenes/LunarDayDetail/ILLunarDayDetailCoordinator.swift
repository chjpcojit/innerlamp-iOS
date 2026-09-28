//
//  ILLunarDayDetailCoordinator.swift
//  InnerLamp
//
//  Created by ChjpCoj on 27/9/26.
//

import UIKit
import Combine

/// Màn lá — không có delegate: `ILLunarDayDetailNavEvent.back` chỉ pop màn và tự `finish()`,
/// parent (`ILHomeCoordinator`) không cần phản ứng gì thêm.
final class ILLunarDayDetailCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?

    private let container: DIContainer
    private let date: Date
    /// Quote handed over by the opening screen (Home hero card); nil loads the fixed quote of `date` from Core Data.
    private let verse: ILHomeQuoteEntity?
    private var cancellables = Set<AnyCancellable>()

    init(
        navigationController: UINavigationController,
        container: DIContainer,
        date: Date,
        verse: ILHomeQuoteEntity? = nil
    ) {
        self.navigationController = navigationController
        self.container = container
        self.date = date
        self.verse = verse
    }

    func start() {
        let viewModel = container.makeLunarDayDetailViewModel(date: date, verse: verse)

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

        let viewController = ILLunarDayDetailViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
