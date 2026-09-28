//
//  ILTempleCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// Màn lá — không có delegate: `ILTempleNavEvent.back` chỉ pop màn và tự `finish()`, parent
/// (`ILHomeCoordinator` / `ILSanghaCoordinator`) không cần phản ứng gì thêm. Các màn con của
/// Trang chùa (Cúng dường, sự kiện & khóa học, chi tiết thời khóa) chưa build nên để TODO.
/// `.openURL` mở app hệ thống (bản đồ/điện thoại/trình duyệt/mail) qua `UIApplication.shared` —
/// đặt ở Coordinator (không phải `ViewController`) để giữ `ViewModel`/`ViewController` không phụ
/// thuộc trực tiếp `UIApplication`, dễ test.
final class ILTempleCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?

    private let container: DIContainer
    private let templeID: String
    private var cancellables = Set<AnyCancellable>()

    init(
        navigationController: UINavigationController,
        container: DIContainer,
        templeID: String
    ) {
        self.navigationController = navigationController
        self.container = container
        self.templeID = templeID
    }

    func start() {
        let viewModel = container.makeTempleViewModel(templeID: templeID)

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .back:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .offer:
                    // TODO: mở màn Cúng dường (`offer`) — chưa build (xem README design handoff).
                    break
                case .events:
                    // TODO: mở màn Sự kiện & khóa học của chùa này (`events`) — chưa build.
                    break
                case .session:
                    // TODO: mở chi tiết thời khóa / màn đọc kinh — chưa build.
                    break
                case .openURL(let urlString):
                    guard let url = URL(string: urlString) else { return }
                    UIApplication.shared.open(url)
                }
            }
            .store(in: &cancellables)

        let viewController = ILTempleViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
