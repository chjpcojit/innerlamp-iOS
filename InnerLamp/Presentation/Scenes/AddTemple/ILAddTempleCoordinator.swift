//
//  ILAddTempleCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

protocol ILAddTempleCoordinatorDelegate: AnyObject {
    /// Người dùng đã gửi form hợp lệ — màn đã được pop.
    func addTempleDidSubmit(_ coordinator: ILAddTempleCoordinator, proposal: ILTempleProposalEntity)
}

/// Màn "Thêm thông tin chùa" — đẩy lên từ bộ chọn nơi xuất gia ở màn Đăng ký khi chưa có chùa.
final class ILAddTempleCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?
    weak var delegate: ILAddTempleCoordinatorDelegate?

    private let container: DIContainer
    private let prefillName: String
    private let existingPlaces: [ILOrdinationPlaceEntity]
    private var cancellables = Set<AnyCancellable>()

    init(
        navigationController: UINavigationController,
        container: DIContainer,
        prefillName: String,
        existingPlaces: [ILOrdinationPlaceEntity]
    ) {
        self.navigationController = navigationController
        self.container = container
        self.prefillName = prefillName
        self.existingPlaces = existingPlaces
    }

    func start() {
        let viewModel = container.makeAddTempleViewModel(prefillName: prefillName, existingPlaces: existingPlaces)

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .back:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .submitted(let proposal):
                    self.navigationController.popViewController(animated: true)
                    self.delegate?.addTempleDidSubmit(self, proposal: proposal)
                    self.finish()
                }
            }
            .store(in: &cancellables)

        let viewController = ILAddTempleViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
