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
    private lazy var lampView: ILMemorialEmptyLampView = {
        let view = ILMemorialEmptyLampView()
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.emptyStateTitle
        label.textColor = ILColors.ink
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "memorial.empty.title".localized
        return label
    }()

    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = ILTypography.makeParagraph(
            text: "memorial.empty.message".localized,
            font: ILTypography.bodyCompact,
            color: ILColors.inkTertiary,
            cssLineHeight: 1.65,
            alignment: .center
        )
        return label
    }()

    private lazy var stepsCard: UIView = {
        let view = UIView()
        view.backgroundColor = ILColors.surface
        view.layer.cornerRadius = ILMetrics.radiusCardRegular
        view.layer.borderWidth = 1
        view.layer.borderColor = ILColors.border.cgColor
        return view
    }()

    private lazy var treeCard: UIControl = {
        let control = UIControl()
        control.backgroundColor = ILColors.surface
        control.layer.cornerRadius = ILMetrics.radiusCardRegular
        control.layer.borderWidth = 1
        control.layer.borderColor = ILColors.border.cgColor
        return control
    }()

    private lazy var treeSealView: UIView = {
        let view = UIView()
        view.backgroundColor = ILColors.FamilyTree.seal
        view.layer.cornerRadius = 10
        view.isUserInteractionEnabled = false
        return view
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

    private func setupStepsCard() {
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
    private lazy var wickView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 2
        return view
    }()

    private lazy var baseView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()

    private let baseGradient = CAGradientLayer()

    private lazy var flameView: ILFlameView = {
        let view = ILFlameView(height: Layout.flameHeight, topColor: ILColors.goldLight)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
        translatesAutoresizingMaskIntoConstraints = false

        haloLayer.type = .radial
        haloLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        haloLayer.endPoint = CGPoint(x: 1, y: 1)
        haloLayer.locations = [0, 0.62, 0.72]
        layer.addSublayer(haloLayer)

        baseView.layer.insertSublayer(baseGradient, at: 0)

        [wickView, baseView, flameView].forEach { addSubview($0) }

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
