//
//  ILArticleCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// Màn lá — không có delegate: `ILArticleNavEvent.back` chỉ pop màn và tự `finish()`, parent
/// (`ILHomeCoordinator`) không cần phản ứng gì thêm. `.share` mở modal chia sẻ nhưng màn `share`
/// chưa build nên tạm để TODO.
final class ILArticleCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?

    private let container: DIContainer
    private let articleID: String
    private var cancellables = Set<AnyCancellable>()

    init(
        navigationController: UINavigationController,
        container: DIContainer,
        articleID: String
    ) {
        self.navigationController = navigationController
        self.container = container
        self.articleID = articleID
    }

    func start() {
        let viewModel = container.makeArticleViewModel(articleID: articleID)

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
                case .openURL(let urlString):
                    guard let url = URL(string: urlString) else { return }
                    UIApplication.shared.open(url)
                }
            }
            .store(in: &cancellables)

        let viewController = ILArticleViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
