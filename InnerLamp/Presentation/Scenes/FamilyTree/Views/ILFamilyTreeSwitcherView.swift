//
//  ILFamilyTreeSwitcherView.swift
//  InnerLamp
//

import UIKit

/// The menu under the tree header's clan name: a dimmed scrim and a paper card listing the user's
/// books (father's / mother's), the merged "Nội – ngoại của bạn" view, a link to the clan
/// chronicle ("Phả ký dòng họ") and — while there is room for another book — "Tạo gia phả mới".
/// Fills its host; taps outside the card go to `onDismiss`.
final class ILFamilyTreeSwitcherView: UIView {

    private typealias Tree = ILColors.FamilyTree
    private typealias Metrics = ILMetrics.FamilyTree

    // MARK: - Properties
    var onDismiss: (() -> Void)?
    var onSelect: ((ILFamilyTreeViewKind) -> Void)?
    var onChronicle: (() -> Void)?
    var onCreate: (() -> Void)?

    // MARK: - UI Elements
    private lazy var scrim: UIControl = {
        let control = UIControl()
        control.backgroundColor = Tree.scrim
        control.accessibilityIdentifier = "familyTree.switcher.scrim"
        control.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        return control
    }()

    private lazy var card: UIView = {
        let card = UIView()
        card.backgroundColor = Tree.paper
        card.layer.cornerRadius = Metrics.switcherRadius
        card.layer.shadowColor = Tree.shadow.cgColor
        card.layer.shadowOpacity = 0.6
        card.layer.shadowRadius = Metrics.switcherShadowBlur / 2
        card.layer.shadowOffset = CGSize(width: 0, height: Metrics.switcherShadowOffsetY)
        card.accessibilityIdentifier = "familyTree.switcher"
        return card
    }()

    private lazy var eyebrowLabel: UILabel = {
        let label = UILabel()
        label.attributedText = ILTypography.makeEyebrow(text: "familyTree.switcher.eyebrow".localized, color: Tree.eyebrow)
        return label
    }()

