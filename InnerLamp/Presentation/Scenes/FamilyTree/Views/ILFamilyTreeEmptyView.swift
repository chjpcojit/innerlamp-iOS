//
//  ILFamilyTreeEmptyView.swift
//  InnerLamp
//

import UIKit

/// Empty state of the family tree (design handoff `giaphaEmpty`): sapling illustration, title,
/// message, a numbered "what you can do" card, "Tạo gia phả mới" / "Tham gia bằng mã mời"
/// buttons and an invite footnote. The content scrolls on small screens; the buttons + footnote
/// block stays pinned to the bottom.
final class ILFamilyTreeEmptyView: UIView {

    private typealias Tree = ILColors.FamilyTree

    // MARK: - Properties
    var onCreateTap: (() -> Void)?
    var onJoinTap: (() -> Void)?

    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let bottomBar = UIView()

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
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        scrollView.contentInsetAdjustmentBehavior = .never

        let illustration = ILFamilyTreeEmptyIllustrationView()

        let titleLabel = UILabel()
        titleLabel.font = ILTypography.treeEmptyTitle
        titleLabel.textColor = Tree.heading
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.text = "familyTree.empty.title".localized

        let messageLabel = UILabel()
        messageLabel.numberOfLines = 0
        messageLabel.attributedText = ILTypography.makeParagraph(
            text: "familyTree.empty.message".localized,
            font: ILTypography.bodyCompact,
            color: Tree.inkSecondary,
            cssLineHeight: 1.65,
            alignment: .center
        )

        let header = UIStackView(arrangedSubviews: [illustration, titleLabel, messageLabel])
        header.axis = .vertical
        header.alignment = .center
        header.spacing = 8
        header.setCustomSpacing(20, after: illustration)

        let createButton = ILFamilyTreeEmptyButton(title: "familyTree.empty.create".localized, isFilled: true)
        createButton.addAction(UIAction { [weak self] _ in self?.onCreateTap?() }, for: .touchUpInside)
        let joinButton = ILFamilyTreeEmptyButton(title: "familyTree.empty.join".localized, isFilled: false)
        joinButton.addAction(UIAction { [weak self] _ in self?.onJoinTap?() }, for: .touchUpInside)
        let buttons = UIStackView(arrangedSubviews: [createButton, joinButton])
        buttons.axis = .vertical
        buttons.spacing = 10

        let footnote = UILabel()
        footnote.numberOfLines = 0
        footnote.attributedText = ILTypography.makeParagraph(
            text: "familyTree.empty.footnote".localized,
            font: ILTypography.subhead,
            color: Tree.inkMuted,
            cssLineHeight: 1.6,
            alignment: .center
        )

