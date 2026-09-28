//
//  ILPostCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// Màn lá — không có delegate: `ILPostNavEvent.back` chỉ pop màn và tự `finish()`, parent
/// (`ILSanghaCoordinator`) không cần phản ứng gì thêm. `.share` mở modal chia sẻ nhưng màn
/// `share` chưa build nên tạm để TODO.
final class ILPostCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?

    private let container: DIContainer
    private let postID: String
    private var cancellables = Set<AnyCancellable>()

    init(
        navigationController: UINavigationController,
        container: DIContainer,
        postID: String
    ) {
        self.navigationController = navigationController
        self.container = container
        self.postID = postID
    }

    func start() {
        let viewModel = container.makePostViewModel(postID: postID)

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .back:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .share:
                    // TODO: mở modal chia sẻ câu kinh (màn `share` chưa build — xem README design
                    // handoff, "chia sẻ câu kinh (3 kiểu thiệp)").
                    break
                }
            }
            .store(in: &cancellables)

        let viewController = ILPostViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
