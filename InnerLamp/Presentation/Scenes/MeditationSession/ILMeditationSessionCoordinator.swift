//
//  ILMeditationSessionCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

protocol ILMeditationSessionCoordinatorDelegate: AnyObject {
    /// The sit ended and was recorded. The "Hoàn thành" (`done`) screen is not built yet, so the
    /// parent decides where to go next.
    func meditationSessionDidFinish(_ coordinator: ILMeditationSessionCoordinator, elapsedSeconds: Int)
}

/// "Phiên thiền" (design handoff `session`) — pushed onto the practice-flow navigation stack that
/// `ILMeditationSetupCoordinator` presents modally (setup → session → done → journal).
final class ILMeditationSessionCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?
    weak var delegate: ILMeditationSessionCoordinatorDelegate?

    private let container: DIContainer
    private let durationMinutes: Int
    private let isGuided: Bool
    private var cancellables = Set<AnyCancellable>()

    init(
        navigationController: UINavigationController,
        container: DIContainer,
        durationMinutes: Int,
        isGuided: Bool
    ) {
        self.navigationController = navigationController
        self.container = container
        self.durationMinutes = durationMinutes
        self.isGuided = isGuided
    }

    func start() {
        let viewModel = container.makeMeditationSessionViewModel(durationMinutes: durationMinutes, isGuided: isGuided)

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .goBack:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .finished(let elapsedSeconds):
                    self.delegate?.meditationSessionDidFinish(self, elapsedSeconds: elapsedSeconds)
                    self.finish()
                }
            }
            .store(in: &cancellables)

        let viewController = ILMeditationSessionViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