        contentStack.axis = .vertical
        contentStack.spacing = 0
        [header, makeStepsCard()].forEach { contentStack.addArrangedSubview($0) }
        contentStack.setCustomSpacing(26, after: header)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        let bottomStack = UIStackView(arrangedSubviews: [buttons, footnote])
        bottomStack.axis = .vertical
        bottomStack.spacing = 14
        bottomStack.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.backgroundColor = .clear
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(bottomStack)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        addSubview(bottomBar)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            bottomBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: bottomAnchor),

            bottomStack.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: ILMetrics.spaceMedium),
            bottomStack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -ILMetrics.spaceMedium),
            bottomStack.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: ILMetrics.screenHorizontal),
            bottomStack.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -ILMetrics.screenHorizontal),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: ILMetrics.spaceLarge + 6),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -ILMetrics.spaceLarge),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: ILMetrics.screenHorizontal),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            messageLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 300)
        ])
    }

    private func makeStepsCard() -> UIView {
        let card = ILFamilyTreeEmptyCardView()
        let steps = [
            ("familyTree.empty.step1.title", "familyTree.empty.step1.body"),
            ("familyTree.empty.step2.title", "familyTree.empty.step2.body"),
            ("familyTree.empty.step3.title", "familyTree.empty.step3.body")
        ]
        let rows = UIStackView()
        rows.axis = .vertical
        rows.translatesAutoresizingMaskIntoConstraints = false
        for (index, step) in steps.enumerated() {
            rows.addArrangedSubview(makeStepRow(
                number: index + 1,
                title: step.0.localized,
                body: step.1.localized,
                showsDivider: index < steps.count - 1
            ))
        }
        card.addSubview(rows)
        NSLayoutConstraint.activate([
            rows.topAnchor.constraint(equalTo: card.topAnchor, constant: 4),
            rows.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -4),
            rows.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            rows.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18)
        ])
        return card
    }

    private func makeStepRow(number: Int, title: String, body: String, showsDivider: Bool) -> UIView {
        let badge = UIView()
        badge.backgroundColor = Tree.forest.withAlphaComponent(0.12)
        badge.layer.cornerRadius = 13
        badge.translatesAutoresizingMaskIntoConstraints = false

        let numberLabel = UILabel()
        numberLabel.font = ILTypography.subheadMedium
        numberLabel.textColor = Tree.forest
        numberLabel.text = "\(number)"
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(numberLabel)

        let titleLabel = UILabel()
        titleLabel.font = ILTypography.bodyMedium
        titleLabel.textColor = Tree.bark
        titleLabel.numberOfLines = 0
        titleLabel.text = title

        let bodyLabel = UILabel()
        bodyLabel.numberOfLines = 0
        bodyLabel.attributedText = ILTypography.makeParagraph(
            text: body,
            font: ILTypography.note,
            color: Tree.inkSecondary,
            cssLineHeight: 1.55
        )

        let textStack = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
        textStack.axis = .vertical
        textStack.spacing = 3

        let content = UIStackView(arrangedSubviews: [badge, textStack])
        content.axis = .horizontal
        content.alignment = .top
        content.spacing = ILMetrics.spaceMedium
        content.translatesAutoresizingMaskIntoConstraints = false

        let row = UIView()
        row.addSubview(content)
        NSLayoutConstraint.activate([
            badge.widthAnchor.constraint(equalToConstant: 26),
            badge.heightAnchor.constraint(equalToConstant: 26),
            numberLabel.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            numberLabel.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
            content.topAnchor.constraint(equalTo: row.topAnchor, constant: ILMetrics.spaceMedium),
            content.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -ILMetrics.spaceMedium),
            content.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: row.trailingAnchor)
        ])

        if showsDivider {
            let divider = UIView()
            divider.backgroundColor = Tree.divider
            divider.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(divider)
            NSLayoutConstraint.activate([
                divider.leadingAnchor.constraint(equalTo: row.leadingAnchor),
                divider.trailingAnchor.constraint(equalTo: row.trailingAnchor),
                divider.bottomAnchor.constraint(equalTo: row.bottomAnchor),
                divider.heightAnchor.constraint(equalToConstant: 1)
            ])
        }
        return row
    }
}

// MARK: - Card

/// Paper-coloured rounded card with a hairline border that follows the appearance.
private final class ILFamilyTreeEmptyCardView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = ILColors.FamilyTree.paper
        layer.cornerRadius = ILMetrics.radiusCardRegular
        layer.borderWidth = 1
        layer.borderColor = ILColors.FamilyTree.borderSoft.cgColor
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILFamilyTreeEmptyCardView, _) in
            view.layer.borderColor = ILColors.FamilyTree.borderSoft.cgColor
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Buttons

/// Pill button of the empty state: forest-filled (primary) or forest-outlined (secondary).
private final class ILFamilyTreeEmptyButton: UIControl {

    private enum Layout {
        static let height: CGFloat = 52
        static let outlineAlpha: CGFloat = 0.4
    }

    private let isFilled: Bool

    init(title: String, isFilled: Bool) {
        self.isFilled = isFilled
        super.init(frame: .zero)

        let label = UILabel()
        label.font = ILTypography.bodyMedium
        label.text = title
        label.textColor = isFilled ? ILColors.FamilyTree.cream : ILColors.FamilyTree.forest
        label.isUserInteractionEnabled = false
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        layer.cornerRadius = Layout.height / 2
        backgroundColor = isFilled ? ILColors.FamilyTree.forest : .clear
        if !isFilled {
            layer.borderWidth = 1
            layer.borderColor = ILColors.FamilyTree.forest.withAlphaComponent(Layout.outlineAlpha).cgColor
        }
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = title

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Layout.height),
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILFamilyTreeEmptyButton, _) in
            guard !view.isFilled else { return }
            view.layer.borderColor = ILColors.FamilyTree.forest.withAlphaComponent(Layout.outlineAlpha).cgColor
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.8 : 1 }
    }
}

// MARK: - Illustration

/// 150×118 sapling: green canopy glow, trunk, a branch with two empty (dashed) slots and the 譜 seal.
private final class ILFamilyTreeEmptyIllustrationView: UIView {

