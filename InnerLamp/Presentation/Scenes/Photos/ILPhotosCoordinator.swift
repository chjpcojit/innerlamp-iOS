//
//  ILPhotosCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// Không có delegate: `ILPhotosNavEvent.back` chỉ pop màn và tự `finish()`, parent
/// (`ILHomeCoordinator`) không cần phản ứng gì thêm. `.openPhoto` mở `ILPhotoViewerCoordinator` làm
/// child.
final class ILPhotosCoordinator: Coordinator {

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
        let viewModel = container.makePhotosViewModel()

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .back:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .openPhoto(let photos, let selectedID):
                    self.showPhotoViewer(photos: photos, selectedID: selectedID)
                }
            }
            .store(in: &cancellables)

        let viewController = ILPhotosViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    private func showPhotoViewer(photos: [ILPhotosPhotoModel], selectedID: String) {
        let items = photos.map {
            ILPhotoViewerItemModel(
                id: $0.id,
                title: $0.title,
                place: $0.place,
                categoryLabel: $0.categoryLabel,
                imageURL: $0.imageURL
            )
        }
        let coordinator = container.makePhotoViewerCoordinator(
            navigationController: navigationController,
            items: items,
            startID: selectedID
        )
        addChild(coordinator)
        coordinator.start()
    }
}
