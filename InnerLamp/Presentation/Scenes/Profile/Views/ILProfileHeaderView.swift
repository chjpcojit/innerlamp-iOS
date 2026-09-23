//
//  ILProfileHeaderView.swift
//  InnerLamp
//

import UIKit

/// Dải đầu dán của màn Tôi: avatar tròn, tên, dòng "Pháp danh … · Phật tử tại gia" và nút pill
/// "Sửa hồ sơ", hairline ở đáy. Nền phủ kín tới mép trên màn hình — cần ghim `topAnchor` vào
/// `view.topAnchor` của màn để phần status bar nằm trong dải; nội dung tự chừa safe area.
/// Biết `ILProfileHeaderModel` nên thuộc riêng màn Tôi.
final class ILProfileHeaderView: UIView {

    // MARK: - Constants
    private enum Layout {
        static let avatarSize: CGFloat = 72
    }

    // MARK: - Properties
    var onEditTapped: (() -> Void)?

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
        label.font = ILTypography.displayMedium
        label.textColor = ILColors.goldDeep
        label.textAlignment = .center
        return label
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.scriptureTitle
        label.textColor = ILColors.ink
        label.numberOfLines = 0
        label.accessibilityTraits = .header
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private lazy var editButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.title = "profile.header.edit".localized
        configuration.baseForegroundColor = ILColors.ink
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = ILTypography.subheadMedium
            return attributes
        }
        let button = UIButton(configuration: configuration)
        button.layer.cornerRadius = ILMetrics.radiusPill
        button.layer.borderWidth = 1
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.addTarget(self, action: #selector(handleEditTapped), for: .touchUpInside)
        return button
    }()

    private lazy var divider: UIView = {
        let view = UIView()
        view.backgroundColor = ILColors.border
        return view
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
        backgroundColor = ILColors.canvas

        initialLabel.translatesAutoresizingMaskIntoConstraints = false
        avatarView.addSubview(initialLabel)
        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: Layout.avatarSize),
            avatarView.heightAnchor.constraint(equalToConstant: Layout.avatarSize),
            initialLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            initialLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor)
        ])

        let textStack = UIStackView(arrangedSubviews: [nameLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 3

        let rowStack = UIStackView(arrangedSubviews: [avatarView, textStack, editButton])
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = ILMetrics.spaceMedium + 2
        rowStack.translatesAutoresizingMaskIntoConstraints = false

        divider.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rowStack)
        addSubview(divider)

        NSLayoutConstraint.activate([
            rowStack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceMedium),
            rowStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.screenHorizontal),
            rowStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.screenHorizontal),
            rowStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -(ILMetrics.spaceMedium - 2)),

            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor),
            divider.bottomAnchor.constraint(equalTo: bottomAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    // MARK: - Configure
    func configure(with model: ILProfileHeaderModel) {
        initialLabel.text = model.initial
        nameLabel.text = model.fullName
        subtitleLabel.attributedText = makeSubtitle(model)
    }

    private func makeSubtitle(_ model: ILProfileHeaderModel) -> NSAttributedString {
        let text = NSMutableAttributedString(
            string: model.subtitle,
            attributes: [.font: ILTypography.bodySmall, .foregroundColor: ILColors.inkTertiary]
        )
        if let highlight = model.subtitleHighlight {
            let range = (model.subtitle as NSString).range(of: highlight)
            if range.location != NSNotFound {
                text.addAttribute(.foregroundColor, value: ILColors.goldDeep, range: range)
            }
        }
        return text
    }

    // `CGColor` tĩnh (viền, gradient) không tự đảo theo trait — dựng lại khi đổi light/dark.
    private func applyDynamicColors() {
        avatarGradient.colors = [ILColors.canvasWarmEnd1.cgColor, ILColors.tint.cgColor]
        avatarView.layer.borderColor = ILColors.goldBorder.cgColor
        editButton.layer.borderColor = ILColors.borderStrong.cgColor
    }

    private func registerForAppearanceChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.applyDynamicColors()
        }
    }

    @objc private func handleEditTapped() {
        onEditTapped?()
    }
}
