//
//  ILFamilyTreeAddMemberCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

protocol ILFamilyTreeAddMemberCoordinatorDelegate: AnyObject {
    /// The member was saved; the form has already popped itself.
    func familyTreeAddMemberDidSave(_ tree: ILFamilyTreeEntity, memberID: String, coordinator: ILFamilyTreeAddMemberCoordinator)
}

/// "Thêm người vào gia phả" flow — a single form pushed from the family tree. `.close` pops and
/// `finish()`es; `.saved` pops, tells the delegate, then `finish()`es.
final class ILFamilyTreeAddMemberCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?
    weak var delegate: ILFamilyTreeAddMemberCoordinatorDelegate?

    private let container: DIContainer
    private let tree: ILFamilyTreeEntity
    private let relativeID: String
    private let relation: ILFamilyAddRelation
    private var cancellables = Set<AnyCancellable>()

    init(
        navigationController: UINavigationController,
        container: DIContainer,
        tree: ILFamilyTreeEntity,
        relativeID: String,
        relation: ILFamilyAddRelation = .child
    ) {
        self.navigationController = navigationController
        self.container = container
        self.tree = tree
        self.relativeID = relativeID
        self.relation = relation
    }

    func start() {
        let viewModel = container.makeFamilyTreeAddMemberViewModel(tree: tree, relativeID: relativeID, relation: relation)

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .close:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .saved(let tree, let memberID):
                    self.navigationController.popViewController(animated: true)
                    self.delegate?.familyTreeAddMemberDidSave(tree, memberID: memberID, coordinator: self)
                    self.finish()
                }
            }
            .store(in: &cancellables)

        let viewController = ILFamilyTreeAddMemberViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
