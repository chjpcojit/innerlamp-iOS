//
//  ILPhotoViewerCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// Màn lá — `.close` pop về lưới ảnh và tự `finish()`; parent (`ILPhotosCoordinator`) không cần
/// phản ứng thêm.
final class ILPhotoViewerCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?

    private let container: DIContainer
    private let items: [ILPhotoViewerItemModel]
    private let startID: String
    private var cancellables = Set<AnyCancellable>()

    init(
        navigationController: UINavigationController,
        container: DIContainer,
        items: [ILPhotoViewerItemModel],
        startID: String
    ) {
        self.navigationController = navigationController
        self.container = container
        self.items = items
        self.startID = startID
    }

    func start() {
        guard let viewModel = container.makePhotoViewerViewModel(items: items, startID: startID) else {
            finish()
            return
        }

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .close:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                }
            }
            .store(in: &cancellables)

        let viewController = ILPhotoViewerViewController(viewModel: viewModel, startID: startID)
        navigationController.pushViewController(viewController, animated: true)
    }
}
