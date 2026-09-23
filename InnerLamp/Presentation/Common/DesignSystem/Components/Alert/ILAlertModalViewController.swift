//
//  ILAlertModalViewController.swift
//  InnerLamp
//

import UIKit

/// Base for the blocking error popups (`ILErrorSheetViewController`, `ILErrorDialogViewController`,
/// `ILErrorFullScreenViewController`). Presented `.overFullScreen` without UIKit's own animation;
/// each subclass drives its own entrance/exit from the design (`ilup`, `ilpop`, `ilfade`) through
/// `applyHiddenState()` / `applyShownState()`.
///
/// Like `ILCountryPickerViewController`, these are not navigation screens (no ViewModel, no stack
/// entry), so `ILAlertPresenter` presents them directly instead of routing through a Coordinator.
class ILAlertModalViewController: BaseViewController {

    // MARK: - Properties
    /// Entrance duration and curve — subclasses override to match the design keyframes.
    var appearDuration: TimeInterval { 0.3 }
    var disappearDuration: TimeInterval { 0.22 }

    private var hasAppeared = false
    private var isClosing = false

    // MARK: - Initializer
    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalPresentationCapturesStatusBarAppearance = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = .clear
        view.accessibilityViewIsModal = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard !hasAppeared else { return }
        view.layoutIfNeeded()
        applyHiddenState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasAppeared else { return }
        hasAppeared = true
        let animator = UIViewPropertyAnimator(
            duration: appearDuration,
            controlPoint1: CGPoint(x: 0.2, y: 0.9),
            controlPoint2: CGPoint(x: 0.3, y: 1)
        ) { [weak self] in
            self?.applyShownState()
        }
        animator.startAnimation()
        didAnimateIn()
        UIAccessibility.post(notification: .screenChanged, argument: view)
    }

    // MARK: - Subclass hooks
    /// Off-screen / transparent starting (and ending) state.
    func applyHiddenState() {}
    /// Resting on-screen state.
    func applyShownState() {}
    /// Extra one-off effects once the entrance starts (e.g. the dialog glyph shake).
    func didAnimateIn() {}

    // MARK: - Dismissal
    /// Animates out, dismisses without UIKit animation, then runs `completion`.
    func close(completion: (() -> Void)? = nil) {
        guard !isClosing else { return }
        isClosing = true
        UIView.animate(withDuration: disappearDuration, delay: 0, options: [.curveEaseIn, .beginFromCurrentState]) {
            self.applyHiddenState()
        } completion: { _ in
            self.dismiss(animated: false, completion: completion)
        }
    }

    /// Wraps an action so tapping it closes the popup first, then runs the handler.
    func closeThenRun(_ action: ILAlertAction) -> () -> Void {
        { [weak self] in self?.close(completion: action.handler) }
    }
}
