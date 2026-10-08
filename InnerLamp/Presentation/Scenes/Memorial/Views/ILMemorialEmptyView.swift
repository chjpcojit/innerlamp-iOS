//
//  ILMemorialEmptyView.swift
//  InnerLamp
//

import UIKit

/// Empty state of "Sổ giỗ chạp" (design handoff `gioEmpty`): lamp illustration, title, hint,
/// a numbered "how it works" card and the "Lấy từ gia phả" shortcut card.
final class ILMemorialEmptyView: UIView {

    // MARK: - Properties
    var onFamilyTreeTap: (() -> Void)?

    // MARK: - UI Elements
    private let lampView = ILMemorialEmptyLampView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let stepsCard = UIView()
    private let treeCard = UIControl()
    private let treeSealView = UIView()

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
        titleLabel.font = ILTypography.emptyStateTitle
        titleLabel.textColor = ILColors.ink
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.text = "memorial.empty.title".localized

        messageLabel.numberOfLines = 0
        messageLabel.attributedText = ILTypography.makeParagraph(
            text: "memorial.empty.message".localized,
            font: ILTypography.bodyCompact,
            color: ILColors.inkTertiary,
            cssLineHeight: 1.65,
            alignment: .center
        )

        let header = UIStackView(arrangedSubviews: [lampView, titleLabel, messageLabel])
        header.axis = .vertical
        header.alignment = .center
        header.spacing = 8
        header.setCustomSpacing(18, after: lampView)

        setupStepsCard()
        setupTreeCard()

