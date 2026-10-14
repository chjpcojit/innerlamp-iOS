//
//  ILAlertPresenter.swift
//  InnerLamp
//

import UIKit

/// Single entry point for showing the shared error popups (`ILAlert`).
///
/// ```swift
/// ILAlertPresenter.shared.show(
///     .dialog(
///         title: "error.sessionExpired.title".localized,
///         message: "error.sessionExpired.message".localized,
///         primary: ILAlertAction(title: "login.cta.login".localized) { [weak self] in self?.relogin() },
///         secondary: ILAlertAction(title: "common.later".localized)
///     ),
///     from: navigationController
/// )
/// ```
///
/// - Floating popups (toast, banner, snackbar) are added to the window, so they survive pushes
///   and pops underneath. Only one is visible at a time — a new one replaces the current one.
/// - Blocking popups (sheet, dialog, full screen) are presented modally over the top-most
///   view controller reachable from `viewController`.
///
/// Popups are not navigation screens (no ViewModel, no stack entry), so — like
/// `ILCountryPickerViewController` — they may be shown from a Coordinator or directly from a
/// ViewController reacting to a failed `ViewState`.
public final class ILAlertPresenter {

    public static let shared = ILAlertPresenter()

    // MARK: - Properties
    private weak var currentOverlay: ILAlertOverlayView?

    // MARK: - Initializer
    init() {}

    // MARK: - Public API
    public func show(_ alert: ILAlert, from viewController: UIViewController) {
        switch alert {
        case let .toast(title, message):
            showOverlay(ILToastView(title: title, message: message), alert: alert, from: viewController)

        case let .success(title, message):
            showOverlay(ILToastView(title: title, message: message, tone: .success), alert: alert, from: viewController)

        case let .banner(title, message, primary, secondary):
            showOverlay(
                ILAlertBannerView(title: title, message: message, primary: primary, secondary: secondary),
                alert: alert,
                from: viewController
            )

        case let .snackbar(message, action):
            showOverlay(ILSnackbarView(message: message, action: action), alert: alert, from: viewController)

        case let .sheet(title, message, errorCode, primary, secondary):
            presentModal(
                ILErrorSheetViewController(title: title, message: message, errorCode: errorCode, primary: primary, secondary: secondary),
                from: viewController
            )

        case let .dialog(title, message, primary, secondary):
            presentModal(
                ILErrorDialogViewController(title: title, message: message, primary: primary, secondary: secondary),
                from: viewController
            )

        case let .confirm(title, message, cancel, confirm):
            presentModal(
                ILConfirmDialogViewController(title: title, message: message, cancel: cancel, confirm: confirm),
                from: viewController
            )

        case let .fullScreen(title, subtitle, message, errorCode, primary, secondary):
            presentModal(
                ILErrorFullScreenViewController(
                    title: title,
                    subtitle: subtitle,
                    message: message,
                    errorCode: errorCode,
                    primary: primary,
                    secondary: secondary
                ),
                from: viewController
            )
        }
    }

    /// Dismisses the visible toast / banner / snackbar, if any.
    public func dismissOverlay() {
        currentOverlay?.dismiss()
    }

    // MARK: - Private
    private func showOverlay(_ overlay: ILAlertOverlayView, alert: ILAlert, from viewController: UIViewController) {
        let container: UIView = viewController.view.window ?? viewController.view
        currentOverlay?.dismiss()
        currentOverlay = overlay
        overlay.present(in: container, autoDismissAfter: alert.autoDismissDelay)
    }

    private func presentModal(_ modal: ILAlertModalViewController, from viewController: UIViewController) {
        var presenter = viewController
        while let presented = presenter.presentedViewController, !presented.isBeingDismissed {
            presenter = presented
        }
        // The popups animate themselves (see `ILAlertModalViewController`).
        presenter.present(modal, animated: false)
    }
}