    private lazy var eyebrowWrap: UIView = {
        let wrap = UIView()
        eyebrowLabel.translatesAutoresizingMaskIntoConstraints = false
        wrap.addSubview(eyebrowLabel)
        NSLayoutConstraint.activate([
            eyebrowLabel.topAnchor.constraint(equalTo: wrap.topAnchor, constant: 10),
            eyebrowLabel.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -6),
            eyebrowLabel.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: 12),
            eyebrowLabel.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -12)
        ])
        return wrap
    }()

    private lazy var rowsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        return stack
    }()

    private lazy var divider: UIView = {
        let line = UIView()
        line.backgroundColor = Tree.borderSoft
        line.heightAnchor.constraint(equalToConstant: 1).isActive = true
        let wrap = UIView()
        line.translatesAutoresizingMaskIntoConstraints = false
        wrap.addSubview(line)
        NSLayoutConstraint.activate([
            line.topAnchor.constraint(equalTo: wrap.topAnchor, constant: 6),
            line.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -6),
            line.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: 12),
            line.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -12)
        ])
        return wrap
    }()

    private lazy var chronicleRow: LinkRow = {
        let row = LinkRow(
            glyph: "familyTree.switcher.chronicle.glyph".localized,
            title: "familyTree.switcher.chronicle.title".localized,
            subtitle: "familyTree.switcher.chronicle.subtitle".localized,
            style: .chronicle,
            accessibilityID: "familyTree.switcher.chronicle"
        )
        row.addTarget(self, action: #selector(handleChronicle), for: .touchUpInside)
        return row
    }()

    private lazy var createRow: LinkRow = {
        let row = LinkRow(
            glyph: "+",
            title: "familyTree.switcher.create.title".localized,
            subtitle: "familyTree.switcher.create.subtitle".localized,
            style: .create,
            accessibilityID: "familyTree.switcher.create"
        )
        row.addTarget(self, action: #selector(handleCreate), for: .touchUpInside)
        return row
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        scrim.translatesAutoresizingMaskIntoConstraints = false
        card.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrim)
        addSubview(card)

        let content = UIStackView(arrangedSubviews: [eyebrowWrap, rowsStack, divider, chronicleRow, createRow])
        content.axis = .vertical
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)

        NSLayoutConstraint.activate([
            scrim.topAnchor.constraint(equalTo: topAnchor),
            scrim.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrim.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrim.trailingAnchor.constraint(equalTo: trailingAnchor),

            card.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Metrics.switcherInset),
            card.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Metrics.switcherInset),

            content.topAnchor.constraint(equalTo: card.topAnchor, constant: Metrics.switcherPadding),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -Metrics.switcherPadding),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: Metrics.switcherPadding),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -Metrics.switcherPadding)
        ])
    }

    /// Pins the top of the card — the host passes the bottom of the header; the design's small gap is added here.
    func pinCardTop(to anchor: NSLayoutYAxisAnchor) {
        card.topAnchor.constraint(equalTo: anchor, constant: Metrics.switcherTopGap).isActive = true
    }

    // MARK: - Configure
    func configure(rows: [ILFamilyTreeSwitcherRowModel], canCreate: Bool) {
        rowsStack.arrangedSubviews.forEach {
            rowsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for model in rows {
            let row = BookRow(model: model)
            row.addTarget(self, action: #selector(handleRowTap(_:)), for: .touchUpInside)
            rowsStack.addArrangedSubview(row)
        }
        createRow.isHidden = !canCreate
    }

    // MARK: - Actions
    @objc private func handleDismiss() { onDismiss?() }
    @objc private func handleChronicle() { onChronicle?() }
    @objc private func handleCreate() { onCreate?() }
    @objc private func handleRowTap(_ sender: BookRow) { onSelect?(sender.kind) }

    // MARK: - Rows
    /// Rotated rounded-square seal with a serif glyph.
    private static func makeSeal(glyph: String, fill: UIColor?, ring: UIColor?, glyphColor: UIColor, font: UIFont) -> UIView {
        let seal = UIView()
        seal.isUserInteractionEnabled = false
        seal.layer.cornerRadius = Metrics.switcherSealRadius
        seal.backgroundColor = fill
        if let ring {
            seal.layer.borderWidth = 1.5
            seal.layer.borderColor = ring.cgColor
        }
        seal.transform = CGAffineTransform(rotationAngle: Metrics.headerSealRotation * .pi / 180)
        let label = UILabel()
        label.text = glyph
        label.font = font
        label.textColor = glyphColor
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        seal.addSubview(label)
        seal.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            seal.widthAnchor.constraint(equalToConstant: Metrics.switcherSealSize),
            seal.heightAnchor.constraint(equalToConstant: Metrics.switcherSealSize),
            label.centerXAnchor.constraint(equalTo: seal.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: seal.centerYAnchor)
        ])
        return seal
    }

    private static func makeTexts(title: String, titleFont: UIFont, subtitle: String) -> UIStackView {
        let titleLabel = UILabel()
        titleLabel.font = titleFont
        titleLabel.textColor = Tree.heading
        titleLabel.text = title
        let subtitleLabel = UILabel()
        subtitleLabel.font = ILTypography.label
        subtitleLabel.textColor = Tree.inkTertiary
        subtitleLabel.text = subtitle
        subtitleLabel.numberOfLines = 2
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.isUserInteractionEnabled = false
        return stack
    }

    /// One book (or the merged view): seal, names, a check on the active one.
    private final class BookRow: UIControl {
        let kind: ILFamilyTreeViewKind

        init(model: ILFamilyTreeSwitcherRowModel) {
            kind = model.kind
            super.init(frame: .zero)
            accessibilityIdentifier = "familyTree.switcher.row"
            accessibilityLabel = model.title
            accessibilityTraits = model.isSelected ? [.button, .selected] : .button
            layer.cornerRadius = Metrics.switcherRowRadius
            backgroundColor = model.isSelected ? Tree.gold.withAlphaComponent(0.18) : .clear

            let fill: UIColor
            switch model.side {
            case .none: fill = Tree.sealMerged
            case .some(.paternal): fill = Tree.seal
            case .some(.maternal): fill = Tree.sealMaternal
            }
            let seal = ILFamilyTreeSwitcherView.makeSeal(
                glyph: model.glyph, fill: fill, ring: nil, glyphColor: Tree.cream, font: ILTypography.treeSealMedium
            )
            let texts = ILFamilyTreeSwitcherView.makeTexts(
                title: model.title, titleFont: ILTypography.treeSwitcherTitle, subtitle: model.subtitle
            )
            let check = UIImageView(image: ILIcons.checkmark)
            check.tintColor = Tree.forest
            check.contentMode = .scaleAspectFit
            check.isHidden = !model.isSelected
            check.isUserInteractionEnabled = false
            check.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                check.widthAnchor.constraint(equalToConstant: 18),
                check.heightAnchor.constraint(equalToConstant: 18)
            ])

            let row = UIStackView(arrangedSubviews: [seal, texts, check])
            row.axis = .horizontal
            row.alignment = .center
            row.spacing = 12
            row.isUserInteractionEnabled = false
            row.translatesAutoresizingMaskIntoConstraints = false
            addSubview(row)
            NSLayoutConstraint.activate([
                heightAnchor.constraint(greaterThanOrEqualToConstant: Metrics.switcherRowHeight),
                row.topAnchor.constraint(equalTo: topAnchor, constant: 8),
                row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
                row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
                row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var isHighlighted: Bool {
            didSet { alpha = isHighlighted ? 0.6 : 1 }
        }
    }

    /// A link below the divider: the chronicle (outlined red 記) or "create a book" (outlined green +).
    private final class LinkRow: UIControl {
        enum Style {
            case chronicle
            case create
        }

        init(glyph: String, title: String, subtitle: String, style: Style, accessibilityID: String) {
            super.init(frame: .zero)
            accessibilityIdentifier = accessibilityID
            accessibilityLabel = title
            accessibilityTraits = .button
            layer.cornerRadius = Metrics.switcherRowRadius

            let tint = style == .chronicle ? Tree.seal : Tree.forest
            let seal = ILFamilyTreeSwitcherView.makeSeal(
                glyph: glyph, fill: nil, ring: tint, glyphColor: tint, font: ILTypography.treeSealMedium
            )
            let texts = ILFamilyTreeSwitcherView.makeTexts(
                title: title, titleFont: ILTypography.treeSealMedium, subtitle: subtitle
            )
            let chevron = UIImageView(image: ILIcons.chevronDown)
            chevron.tintColor = Tree.inkMuted
            chevron.contentMode = .scaleAspectFit
            chevron.transform = CGAffineTransform(rotationAngle: -.pi / 2)
            chevron.isUserInteractionEnabled = false
            chevron.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                chevron.widthAnchor.constraint(equalToConstant: Metrics.headerChevronSize),
                chevron.heightAnchor.constraint(equalToConstant: Metrics.headerChevronSize)
            ])

            let row = UIStackView(arrangedSubviews: [seal, texts, chevron])
            row.axis = .horizontal
            row.alignment = .center
            row.spacing = 12
            row.isUserInteractionEnabled = false
            row.translatesAutoresizingMaskIntoConstraints = false
            addSubview(row)
            NSLayoutConstraint.activate([
                heightAnchor.constraint(greaterThanOrEqualToConstant: Metrics.switcherLinkRowHeight),
                row.topAnchor.constraint(equalTo: topAnchor, constant: 6),
                row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
                row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
                row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var isHighlighted: Bool {
            didSet { alpha = isHighlighted ? 0.6 : 1 }
        }
    }
}