        let stack = UIStackView(arrangedSubviews: [header, stepsCard, treeCard])
        stack.axis = .vertical
        stack.spacing = 12
        stack.setCustomSpacing(26, after: header)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: ILMetrics.spaceLarge),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            messageLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 300)
        ])

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILMemorialEmptyView, _) in
            [view.stepsCard, view.treeCard].forEach { $0.layer.borderColor = ILColors.border.cgColor }
        }
    }

    private func styleCard(_ card: UIView) {
        card.backgroundColor = ILColors.surface
        card.layer.cornerRadius = ILMetrics.radiusCardRegular
        card.layer.borderWidth = 1
        card.layer.borderColor = ILColors.border.cgColor
    }

    private func setupStepsCard() {
        styleCard(stepsCard)
        let steps = [
            ("memorial.empty.step1.title", "memorial.empty.step1.body"),
            ("memorial.empty.step2.title", "memorial.empty.step2.body"),
            ("memorial.empty.step3.title", "memorial.empty.step3.body")
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
        stepsCard.addSubview(rows)
        NSLayoutConstraint.activate([
            rows.topAnchor.constraint(equalTo: stepsCard.topAnchor, constant: 6),
            rows.bottomAnchor.constraint(equalTo: stepsCard.bottomAnchor, constant: -6),
            rows.leadingAnchor.constraint(equalTo: stepsCard.leadingAnchor, constant: 18),
            rows.trailingAnchor.constraint(equalTo: stepsCard.trailingAnchor, constant: -18)
        ])
    }

    private func makeStepRow(number: Int, title: String, body: String, showsDivider: Bool) -> UIView {
        let badge = UIView()
        badge.backgroundColor = ILColors.goldDayTint
        badge.layer.cornerRadius = 13
        badge.translatesAutoresizingMaskIntoConstraints = false

        let numberLabel = UILabel()
        numberLabel.font = ILTypography.subheadMedium
        numberLabel.textColor = ILColors.gold
        numberLabel.text = "\(number)"
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(numberLabel)

        let titleLabel = UILabel()
        titleLabel.font = ILTypography.bodyMedium
        titleLabel.textColor = ILColors.ink
        titleLabel.numberOfLines = 0
        titleLabel.text = title

        let bodyLabel = UILabel()
        bodyLabel.numberOfLines = 0
        bodyLabel.attributedText = ILTypography.makeParagraph(
            text: body,
            font: ILTypography.note,
            color: ILColors.inkTertiary,
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
            divider.backgroundColor = ILColors.borderSoft
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

    private func setupTreeCard() {
        styleCard(treeCard)

        treeSealView.backgroundColor = ILColors.FamilyTree.seal
        treeSealView.layer.cornerRadius = 10
        treeSealView.isUserInteractionEnabled = false

        let sealLabel = UILabel()
        sealLabel.font = ILTypography.treeSealMedium
        sealLabel.textColor = ILColors.FamilyTree.cream
        sealLabel.text = "memorial.empty.fromTree.seal".localized
        sealLabel.translatesAutoresizingMaskIntoConstraints = false
        treeSealView.addSubview(sealLabel)

        let titleLabel = UILabel()
        titleLabel.font = ILTypography.bodyMedium
        titleLabel.textColor = ILColors.ink
        titleLabel.text = "memorial.empty.fromTree.title".localized

        let subtitleLabel = UILabel()
        subtitleLabel.font = ILTypography.subhead
        subtitleLabel.textColor = ILColors.inkTertiary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = "memorial.empty.fromTree.subtitle".localized

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let chevron = UILabel()
        chevron.font = ILTypography.chevron
        chevron.textColor = ILColors.inkFaint
        chevron.text = "›"
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [treeSealView, textStack, chevron])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = ILMetrics.spaceMedium
        row.isUserInteractionEnabled = false
        row.translatesAutoresizingMaskIntoConstraints = false
        treeCard.addSubview(row)

        NSLayoutConstraint.activate([
            treeSealView.widthAnchor.constraint(equalToConstant: 38),
            treeSealView.heightAnchor.constraint(equalToConstant: 38),
            sealLabel.centerXAnchor.constraint(equalTo: treeSealView.centerXAnchor),
            sealLabel.centerYAnchor.constraint(equalTo: treeSealView.centerYAnchor),
            row.topAnchor.constraint(equalTo: treeCard.topAnchor, constant: ILMetrics.spaceMedium),
            row.bottomAnchor.constraint(equalTo: treeCard.bottomAnchor, constant: -ILMetrics.spaceMedium),
            row.leadingAnchor.constraint(equalTo: treeCard.leadingAnchor, constant: 18),
            row.trailingAnchor.constraint(equalTo: treeCard.trailingAnchor, constant: -18)
        ])

        treeCard.addTarget(self, action: #selector(handleTreeTouchDown), for: [.touchDown, .touchDragEnter])
        treeCard.addTarget(self, action: #selector(handleTreeTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        treeCard.addTarget(self, action: #selector(handleTreeTap), for: .touchUpInside)
    }

    @objc private func handleTreeTouchDown() {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.treeCard.transform = CGAffineTransform(scaleX: 0.99, y: 0.99)
        }
    }

    @objc private func handleTreeTouchUp() {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.treeCard.transform = .identity
        }
    }

    @objc private func handleTreeTap() {
        onFamilyTreeTap?()
    }
}

/// 112pt lamp of the empty memorial book: warm radial halo, flame, wick and base.
private final class ILMemorialEmptyLampView: UIView {

    // MARK: - Layout constants (design handoff `gioEmpty`)
    private enum Layout {
        static let size: CGFloat = 112
        static let flameHeight: CGFloat = 20
        static let flameTop: CGFloat = 22
        static let wickSize = CGSize(width: 4, height: 22)
        static let wickBottom: CGFloat = 36
        static let baseSize = CGSize(width: 56, height: 16)
        static let baseBottom: CGFloat = 22
    }

    // MARK: - UI Elements
    private let haloLayer = CAGradientLayer()
    private let wickView = UIView()
    private let baseView = UIView()
    private let baseGradient = CAGradientLayer()
    private let flameView = ILFlameView(height: Layout.flameHeight, topColor: ILColors.goldLight)

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
        translatesAutoresizingMaskIntoConstraints = false

        haloLayer.type = .radial
        haloLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        haloLayer.endPoint = CGPoint(x: 1, y: 1)
        haloLayer.locations = [0, 0.62, 0.72]
        layer.addSublayer(haloLayer)

        wickView.layer.cornerRadius = 2
        baseView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        baseView.layer.cornerRadius = 12
        baseView.layer.insertSublayer(baseGradient, at: 0)
        baseView.clipsToBounds = true

        [wickView, baseView, flameView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: Layout.size),
            heightAnchor.constraint(equalToConstant: Layout.size),
            flameView.centerXAnchor.constraint(equalTo: centerXAnchor),
            flameView.bottomAnchor.constraint(equalTo: topAnchor, constant: Layout.flameTop + Layout.flameHeight),
            wickView.centerXAnchor.constraint(equalTo: centerXAnchor),
            wickView.widthAnchor.constraint(equalToConstant: Layout.wickSize.width),
            wickView.heightAnchor.constraint(equalToConstant: Layout.wickSize.height),
            wickView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.wickBottom),
            baseView.centerXAnchor.constraint(equalTo: centerXAnchor),
            baseView.widthAnchor.constraint(equalToConstant: Layout.baseSize.width),
            baseView.heightAnchor.constraint(equalToConstant: Layout.baseSize.height),
            baseView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.baseBottom)
        ])

        applyColors()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILMemorialEmptyLampView, _) in
            view.applyColors()
        }
    }

    private func applyColors() {
        haloLayer.colors = [
            ILColors.goldBright.withAlphaComponent(0.20).cgColor,
            ILColors.goldBright.withAlphaComponent(0.05).cgColor,
            ILColors.goldGlowClear.cgColor
        ]
        wickView.backgroundColor = ILColors.goldDeep
        baseGradient.colors = [ILColors.gold.cgColor, ILColors.goldDeep.cgColor]
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        haloLayer.frame = bounds
        haloLayer.cornerRadius = bounds.width / 2
        baseGradient.frame = baseView.bounds
    }
}
