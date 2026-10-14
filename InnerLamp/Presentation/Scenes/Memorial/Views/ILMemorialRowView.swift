//
//  ILMemorialRowView.swift
//  InnerLamp
//

import UIKit

/// 1 row of "THEO NGÀY GIỖ SẮP TỚI" (design handoff `gioList`): portrait placeholder, name and
/// "relationship · date" on the left, days label and the "Có nhắc" tag on the right.
final class ILMemorialRowView: UIControl {

    // MARK: - Properties
    var onTap: (() -> Void)?

    // MARK: - UI Elements
    private lazy var avatarView: ILAvatarView = {
        let view = ILAvatarView(initials: "", tone: .gold, size: 46)
        return view
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.bodyMedium
        label.textColor = ILColors.ink
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.inkSubtle
        return label
    }()

    private lazy var daysLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subheadMedium
        label.textAlignment = .right
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private lazy var tagLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.label
        label.textColor = ILColors.inkMuted
        label.textAlignment = .right
        return label
    }()

    // MARK: - Initializer
    init(model: ILMemorialRowModel) {
        super.init(frame: .zero)
        setupViews()
        configure(with: model)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public API
    func configure(with model: ILMemorialRowModel) {
        avatarView.initials = model.name.first.map { String($0).uppercased() } ?? ""
        nameLabel.text = model.name
        subtitleLabel.text = model.subtitle
        daysLabel.text = model.daysText
        daysLabel.textColor = model.isSoon ? ILColors.link : ILColors.inkMuted
        tagLabel.text = model.reminderTag
        tagLabel.isHidden = model.reminderTag.isEmpty
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardSmall
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor

        let textStack = UIStackView(arrangedSubviews: [nameLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let trailingStack = UIStackView(arrangedSubviews: [daysLabel, tagLabel])
        trailingStack.axis = .vertical
        trailingStack.alignment = .trailing
        trailingStack.spacing = 4
        trailingStack.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [avatarView, textStack, trailingStack])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = ILMetrics.spaceMedium
        row.isUserInteractionEnabled = false
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.spaceStandard),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.spaceStandard)
        ])

        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILMemorialRowView, _) in
            view.layer.borderColor = ILColors.border.cgColor
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
