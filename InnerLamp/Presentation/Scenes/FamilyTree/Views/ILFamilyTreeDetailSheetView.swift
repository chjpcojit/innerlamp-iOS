//
//  ILFamilyTreeDetailSheetView.swift
//  InnerLamp
//

import UIKit

/// Bottom sheet describing the selected person. Collapsed it shows only the header (medallion,
/// name, status chips); expanded it also scrolls the facts, relations and the lineage back to the
/// founder. The owning ViewController animates the sheet's height; this view only lays out content.
final class ILFamilyTreeDetailSheetView: UIView {

    private typealias Tree = ILColors.FamilyTree
    private typealias Metrics = ILMetrics.FamilyTree

    // MARK: - Properties
    var onHeaderTap: (() -> Void)?
    /// Swipe up / down on the header — open / close the sheet.
    var onSwipeUp: (() -> Void)?
    var onSwipeDown: (() -> Void)?
    var onMemberTap: ((String) -> Void)?
    var onFullProfileTap: (() -> Void)?
    var onReminderTap: (() -> Void)?
    var onContextualActionTap: (() -> Void)?
    var onOfferingTap: (() -> Void)?
    var onChantTap: (() -> Void)?
    var onTempleTap: (() -> Void)?

    /// Last configured detail: the body is only rebuilt when it changes, so toggling the sheet
    /// never re-creates (and re-animates from zero size) the content.
    private var configuredDetail: ILFamilyTreeDetailModel?

    private let highlightLayer = CAShapeLayer()
    private let highlightMask = CALayer()

    // MARK: - UI Elements
    private lazy var grabber: UIView = {
        let view = UIView()
        view.backgroundColor = Tree.grabber
        view.layer.cornerRadius = Metrics.sheetGrabberSize.height / 2
        return view
    }()

    private lazy var medallion = ILFamilyTreeMedallionView()

    private lazy var headSeal: ILFamilyTreeSealView = {
        let seal = ILFamilyTreeSealView(
            glyph: "familyTree.seal.head".localized, font: ILTypography.treeSealSmall,
            size: Metrics.sealSize, cornerRadius: Metrics.sealRadius,
            ringInset: 1.5, rotation: Metrics.sealRotation
        )
        seal.pinSize()
        seal.isHidden = true
        return seal
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.treeSheetName
        label.textColor = Tree.heading
        return label
    }()

