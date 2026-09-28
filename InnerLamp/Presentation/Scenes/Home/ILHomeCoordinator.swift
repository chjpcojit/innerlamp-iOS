//
//  ILHomeCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILHomeCoordinator: Coordinator {

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
        let viewModel = container.makeHomeViewModel()

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                switch event {
                case .openMala:
                    self?.showMala()
                case .openLunarCalendar:
                    self?.showLunarCalendar()
                case .openLunarDayDetail(let date, let verse):
                    self?.showLunarDayDetail(date, verse: verse)
                case .openPhotos:
                    self?.showPhotos()
                case .openBell:
                    self?.showBell()
                case .openFestivals:
                    self?.showFestivals()
                case .openArticle(let id):
                    self?.showArticle(id)
                case .openArticles:
                    self?.showArticles()
                case .openTemple(let id):
                    self?.showTemple(id)
                case .openDeity(let id):
                    self?.showDeity(id)
                case .openMeditationSetup:
                    self?.showMeditationSetup()
                }
            }
            .store(in: &cancellables)

        let viewController = ILHomeViewController(viewModel: viewModel)
        navigationController.setViewControllers([viewController], animated: false)
    }

    private func showLunarCalendar() {
        let coordinator = container.makeLunarCalendarCoordinator(navigationController: navigationController)
        coordinator.delegate = self
        addChild(coordinator)
        coordinator.start()
    }

    private func showLunarDayDetail(_ date: Date, verse: ILHomeQuoteEntity? = nil) {
        let coordinator = container.makeLunarDayDetailCoordinator(
            navigationController: navigationController,
            date: date,
            verse: verse
        )
        addChild(coordinator)
        coordinator.start()
    }

    private func showMala() {
        let coordinator = container.makeMalaCoordinator(navigationController: navigationController)
        addChild(coordinator)
        coordinator.start()
    }

    private func showPhotos() {
        let coordinator = container.makePhotosCoordinator(navigationController: navigationController)
        addChild(coordinator)
        coordinator.start()
    }

    private func showBell() {
        let coordinator = container.makeBellCoordinator(navigationController: navigationController)
        addChild(coordinator)
        coordinator.start()
    }

    private func showFestivals() {
        let coordinator = container.makeFestivalsCoordinator(navigationController: navigationController)
        addChild(coordinator)
        coordinator.start()
    }

    private func showArticle(_ articleID: String) {
        let coordinator = container.makeArticleCoordinator(navigationController: navigationController, articleID: articleID)
        addChild(coordinator)
        coordinator.start()
    }

    /// Màn "Tất cả bài viết" — danh sách toàn bộ bài viết Phật pháp.
    private func showArticles() {
        let coordinator = container.makeArticlesCoordinator(navigationController: navigationController)
        addChild(coordinator)
        coordinator.start()
    }

    private func showTemple(_ templeID: String) {
        let coordinator = container.makeTempleCoordinator(navigationController: navigationController, templeID: templeID)
        addChild(coordinator)
        coordinator.start()
    }

    /// Màn chi tiết Phật & Bồ Tát — đẩy lên từ carousel "Thư viện Phật & Bồ Tát".
    private func showDeity(_ deityID: String) {
        let coordinator = container.makeDeityCoordinator(navigationController: navigationController, deityID: deityID)
        addChild(coordinator)
        coordinator.start()
    }

    /// Màn Chuẩn bị thiền tự present modal full-screen (xem `ILMeditationSetupCoordinator`).
    private func showMeditationSetup() {
        let coordinator = container.makeMeditationSetupCoordinator(navigationController: navigationController)
        addChild(coordinator)
        coordinator.start()
    }
}

// MARK: - ILLunarCalendarCoordinatorDelegate
extension ILHomeCoordinator: ILLunarCalendarCoordinatorDelegate {
    func lunarCalendarDidRequestDayDetail(_ coordinator: ILLunarCalendarCoordinator, date: Date) {
        showLunarDayDetail(date)
    }
}
