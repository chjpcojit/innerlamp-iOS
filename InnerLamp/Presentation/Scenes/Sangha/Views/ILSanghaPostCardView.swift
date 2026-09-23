//
//  ILSanghaPostCardView.swift
//  InnerLamp
//

import UIKit

/// Thẻ 1 bài chia sẻ của bạn đồng tu: avatar chữ cái + tên + (thời gian · tinh tấn), câu chia sẻ
/// Lora nghiêng, hàng Tùy hỷ / Hồi âm. Cả thẻ là 1 vùng chạm. Biết `ILSanghaPostModel` nên thuộc
/// riêng màn Đạo tràng.
final class ILSanghaPostCardView: UIControl {

    // MARK: - Constants
    private enum Layout {
        static let padding: CGFloat = 16
        static let avatarSize: CGFloat = 32
    }

    // MARK: - Properties
    var onTap: (() -> Void)?

    // MARK: - UI Elements
    private lazy var avatarView = ILAvatarView(initials: "", tone: .gold, size: Layout.avatarSize)

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.bodySmallMedium
        label.textColor = ILColors.ink
        return label
    }()

    private lazy var metaLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.caption
        label.textColor = ILColors.inkMuted
        return label
    }()

    private lazy var bodyLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private lazy var likeLabel: UILabel = makeEngagementLabel()
    private lazy var replyLabel: UILabel = makeEngagementLabel()

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

        let authorText = UIStackView(arrangedSubviews: [nameLabel, metaLabel])
        authorText.axis = .vertical

        let authorRow = UIStackView(arrangedSubviews: [avatarView, authorText, UIView()])
        authorRow.axis = .horizontal
        authorRow.alignment = .center
        authorRow.spacing = ILMetrics.rowSpacing

        let engagementRow = UIStackView(arrangedSubviews: [likeLabel, replyLabel, UIView()])
        engagementRow.axis = .horizontal
        engagementRow.spacing = ILMetrics.groupSpacing - 4

        let contentStack = UIStackView(arrangedSubviews: [authorRow, bodyLabel, engagementRow])
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = ILMetrics.spaceMedium - 2
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

    private func makeEngagementLabel() -> UILabel {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.inkSubtle
        return label
    }

    // MARK: - Configure
    func configure(with model: ILSanghaPostModel) {
        avatarView.initials = model.authorInitials
        nameLabel.text = model.authorName
        metaLabel.text = model.metaText
        bodyLabel.attributedText = ILTypography.makeAttributedString(
            text: model.body,
            font: ILTypography.quoteItalic,
            color: ILColors.inkSecondary,
            lineHeightMultiple: 1.6
        )
        likeLabel.text = model.likeText
        replyLabel.text = model.replyText
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