    private lazy var metaLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = Tree.inkSecondary
        return label
    }()

    private lazy var statusPill = PillLabel()
    private lazy var rolePill = PillLabel()

    private lazy var pillRow: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [statusPill, rolePill, UIView()])
        stack.axis = .horizontal
        stack.spacing = 6
        return stack
    }()

    private lazy var chevron: UIView = ChevronView()

    private lazy var headerView: UIControl = {
        let control = UIControl()
        control.accessibilityIdentifier = "familyTree.sheet.header"
        control.accessibilityTraits = .button
        control.addTarget(self, action: #selector(handleHeaderTap), for: .touchUpInside)
        for direction in [UISwipeGestureRecognizer.Direction.up, .down] {
            let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleHeaderSwipe(_:)))
            swipe.direction = direction
            control.addGestureRecognizer(swipe)
        }
        return control
    }()

    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.alwaysBounceVertical = false
        return scroll
    }()

    private lazy var bodyStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        return stack
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
        backgroundColor = Tree.paper
        layer.cornerRadius = ILMetrics.radiusCardLarge
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        layer.shadowColor = Tree.shadow.cgColor
        layer.shadowOpacity = 0.45
        layer.shadowRadius = 15
        layer.shadowOffset = CGSize(width: 0, height: -10)
        accessibilityIdentifier = "familyTree.sheet"

        // Top highlight: a 1pt light edge along the rounded top (design `inset 0 1px 0 white 60%`).
        highlightLayer.fillColor = nil
        highlightLayer.strokeColor = Tree.sheetHighlight.cgColor
        highlightLayer.lineWidth = 1
        highlightMask.backgroundColor = UIColor.white.cgColor
        highlightLayer.mask = highlightMask
        layer.addSublayer(highlightLayer)

        let textStack = UIStackView(arrangedSubviews: [nameLabel, metaLabel, pillRow])
        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.setCustomSpacing(7, after: metaLabel)

        [grabber, medallion, headSeal, textStack, chevron].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview($0)
        }
        [headerView, scrollView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        bodyStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(bodyStack)

        let inset = ILMetrics.screenHorizontal - 2
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor),

            grabber.topAnchor.constraint(equalTo: headerView.topAnchor, constant: ILMetrics.spaceSmall),
            grabber.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            grabber.widthAnchor.constraint(equalToConstant: Metrics.sheetGrabberSize.width),
            grabber.heightAnchor.constraint(equalToConstant: Metrics.sheetGrabberSize.height),

            medallion.topAnchor.constraint(equalTo: grabber.bottomAnchor, constant: ILMetrics.spaceMedium - 4),
            medallion.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: inset),
            medallion.widthAnchor.constraint(equalToConstant: Metrics.sheetHeaderMedallion.width),
            medallion.heightAnchor.constraint(equalToConstant: Metrics.sheetHeaderMedallion.height),
            medallion.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -ILMetrics.spaceMedium + 2),

            headSeal.trailingAnchor.constraint(equalTo: medallion.trailingAnchor, constant: 7),
            headSeal.topAnchor.constraint(equalTo: medallion.topAnchor, constant: -2),

            textStack.leadingAnchor.constraint(equalTo: medallion.trailingAnchor, constant: ILMetrics.spaceMedium),
            textStack.centerYAnchor.constraint(equalTo: medallion.centerYAnchor),
            textStack.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -ILMetrics.spaceMedium),

            chevron.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -inset),
            chevron.centerYAnchor.constraint(equalTo: medallion.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 36),
            chevron.heightAnchor.constraint(equalToConstant: 36),

            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            bodyStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            bodyStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: inset),
            bodyStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -inset),
            bodyStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -ILMetrics.screenPadding.bottom),
            bodyStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -inset * 2)
        ])

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILFamilyTreeDetailSheetView, _) in
            view.layer.shadowColor = Tree.shadow.cgColor
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let radius = ILMetrics.radiusCardLarge
        highlightLayer.frame = bounds
        highlightLayer.path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5),
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath
        highlightMask.frame = CGRect(x: 0, y: 0, width: bounds.width, height: radius)
    }

    // MARK: - Configure
    func configure(with detail: ILFamilyTreeDetailModel) {
        guard detail != configuredDetail else { return }
        configuredDetail = detail
        medallion.configure(with: detail.look)
        headSeal.isHidden = !detail.look.isClanHead
        nameLabel.text = detail.name
        metaLabel.text = detail.meta
        statusPill.configure(
            text: detail.status,
            background: detail.look.isLiving ? Tree.livingTint : Tree.deceasedTint,
            foreground: detail.look.isLiving ? Tree.forest : Tree.brown
        )
        if let role = detail.role {
            rolePill.isHidden = false
            rolePill.configure(text: role, background: detail.look.isFounder ? Tree.founderGold : Tree.seal, foreground: Tree.cream)
        } else {
            rolePill.isHidden = true
        }
        headerView.accessibilityLabel = "\(detail.name), \(detail.meta)"
        rebuildBody(detail)
    }

    func setExpanded(_ expanded: Bool, animated: Bool) {
        scrollView.isScrollEnabled = expanded
        if !expanded { scrollView.setContentOffset(.zero, animated: false) }
        (chevron as? ChevronView)?.setExpanded(expanded, animated: animated)
    }

    // MARK: - Body
    private var notUpdated: String { "familyTree.detail.notUpdated".localized }

    private func rebuildBody(_ detail: ILFamilyTreeDetailModel) {
        bodyStack.arrangedSubviews.forEach {
            bodyStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let divider = UIView()
        divider.backgroundColor = Tree.border
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        bodyStack.addArrangedSubview(divider)
        bodyStack.setCustomSpacing(ILMetrics.spaceMedium, after: divider)

        var facts: [(key: String, value: String?, isLink: Bool)] = []
        let kinshipRow = detail.kinship.map {
            makeFactRow(key: "familyTree.detail.kinship".localized, value: $0, valueColor: Tree.meRelation, valueFont: ILTypography.bodySmallSemibold)
        }
        facts.append(("familyTree.detail.years".localized, detail.years, false))
        if let anniversary = detail.anniversary { facts.append(("familyTree.detail.anniversary".localized, anniversary, false)) }
        if detail.look.isLiving {
            facts.append(("familyTree.detail.residence".localized, detail.residence ?? notUpdated, false))
        } else {
            facts.append(("familyTree.detail.burial".localized, detail.burialPlace ?? notUpdated, false))
        }
        facts.append(("familyTree.detail.dharmaName".localized, detail.dharmaName ?? notUpdated, false))
        if !detail.look.isLiving {
            facts.append(("familyTree.detail.tablet".localized, detail.tabletTemple ?? notUpdated, detail.tabletTemple != nil))
        }
        facts.append(("familyTree.detail.branch".localized, detail.branch, false))
        let factRows = facts.map { makeFactRow(key: $0.key, value: $0.value ?? notUpdated, isLink: $0.isLink) }
        let factsStack = UIStackView(arrangedSubviews: (kinshipRow.map { [$0] } ?? []) + factRows)
        factsStack.axis = .vertical
        factsStack.spacing = 9
        bodyStack.addArrangedSubview(factsStack)

        if let note = detail.note, !note.isEmpty {
            bodyStack.setCustomSpacing(ILMetrics.spaceMedium, after: factsStack)
            let noteView = makeNote(note)
            bodyStack.addArrangedSubview(noteView)
        }

        if let memorial = detail.memorial {
            addMemorial(memorial)
        }

        if !detail.relations.isEmpty {
            addSection(title: "familyTree.detail.relations".localized)
            detail.relations.forEach { bodyStack.addArrangedSubview(makeRelationRow($0)) }
        }
        if !detail.lineage.isEmpty {
            addSection(title: "familyTree.detail.lineage".localized)
            let lineageStack = UIStackView(arrangedSubviews: detail.lineage.map(makeLineageRow))
            lineageStack.axis = .vertical
            bodyStack.addArrangedSubview(lineageStack)
        }

        if let last = bodyStack.arrangedSubviews.last {
            bodyStack.setCustomSpacing(ILMetrics.spaceStandard, after: last)
        }
        bodyStack.addArrangedSubview(makeActionRow(contextualTitle: detail.contextualActionTitle))
    }

    private func addSection(title: String, spacingAfter: CGFloat = 4) {
        let label = UILabel()
        label.attributedText = ILTypography.makeEyebrow(text: title, color: Tree.eyebrow)
        if let last = bodyStack.arrangedSubviews.last {
            bodyStack.setCustomSpacing(ILMetrics.spaceLarge - 8, after: last)
        }
        bodyStack.addArrangedSubview(label)
        bodyStack.setCustomSpacing(spacingAfter, after: label)
    }

    private func makeFactRow(
        key: String, value: String, isLink: Bool = false,
        valueColor: UIColor = Tree.ink, valueFont: UIFont = ILTypography.bodySmall
    ) -> UIView {
        let keyLabel = UILabel()
        keyLabel.font = ILTypography.bodySmall
        keyLabel.textColor = Tree.inkTertiary
        keyLabel.text = key
        keyLabel.widthAnchor.constraint(equalToConstant: Metrics.sheetKeyColumnWidth).isActive = true
        let valueLabel = UILabel()
        valueLabel.font = valueFont
        valueLabel.textColor = valueColor
        valueLabel.numberOfLines = 0
        valueLabel.text = value
        let row = UIStackView(arrangedSubviews: [keyLabel, valueLabel])
        row.axis = .horizontal
        row.alignment = .firstBaseline
        row.spacing = ILMetrics.spaceMedium - 2
        guard isLink else { return row }

        // Underlined, tappable value ("Bài vị thờ tại").
        valueLabel.attributedText = NSAttributedString(string: value, attributes: [
            .font: ILTypography.bodySmallMedium,
            .foregroundColor: Tree.selected,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .underlineColor: Tree.linkUnderline
        ])
        valueLabel.isUserInteractionEnabled = true
        valueLabel.accessibilityTraits = .link
        valueLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTempleTap)))
        return row
    }

    // MARK: - Memorial ("TƯỞNG NIỆM")
    private func addMemorial(_ memorial: ILFamilyTreeMemorialModel) {
        addSection(title: "familyTree.detail.memorial".localized, spacingAfter: 10)
        let card = makeMemorialCard(memorial)
        bodyStack.addArrangedSubview(card)
        bodyStack.setCustomSpacing(8, after: card)
        bodyStack.addArrangedSubview(makeOfferingTiles())
    }

    private func makeMemorialCard(_ memorial: ILFamilyTreeMemorialModel) -> UIView {
        let glyph = UILabel()
        glyph.text = "familyTree.memorial.glyph".localized
        glyph.font = ILTypography.treeMemorialTitle
        glyph.textColor = Tree.seal
        glyph.textAlignment = .center
        glyph.backgroundColor = Tree.memorialGlyphTint
        glyph.layer.cornerRadius = Metrics.sheetMemorialGlyphSize / 2
        glyph.layer.borderWidth = 1
        glyph.layer.borderColor = Tree.memorialGlyphRing.cgColor
        glyph.clipsToBounds = true
        NSLayoutConstraint.activate([
            glyph.widthAnchor.constraint(equalToConstant: Metrics.sheetMemorialGlyphSize),
            glyph.heightAnchor.constraint(equalToConstant: Metrics.sheetMemorialGlyphSize)
        ])

        let title = UILabel()
        title.font = ILTypography.treeMemorialTitle
        title.textColor = Tree.heading
        title.numberOfLines = 0
        title.text = memorial.title
        let subtitle = UILabel()
        subtitle.font = ILTypography.subhead
        subtitle.textColor = Tree.inkSecondary
        subtitle.numberOfLines = 0
        subtitle.text = memorial.subtitle
        let texts = UIStackView(arrangedSubviews: [title, subtitle])
        texts.axis = .vertical
        texts.spacing = 2

        let header = UIStackView(arrangedSubviews: [glyph, texts])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = ILMetrics.spaceMedium - 2

        let button = SheetButton(
            title: memorial.buttonTitle,
            style: memorial.isButtonFilled ? .filled : .outlined(Tree.reminderButtonBorder),
            font: ILTypography.bodySmallMedium,
            height: Metrics.sheetPillHeight
        )
        button.accessibilityIdentifier = "familyTree.sheet.reminder"
        button.onTap = { [weak self] in self?.onReminderTap?() }

        let content = UIStackView(arrangedSubviews: [header, button])
        content.axis = .vertical
        content.spacing = ILMetrics.spaceMedium - 2
        return makeCard(wrapping: content, padding: ILMetrics.spaceMedium)
    }

    private func makeOfferingTiles() -> UIView {
        let offer = makeTile(
            icon: FlameIconView(), title: "familyTree.memorial.offerTitle".localized,
            subtitle: "familyTree.memorial.offerSubtitle".localized
        ) { [weak self] in self?.onOfferingTap?() }
        offer.accessibilityIdentifier = "familyTree.sheet.offering"
        let chant = makeTile(
            icon: ScriptureIconView(), title: "familyTree.memorial.chantTitle".localized,
            subtitle: "familyTree.memorial.chantSubtitle".localized
        ) { [weak self] in self?.onChantTap?() }
        chant.accessibilityIdentifier = "familyTree.sheet.chant"
        let grid = UIStackView(arrangedSubviews: [offer, chant])
        grid.axis = .horizontal
        grid.distribution = .fillEqually
        grid.spacing = ILMetrics.spaceSmall
        return grid
    }

    private func makeTile(icon: UIView, title: String, subtitle: String, onTap: @escaping () -> Void) -> TapCard {
        let titleLabel = UILabel()
        titleLabel.font = ILTypography.treeTileTitle
        titleLabel.textColor = Tree.ink
        titleLabel.text = title
        let titleRow = UIStackView(arrangedSubviews: [icon, titleLabel])
        titleRow.axis = .horizontal
        titleRow.alignment = .center
        titleRow.spacing = ILMetrics.spaceSmall

        let subtitleLabel = UILabel()
        subtitleLabel.font = ILTypography.caption
        subtitleLabel.textColor = Tree.inkTertiary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = subtitle

        let content = UIStackView(arrangedSubviews: [titleRow, subtitleLabel])
        content.axis = .vertical
        content.spacing = 4
        content.isUserInteractionEnabled = false

        let card = TapCard()
        card.onTap = onTap
        applyCardStyle(to: card)
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: Metrics.sheetTileMinHeight),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            content.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            content.topAnchor.constraint(greaterThanOrEqualTo: card.topAnchor, constant: 10)
        ])
        return card
    }

    private func applyCardStyle(to view: UIView) {
        view.backgroundColor = Tree.cardSurface
        view.layer.cornerRadius = Metrics.sheetCardRadius
        view.layer.borderWidth = 1
        view.layer.borderColor = Tree.cardRing.cgColor
    }

    private func makeCard(wrapping content: UIView, padding: CGFloat) -> UIView {
        let card = UIView()
        applyCardStyle(to: card)
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: padding),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -padding),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: padding),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -padding)
        ])
        return card
    }

    // MARK: - Bottom actions
    private func makeActionRow(contextualTitle: String) -> UIView {
        let profile = SheetButton(
            title: "familyTree.cta.profile".localized, style: .filled,
            font: ILTypography.button, height: Metrics.sheetCTAHeight
        )
        profile.accessibilityIdentifier = "familyTree.sheet.profile"
        profile.onTap = { [weak self] in self?.onFullProfileTap?() }
        let contextual = SheetButton(
            title: contextualTitle, style: .outlined(Tree.outlineButtonBorder),
            font: ILTypography.button, height: Metrics.sheetCTAHeight
        )
        contextual.accessibilityIdentifier = "familyTree.sheet.contextual"
        contextual.onTap = { [weak self] in self?.onContextualActionTap?() }
        let row = UIStackView(arrangedSubviews: [profile, contextual])
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = ILMetrics.spaceSmall
        return row
    }

    private func makeNote(_ text: String) -> UIView {
        let container = UIView()
        container.backgroundColor = Tree.cream.withAlphaComponent(0.9)
        container.layer.cornerRadius = 4
        container.layer.borderWidth = 1
        container.layer.borderColor = Tree.borderSoft.cgColor
        let label = UILabel()
        label.font = ILTypography.treeNote
        label.textColor = Tree.ink
        label.numberOfLines = 0
        label.text = text
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: ILMetrics.spaceMedium),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -ILMetrics.spaceMedium)
        ])
        return container
    }

    private func makeRelationRow(_ relation: ILFamilyTreeRelationModel) -> UIView {
        let kind = UILabel()
        kind.font = ILTypography.subhead
        kind.textColor = Tree.inkTertiary
        kind.text = relation.kind
        kind.widthAnchor.constraint(equalToConstant: Metrics.sheetRelationKeyWidth).isActive = true

        let name = UILabel()
        name.font = ILTypography.treeRelationName
        name.textColor = Tree.heading
        name.text = relation.name

        let generation = UILabel()
        generation.font = ILTypography.label
        generation.textColor = Tree.inkMuted
        generation.text = relation.generation
        generation.setContentHuggingPriority(.required, for: .horizontal)

        let chevron = RowChevronView()

        let row = TapRow(memberID: relation.memberID)
        row.onTap = { [weak self] id in self?.onMemberTap?(id) }
        let stack = UIStackView(arrangedSubviews: [kind, name, generation, chevron])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = ILMetrics.spaceSmall + 2
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(stack)

        let bottomLine = UIView()
        bottomLine.backgroundColor = Tree.divider
        bottomLine.isUserInteractionEnabled = false
        bottomLine.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(bottomLine)

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(greaterThanOrEqualToConstant: Metrics.sheetRelationRowHeight),
            stack.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            bottomLine.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            bottomLine.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            bottomLine.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            bottomLine.heightAnchor.constraint(equalToConstant: 1)
        ])
        return row
    }

    private func makeLineageRow(_ step: ILFamilyTreeLineageStepModel) -> UIView {
        let marker = LineageMarkerView(isSelected: step.isSelected, hasNext: step.hasNext)

        let name = UILabel()
        name.font = ILTypography.treeChainName
        name.textColor = step.isSelected ? Tree.selected : Tree.heading
        name.text = step.name
        let meta = UILabel()
        meta.font = ILTypography.caption
        meta.textColor = Tree.inkMuted
        meta.text = step.meta
        let textStack = UIStackView(arrangedSubviews: [name, meta])
        textStack.axis = .vertical
        textStack.isUserInteractionEnabled = false

        let row = TapRow(memberID: step.memberID)
        row.onTap = { [weak self] id in self?.onMemberTap?(id) }
        let stack = UIStackView(arrangedSubviews: [marker, textStack])
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.spacing = ILMetrics.spaceMedium - 2
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: row.topAnchor),
            stack.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -10),
            stack.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: row.trailingAnchor)
        ])
        return row
    }

    @objc private func handleHeaderSwipe(_ swipe: UISwipeGestureRecognizer) {
        if swipe.direction == .up { onSwipeUp?() } else { onSwipeDown?() }
    }

    @objc private func handleHeaderTap() {
        onHeaderTap?()
    }

    @objc private func handleTempleTap() {
        onTempleTap?()
    }
}

