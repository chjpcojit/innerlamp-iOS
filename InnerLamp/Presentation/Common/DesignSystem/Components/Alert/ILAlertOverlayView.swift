//
//  ILAlertOverlayView.swift
//  InnerLamp
//

import UIKit

/// Base class for the floating, non-blocking popups (`ILToastView`, `ILAlertBannerView`,
/// `ILSnackbarView`): a rounded card pinned to the top or bottom safe area, which slides in
/// (design `ildrop` / `ilup`, cubic-bezier(.2,.9,.3,1)), can auto-dismiss, and can be swiped away.
/// Touches outside the card pass through to the screen below.
///
/// Subclasses add their content to `contentView` (clipped to the card's corners) and never
/// position themselves — `ILAlertPresenter` calls `present(in:autoDismissAfter:)`.
public class ILAlertOverlayView: UIView {

    public enum Edge {
        case top
        case bottom
    }

    // MARK: - Properties
    /// Called once the card has left the screen (by any path).
    var onDismissed: (() -> Void)?

    let edge: Edge
    /// Clipped card content — subclasses lay out inside this.
    let contentView = UIView()

    private let shadow: ILMetrics.Shadow
    private let cornerRadius: CGFloat
    private let borderColor: UIColor?
    private var autoDismissWorkItem: DispatchWorkItem?
    private(set) var isDismissing = false

    // MARK: - Initializer
    init(edge: Edge, cornerRadius: CGFloat, background: UIColor, borderColor: UIColor?, shadow: ILMetrics.Shadow) {
        self.edge = edge
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.shadow = shadow
        super.init(frame: .zero)
        contentView.backgroundColor = background
        setupBase()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupBase() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear

        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.layer.cornerRadius = cornerRadius
        contentView.layer.cornerCurve = .continuous
        contentView.clipsToBounds = true
        addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipe.direction = edge == .top ? .up : .down
        addGestureRecognizer(swipe)

        applyLayerColors()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        applyLayerColors()
    }

    /// CGColors (border, shadow) do not follow trait changes — re-resolve them here.
    private func applyLayerColors() {
        traitCollection.performAsCurrent {
            shadow.apply(to: layer)
            contentView.layer.borderWidth = borderColor == nil ? 0 : 1
            contentView.layer.borderColor = borderColor?.cgColor
        }
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
    }

    // MARK: - Presentation
    func present(in container: UIView, autoDismissAfter delay: TimeInterval?) {
        container.addSubview(self)

        let inset = ILMetrics.Alert.floatingInset
        var constraints = [
            leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: inset),
            trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -inset)
        ]
        switch edge {
        case .top:
            constraints.append(topAnchor.constraint(equalTo: container.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.Alert.topOffset))
        case .bottom:
            constraints.append(bottomAnchor.constraint(equalTo: container.safeAreaLayoutGuide.bottomAnchor, constant: -ILMetrics.Alert.bottomOffset))
        }
        NSLayoutConstraint.activate(constraints)
        container.layoutIfNeeded()

        alpha = 0
        transform = hiddenTransform
        let animator = UIViewPropertyAnimator(
            duration: edge == .top ? 0.32 : 0.30,
            controlPoint1: CGPoint(x: 0.2, y: 0.9),
            controlPoint2: CGPoint(x: 0.3, y: 1)
        ) {
            self.alpha = 1
            self.transform = .identity
        }
        animator.startAnimation()

        UIAccessibility.post(notification: .layoutChanged, argument: self)

        if let delay {
            let workItem = DispatchWorkItem { [weak self] in self?.dismiss() }
            autoDismissWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
            autoDismissCountdownDidStart(duration: delay)
        }
    }

    /// Slides the card back out, removes it, then runs `completion` (e.g. an action handler).
    func dismiss(completion: (() -> Void)? = nil) {
        guard !isDismissing else { return }
        isDismissing = true
        autoDismissWorkItem?.cancel()

        UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseIn, .beginFromCurrentState]) {
            self.alpha = 0
            self.transform = self.hiddenTransform
        } completion: { _ in
            // Strong capture on purpose: the animation block is not retained by `self`, and
            // `onDismissed` must still fire after the view leaves the hierarchy.
            self.removeFromSuperview()
            self.onDismissed?()
            completion?()
        }
    }

    /// Hook for subclasses that visualise the auto-dismiss countdown (the toast's progress bar).
    func autoDismissCountdownDidStart(duration: TimeInterval) {}

    /// Wraps an action so tapping it dismisses the card first, then runs the handler.
    func dismissThenRun(_ action: ILAlertAction) -> () -> Void {
        { [weak self] in self?.dismiss(completion: action.handler) }
    }

    /// Design: `translateY(-130%)` from the top, `translateY(115%)` from the bottom.
    private var hiddenTransform: CGAffineTransform {
        switch edge {
        case .top: return CGAffineTransform(translationX: 0, y: -bounds.height * 1.3)
        case .bottom: return CGAffineTransform(translationX: 0, y: bounds.height * 1.15)
        }
    }

    @objc private func handleSwipe() {
        dismiss()
    }
}
