//
//  ILSettingsAccountCardView.swift
//  InnerLamp
//

import UIKit

/// Thẻ tài khoản đầu màn Cài đặt: avatar tròn (chữ đầu tên), tên, dòng "Pháp danh … · SĐT" và
/// mũi tên chevron. Bấm để về hồ sơ. Là composition riêng của màn Cài đặt.
final class ILSettingsAccountCardView: UIControl {

    // MARK: - Constants
    private enum Layout {
        static let avatarSize: CGFloat = 46
    }

    // MARK: - Properties
    var onTap: (() -> Void)?

    // MARK: - UI Elements
    private let avatarGradient = CAGradientLayer()

    private lazy var avatarView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Layout.avatarSize / 2
        view.layer.borderWidth = 1
        view.clipsToBounds = true
        avatarGradient.startPoint = CGPoint(x: 0.25, y: 0)
        avatarGradient.endPoint = CGPoint(x: 0.75, y: 1)
        view.layer.insertSublayer(avatarGradient, at: 0)
        return view
    }()

    private lazy var initialLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.scriptureBody
        label.textColor = ILColors.goldDeep
        label.textAlignment = .center
        return label
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.rowTitle
        label.textColor = ILColors.ink
        label.numberOfLines = 1
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.inkTertiary
        label.numberOfLines = 1
        return label
    }()

    private lazy var chevronLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.chevron
        label.textColor = ILColors.inkFaint
        label.text = "›"
        return label
    }()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
        applyDynamicColors()
        registerForAppearanceChanges()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        avatarGradient.frame = avatarView.bounds
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardSmall + 2
        layer.borderWidth = 1
        clipsToBounds = true

        initialLabel.translatesAutoresizingMaskIntoConstraints = false
        avatarView.addSubview(initialLabel)
        chevronLabel.setContentHuggingPriority(.required, for: .horizontal)

        let textStack = UIStackView(arrangedSubviews: [nameLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading

        let rowStack = UIStackView(arrangedSubviews: [avatarView, textStack, chevronLabel])
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = ILMetrics.spaceMedium
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        rowStack.isUserInteractionEnabled = false

        addSubview(rowStack)

        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: Layout.avatarSize),
            avatarView.heightAnchor.constraint(equalToConstant: Layout.avatarSize),
            initialLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            initialLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            rowStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.spaceStandard),
            rowStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.spaceStandard),
            rowStack.topAnchor.constraint(equalTo: topAnchor, constant: ILMetrics.spaceStandard),
            rowStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -ILMetrics.spaceStandard)
        ])

        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)
    }

    // MARK: - Configure
    func configure(initial: String, name: String, subtitle: String) {
        initialLabel.text = initial
        nameLabel.text = name
        subtitleLabel.text = subtitle
    }

    // `CGColor` tĩnh (viền, gradient) không tự đảo theo trait — dựng lại khi đổi light/dark.
    private func applyDynamicColors() {
        avatarGradient.colors = [ILColors.canvasWarmEnd1.cgColor, ILColors.tint.cgColor]
        avatarView.layer.borderColor = ILColors.goldBorder.cgColor
        layer.borderColor = ILColors.border.cgColor
    }

    private func registerForAppearanceChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.applyDynamicColors()
        }
    }

    @objc private func handleTouchDown() {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = CGAffineTransform(scaleX: 0.99, y: 0.99)
        }
    }

    @objc private func handleTouchUp() {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = .identity
        }
    }

    @objc private func handleTapAction() {
        onTap?()
    }
}
