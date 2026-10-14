//
//  ILFamilyTreeChronicleShrineCardView.swift
//  InnerLamp
//

import UIKit

/// "NHÀ THỜ HỌ" card (view mode): shrine name and address, then the keeper ("Trưởng họ" with an
/// "Đổi" pill), the founder's anniversary and the yearly clan gathering, and the "Nhắc giỗ tổ"
/// button. The design's photo slot is not built — TD-FamilyTreeChronicle-002.
final class ILFamilyTreeChronicleShrineCardView: UIView {

    private typealias Tree = ILColors.FamilyTree

    private enum Layout {
        static let padding: CGFloat = 14
        static let nameGap: CGFloat = 3
        static let gridTop: CGFloat = 12
        static let rowGap: CGFloat = 8
        static let keyWidth: CGFloat = 96
        static let keyGap: CGFloat = 10
        static let changeHeight: CGFloat = 32
        static let remindTop: CGFloat = 14
        static let remindHeight: CGFloat = 44
    }

    // MARK: - Properties
    var onKeeperTap: (() -> Void)?
    var onChangeTap: (() -> Void)?
    var onRemindTap: (() -> Void)?

    private lazy var nameLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.treeMemorialTitle
        v.textColor = Tree.heading
        v.numberOfLines = 0
        return v
    }()
    private lazy var addressLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.bodySmall
        v.textColor = Tree.inkSecondary
        v.numberOfLines = 0
        return v
    }()
    private lazy var keeperControl = ILFamilyTreeChronicleTapControl()
    private lazy var keeperLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.bodySmallMedium
        v.textColor = Tree.selected
        v.numberOfLines = 0
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var anniversaryValueLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.bodySmall
        v.textColor = Tree.ink
        v.numberOfLines = 0
        return v
    }()
    private lazy var gatheringValueLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.bodySmall
        v.textColor = Tree.ink
        v.numberOfLines = 0
        return v
    }()
    private lazy var changeButton: ILFamilyTreeChroniclePillButton = {
        let button = ILFamilyTreeChroniclePillButton(
            title: "familyTreeChronicle.shrine.change".localized, style: .outlined,
            font: ILTypography.subheadMedium, height: Layout.changeHeight
        )
        button.onTap = { [weak self] in self?.onChangeTap?() }
        return button
    }()
    private lazy var remindButton: ILFamilyTreeChroniclePillButton = {
        let button = ILFamilyTreeChroniclePillButton(
            title: "familyTreeChronicle.shrine.remind".localized, style: .filled,
            font: ILTypography.bodySmallMedium, height: Layout.remindHeight
        )
        button.onTap = { [weak self] in self?.onRemindTap?() }
        return button
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    func configure(with state: ILFamilyTreeChronicleStateModel) {
        nameLabel.text = state.shrineName
        addressLabel.text = state.shrineAddress
        addressLabel.isHidden = state.shrineAddress.isEmpty
        keeperLabel.text = state.keeperName
        keeperControl.isEnabled = state.keeperMemberID != nil
        anniversaryValueLabel.text = state.founderAnniversary
        gatheringValueLabel.text = state.annualGathering.isEmpty
            ? "familyTreeChronicle.shrine.gathering.unknown".localized : state.annualGathering
        remindButton.isHidden = !state.canRemindFounder
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = Tree.cardSurface
        layer.cornerRadius = ILMetrics.FamilyTree.sheetCardRadius
        layer.borderWidth = 1
        layer.borderColor = Tree.cardRing.cgColor

        keeperControl.addSubview(keeperLabel)
        NSLayoutConstraint.activate([
            keeperLabel.topAnchor.constraint(equalTo: keeperControl.topAnchor),
            keeperLabel.bottomAnchor.constraint(equalTo: keeperControl.bottomAnchor),
            keeperLabel.leadingAnchor.constraint(equalTo: keeperControl.leadingAnchor),
            keeperLabel.trailingAnchor.constraint(equalTo: keeperControl.trailingAnchor)
        ])
        keeperControl.onTap = { [weak self] in self?.onKeeperTap?() }

        let keeperRow = UIStackView(arrangedSubviews: [keeperControl, changeButton])
        keeperRow.axis = .horizontal
        keeperRow.alignment = .center
        keeperRow.spacing = ILMetrics.spaceSmall
        changeButton.setContentHuggingPriority(.required, for: .horizontal)
        changeButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        let grid = UIStackView(arrangedSubviews: [
            makeRow(key: "familyTreeChronicle.shrine.keeper", value: keeperRow),
            makeRow(key: "familyTreeChronicle.shrine.anniversary", value: anniversaryValueLabel),
            makeRow(key: "familyTreeChronicle.shrine.gathering", value: gatheringValueLabel)
        ])
        grid.axis = .vertical
        grid.spacing = Layout.rowGap

        let divider = UIView()
        divider.backgroundColor = Tree.borderSoft
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true

        let stack = UIStackView(arrangedSubviews: [nameLabel, addressLabel, divider, grid, remindButton])
        stack.axis = .vertical
        stack.setCustomSpacing(Layout.nameGap, after: nameLabel)
        stack.setCustomSpacing(Layout.gridTop, after: addressLabel)
        stack.setCustomSpacing(Layout.gridTop, after: divider)
        stack.setCustomSpacing(Layout.remindTop, after: grid)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: Layout.padding),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.padding),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.padding),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.padding)
        ])
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILFamilyTreeChronicleShrineCardView, _) in
            view.layer.borderColor = Tree.cardRing.cgColor
        }
    }

    private func makeRow(key: String, value: UIView) -> UIView {
        let keyLabel = UILabel()
        keyLabel.text = key.localized
        keyLabel.font = ILTypography.bodySmall
        keyLabel.textColor = Tree.inkTertiary
        keyLabel.setContentHuggingPriority(.required, for: .vertical)
        let keyWrap = UIView()
        keyLabel.translatesAutoresizingMaskIntoConstraints = false
        keyWrap.addSubview(keyLabel)
        NSLayoutConstraint.activate([
            keyLabel.topAnchor.constraint(greaterThanOrEqualTo: keyWrap.topAnchor),
            keyLabel.bottomAnchor.constraint(lessThanOrEqualTo: keyWrap.bottomAnchor),
            keyLabel.centerYAnchor.constraint(equalTo: keyWrap.centerYAnchor),
            keyLabel.leadingAnchor.constraint(equalTo: keyWrap.leadingAnchor),
            keyLabel.trailingAnchor.constraint(equalTo: keyWrap.trailingAnchor),
            keyWrap.widthAnchor.constraint(equalToConstant: Layout.keyWidth)
        ])
        let row = UIStackView(arrangedSubviews: [keyWrap, value])
        row.axis = .horizontal
        row.alignment = .fill
        row.spacing = Layout.keyGap
        return row
    }
}
