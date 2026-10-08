//
//  ILFamilyTreeChronicleCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

protocol ILFamilyTreeChronicleCoordinatorDelegate: AnyObject {
    /// An edit or a clan-head change was saved. The screen stays open.
    func familyTreeChronicleDidUpdate(_ trees: [ILFamilyTreeEntity], coordinator: ILFamilyTreeChronicleCoordinator)
    /// A person was tapped; the screen has already popped itself.
    func familyTreeChronicleDidRequestOpen(treeID: String, memberID: String, coordinator: ILFamilyTreeChronicleCoordinator)
}

/// "Phả ký dòng họ" flow — a single screen (view + edit modes) pushed from the family tree.
/// `.back` pops and `finish()`es; `.updated` tells the delegate and stays; `.openMember` pops, tells
/// the delegate, then `finish()`es; `.remindFounderAnniversary` is a one-line TODO stub.
final class ILFamilyTreeChronicleCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?
    weak var delegate: ILFamilyTreeChronicleCoordinatorDelegate?

    private let container: DIContainer
    private let trees: [ILFamilyTreeEntity]
    private let initialTreeID: String
    private var cancellables = Set<AnyCancellable>()

    init(
        navigationController: UINavigationController,
        container: DIContainer,
        trees: [ILFamilyTreeEntity],
        initialTreeID: String
    ) {
        self.navigationController = navigationController
        self.container = container
        self.trees = trees
        self.initialTreeID = initialTreeID
    }

    func start() {
        let viewModel = container.makeFamilyTreeChronicleViewModel(trees: trees, initialTreeID: initialTreeID)

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .back:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .updated(let trees):
                    self.delegate?.familyTreeChronicleDidUpdate(trees, coordinator: self)
                case .openMember(let treeID, let memberID):
                    self.navigationController.popViewController(animated: true)
                    self.delegate?.familyTreeChronicleDidRequestOpen(treeID: treeID, memberID: memberID, coordinator: self)
                    self.finish()
                case .remindFounderAnniversary(_, let memberID):
                    print("TODO: add the founder's (\(memberID)) anniversary to the Sổ giỗ (no hand-off yet — TD-FamilyTreeChronicle-003)")
                }
            }
            .store(in: &cancellables)

        let viewController = ILFamilyTreeChronicleViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
