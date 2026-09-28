//
//  ILPostCardView.swift
//  InnerLamp
//

import UIKit

/// Thẻ bài đăng đạo tràng: avatar + tên + (thời gian · tag), thân bài Lora, hàng tán thán / bình
/// luận / chia sẻ. Biết `ILPostStateModel` nên thuộc riêng màn Bài đăng đạo tràng.
final class ILPostCardView: UIView {

    // MARK: - Constants
    private enum Layout {
        static let avatarSize: CGFloat = 42
        static let glyphSize: CGFloat = 9
        static let padding: CGFloat = 20
    }

    // MARK: - Properties
    var onLikeTap: (() -> Void)?
    var onShareTap: (() -> Void)?

    // MARK: - UI Elements
    private lazy var avatarView = ILAvatarView(initials: "", tone: .gold, size: Layout.avatarSize)

    private lazy var authorLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.bodyMedium
        label.textColor = ILColors.ink
        label.numberOfLines = 1
        return label
    }()

    private lazy var metaLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.label
        label.textColor = ILColors.inkMuted
        label.numberOfLines = 1
        return label
    }()

    private lazy var bodyLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private lazy var footerDivider: UIView = {
        let divider = UIView()
        divider.backgroundColor = ILColors.border
        return divider
    }()

    private lazy var likeButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = Self.makeLikeGlyphImage()
        config.imagePadding = 7
        config.baseForegroundColor = ILColors.inkTertiary
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = ILTypography.chip
            return outgoing
        }
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(handleLikeTap), for: .touchUpInside)
        return button
    }()

    private lazy var commentGlyph: UIView = {
        let view = UIView()
        view.layer.cornerRadius = ILMetrics.radiusGlyph
        view.layer.borderWidth = 1.4
        view.layer.borderColor = ILColors.inkMuted.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var commentLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.chip
        label.textColor = ILColors.inkTertiary
        return label
    }()

    private lazy var commentStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [commentGlyph, commentLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 7
        return stack
    }()

    private lazy var shareButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "post.action.share".localized
        config.baseForegroundColor = ILColors.link
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = ILTypography.chip
            return outgoing
        }
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(handleShareTap), for: .touchUpInside)
        return button
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
        layer.cornerRadius = ILMetrics.radiusCardMedium
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor

        let authorText = UIStackView(arrangedSubviews: [authorLabel, metaLabel])
        authorText.axis = .vertical
        authorText.spacing = 2

        let authorRow = UIStackView(arrangedSubviews: [avatarView, authorText, UIView()])
        authorRow.axis = .horizontal
        authorRow.alignment = .center
        authorRow.spacing = ILMetrics.rowSpacing + 2

        NSLayoutConstraint.activate([
            commentGlyph.widthAnchor.constraint(equalToConstant: Layout.glyphSize),
            commentGlyph.heightAnchor.constraint(equalToConstant: Layout.glyphSize)
        ])

        let engagementRow = UIStackView(
            arrangedSubviews: [likeButton, commentStack, UIView(), shareButton]
        )
        engagementRow.axis = .horizontal
        engagementRow.alignment = .center
        engagementRow.spacing = ILMetrics.spaceStandard + 2

        let contentStack = UIStackView(
            arrangedSubviews: [authorRow, bodyLabel, footerDivider, engagementRow]
        )
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 0
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.setCustomSpacing(ILMetrics.spaceStandard, after: authorRow)
        contentStack.setCustomSpacing(ILMetrics.spaceStandard, after: bodyLabel)
        contentStack.setCustomSpacing(ILMetrics.spaceStandard, after: footerDivider)
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: Layout.padding),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.padding),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.padding),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.padding),

            footerDivider.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    // MARK: - Configure
    func configure(with model: ILPostStateModel) {
        avatarView.initials = model.authorInitials
        avatarView.tone = Self.mapTone(model.authorTone)
        authorLabel.text = model.authorName
        metaLabel.text = model.metaText
        bodyLabel.attributedText = ILTypography.makeParagraph(
            text: model.body,
            font: ILTypography.postBody,
            color: ILColors.inkStrong,
            cssLineHeight: 1.8
        )

        let likeColor = model.isLiked ? ILColors.gold : ILColors.inkTertiary
        likeButton.configuration?.title = model.likeCountText
        likeButton.configuration?.baseForegroundColor = likeColor
        commentLabel.text = model.commentCountText
    }

    /// Map tone Foundation-safe (`ILPostAuthorTone`) sang token màu UIKit (`ILColors.Tone`).
    private static func mapTone(_ tone: ILPostAuthorTone) -> ILColors.Tone {
        switch tone {
        case .gold: return .gold
        case .green: return .green
        case .rose: return .rose
        }
    }

    /// Hình giọt "tán thán" 9×9 — bo tròn 3 góc, sắc góc trên-phải (khớp `border-radius: 50% 0
    /// 50% 50%`). Render dạng template để tint theo trạng thái liked.
    private static func makeLikeGlyphImage() -> UIImage {
        let size = Layout.glyphSize
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { _ in
            let path = UIBezierPath(
                roundedRect: CGRect(x: 0, y: 0, width: size, height: size),
                byRoundingCorners: [.topLeft, .bottomLeft, .bottomRight],
                cornerRadii: CGSize(width: size / 2, height: size / 2)
            )
            UIColor.black.setFill()
            path.fill()
        }
        return image.withRenderingMode(.alwaysTemplate)
    }

    // `layer.borderColor` là CGColor tĩnh, không tự đảo theo trait — refresh thủ công khi đổi
    // light/dark.
    private func registerForAppearanceChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.layer.borderColor = ILColors.border.cgColor
            self.commentGlyph.layer.borderColor = ILColors.inkMuted.cgColor
        }
    }

    // MARK: - Actions
    @objc private func handleLikeTap() {
        onLikeTap?()
    }

    @objc private func handleShareTap() {
        onShareTap?()
    }
}
