//
//  ILBellActionBarView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import UIKit

/// The bottom action bar of the "Chuông mõ" screen: a left ghost pill (Đặt lại / Dồn mõ), a round
/// gold play/pause button, and a right gold-tinted pill (Thỉnh chuông). Feature-scoped — its
/// three-slot layout is specific to this screen.
final class ILBellActionBarView: UIView {

    // MARK: - Properties
    var leftTitle: String = "" {
        didSet { leftButton.setTitle(leftTitle, for: .normal) }
    }

    var ringBellTitle: String = "" {
        didSet { ringBellButton.setTitle(ringBellTitle, for: .normal) }
    }

    var isRunning: Bool = false {
        didSet { toggleIconView.isPlaying = isRunning }
    }

    var onLeftTap: (() -> Void)?
    var onToggleTap: (() -> Void)?
    var onRingBellTap: (() -> Void)?

    // MARK: - UI Elements
    private let leftButton = UIButton(type: .system)
    private let toggleButton = UIButton(type: .system)
    private let toggleIconView = ILBellToggleIconView()
    private let ringBellButton = UIButton(type: .system)

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        configurePill(leftButton, foreground: ILColors.medInk, stroke: ILColors.medBorder, fill: nil)
        leftButton.addTarget(self, action: #selector(handleLeftTap), for: .touchUpInside)

        toggleButton.backgroundColor = ILColors.goldBright
        toggleButton.layer.cornerRadius = 32
        ILMetrics.shadowGoldToggle.apply(to: toggleButton.layer)
        toggleButton.addTarget(self, action: #selector(handleToggleTap), for: .touchUpInside)

        toggleIconView.isUserInteractionEnabled = false
        toggleIconView.translatesAutoresizingMaskIntoConstraints = false
        toggleButton.addSubview(toggleIconView)

        configurePill(
            ringBellButton,
            foreground: ILColors.link,
            stroke: ILColors.medGoldTintBorder,
            fill: ILColors.medGoldTint
        )
        ringBellButton.addTarget(self, action: #selector(handleRingBellTap), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [leftButton, toggleButton, ringBellButton])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = ILMetrics.rowSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),

            leftButton.heightAnchor.constraint(equalToConstant: ILMetrics.inputHeight),
            ringBellButton.heightAnchor.constraint(equalToConstant: ILMetrics.inputHeight),

            toggleButton.widthAnchor.constraint(equalToConstant: 64),
            toggleButton.heightAnchor.constraint(equalToConstant: 64),

            toggleIconView.centerXAnchor.constraint(equalTo: toggleButton.centerXAnchor),
            toggleIconView.centerYAnchor.constraint(equalTo: toggleButton.centerYAnchor),
            toggleIconView.widthAnchor.constraint(equalToConstant: 24),
            toggleIconView.heightAnchor.constraint(equalToConstant: 24)
        ])
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILBellActionBarView, _) in
            view.applyColorAppearanceChange()
        }
    }

    private func configurePill(_ button: UIButton, foreground: UIColor, stroke: UIColor, fill: UIColor?) {
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = foreground
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = ILTypography.sectionTitle
            return outgoing
        }
        config.cornerStyle = .capsule
        config.background.strokeWidth = 1
        if let fill {
            config.background.backgroundColor = fill
        }
        button.configuration = config
        button.configurationUpdateHandler = { button in
            UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
                button.transform = button.isHighlighted ? CGAffineTransform(scaleX: 0.978, y: 0.978) : .identity
            }
        }
    }

    private func applyColorAppearanceChange() {
        leftButton.configuration?.baseForegroundColor = ILColors.medInk
        leftButton.configuration?.background.strokeColor = ILColors.medBorder.resolvedColor(with: traitCollection)
        ringBellButton.configuration?.baseForegroundColor = ILColors.link.resolvedColor(with: traitCollection)
        ringBellButton.configuration?.background.strokeColor = ILColors.medGoldTintBorder.resolvedColor(with: traitCollection)
        ringBellButton.configuration?.background.backgroundColor = ILColors.medGoldTint.resolvedColor(with: traitCollection)
    }

    @objc private func handleLeftTap() {
        onLeftTap?()
    }

    @objc private func handleToggleTap() {
        onToggleTap?()
    }

    @objc private func handleRingBellTap() {
        onRingBellTap?()
    }
}

// MARK: - Toggle icon (play triangle / pause bars)
private final class ILBellToggleIconView: UIView {

    var isPlaying: Bool = false {
        didSet { setNeedsDisplay() }
    }

    private let color = ILColors.lampFlameDark

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setFillColor(color.cgColor)

        if isPlaying {
            // Two vertical bars (pause).
            let barWidth = rect.width * 0.30
            let gap = rect.width * 0.16
            let leftX = (rect.width - barWidth * 2 - gap) / 2
            let barRect1 = CGRect(x: leftX, y: 0, width: barWidth, height: rect.height)
            let barRect2 = CGRect(x: leftX + barWidth + gap, y: 0, width: barWidth, height: rect.height)
            context.fill(barRect1)
            context.fill(barRect2)
        } else {
            // Right-pointing triangle (play).
            let triangle = CGMutablePath()
            triangle.move(to: CGPoint(x: rect.width * 0.15, y: 0))
            triangle.addLine(to: CGPoint(x: rect.width, y: rect.height / 2))
            triangle.addLine(to: CGPoint(x: rect.width * 0.15, y: rect.height))
            triangle.closeSubpath()
            context.addPath(triangle)
            context.fillPath()
        }
    }
}
