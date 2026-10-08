//
//  ILFamilyTreeCreateCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

protocol ILFamilyTreeCreateCoordinatorDelegate: AnyObject {
    /// The new tree was saved; the create screen has already popped itself.
    func familyTreeCreateDidCreate(_ tree: ILFamilyTreeEntity, coordinator: ILFamilyTreeCreateCoordinator)
}

/// "Tạo gia phả" flow — a single screen pushed from the empty family tree. `.back` pops and
/// `finish()`es; `.created` pops, tells the delegate, then `finish()`es.
final class ILFamilyTreeCreateCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?
    weak var delegate: ILFamilyTreeCreateCoordinatorDelegate?

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
        let viewModel = container.makeFamilyTreeCreateViewModel()

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .back:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .created(let tree):
                    self.navigationController.popViewController(animated: true)
                    self.delegate?.familyTreeCreateDidCreate(tree, coordinator: self)
                    self.finish()
                }
            }
            .store(in: &cancellables)

        let viewController = ILFamilyTreeCreateViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
