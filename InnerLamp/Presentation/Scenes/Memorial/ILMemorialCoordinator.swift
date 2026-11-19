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
    /// Set when a local notification opened the flow; the list loads that entry and pushes its form.
    private let initialEntryID: String?
    private var listViewModel: ILMemorialViewModel?
    private var cancellables = Set<AnyCancellable>()

    init(
        navigationController: UINavigationController,
        container: DIContainer,
        initialEntryID: String? = nil
    ) {
        self.navigationController = navigationController
        self.container = container
        self.initialEntryID = initialEntryID
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
                }
            }
            .store(in: &cancellables)

        let viewController = ILMemorialViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)

        if let initialEntryID, !initialEntryID.isEmpty {
            viewModel.openEntry(id: initialEntryID)
        }
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
