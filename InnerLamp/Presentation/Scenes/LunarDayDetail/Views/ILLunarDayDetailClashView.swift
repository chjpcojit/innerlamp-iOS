//
//  ILLunarDayDetailClashView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 27/9/26.
//

import UIKit

/// Thẻ "Tuổi xung khắc" — nền `surface`, 2 chip đỏ (con giáp + tuổi) và dòng giải thích (khớp
/// `lnClash`/`lnClashNote` trong design handoff).
final class ILLunarDayDetailClashView: UIView {

    // MARK: - Properties
    var items: [ILLunarDayDetailClashModel] = [] {
        didSet { rebuildChips() }
    }

    var note: String = "" {
        didSet {
            noteLabel.attributedText = ILTypography.makeParagraph(
                text: note,
                font: ILTypography.note,
                color: ILColors.inkTertiary,
                cssLineHeight: 1.6
            )
        }
    }

    // MARK: - UI Elements
    private let chipsRow = UIStackView()
    private let noteLabel = UILabel()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardRegular
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor

        chipsRow.axis = .horizontal
        chipsRow.spacing = 8
        chipsRow.alignment = .center
        chipsRow.translatesAutoresizingMaskIntoConstraints = false

        noteLabel.numberOfLines = 0
        noteLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(chipsRow)
        addSubview(noteLabel)

        NSLayoutConstraint.activate([
            chipsRow.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            chipsRow.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            chipsRow.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),

            noteLabel.topAnchor.constraint(equalTo: chipsRow.bottomAnchor, constant: 12),
            noteLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            noteLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            noteLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILLunarDayDetailClashView, _) in
            view.applyColorAppearanceChange()
        }
    }

    private func rebuildChips() {
        chipsRow.arrangedSubviews.forEach {
            chipsRow.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for item in items {
            chipsRow.addArrangedSubview(makeChip(item))
        }
    }

    private func makeChip(_ item: ILLunarDayDetailClashModel) -> UIView {
        let chip = UIView()
        chip.backgroundColor = ILColors.clashTintBackground
        chip.layer.cornerRadius = ILMetrics.radiusPill
        chip.layer.borderWidth = 1
        chip.layer.borderColor = ILColors.clashBorder.cgColor

        let iconLabel = UILabel()
        iconLabel.font = ILTypography.dateTileDay
        iconLabel.text = item.icon

        let nameLabel = UILabel()
        nameLabel.font = ILTypography.bodySmallMedium
        nameLabel.textColor = ILColors.clashForeground
        nameLabel.text = item.name

        let stack = UIStackView(arrangedSubviews: [iconLabel, nameLabel])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        chip.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: chip.topAnchor, constant: 7),
            stack.bottomAnchor.constraint(equalTo: chip.bottomAnchor, constant: -7),
            stack.leadingAnchor.constraint(equalTo: chip.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: chip.trailingAnchor, constant: -14)
        ])

        return chip
    }

    private func applyColorAppearanceChange() {
        layer.borderColor = ILColors.border.cgColor
        for chip in chipsRow.arrangedSubviews {
            chip.layer.borderColor = ILColors.clashBorder.cgColor
        }
    }
}
