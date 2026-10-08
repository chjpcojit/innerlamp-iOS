//
//  ILFamilyTreeCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// Family tree ("Gia phả") flow — a screen pushed from the Sổ giỗ chạp list. No delegate:
/// `.back` pops the screen and `finish()`es; `.createTree` pushes the "Tạo gia phả" child flow;
/// `.addMember` / `.addDescendant` push the "Thêm người vào gia phả" form; `.openProfile` pushes the
/// member profile (view + edit); `.openChronicle` pushes "Phả ký dòng họ"; the other events are
/// one-line TODO stubs.
final class ILFamilyTreeCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?

    private let container: DIContainer
    private var viewModel: ILFamilyTreeViewModel?
    private var cancellables = Set<AnyCancellable>()
    /// The book each open profile screen belongs to, so "open this person" can find its book again.
    private var profileTreeIDs: [ObjectIdentifier: String] = [:]

    init(
        navigationController: UINavigationController,
        container: DIContainer
    ) {
        self.navigationController = navigationController
        self.container = container
    }

    func start() {
        let viewModel = container.makeFamilyTreeViewModel()
        self.viewModel = viewModel

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .back:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .createTree:
                    self.showCreateTree()
                case .addMember:
                    self.showAddMember(relativeID: nil, relation: .child)
                case .openProfile(let memberID):
                    self.showProfile(memberID: memberID)
                case .openChronicle:
                    self.showChronicle()
                case .remindAnniversary(let memberID):
                    print("TODO: add \(memberID)'s anniversary to the Sổ giỗ / open it (no hand-off yet — TD-FamilyTree-005)")
                case .addDescendant(let memberID):
                    self.showAddMember(relativeID: memberID, relation: .child)
                case .lightLamp(let memberID):
                    print("TODO: open the light-a-lamp offering for \(memberID) (destination unconfirmed — TD-FamilyTree-006)")
                case .chant(let memberID):
                    print("TODO: open chanting with merit dedication for \(memberID) (destination unconfirmed — TD-FamilyTree-006)")
                case .openTemple(let memberID):
                    print("TODO: open the tablet temple page for \(memberID) (no temple link/data yet — TD-FamilyTree-008)")
                }
            }
            .store(in: &cancellables)

        let viewController = ILFamilyTreeViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    private func showAddMember(relativeID: String?, relation: ILFamilyAddRelation) {
        guard let context = viewModel?.addMemberContext(relativeID: relativeID) else { return }
        let coordinator = container.makeFamilyTreeAddMemberCoordinator(
            navigationController: navigationController, tree: context.tree, relativeID: context.relativeID, relation: relation
        )
        coordinator.delegate = self
        addChild(coordinator)
        coordinator.start()
    }

    private func showProfile(memberID: String) {
        guard let context = viewModel?.profileContext(memberID: memberID) else { return }
        let coordinator = container.makeFamilyTreeMemberCoordinator(
            navigationController: navigationController,
            tree: context.tree, memberID: context.memberID, kinship: context.kinship
        )
        coordinator.delegate = self
        profileTreeIDs[ObjectIdentifier(coordinator)] = context.tree.id
        addChild(coordinator)
        coordinator.start()
    }

    private func showChronicle() {
        guard let context = viewModel?.chronicleContext() else { return }
        let coordinator = container.makeFamilyTreeChronicleCoordinator(
            navigationController: navigationController, trees: context.trees, initialTreeID: context.activeTreeID
        )
        coordinator.delegate = self
        addChild(coordinator)
        coordinator.start()
    }

    private func showCreateTree() {
        let coordinator = container.makeFamilyTreeCreateCoordinator(navigationController: navigationController)
        coordinator.delegate = self
        addChild(coordinator)
        coordinator.start()
    }
}

// MARK: - ILFamilyTreeCreateCoordinatorDelegate
extension ILFamilyTreeCoordinator: ILFamilyTreeCreateCoordinatorDelegate {
    func familyTreeCreateDidCreate(_ tree: ILFamilyTreeEntity, coordinator: ILFamilyTreeCreateCoordinator) {
        viewModel?.showCreatedTree(tree)
    }
}

// MARK: - ILFamilyTreeAddMemberCoordinatorDelegate
extension ILFamilyTreeCoordinator: ILFamilyTreeAddMemberCoordinatorDelegate {
    func familyTreeAddMemberDidSave(_ tree: ILFamilyTreeEntity, memberID: String, coordinator: ILFamilyTreeAddMemberCoordinator) {
        viewModel?.showTree(tree, selecting: memberID)
    }
}

// MARK: - ILFamilyTreeMemberCoordinatorDelegate
extension ILFamilyTreeCoordinator: ILFamilyTreeMemberCoordinatorDelegate {
    func familyTreeMemberDidSave(_ tree: ILFamilyTreeEntity, memberID: String, coordinator: ILFamilyTreeMemberCoordinator) {
        viewModel?.showUpdatedBook(tree, memberID: memberID)
    }

    func familyTreeMemberDidRequestOpen(memberID: String, coordinator: ILFamilyTreeMemberCoordinator) {
        guard let treeID = profileTreeIDs.removeValue(forKey: ObjectIdentifier(coordinator)) else { return }
        viewModel?.openMember(treeID: treeID, memberID: memberID)
    }
}

// MARK: - ILFamilyTreeChronicleCoordinatorDelegate
extension ILFamilyTreeCoordinator: ILFamilyTreeChronicleCoordinatorDelegate {
    func familyTreeChronicleDidUpdate(_ trees: [ILFamilyTreeEntity], coordinator: ILFamilyTreeChronicleCoordinator) {
        viewModel?.showUpdatedBooks(trees)
    }

    func familyTreeChronicleDidRequestOpen(treeID: String, memberID: String, coordinator: ILFamilyTreeChronicleCoordinator) {
        viewModel?.openMember(treeID: treeID, memberID: memberID)
    }
}