    private typealias Tree = ILColors.FamilyTree

    // MARK: - Layout constants (design handoff `giaphaEmpty`)
    private enum Layout {
        static let size = CGSize(width: 150, height: 118)
        static let glowHeight: CGFloat = 84
        static let trunkTop: CGFloat = 58
        static let trunkHeight: CGFloat = 44
        static let branchTop: CGFloat = 44
        static let branchInset: CGFloat = 31
        static let slotDiameter: CGFloat = 22
        static let slotInset: CGFloat = 21
        static let slotTop: CGFloat = 32
        static let sealSize: CGFloat = 30
        static let sealTop: CGFloat = 88
    }

    private let glowLayer = CAGradientLayer()
    private let slotLayers = [CAShapeLayer(), CAShapeLayer()]
    private let trunkView = UIView()
    private let branchView = UIView()
    private let sealView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize { Layout.size }

    private func setupViews() {
        isAccessibilityElement = false

        glowLayer.type = .radial
        glowLayer.colors = [Tree.canopyGlow.cgColor, Tree.forestLight.withAlphaComponent(0.08).cgColor, UIColor.clear.cgColor]
        glowLayer.locations = [0, 0.7, 1]
        glowLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        glowLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(glowLayer)

        trunkView.backgroundColor = Tree.bark.withAlphaComponent(0.35)
        branchView.backgroundColor = Tree.bark.withAlphaComponent(0.25)
        [branchView, trunkView].forEach { addSubview($0) }

        slotLayers.forEach {
            $0.fillColor = Tree.paper.cgColor
            $0.strokeColor = Tree.bark.withAlphaComponent(0.4).cgColor
            $0.lineWidth = 1.5
            $0.lineDashPattern = [3, 2.5]
            layer.addSublayer($0)
        }

        sealView.backgroundColor = Tree.seal
        sealView.layer.cornerRadius = 8
        sealView.layer.shadowColor = Tree.seal.cgColor
        sealView.layer.shadowOpacity = 0.3
        sealView.layer.shadowRadius = 7
        sealView.layer.shadowOffset = CGSize(width: 0, height: 6)
        addSubview(sealView)

        let sealLabel = UILabel()
        sealLabel.font = ILTypography.treeSealMedium
        sealLabel.textColor = Tree.cream
        sealLabel.text = "familyTree.empty.seal".localized
        sealLabel.translatesAutoresizingMaskIntoConstraints = false
        sealView.addSubview(sealLabel)
        NSLayoutConstraint.activate([
            sealLabel.centerXAnchor.constraint(equalTo: sealView.centerXAnchor),
            sealLabel.centerYAnchor.constraint(equalTo: sealView.centerYAnchor)
        ])

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILFamilyTreeEmptyIllustrationView, _) in
            view.applyColors()
        }
    }

    private func applyColors() {
        glowLayer.colors = [Tree.canopyGlow.cgColor, Tree.forestLight.withAlphaComponent(0.08).cgColor, UIColor.clear.cgColor]
        slotLayers.forEach {
            $0.fillColor = Tree.paper.cgColor
            $0.strokeColor = Tree.bark.withAlphaComponent(0.4).cgColor
        }
        sealView.layer.shadowColor = Tree.seal.cgColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = bounds.width
        glowLayer.frame = CGRect(x: 0, y: 0, width: width, height: Layout.glowHeight)
        trunkView.frame = CGRect(x: (width - 2) / 2, y: Layout.trunkTop, width: 2, height: Layout.trunkHeight)
        branchView.frame = CGRect(
            x: Layout.branchInset, y: Layout.branchTop,
            width: width - Layout.branchInset * 2, height: 2
        )
        let slotSize = CGSize(width: Layout.slotDiameter, height: Layout.slotDiameter)
        let slotRects = [
            CGRect(origin: CGPoint(x: Layout.slotInset, y: Layout.slotTop), size: slotSize),
            CGRect(origin: CGPoint(x: width - Layout.slotInset - Layout.slotDiameter, y: Layout.slotTop), size: slotSize)
        ]
        for (layer, rect) in zip(slotLayers, slotRects) {
            layer.path = UIBezierPath(ovalIn: rect.insetBy(dx: 0.75, dy: 0.75)).cgPath
        }
        sealView.frame = CGRect(
            x: (width - Layout.sealSize) / 2, y: Layout.sealTop,
            width: Layout.sealSize, height: Layout.sealSize
        )
    }
}
