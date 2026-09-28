//
//  ILLunarDayDetailDirectionsView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 27/9/26.
//

import UIKit

/// Danh sách 2 ô "Hướng xuất hành" — Hỷ thần / Tài thần nằm cạnh nhau (khớp `lnDirs` grid 2 cột
/// trong design handoff). Mỗi ô: glyph Hán tự 喜/財 (38pt) + tên, hướng và ý nghĩa.
final class ILLunarDayDetailDirectionsView: UIView {

    // MARK: - Properties
    var directions: [ILLunarDayDetailDirectionModel] = [] {
        didSet { rebuild() }
    }

    // MARK: - UI Elements
    private let columnsStack = UIStackView()

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
        columnsStack.axis = .horizontal
        columnsStack.distribution = .fillEqually
        columnsStack.alignment = .fill
        columnsStack.spacing = 8
        columnsStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(columnsStack)

        NSLayoutConstraint.activate([
            columnsStack.topAnchor.constraint(equalTo: topAnchor),
            columnsStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            columnsStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            columnsStack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILLunarDayDetailDirectionsView, _) in
            view.applyColorAppearanceChange()
        }
    }

    private func rebuild() {
        columnsStack.arrangedSubviews.forEach {
            columnsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for direction in directions {
            columnsStack.addArrangedSubview(makeCard(direction))
        }
    }

    /// Tone glyph của từng loại thần — Hỷ thần (đỏ clash), Tài thần (vàng accent).
    private static func glyphTone(_ kind: ILLunarDayDetailDirectionKind) -> (background: UIColor, border: UIColor, foreground: UIColor) {
        switch kind {
        case .joy:
            return (ILColors.clashTintBackground, ILColors.clashBorder, ILColors.clashForeground)
        case .wealth:
            return (ILColors.featGlow, ILColors.featAccent.withAlphaComponent(0.5), ILColors.featAccent)
        }
    }

    private func makeCard(_ direction: ILLunarDayDetailDirectionModel) -> UIView {
        let card = UIView()
        card.backgroundColor = ILColors.surface
        card.layer.cornerRadius = ILMetrics.radiusCardSmall
        card.layer.borderWidth = 1
        card.layer.borderColor = ILColors.border.cgColor

        let glyphTile = UIView()
        glyphTile.layer.cornerRadius = 12
        glyphTile.layer.borderWidth = 1
        let tone = Self.glyphTone(direction.kind)
        glyphTile.backgroundColor = tone.background
        glyphTile.layer.borderColor = tone.border.cgColor
        glyphTile.translatesAutoresizingMaskIntoConstraints = false

        let glyphLabel = UILabel()
        glyphLabel.font = ILTypography.directionGlyph
        glyphLabel.textColor = tone.foreground
        glyphLabel.text = direction.glyph
        glyphLabel.textAlignment = .center
        glyphLabel.translatesAutoresizingMaskIntoConstraints = false
        glyphTile.addSubview(glyphLabel)
        NSLayoutConstraint.activate([
            glyphTile.widthAnchor.constraint(equalToConstant: 38),
            glyphTile.heightAnchor.constraint(equalToConstant: 38),
            glyphLabel.centerXAnchor.constraint(equalTo: glyphTile.centerXAnchor),
            glyphLabel.centerYAnchor.constraint(equalTo: glyphTile.centerYAnchor)
        ])

        let keyLabel = UILabel()
        keyLabel.font = ILTypography.bodySmallMedium
        keyLabel.textColor = ILColors.ink
        keyLabel.text = direction.key

        let headerRow = UIStackView(arrangedSubviews: [glyphTile, keyLabel])
        headerRow.axis = .horizontal
        headerRow.spacing = 8
        headerRow.alignment = .center

        let valueLabel = UILabel()
        valueLabel.font = ILTypography.scriptureBody
        valueLabel.textColor = ILColors.ink
        valueLabel.text = direction.value

        let subtitleLabel = UILabel()
        subtitleLabel.font = ILTypography.label
        subtitleLabel.textColor = ILColors.inkTertiary
        subtitleLabel.text = direction.subtitle
        subtitleLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [headerRow, valueLabel, subtitleLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 3
        stack.setCustomSpacing(12, after: headerRow)
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
        ])

        return card
    }

    private func applyColorAppearanceChange() {
        for card in columnsStack.arrangedSubviews {
            card.layer.borderColor = ILColors.border.cgColor
        }
    }
}
