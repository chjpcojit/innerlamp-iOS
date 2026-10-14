//
//  ILMemorialHighlightCardView.swift
//  InnerLamp
//

import UIKit

/// Large card of the soonest giỗ on top of the list (design handoff `gioTop`): eyebrow, portrait
/// placeholder + name + relation line, then "Ngày giỗ / Nhằm / Nhắc nhở" rows on the featured
/// gradient. The whole card is one tap area.
final class ILMemorialHighlightCardView: UIControl {

    // MARK: - Properties
    var onTap: (() -> Void)?

    // MARK: - UI Elements
    private let gradientLayer = CAGradientLayer()
    private lazy var eyebrowLabel: UILabel = {
        let label = UILabel()
        return label
    }()

    private lazy var avatarView: ILAvatarView = {
        let view = ILAvatarView(initials: "", tone: .gold, size: 64)
        return view
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.serifCardTitle
        label.textColor = ILColors.ink
        label.numberOfLines = 2
        return label
    }()

    private lazy var relationLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.featSub
        label.numberOfLines = 0
        return label
    }()

    private lazy var divider: UIView = {
        let view = UIView()
        view.backgroundColor = ILColors.featBorder
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var dateValueLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.ink
        label.numberOfLines = 0
        return label
    }()

    private lazy var whenValueLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.ink
        label.numberOfLines = 0
        return label
    }()

    private lazy var remindValueLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.ink
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    // MARK: - Public API
    func configure(with model: ILMemorialHighlightModel) {
        eyebrowLabel.attributedText = ILTypography.makeEyebrow(text: model.eyebrow, color: ILColors.featAccent)
        avatarView.initials = model.name.first.map { String($0).uppercased() } ?? ""
        nameLabel.text = model.name
        relationLabel.text = model.relationLine
        dateValueLabel.text = model.dateLine
        whenValueLabel.text = model.whenLine
        remindValueLabel.text = model.remindLine
    }

    // MARK: - Setup
    private func setupViews() {
        layer.cornerRadius = ILMetrics.radiusCardMedium
        layer.borderWidth = 1
        layer.borderColor = ILColors.featBorder.cgColor
        clipsToBounds = true

        gradientLayer.colors = [ILColors.featBackgroundStart.cgColor, ILColors.featBackgroundEnd.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.2, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.8, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)

        let nameStack = UIStackView(arrangedSubviews: [nameLabel, relationLabel])
        nameStack.axis = .vertical
        nameStack.spacing = 4

        let headerRow = UIStackView(arrangedSubviews: [avatarView, nameStack])
        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.spacing = ILMetrics.spaceMedium

        let detailStack = UIStackView(arrangedSubviews: [
            makeDetailRow(title: "memorial.highlight.date".localized, value: dateValueLabel),
            makeDetailRow(title: "memorial.highlight.when".localized, value: whenValueLabel),
            makeDetailRow(title: "memorial.highlight.remind".localized, value: remindValueLabel)
        ])
        detailStack.axis = .vertical
        detailStack.spacing = 7

        let content = UIStackView(arrangedSubviews: [eyebrowLabel, headerRow, divider, detailStack])
        content.axis = .vertical
        content.spacing = ILMetrics.spaceMedium
        content.setCustomSpacing(ILMetrics.spaceStandard, after: headerRow)
        content.setCustomSpacing(12, after: divider)
        content.isUserInteractionEnabled = false
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)

        NSLayoutConstraint.activate([
            divider.heightAnchor.constraint(equalToConstant: 1),
            content.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            content.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])

        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILMemorialHighlightCardView, _) in
            view.layer.borderColor = ILColors.featBorder.cgColor
            view.gradientLayer.colors = [ILColors.featBackgroundStart.cgColor, ILColors.featBackgroundEnd.cgColor]
        }
    }

    private func makeDetailRow(title: String, value: UILabel) -> UIView {
        let titleLabel = UILabel()
        titleLabel.font = ILTypography.subhead
        titleLabel.textColor = ILColors.featSub
        titleLabel.text = title
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.widthAnchor.constraint(equalToConstant: Self.detailTitleWidth).isActive = true

        let row = UIStackView(arrangedSubviews: [titleLabel, value])
        row.axis = .horizontal
        row.alignment = .firstBaseline
        row.spacing = ILMetrics.rowSpacing
        return row
    }

    @objc private func handleTouchDown() {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = CGAffineTransform(scaleX: 0.99, y: 0.99)
        }
    }

    @objc private func handleTouchUp() {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = .identity
        }
    }

    @objc private func handleTapAction() {
        onTap?()
    }

    private static let detailTitleWidth: CGFloat = 72
}
