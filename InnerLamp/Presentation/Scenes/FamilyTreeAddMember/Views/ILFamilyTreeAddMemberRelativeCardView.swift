//
//  ILFamilyTreeAddMemberRelativeCardView.swift
//  InnerLamp
//

import UIKit

/// The "Con của / Vợ chồng của" target: a gold hexagon, the relative's name + meta line and an
/// outlined "Đổi" / "Xong" pill that toggles the people picker.
final class ILFamilyTreeAddMemberRelativeCardView: UIView {

    private typealias Tree = ILColors.FamilyTree

    private enum Layout {
        static let sealSize = CGSize(width: 12, height: 13)
        static let insets = UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
        static let gap: CGFloat = 12
        static let pillHeight: CGFloat = 34
        static let pillPadding: CGFloat = 14
    }

    // MARK: - Properties
    var onToggle: (() -> Void)?

    // MARK: - UI Elements
    private let sealLayer = CAShapeLayer()
    private let sealView = UIView()
    private let nameLabel = UILabel()
    private let metaLabel = UILabel()
    private let toggleButton = UIButton(type: .system)

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    func configure(name: String, meta: String, isPickerOpen: Bool) {
        nameLabel.text = name
        metaLabel.text = meta
        toggleButton.setTitle(
            (isPickerOpen ? "familyTreeAddMember.relative.done" : "familyTreeAddMember.relative.change").localized,
            for: .normal
        )
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = Tree.creamLight
        layer.cornerRadius = ILMetrics.radiusInput
        layer.borderWidth = 1
        layer.borderColor = Tree.cardRing.cgColor

        sealLayer.path = ILFamilyTreeMedallionView.hexagon(in: CGRect(origin: .zero, size: Layout.sealSize)).cgPath
        sealLayer.fillColor = Tree.gold.cgColor
        sealView.layer.addSublayer(sealLayer)

        nameLabel.font = ILTypography.treeSheetName
        nameLabel.textColor = Tree.heading
        metaLabel.font = ILTypography.label
        metaLabel.textColor = Tree.inkTertiary

        toggleButton.titleLabel?.font = ILTypography.chip
        toggleButton.setTitleColor(Tree.forest, for: .normal)
        toggleButton.layer.cornerRadius = Layout.pillHeight / 2
        toggleButton.layer.borderWidth = 1
        toggleButton.layer.borderColor = Tree.outlineButtonBorder.cgColor
        toggleButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: Layout.pillPadding, bottom: 0, right: Layout.pillPadding)
        toggleButton.setContentHuggingPriority(.required, for: .horizontal)
        toggleButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        toggleButton.addTarget(self, action: #selector(handleToggle), for: .touchUpInside)

        let texts = UIStackView(arrangedSubviews: [nameLabel, metaLabel])
        texts.axis = .vertical
        texts.spacing = 1

        sealView.translatesAutoresizingMaskIntoConstraints = false
        let row = UIStackView(arrangedSubviews: [sealView, texts, toggleButton])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = Layout.gap
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        NSLayoutConstraint.activate([
            sealView.widthAnchor.constraint(equalToConstant: Layout.sealSize.width),
            sealView.heightAnchor.constraint(equalToConstant: Layout.sealSize.height),
            toggleButton.heightAnchor.constraint(equalToConstant: Layout.pillHeight),
            row.topAnchor.constraint(equalTo: topAnchor, constant: Layout.insets.top),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.insets.bottom),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.insets.left),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.insets.right)
        ])
    }

    @objc private func handleToggle() { onToggle?() }
}
