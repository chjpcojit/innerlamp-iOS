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
    private let avatarView = ILAvatarView(initials: "", tone: .gold, size: 46)
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let daysLabel = UILabel()
    private let tagLabel = UILabel()

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

        nameLabel.font = ILTypography.bodyMedium
        nameLabel.textColor = ILColors.ink

        subtitleLabel.font = ILTypography.subhead
        subtitleLabel.textColor = ILColors.inkSubtle

        let textStack = UIStackView(arrangedSubviews: [nameLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        daysLabel.font = ILTypography.subheadMedium
        daysLabel.textAlignment = .right
        daysLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        tagLabel.font = ILTypography.label
        tagLabel.textColor = ILColors.inkMuted
        tagLabel.textAlignment = .right

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
