//
//  ILNotificationRowView.swift
//  InnerLamp
//

import UIKit

/// 1 dòng thông báo trong màn Thông báo: ô icon tint (38px, glyph giọt lệ màu nhấn), tiêu đề +
/// thời gian tương đối trên một dòng, nội dung phụ bên dưới, và chấm vàng "chưa đọc" ở cuối. Là
/// composition riêng của màn Thông báo — nhận `ILNotificationItemModel`, không có copy cứng.
final class ILNotificationRowView: UIView {

    // MARK: - Constants
    private enum Layout {
        static let tileSize: CGFloat = 38
        static let tileRadius: CGFloat = 12
        static let glyphSize: CGFloat = 13
        static let dotSize: CGFloat = 7
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 14
        static let gap: CGFloat = 13
    }

    // MARK: - UI Elements
    private let iconTile = UIView()
    private let glyphView = UIView()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.sectionTitle
        label.textColor = ILColors.ink
        return label
    }()

    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.caption
        label.textColor = ILColors.inkMuted
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private lazy var bodyLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.note
        label.textColor = ILColors.inkTertiary
        label.numberOfLines = 0
        return label
    }()

    private lazy var unreadDot: UIView = {
        let view = UIView()
        view.backgroundColor = ILColors.goldBright
        view.layer.cornerRadius = Layout.dotSize / 2
        return view
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

        iconTile.translatesAutoresizingMaskIntoConstraints = false
        iconTile.layer.cornerRadius = Layout.tileRadius
        iconTile.clipsToBounds = true
        addSubview(iconTile)

        glyphView.translatesAutoresizingMaskIntoConstraints = false
        iconTile.addSubview(glyphView)

        let titleRow = UIStackView(arrangedSubviews: [titleLabel, timeLabel])
        titleRow.axis = .horizontal
        titleRow.alignment = .firstBaseline
        titleRow.spacing = ILMetrics.spaceSmall

        let textStack = UIStackView(arrangedSubviews: [titleRow, bodyLabel])
        textStack.axis = .vertical
        textStack.alignment = .fill
        textStack.spacing = 4

        unreadDot.translatesAutoresizingMaskIntoConstraints = false
        addSubview(unreadDot)

        textStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textStack)

        NSLayoutConstraint.activate([
            iconTile.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalPadding),
            iconTile.topAnchor.constraint(equalTo: topAnchor, constant: Layout.verticalPadding),
            iconTile.widthAnchor.constraint(equalToConstant: Layout.tileSize),
            iconTile.heightAnchor.constraint(equalToConstant: Layout.tileSize),

            glyphView.centerXAnchor.constraint(equalTo: iconTile.centerXAnchor),
            glyphView.centerYAnchor.constraint(equalTo: iconTile.centerYAnchor),
            glyphView.widthAnchor.constraint(equalToConstant: Layout.glyphSize),
            glyphView.heightAnchor.constraint(equalToConstant: Layout.glyphSize),

            textStack.leadingAnchor.constraint(equalTo: iconTile.trailingAnchor, constant: Layout.gap),
            textStack.topAnchor.constraint(equalTo: topAnchor, constant: Layout.verticalPadding),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -Layout.verticalPadding),

            unreadDot.leadingAnchor.constraint(equalTo: textStack.trailingAnchor, constant: Layout.gap),
            unreadDot.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalPadding),
            unreadDot.topAnchor.constraint(equalTo: topAnchor, constant: Layout.verticalPadding + 5),
            unreadDot.widthAnchor.constraint(equalToConstant: Layout.dotSize),
            unreadDot.heightAnchor.constraint(equalToConstant: Layout.dotSize),

            bottomAnchor.constraint(greaterThanOrEqualTo: iconTile.bottomAnchor, constant: Layout.verticalPadding)
        ])
    }

    // MARK: - Configure
    func configure(with item: ILNotificationItemModel) {
        let tone = tone(for: item.kind)

        iconTile.backgroundColor = tone.tintBackground
        glyphView.backgroundColor = tone.accentColor
        glyphView.layer.cornerRadius = Layout.glyphSize / 2
        glyphView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]

        titleLabel.text = item.title
        bodyLabel.text = item.body
        timeLabel.text = item.relativeTime
        unreadDot.isHidden = item.isRead
    }

    /// Ánh xạ loại thông báo (nghiệp vụ) sang tone màu (hiển thị) — việc riêng của tầng view.
    private func tone(for kind: ILNotificationKind) -> ILColors.Tone {
        switch kind {
        case .bell: return .gold
        case .sangha: return .green
        case .community: return .rose
        case .offering: return .ink
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
