//
//  ILProfileDonateCardView.swift
//  InnerLamp
//

import UIKit

/// Thẻ "Ủng hộ InnerLamp": viền vàng, icon tile hoa sen, tiêu đề + dòng "miễn phí trọn đời · ủng hộ
/// tùy tâm", mũi tên. Luôn hiện (không phụ thuộc gói). Cả thẻ là 1 vùng chạm (mở màn Ủng hộ).
/// Nội dung riêng màn Tôi.
final class ILProfileDonateCardView: UIControl {

    // MARK: - Constants
    private enum Layout {
        static let horizontalPadding: CGFloat = 20
        static let verticalPadding: CGFloat = 18
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
        tile.layer.cornerRadius = ILMetrics.radiusIconTile
        tile.isUserInteractionEnabled = false
        tile.translatesAutoresizingMaskIntoConstraints = false

        // The 44×44 icon asset carries its own padding, so it fills the whole tile (same as `ILRow`).
        let glyph = UIImageView(image: ILIcons.rowLotus)
        glyph.tintColor = ILColors.Tone.gold.accentColor
        glyph.contentMode = .scaleAspectFit
        glyph.translatesAutoresizingMaskIntoConstraints = false
        tile.addSubview(glyph)
        NSLayoutConstraint.activate([
            glyph.leadingAnchor.constraint(equalTo: tile.leadingAnchor),
            glyph.trailingAnchor.constraint(equalTo: tile.trailingAnchor),
            glyph.topAnchor.constraint(equalTo: tile.topAnchor),
            glyph.bottomAnchor.constraint(equalTo: tile.bottomAnchor)
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