// MARK: - Small private views
private extension ILFamilyTreeDetailSheetView {

    /// Tappable container carrying the member id of the row.
    final class TapRow: UIControl {
        let memberID: String
        var onTap: ((String) -> Void)?

        init(memberID: String) {
            self.memberID = memberID
            super.init(frame: .zero)
            addTarget(self, action: #selector(handleTap), for: .touchUpInside)
            accessibilityTraits = .button
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var isHighlighted: Bool {
            didSet { alpha = isHighlighted ? 0.6 : 1 }
        }

        @objc private func handleTap() { onTap?(memberID) }
    }

    /// Tappable card container (tile).
    final class TapCard: UIControl {
        var onTap: (() -> Void)?

        override init(frame: CGRect) {
            super.init(frame: frame)
            addTarget(self, action: #selector(handleTap), for: .touchUpInside)
            accessibilityTraits = .button
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var isHighlighted: Bool {
            didSet { alpha = isHighlighted ? 0.6 : 1 }
        }

        @objc private func handleTap() { onTap?() }
    }

    /// Full-width pill button: filled forest with cream text, or outlined forest.
    final class SheetButton: UIControl {
        enum Style {
            case filled
            case outlined(UIColor)
        }

        var onTap: (() -> Void)?

        init(title: String, style: Style, font: UIFont, height: CGFloat) {
            super.init(frame: .zero)
            layer.cornerRadius = height / 2
            accessibilityTraits = .button
            accessibilityLabel = title
            let label = UILabel()
            label.text = title
            label.font = font
            label.textAlignment = .center
            label.isUserInteractionEnabled = false
            switch style {
            case .filled:
                backgroundColor = ILColors.FamilyTree.forest
                label.textColor = ILColors.FamilyTree.cream
            case .outlined(let border):
                layer.borderWidth = 1
                layer.borderColor = border.cgColor
                label.textColor = ILColors.FamilyTree.forest
            }
            label.translatesAutoresizingMaskIntoConstraints = false
            addSubview(label)
            NSLayoutConstraint.activate([
                heightAnchor.constraint(greaterThanOrEqualToConstant: height),
                label.topAnchor.constraint(equalTo: topAnchor, constant: 4),
                label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
                label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.spaceMedium),
                label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.spaceMedium)
            ])
            addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var isHighlighted: Bool {
            didSet { alpha = isHighlighted ? 0.7 : 1 }
        }

        @objc private func handleTap() { onTap?() }
    }

    /// Candle-flame glyph on the "Thắp đèn" tile (10×14 gradient drop).
    final class FlameIconView: UIView {
        private let gradient = CAGradientLayer()

        init() {
            super.init(frame: .zero)
            translatesAutoresizingMaskIntoConstraints = false
            isUserInteractionEnabled = false
            gradient.colors = ILColors.FamilyTree.flameStops.map { $0.cgColor }
            layer.addSublayer(gradient)
            NSLayoutConstraint.activate([
                widthAnchor.constraint(equalToConstant: 10),
                heightAnchor.constraint(equalToConstant: 14)
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            gradient.frame = bounds
            // Teardrop: `50% 50% 45% 45% / 62% 62% 38% 38%` approximated with a rounded top.
            let mask = CAShapeLayer()
            mask.path = UIBezierPath(
                roundedRect: bounds, byRoundingCorners: [.topLeft, .topRight, .bottomLeft, .bottomRight],
                cornerRadii: CGSize(width: bounds.width * 0.5, height: bounds.height * 0.5)
            ).cgPath
            gradient.mask = mask
        }
    }

    /// Scripture glyph on the "Tụng kinh" tile (12×12 outlined square).
    final class ScriptureIconView: UIView {
        init() {
            super.init(frame: .zero)
            translatesAutoresizingMaskIntoConstraints = false
            isUserInteractionEnabled = false
            layer.cornerRadius = 2
            layer.borderWidth = 1.5
            layer.borderColor = ILColors.FamilyTree.brown.cgColor
            NSLayoutConstraint.activate([
                widthAnchor.constraint(equalToConstant: 12),
                heightAnchor.constraint(equalToConstant: 12)
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    /// Small pill with a text label (status / role).
    final class PillLabel: UIView {
        private let label = UILabel()

        init() {
            super.init(frame: .zero)
            layer.cornerRadius = 10
            label.font = ILTypography.captionMedium
            label.translatesAutoresizingMaskIntoConstraints = false
            addSubview(label)
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: topAnchor, constant: 2),
                label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
                label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 9),
                label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -9)
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func configure(text: String, background: UIColor, foreground: UIColor) {
            label.text = text
            label.textColor = foreground
            backgroundColor = background
            layer.cornerRadius = bounds.height / 2
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            layer.cornerRadius = bounds.height / 2
        }
    }

    /// Round chevron button in the sheet header: "^" when collapsed (pull up), "v" when expanded.
    final class ChevronView: UIView {
        private let arrowLayer = CAShapeLayer()

        init() {
            super.init(frame: .zero)
            backgroundColor = ILColors.FamilyTree.brown.withAlphaComponent(0.08)
            layer.cornerRadius = 18
            isUserInteractionEnabled = false
            let path = UIBezierPath()
            // Design: 24-box "M6 15l6-6 6 6" drawn at 16pt.
            path.move(to: CGPoint(x: -4, y: 2))
            path.addLine(to: CGPoint(x: 0, y: -2))
            path.addLine(to: CGPoint(x: 4, y: 2))
            arrowLayer.path = path.cgPath
            arrowLayer.fillColor = nil
            arrowLayer.lineWidth = ILMetrics.FamilyTree.sheetChevronStroke
            arrowLayer.lineCap = .round
            arrowLayer.lineJoin = .round
            layer.addSublayer(arrowLayer)
            applyColors()
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ChevronView, _) in
                view.applyColors()
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            arrowLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        }

        private func applyColors() {
            arrowLayer.strokeColor = ILColors.FamilyTree.brown.cgColor
            backgroundColor = ILColors.FamilyTree.brown.withAlphaComponent(0.08)
        }

        func setExpanded(_ expanded: Bool, animated: Bool) {
            let transform = expanded ? CATransform3DMakeRotation(.pi, 0, 0, 1) : CATransform3DIdentity
            guard animated else {
                arrowLayer.transform = transform
                return
            }
            let animation = CABasicAnimation(keyPath: "transform")
            animation.fromValue = arrowLayer.transform
            animation.toValue = transform
            animation.duration = ILMetrics.FamilyTree.sheetAnimationDuration
            arrowLayer.add(animation, forKey: "rotate")
            arrowLayer.transform = transform
        }
    }

    /// Small right-pointing chevron at the end of a relation row.
    final class RowChevronView: UIView {
        init() {
            super.init(frame: .zero)
            backgroundColor = .clear
            isUserInteractionEnabled = false
            translatesAutoresizingMaskIntoConstraints = false
            widthAnchor.constraint(equalToConstant: 10).isActive = true
            heightAnchor.constraint(equalToConstant: 10).isActive = true
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func draw(_ rect: CGRect) {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 3, y: 1))
            path.addLine(to: CGPoint(x: 7, y: 5))
            path.addLine(to: CGPoint(x: 3, y: 9))
            path.lineWidth = 1.4
            path.lineCapStyle = .round
            ILColors.FamilyTree.inkMuted.setStroke()
            path.stroke()
        }
    }

    /// Hexagon bullet plus the connecting line down to the next step of the lineage.
    final class LineageMarkerView: UIView {
        private let isSelected: Bool
        private let hasNext: Bool

        init(isSelected: Bool, hasNext: Bool) {
            self.isSelected = isSelected
            self.hasNext = hasNext
            super.init(frame: .zero)
            backgroundColor = .clear
            isUserInteractionEnabled = false
            translatesAutoresizingMaskIntoConstraints = false
            widthAnchor.constraint(equalToConstant: 14).isActive = true
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func draw(_ rect: CGRect) {
            let dotRect = CGRect(x: (bounds.width - 10) / 2, y: 4, width: 10, height: 11)
            (isSelected ? ILColors.FamilyTree.seal : ILColors.FamilyTree.founderGold).setFill()
            ILFamilyTreeMedallionView.hexagon(in: dotRect).fill()
            guard hasNext else { return }
            ILColors.FamilyTree.gold.withAlphaComponent(0.7).setFill()
            UIBezierPath(rect: CGRect(x: (bounds.width - 1.5) / 2, y: dotRect.maxY + 2, width: 1.5, height: max(bounds.height - dotRect.maxY - 2, 0))).fill()
        }
    }
}
