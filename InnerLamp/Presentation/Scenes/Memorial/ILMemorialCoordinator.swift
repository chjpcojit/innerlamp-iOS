//
//  ILMemorialCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// "Sổ giỗ chạp" flow — the list and its add/edit form, pushed from Home's week-strip link. One
/// coordinator owns both screens; there is no delegate: `.back` on the list pops and `finish()`es,
/// and a save/delete in the form pops back to the list and hands it the confirmation message.
final class ILMemorialCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?

    private let container: DIContainer
    private var listViewModel: ILMemorialViewModel?
    private var cancellables = Set<AnyCancellable>()

    init(
        navigationController: UINavigationController,
        container: DIContainer
    ) {
        self.navigationController = navigationController
        self.container = container
    }

    func start() {
        let viewModel = container.makeMemorialViewModel()
        listViewModel = viewModel

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .back:
                    self.navigationController.popViewController(animated: true)
                    self.finish()
                case .addEntry:
                    self.showEdit(entry: nil)
                case .editEntry(let entry):
                    self.showEdit(entry: entry)
                case .openFamilyTree:
                    self.showFamilyTree()
                }
            }
            .store(in: &cancellables)

        let viewController = ILMemorialViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    // @ai: assumption — see Docs/Assumptions/FamilyTree/AS-FamilyTree-003-entry-from-memorial.md
    private func showFamilyTree() {
        let coordinator = container.makeFamilyTreeCoordinator(navigationController: navigationController)
        addChild(coordinator)
        coordinator.start()
    }

    private func showEdit(entry: ILMemorialEntity?) {
        let viewModel = container.makeMemorialEditViewModel(entry: entry)

        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                self.navigationController.popViewController(animated: true)
                switch event {
                case .back:
                    break
                case .saved(let message), .deleted(let message):
                    self.listViewModel?.didFinishEditing(message: message)
                }
            }
            .store(in: &cancellables)

        let viewController = ILMemorialEditViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
