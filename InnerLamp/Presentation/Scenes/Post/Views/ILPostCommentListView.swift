//
//  ILPostCommentListView.swift
//  InnerLamp
//

import UIKit

/// Mục bình luận của màn Bài đăng đạo tràng: tiêu đề "N lời chia sẻ" + nhãn sắp xếp "Mới nhất",
/// rồi danh sách thẻ bình luận (`ILPostCommentView`), bình luận trả lời thụt 22px. Biết
/// `ILPostCommentModel` nên thuộc riêng màn Bài đăng đạo tràng.
final class ILPostCommentListView: UIView {

    // MARK: - Properties
    var comments: [ILPostCommentModel] = [] {
        didSet { rebuildRows() }
    }

    var headerTitle: String = "" {
        didSet { headerLabel.text = headerTitle }
    }

    // MARK: - UI Elements
    private lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.bodyMedium
        label.textColor = ILColors.ink
        return label
    }()

    private lazy var sortLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.inkSubtle
        label.text = "post.comments.sort".localized
        return label
    }()

    private lazy var headerRow: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [headerLabel, UIView(), sortLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        return stack
    }()

    private let rowsStack = UIStackView()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        headerRow.translatesAutoresizingMaskIntoConstraints = false

        rowsStack.axis = .vertical
        rowsStack.spacing = ILMetrics.rowSpacing + 2
        rowsStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(headerRow)
        addSubview(rowsStack)

        NSLayoutConstraint.activate([
            headerRow.topAnchor.constraint(equalTo: topAnchor),
            headerRow.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerRow.trailingAnchor.constraint(equalTo: trailingAnchor),

            rowsStack.topAnchor.constraint(equalTo: headerRow.bottomAnchor, constant: ILMetrics.rowSpacing + 2),
            rowsStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            rowsStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            rowsStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func rebuildRows() {
        rowsStack.arrangedSubviews.forEach {
            rowsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for comment in comments {
            let card = ILPostCommentView(model: comment)

            // Bình luận trả lời thụt trái 22px — wrap trong container trong suốt để thẻ con không
            // bị stack kéo giãn full-width (khớp `margin-left: 22px` của prototype).
            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(card)
            NSLayoutConstraint.activate([
                card.topAnchor.constraint(equalTo: container.topAnchor),
                card.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                card.leadingAnchor.constraint(
                    equalTo: container.leadingAnchor,
                    constant: comment.depth == 1 ? ILMetrics.commentIndent : 0
                ),
                card.trailingAnchor.constraint(equalTo: container.trailingAnchor)
            ])

            rowsStack.addArrangedSubview(container)
        }
    }
}

/// 1 thẻ bình luận: avatar + tên + thời gian, nội dung, hàng "Tán thán N" / "Trả lời".
private final class ILPostCommentView: UIView {

    private enum Layout {
        static let avatarSize: CGFloat = 34
    }

    private let model: ILPostCommentModel

    init(model: ILPostCommentModel) {
        self.model = model
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardSmall
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.layer.borderColor = ILColors.border.cgColor
        }

        let avatarView = ILAvatarView(
            initials: model.authorInitials,
            tone: Self.mapTone(model.tone),
            size: Layout.avatarSize
        )
        avatarView.translatesAutoresizingMaskIntoConstraints = false

        let nameLabel = UILabel()
        nameLabel.font = ILTypography.bodySmallMedium
        nameLabel.textColor = ILColors.ink
        nameLabel.text = model.authorName

        let timeLabel = UILabel()
        timeLabel.font = ILTypography.caption
        timeLabel.textColor = ILColors.inkMuted
        timeLabel.text = model.timeText

        let nameRow = UIStackView(arrangedSubviews: [nameLabel, timeLabel])
        nameRow.axis = .horizontal
        nameRow.alignment = .firstBaseline
        nameRow.spacing = ILMetrics.spaceSmall

        let textLabel = UILabel()
        textLabel.numberOfLines = 0
        textLabel.attributedText = ILTypography.makeParagraph(
            text: model.text,
            font: ILTypography.bodySmall,
            color: ILColors.inkSecondary,
            cssLineHeight: 1.7
        )

        let actionsRow = UIStackView(
            arrangedSubviews: [
                makeActionLabel(model.likeText),
                makeActionLabel("post.comments.action.reply".localized),
                UIView()
            ]
        )
        actionsRow.axis = .horizontal
        actionsRow.spacing = ILMetrics.spaceStandard

        let textStack = UIStackView(arrangedSubviews: [nameRow, textLabel, actionsRow])
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = ILMetrics.spaceSmall - 3
        textStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(avatarView)
        addSubview(textStack)

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            avatarView.topAnchor.constraint(equalTo: topAnchor, constant: 15),
            avatarView.widthAnchor.constraint(equalToConstant: Layout.avatarSize),
            avatarView.heightAnchor.constraint(equalToConstant: Layout.avatarSize),

            textStack.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: ILMetrics.rowSpacing + 2),
            textStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            textStack.topAnchor.constraint(equalTo: topAnchor, constant: 15),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -15)
        ])
    }

    private func makeActionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.font = ILTypography.labelMedium
        label.textColor = ILColors.inkSubtle
        label.text = text
        return label
    }

    /// Map tone Foundation-safe (`ILPostAuthorTone`) sang token màu UIKit (`ILColors.Tone`).
    private static func mapTone(_ tone: ILPostAuthorTone) -> ILColors.Tone {
        switch tone {
        case .gold: return .gold
        case .green: return .green
        case .rose: return .rose
        }
    }
}
