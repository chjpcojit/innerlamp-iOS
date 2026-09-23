//
//  ILProfilePremiumCardView.swift
//  InnerLamp
//

import UIKit

/// Thẻ mời nâng cấp "Sen Vàng · mở trọn thư viện": viền vàng, icon tile lá vàng, tiêu đề + dòng
/// dùng thử, mũi tên. Cả thẻ là 1 vùng chạm (mở paywall). Nội dung riêng màn Tôi.
final class ILProfilePremiumCardView: UIControl {

    // MARK: - Constants
    private enum Layout {
        static let horizontalPadding: CGFloat = 20
        static let verticalPadding: CGFloat = 18
        static let tileSize: CGFloat = 40
        static let glyphSize: CGFloat = 14
    }

    // MARK: - Properties
    var title: String = "" {
        didSet { titleLabel.text = title }
    }

    var subtitle: String = "" {
        didSet { subtitleLabel.text = subtitle }
    }

    var onTap: (() -> Void)?

    // MARK: - UI Elements
    private lazy var iconTile: UIView = {
        let tile = UIView()
        tile.backgroundColor = ILColors.Tone.gold.tintBackground
        tile.layer.cornerRadius = Layout.tileSize / 2
        tile.isUserInteractionEnabled = false
        tile.translatesAutoresizingMaskIntoConstraints = false

        // Hình giọt lá (bo 3 góc, vuông góc trên-phải) — cùng glyph `.leaf` của `ILRow`.
        let glyph = UIView()
        glyph.backgroundColor = ILColors.Tone.gold.accentColor
        glyph.layer.cornerRadius = Layout.glyphSize / 2
        glyph.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        glyph.translatesAutoresizingMaskIntoConstraints = false
        tile.addSubview(glyph)
        NSLayoutConstraint.activate([
            glyph.centerXAnchor.constraint(equalTo: tile.centerXAnchor),
            glyph.centerYAnchor.constraint(equalTo: tile.centerYAnchor),
            glyph.widthAnchor.constraint(equalToConstant: Layout.glyphSize),
            glyph.heightAnchor.constraint(equalToConstant: Layout.glyphSize)
        ])
        return tile
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.headerTitle
        label.textColor = ILColors.ink
        label.numberOfLines = 0
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.inkTertiary
        label.numberOfLines = 0
        return label
    }()

    private lazy var chevronLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.chevron
        label.textColor = ILColors.inkFaint
        label.text = "›"
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
        registerForAppearanceChanges()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardSmall + 2
        layer.borderWidth = 1
        layer.borderColor = ILColors.goldBorder.cgColor

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
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
            iconTile.widthAnchor.constraint(equalToConstant: Layout.tileSize),
            iconTile.heightAnchor.constraint(equalToConstant: Layout.tileSize),

            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: Layout.verticalPadding),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.verticalPadding),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalPadding),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalPadding)
        ])

        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)
    }

    // `layer.borderColor` là CGColor tĩnh, không tự đảo theo trait — refresh thủ công khi đổi
    // light/dark.
    private func registerForAppearanceChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.layer.borderColor = ILColors.goldBorder.cgColor
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
