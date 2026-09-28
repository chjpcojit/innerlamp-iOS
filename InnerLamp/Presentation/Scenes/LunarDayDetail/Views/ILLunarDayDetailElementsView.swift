//
//  ILLunarDayDetailElementsView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 27/9/26.
//

import UIKit

/// Phần "Ngũ hành & nạp âm" — khớp khối `alElems`/`napamLine` trong design handoff: dòng nạp âm
/// lớn (màu theo Ngũ Hành) + 3 ô Can ngày / Chi ngày / Nạp âm, mỗi ô gồm nhãn, tên và chấm màu
/// theo Ngũ Hành. Tiêu đề section "Ngũ hành & nạp âm" do `ViewController` đặt riêng.
final class ILLunarDayDetailElementsView: UIView {

    // MARK: - UI Elements
    private let cardView = UIView()
    private let napamLineLabel = UILabel()
    private let tilesRow = UIStackView()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration
    func configure(napamLine: String, napamElement: ILFiveElements, elements: [ILLunarDayDetailElementModel]) {
        napamLineLabel.text = napamLine
        napamLineLabel.textColor = Self.elementColor(napamElement)
        rebuildTiles(elements)
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false

        cardView.backgroundColor = ILColors.surface
        cardView.layer.cornerRadius = ILMetrics.radiusCardRegular
        cardView.layer.borderWidth = 1
        cardView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cardView)

        napamLineLabel.font = ILTypography.dateTileDay
        napamLineLabel.numberOfLines = 1

        tilesRow.axis = .horizontal
        tilesRow.distribution = .fillEqually
        tilesRow.spacing = 8

        let contentStack = UIStackView(arrangedSubviews: [napamLineLabel, tilesRow])
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 14
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: topAnchor),
            cardView.bottomAnchor.constraint(equalTo: bottomAnchor),
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor),

            contentStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            contentStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
            contentStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16)
        ])

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILLunarDayDetailElementsView, _) in
            view.cardView.layer.borderColor = ILColors.border.cgColor
        }
    }

    // MARK: - Tiles

    private func rebuildTiles(_ elements: [ILLunarDayDetailElementModel]) {
        tilesRow.arrangedSubviews.forEach {
            tilesRow.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for element in elements {
            tilesRow.addArrangedSubview(makeTile(element))
        }
    }

    private func makeTile(_ element: ILLunarDayDetailElementModel) -> UIView {
        let tile = UIView()
        tile.layer.cornerRadius = 14
        tile.layer.borderWidth = 1
        tile.layer.borderColor = ILColors.border.cgColor

        let keyLabel = UILabel()
        keyLabel.font = ILTypography.caption
        keyLabel.textColor = ILColors.inkTertiary
        keyLabel.text = element.key
        keyLabel.textAlignment = .center

        let nameLabel = UILabel()
        nameLabel.font = ILTypography.scriptureDescription
        nameLabel.textColor = ILColors.ink
        nameLabel.text = element.name
        nameLabel.textAlignment = .center

        let dot = UIView()
        dot.backgroundColor = Self.elementColor(element.element)
        dot.layer.cornerRadius = 3.5
        dot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dot.widthAnchor.constraint(equalToConstant: 7),
            dot.heightAnchor.constraint(equalToConstant: 7)
        ])

        let elementLabel = UILabel()
        elementLabel.font = ILTypography.labelMedium
        elementLabel.textColor = Self.elementColor(element.element)
        elementLabel.text = element.elementName

        let elementRow = UIStackView(arrangedSubviews: [dot, elementLabel])
        elementRow.axis = .horizontal
        elementRow.alignment = .center
        elementRow.spacing = 5
        elementRow.isUserInteractionEnabled = false

        let stack = UIStackView(arrangedSubviews: [keyLabel, nameLabel, elementRow])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.setCustomSpacing(6, after: nameLabel)
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        tile.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: tile.topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: tile.bottomAnchor, constant: -10),
            stack.leadingAnchor.constraint(equalTo: tile.leadingAnchor, constant: 6),
            stack.trailingAnchor.constraint(equalTo: tile.trailingAnchor, constant: -6)
        ])

        return tile
    }

    // MARK: - Colors

    /// Màu chấm/chữ theo Ngũ Hành — dùng bảng màu ấm sẵn có (kim vàng, thủy tối, mộc xanh,
    /// hỏa đỏ, thổ nâu đất).
    static func elementColor(_ element: ILFiveElements) -> UIColor {
        switch element {
        case .kim: return ILColors.gold
        case .thuy: return ILColors.inkSecondary
        case .moc: return ILColors.auspicious
        case .hoa: return ILColors.inauspicious
        case .tho: return ILColors.goldDeep
        }
    }
}
