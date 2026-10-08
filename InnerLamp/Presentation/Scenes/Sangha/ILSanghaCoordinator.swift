//
//  ILSanghaCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// Tab Chùa. "Chọn" ở danh sách gợi ý do `ILSanghaViewModel` tự xử lý (lưu qua use case rồi tải lại
/// màn); "Đổi chùa" mở màn "Chọn chùa tu tập". Coordinator chỉ điều hướng sang các màn con. Cúng dường và buổi tu trực tuyến chưa có màn
/// đích nên để TODO.
final class ILSanghaCoordinator: Coordinator {

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
        let viewModel = container.makeSanghaViewModel()

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                switch event {
                case .openTemple(let id):
                    self?.showTemple(id)
                case .openEvents:
                    self?.showEvents()
                case .openTalk(let id):
                    self?.showTalk(id)
                case .openOffer:
                    // TODO: mở màn Cúng dường (`offer`) — chưa build.
                    break
                case .openTempleFinder:
                    self?.showTempleFinder()
                case .openOnlineSession:
                    // TODO: mở buổi tu học trực tuyến (Chuẩn bị thiền / Reader) — chưa nối.
                    break
                case .openFestivals:
                    self?.showFestivals()
                }
            }
            .store(in: &cancellables)

        let viewController = ILSanghaViewController(viewModel: viewModel)
        navigationController.setViewControllers([viewController], animated: false)
    }

    private func showTemple(_ templeID: String) {
        let coordinator = container.makeTempleCoordinator(navigationController: navigationController, templeID: templeID)
        addChild(coordinator)
        coordinator.start()
    }

    private func showTempleFinder() {
        let coordinator = container.makeTempleFinderCoordinator(navigationController: navigationController)
        addChild(coordinator)
        coordinator.start()
    }

    private func showEvents() {
        let coordinator = container.makeEventsCoordinator(navigationController: navigationController)
        addChild(coordinator)
        coordinator.start()
    }

    private func showTalk(_ talkID: String) {
        let coordinator = container.makeTalkCoordinator(navigationController: navigationController, talkID: talkID)
        addChild(coordinator)
        coordinator.start()
    }

    private func showFestivals() {
        let coordinator = container.makeFestivalsCoordinator(navigationController: navigationController)
        addChild(coordinator)
        coordinator.start()
    }
}
