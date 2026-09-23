//
//  ILProfileBadgeCardView.swift
//  InnerLamp
//

import UIKit

/// 1 thẻ dấu ấn nhỏ: icon tròn tint theo nhóm + tên + dòng phụ. Biết `ILProfileBadgeModel` (và
/// ánh xạ nhóm → tông màu) nên thuộc riêng màn Tôi. Không tự xử lý chạm — cả hàng dấu ấn là 1
/// vùng chạm (`ILProfileBadgesRowView`).
final class ILProfileBadgeCardView: UIView {

    // MARK: - Constants
    private enum Layout {
        static let tileSize: CGFloat = 36
        static let glyphSize: CGFloat = 12
    }

    // MARK: - UI Elements
    private lazy var iconTile: UIView = {
        let tile = UIView()
        tile.layer.cornerRadius = Layout.tileSize / 2
        tile.translatesAutoresizingMaskIntoConstraints = false
        return tile
    }()

    // Hình giọt lá (bo 3 góc, vuông góc trên-phải) — cùng glyph `.leaf` của `ILRow`.
    private lazy var glyph: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Layout.glyphSize / 2
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subheadMedium
        label.textColor = ILColors.ink
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.microCaption
        label.textColor = ILColors.inkSubtle
        label.textAlignment = .center
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
        layer.cornerRadius = ILMetrics.radiusCardSmall
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor

        iconTile.addSubview(glyph)
        NSLayoutConstraint.activate([
            iconTile.widthAnchor.constraint(equalToConstant: Layout.tileSize),
            iconTile.heightAnchor.constraint(equalToConstant: Layout.tileSize),
            glyph.centerXAnchor.constraint(equalTo: iconTile.centerXAnchor),
            glyph.centerYAnchor.constraint(equalTo: iconTile.centerYAnchor),
            glyph.widthAnchor.constraint(equalToConstant: Layout.glyphSize),
            glyph.heightAnchor.constraint(equalToConstant: Layout.glyphSize)
        ])

        // Bọc icon để stack `.fill` không kéo giãn hình tròn hết chiều ngang thẻ.
        let iconRow = UIStackView(arrangedSubviews: [UIView(), iconTile, UIView()])
        iconRow.axis = .horizontal
        iconRow.distribution = .equalCentering

        let contentStack = UIStackView(arrangedSubviews: [iconRow, titleLabel, subtitleLabel])
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 2
        contentStack.setCustomSpacing(ILMetrics.spaceSmall, after: iconRow)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: ILMetrics.spaceMedium),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -ILMetrics.spaceMedium),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.rowSpacing),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.rowSpacing)
        ])
    }

    // MARK: - Configure
    func configure(with model: ILProfileBadgeModel) {
        let tone = Self.tone(for: model.category)
        iconTile.backgroundColor = tone.tintBackground
        glyph.backgroundColor = tone.accentColor
        titleLabel.text = model.title
        subtitleLabel.text = model.subtitle
    }

    /// Niệm Phật → vàng, giữ thời khóa liên tục → xanh, cúng dường / hồi hướng → hồng.
    static func tone(for category: ILProfileBadgeCategory) -> ILColors.Tone {
        switch category {
        case .mala: return .gold
        case .streak: return .green
        case .offering: return .rose
        }
    }

    // `layer.borderColor` là CGColor tĩnh, không tự đảo theo trait — refresh thủ công khi đổi
    // light/dark.
    private func registerForAppearanceChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.layer.borderColor = ILColors.border.cgColor
        }
    }
}
