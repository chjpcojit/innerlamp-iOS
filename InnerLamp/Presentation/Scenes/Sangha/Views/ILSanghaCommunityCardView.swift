//
//  ILSanghaCommunityCardView.swift
//  InnerLamp
//

import UIKit

/// Thẻ "Đạo tràng của tôi": icon tile lá xanh + tên / số thành viên + mũi tên, hairline, rồi
/// thông báo mới nhất của đạo tràng. Cả thẻ là 1 vùng chạm. Biết `ILSanghaCommunityModel` nên
/// thuộc riêng màn Đạo tràng.
final class ILSanghaCommunityCardView: UIControl {

    // MARK: - Constants
    private enum Layout {
        static let padding: CGFloat = 16
        static let tileSize: CGFloat = 42
        static let glyphSize: CGFloat = 15
    }

    // MARK: - Properties
    var onTap: (() -> Void)?

    // MARK: - UI Elements
    private lazy var iconTile: UIView = {
        let tile = UIView()
        tile.backgroundColor = ILColors.Tone.green.tintBackground
        tile.layer.cornerRadius = ILMetrics.radiusInput
        tile.isUserInteractionEnabled = false

        // Hình giọt lá (bo 3 góc, vuông góc trên-phải) — cùng glyph `.leaf` của `ILRow`.
        let glyph = UIView()
        glyph.backgroundColor = ILColors.Tone.green.accentColor
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

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.rowTitle
        label.textColor = ILColors.ink
        return label
    }()

    private lazy var metaLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.inkTertiary
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

    private lazy var divider: UIView = {
        let view = UIView()
        view.backgroundColor = ILColors.border
        return view
    }()

    private lazy var announcementLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
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
        layer.borderColor = ILColors.border.cgColor

        let titleStack = UIStackView(arrangedSubviews: [nameLabel, metaLabel])
        titleStack.axis = .vertical
        titleStack.spacing = 2

        let topRow = UIStackView(arrangedSubviews: [iconTile, titleStack, chevronLabel])
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.spacing = ILMetrics.spaceMedium - 2
        iconTile.widthAnchor.constraint(equalToConstant: Layout.tileSize).isActive = true
        iconTile.heightAnchor.constraint(equalToConstant: Layout.tileSize).isActive = true

        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true

        let contentStack = UIStackView(arrangedSubviews: [topRow, divider, announcementLabel])
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = ILMetrics.spaceMedium
        contentStack.isUserInteractionEnabled = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: Layout.padding),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.padding),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.padding),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.padding)
        ])

        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)
    }

    // MARK: - Configure
    func configure(with model: ILSanghaCommunityModel) {
        nameLabel.text = model.name
        metaLabel.text = model.metaText
        announcementLabel.attributedText = ILTypography.makeAttributedString(
            text: model.announcement,
            font: ILTypography.bodyCompact,
            color: ILColors.inkSecondary,
            lineHeightMultiple: 1.6
        )
    }

    // `layer.borderColor` là CGColor tĩnh, không tự đảo theo trait — refresh thủ công khi đổi
    // light/dark.
    private func registerForAppearanceChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.layer.borderColor = ILColors.border.cgColor
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
