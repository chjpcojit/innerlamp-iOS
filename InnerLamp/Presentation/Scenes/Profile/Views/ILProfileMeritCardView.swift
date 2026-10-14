//
//  ILProfileMeritCardView.swift
//  InnerLamp
//

import UIKit

/// Thẻ "Công đức đã hồi hướng": nền gradient thẻ nổi bật (`--il-feat-bg`, đổi theo light/dark),
/// icon đèn 44pt (tone rose), tiêu đề + tóm tắt số lần cúng dường / đèn Vu Lan, mũi tên. Cả thẻ là
/// 1 vùng chạm (mở Cúng dường). Nội dung riêng màn Tôi.
final class ILProfileMeritCardView: UIControl {

    // MARK: - Constants
    private enum Layout {
        static let horizontalPadding: CGFloat = 20
        static let verticalPadding: CGFloat = 18
    }

    // MARK: - Properties
    var title: String = "" {
        didSet { titleLabel.text = title }
    }

    var onTap: (() -> Void)?

    // MARK: - UI Elements
    private let gradientLayer = CAGradientLayer()

    private lazy var iconTile: UIView = {
        let tile = UIView()
        tile.backgroundColor = ILColors.Tone.rose.tintBackground
        tile.layer.cornerRadius = ILMetrics.radiusIconTile
        tile.isUserInteractionEnabled = false

        let glyph = UIImageView(image: ILIcons.rowLamp)
        glyph.tintColor = ILColors.Tone.rose.accentColor
        glyph.contentMode = .scaleAspectFit
        glyph.translatesAutoresizingMaskIntoConstraints = false
        tile.addSubview(glyph)
        NSLayoutConstraint.activate([
            glyph.topAnchor.constraint(equalTo: tile.topAnchor),
            glyph.bottomAnchor.constraint(equalTo: tile.bottomAnchor),
            glyph.leadingAnchor.constraint(equalTo: tile.leadingAnchor),
            glyph.trailingAnchor.constraint(equalTo: tile.trailingAnchor)
        ])
        return tile
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.headerTitle
        label.textColor = ILColors.ink
        return label
    }()

    private lazy var summaryLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.featSub
        label.numberOfLines = 0
        return label
    }()

    private lazy var chevronLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.chevron
        label.textColor = ILColors.featSub
        label.text = "›"
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
        applyDynamicColors()
        registerForAppearanceChanges()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // A bare sublayer animates `frame` implicitly — without this the gradient grows in on first layout.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = bounds
        CATransaction.commit()
    }

    // MARK: - Setup
    private func setupViews() {
        layer.cornerRadius = ILMetrics.radiusCardSmall + 2
        clipsToBounds = true

        layer.borderWidth = 1
        gradientLayer.startPoint = CGPoint(x: 0.2, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.8, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, summaryLabel])
        textStack.axis = .vertical
        textStack.spacing = 3

        let contentStack = UIStackView(arrangedSubviews: [iconTile, textStack, chevronLabel])
        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = ILMetrics.spaceMedium
        contentStack.isUserInteractionEnabled = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            iconTile.widthAnchor.constraint(equalToConstant: ILMetrics.iconTileSize),
            iconTile.heightAnchor.constraint(equalToConstant: ILMetrics.iconTileSize),

            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: Layout.verticalPadding),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.verticalPadding),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalPadding),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalPadding)
        ])

        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)
    }

    // MARK: - Configure
    func configure(summary: String) {
        summaryLabel.text = summary
    }

    // `CGColor` tĩnh (viền, gradient) không tự đảo theo trait — dựng lại khi đổi light/dark.
    private func applyDynamicColors() {
        gradientLayer.colors = [
            ILColors.featBackgroundStart.resolvedColor(with: traitCollection).cgColor,
            ILColors.featBackgroundEnd.resolvedColor(with: traitCollection).cgColor
        ]
        layer.borderColor = ILColors.featBorder.resolvedColor(with: traitCollection).cgColor
    }

    private func registerForAppearanceChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.applyDynamicColors()
        }
    }

    // MARK: - Touch
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
}
