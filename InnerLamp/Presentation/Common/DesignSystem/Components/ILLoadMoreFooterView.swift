//
//  ILLoadMoreFooterView.swift
//  InnerLamp
//

import UIKit

/// Footer for paginated lists (design handoff "arts" list): a 14pt gold spinner + "Loading
/// more…" while the next page loads, a centered end-of-list note once everything is loaded,
/// or nothing. Put it as the last arranged subview of the list's stack.
public final class ILLoadMoreFooterView: UIView {

    public enum State: Equatable {
        case hidden
        case loading
        case end
    }

    // MARK: - Properties
    public var state: State = .hidden {
        didSet {
            guard state != oldValue else { return }
            updateAppearance()
        }
    }

    public var loadingText: String {
        didSet { updateAppearance() }
    }

    public var endText: String {
        didSet { updateAppearance() }
    }

    // MARK: - UI Elements
    private let stackView = UIStackView()
    private let spinnerView = UIView()
    private let trackLayer = CAShapeLayer()
    private let arcLayer = CAShapeLayer()
    private let label = UILabel()

    // MARK: - Initializer
    /// Texts default to the localized "loading.more" / "loading.end" copy.
    public init(loadingText: String? = nil, endText: String? = nil) {
        self.loadingText = loadingText ?? "loading.more".localized
        self.endText = endText ?? "loading.end".localized
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
        updateAppearance()

        // CGColor does not follow dark mode on its own.
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.applyLayerColors()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false

        let spec = ILMetrics.Skeleton.self
        let inset = spec.spinnerLineWidth / 2
        let ringPath = UIBezierPath(
            ovalIn: CGRect(x: 0, y: 0, width: spec.spinnerSize, height: spec.spinnerSize).insetBy(dx: inset, dy: inset)
        ).cgPath

        [trackLayer, arcLayer].forEach {
            $0.path = ringPath
            $0.fillColor = UIColor.clear.cgColor
            $0.lineWidth = spec.spinnerLineWidth
            spinnerView.layer.addSublayer($0)
        }
        // `border-top-color` on a round box paints roughly a quarter of the ring.
        arcLayer.strokeStart = 0.625
        arcLayer.strokeEnd = 0.875
        applyLayerColors()

        label.font = ILTypography.note
        label.textColor = ILColors.inkSubtle
        label.textAlignment = .center
        label.numberOfLines = 0

        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = ILMetrics.rowSpacing
        stackView.addArrangedSubview(spinnerView)
        stackView.addArrangedSubview(label)
        addSubview(stackView)
    }

    private func setupConstraints() {
        [stackView, spinnerView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        let padding = ILMetrics.Skeleton.footerPadding

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: padding.top),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding.bottom),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),

            spinnerView.widthAnchor.constraint(equalToConstant: ILMetrics.Skeleton.spinnerSize),
            spinnerView.heightAnchor.constraint(equalToConstant: ILMetrics.Skeleton.spinnerSize)
        ])
    }

    // MARK: - Lifecycle
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        // CAAnimations added before the view has a window are dropped by Core Animation.
        if window != nil, state == .loading { startSpinning() }
    }


    // MARK: - Private
    private func updateAppearance() {
        isHidden = state == .hidden
        spinnerView.isHidden = state != .loading
        label.text = state == .end ? endText : loadingText
        accessibilityLabel = isHidden ? nil : label.text

        if state == .loading {
            startSpinning()
        } else {
            spinnerView.layer.removeAnimation(forKey: Self.spinAnimationKey)
        }
    }

    private func startSpinning() {
        guard window != nil,
              spinnerView.layer.animation(forKey: Self.spinAnimationKey) == nil else { return }
        let spin = CABasicAnimation(keyPath: "transform.rotation.z")
        spin.fromValue = 0
        spin.toValue = CGFloat.pi * 2
        spin.duration = ILMetrics.Skeleton.spinnerRotationDuration
        spin.repeatCount = .infinity
        spin.timingFunction = CAMediaTimingFunction(name: .linear)
        // Keeps the spinner alive across app background/foreground.
        spin.isRemovedOnCompletion = false
        spinnerView.layer.add(spin, forKey: Self.spinAnimationKey)
    }

    private func applyLayerColors() {
        trackLayer.strokeColor = ILColors.Skeleton.spinnerTrack.resolvedColor(with: traitCollection).cgColor
        arcLayer.strokeColor = ILColors.gold.resolvedColor(with: traitCollection).cgColor
    }

    private static let spinAnimationKey = "ilLoadMoreSpin"
}
