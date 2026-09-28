//
//  ILDeityCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// Không có delegate: `ILDeityNavEvent.back` chỉ pop màn và tự `finish()`, parent
/// (`ILHomeCoordinator`) không cần phản ứng gì thêm. Các màn con (Lịch lễ Phật giáo, Niệm Phật,
/// Chi tiết bài kinh) là child coordinator của màn này; "Chia sẻ" dùng share sheet hệ thống.
final class ILDeityCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?

    private let container: DIContainer
    private let deityID: String
    private var cancellables = Set<AnyCancellable>()

    init(
        navigationController: UINavigationController,
        container: DIContainer,
        deityID: String
    ) {
        self.navigationController = navigationController
        self.container = container
        self.deityID = deityID
    }

    func start() {
        let viewModel = container.makeDeityViewModel(deityID: deityID)

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .back:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .openFestivals:
                    self.showFestivals()
                case .openMala(let mantraText):
                    self.showMala(mantraText: mantraText)
                case .share(let text):
                    self.presentShareSheet(text: text)
                case .openSutra(let sutraID):
                    self.showSutraDetail(sutraID: sutraID)
                }
            }
            .store(in: &cancellables)

        let viewController = ILDeityViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    // MARK: - Navigation
    private func showFestivals() {
        let coordinator = container.makeFestivalsCoordinator(navigationController: navigationController)
        addChild(coordinator)
        coordinator.start()
    }

    private func showMala(mantraText: String) {
        let coordinator = container.makeMalaCoordinator(navigationController: navigationController, mantraText: mantraText)
        addChild(coordinator)
        coordinator.start()
    }

    private func showSutraDetail(sutraID: String) {
        let coordinator = container.makeSutraDetailCoordinator(navigationController: navigationController, sutraID: sutraID)
        addChild(coordinator)
        coordinator.start()
    }

    /// TODO: thay bằng màn "Chia sẻ câu kinh" (`share`, 3 kiểu thiệp) khi màn đó được build.
    private func presentShareSheet(text: String) {
        let activityController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        navigationController.present(activityController, animated: true)
    }
}
