//
//  ILFamilyTreeMemberCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

protocol ILFamilyTreeMemberCoordinatorDelegate: AnyObject {
    /// The member was edited and saved. The profile stays open.
    func familyTreeMemberDidSave(_ tree: ILFamilyTreeEntity, memberID: String, coordinator: ILFamilyTreeMemberCoordinator)
    /// A relation row was tapped; the profile has already popped itself.
    func familyTreeMemberDidRequestOpen(memberID: String, coordinator: ILFamilyTreeMemberCoordinator)
}

/// "Hồ sơ thành viên" flow — one screen (view + edit modes) pushed from the family tree's detail
/// sheet. `.back` pops and `finish()`es; `.saved` only tells the delegate; `.openMember` pops, tells
/// the delegate, then `finish()`es; the memorial / temple events are one-line TODO stubs.
final class ILFamilyTreeMemberCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?
    weak var delegate: ILFamilyTreeMemberCoordinatorDelegate?

    private let container: DIContainer
    private let tree: ILFamilyTreeEntity
    private let memberID: String
    private let kinship: String?
    private var cancellables = Set<AnyCancellable>()

    init(
        navigationController: UINavigationController,
        container: DIContainer,
        tree: ILFamilyTreeEntity,
        memberID: String,
        kinship: String?
    ) {
        self.navigationController = navigationController
        self.container = container
        self.tree = tree
        self.memberID = memberID
        self.kinship = kinship
    }

    func start() {
        let viewModel = container.makeFamilyTreeMemberViewModel(tree: tree, memberID: memberID, kinship: kinship)

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .back:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .saved(let tree, let memberID):
                    self.delegate?.familyTreeMemberDidSave(tree, memberID: memberID, coordinator: self)
                case .openMember(let id):
                    self.navigationController.popViewController(animated: true)
                    self.delegate?.familyTreeMemberDidRequestOpen(memberID: id, coordinator: self)
                    self.finish()
                case .remind(let id):
                    print("TODO: add \(id)'s anniversary to the Sổ giỗ / open it (no hand-off yet — TD-FamilyTreeMember-003)")
                case .lightLamp(let id):
                    print("TODO: open the light-a-lamp offering for \(id) (destination unconfirmed — TD-FamilyTreeMember-003)")
                case .chant(let id):
                    print("TODO: open chanting with merit dedication for \(id) (destination unconfirmed — TD-FamilyTreeMember-003)")
                case .openTemple(let id):
                    print("TODO: open the tablet temple page for \(id) (no temple link/data yet — TD-FamilyTreeMember-003)")
                }
            }
            .store(in: &cancellables)

        let viewController = ILFamilyTreeMemberViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
