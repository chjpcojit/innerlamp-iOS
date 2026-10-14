//
//  ILLightLampCoordinator.swift
//  InnerLamp
//

import UIKit
import Combine

/// "Thắp đèn" flow — the lighting screen and the lamp garden. One coordinator owns both; there is
/// no delegate. Two entry modes:
/// - `start()` pushes onto `navigationController` (Home suggested-session row); `.back` pops.
/// - `startModal()` presents a full-screen `BaseNavigationController` over it (center tab-bar lamp
///   button); `.back` dismisses the whole modal.
/// Either way `.back` on the lighting screen `finish()`es the flow, and `.back` on the garden only
/// pops back to the lighting screen.
final class ILLightLampCoordinator: Coordinator {

    let navigationController: UINavigationController
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?

    private let container: DIContainer
    private var cancellables = Set<AnyCancellable>()
    private weak var lightingViewController: UIViewController?
    private weak var gardenViewController: UIViewController?
    /// Stack the flow's screens live on: `navigationController` when pushed, the presented
    /// navigation controller when modal.
    private lazy var flowNavigationController: UINavigationController = navigationController
    private var isModal = false

    init(
        navigationController: UINavigationController,
        container: DIContainer
    ) {
        self.navigationController = navigationController
        self.container = container
    }

    func start() {
        let viewController = makeLightingViewController()
        navigationController.pushViewController(viewController, animated: true)
    }

    func startModal() {
        let viewController = makeLightingViewController()
        let modalNavigation = BaseNavigationController(rootViewController: viewController)
        modalNavigation.modalPresentationStyle = .fullScreen
        flowNavigationController = modalNavigation
        isModal = true
        navigationController.present(modalNavigation, animated: true)
    }

    // MARK: - Screens
    private func makeLightingViewController() -> UIViewController {
        let viewModel = container.makeLightLampViewModel()
        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .back:
                    if self.isModal {
                        self.flowNavigationController.dismiss(animated: true)
                    } else {
                        self.navigationController.popViewController(animated: true)
                    }
                    self.finish()
                case .openGarden:
                    self.showGarden()
                }
            }
            .store(in: &cancellables)

        let viewController = ILLightLampViewController(viewModel: viewModel)
        lightingViewController = viewController
        return viewController
    }

    private func showGarden() {
        let viewModel = container.makeLampGardenViewModel()
        viewModel.navigationEventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .back:
                    self.flowNavigationController.popViewController(animated: true)
                case .openLighting:
                    self.replaceGardenWithFreshLighting()
                }
            }
            .store(in: &cancellables)

        let viewController = ILLampGardenViewController(viewModel: viewModel)
        gardenViewController = viewController
        flowNavigationController.pushViewController(viewController, animated: true)
    }

    /// Garden header "Thắp đèn": swap the old lighting screen and the garden for a fresh form, so
    /// Back from it leaves the flow instead of landing on a stale completion state.
    private func replaceGardenWithFreshLighting() {
        let oldLighting = lightingViewController
        let garden = gardenViewController
        let fresh = makeLightingViewController()
        var stack = flowNavigationController.viewControllers
        stack.removeAll { $0 === garden || $0 === oldLighting }
        stack.append(fresh)
        flowNavigationController.setViewControllers(stack, animated: true)
    }
}
