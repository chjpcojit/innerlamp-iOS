//
//  ILProfileHeaderView.swift
//  InnerLamp
//

import UIKit

/// Đầu trang màn Tôi (khớp `isProfile` trong design handoff): ảnh bìa 250pt tràn cạnh với nút pill
/// "Sửa hồ sơ" nổi trên ảnh, avatar tròn 84pt đè lên mép dưới ảnh bìa, tên + dòng "Pháp danh … ·
/// Phật tử tại gia" bên phải avatar.
///
/// View này nằm đầu nội dung cuộn (không ghim). Màn chủ chuyển `contentOffset.y` vào
/// `update(contentOffsetY:)`:
/// - kéo xuống (offset < 0): ảnh bìa phóng to từ mép trên, mép trên luôn dính đỉnh màn hình;
/// - cuộn lên (offset > 0): ảnh bìa trượt xuống 0.45× quãng cuộn (parallax) và bị cắt trong khung bìa.
///
/// Ảnh bìa hiện là nền gradient mặc định; `setCoverImage(_:)` nhận ảnh khi có nguồn (xem
/// `Docs/Assumptions/Profile`). Biết `ILProfileHeaderModel` nên thuộc riêng màn Tôi.
final class ILProfileHeaderView: UIView {

    // MARK: - Constants
    private enum Layout {
        static let coverHeight: CGFloat = 250
        static let fadeHeight: CGFloat = 90
        static let avatarSize: CGFloat = 84
        static let avatarOverlap: CGFloat = 44
        static let avatarBorderWidth: CGFloat = 3
        static let avatarRingWidth: CGFloat = 1
        static let textBottomInset: CGFloat = 6
        static let pillTopInset: CGFloat = 8
        static let parallaxFactor: CGFloat = 0.45
    }

    // MARK: - Properties
    var onEditTapped: (() -> Void)?

    // MARK: - UI Elements
    private let coverContainer = UIView()
    /// Gradient + ảnh bìa: phần được phóng to / trượt khi cuộn.
    private let coverMedia = UIView()
    private let coverGradient = CAGradientLayer()
    private let fadeGradient = CAGradientLayer()

    private lazy var coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private let fadeView = UIView()
    private let avatarGradient = CAGradientLayer()

    private lazy var avatarView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Layout.avatarSize / 2
        view.layer.borderWidth = Layout.avatarBorderWidth
        avatarGradient.startPoint = CGPoint(x: 0.25, y: 0)
        avatarGradient.endPoint = CGPoint(x: 0.75, y: 1)
        avatarGradient.cornerRadius = Layout.avatarSize / 2
        view.layer.insertSublayer(avatarGradient, at: 0)
        return view
    }()

    private lazy var avatarRingView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = (Layout.avatarSize + Layout.avatarRingWidth * 2) / 2
        view.layer.borderWidth = Layout.avatarRingWidth
        view.isUserInteractionEnabled = false
        return view
    }()

    private lazy var initialLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.displayLarge
        label.textColor = ILColors.goldDeep
        label.textAlignment = .center
        return label
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.displayMedium
        label.textColor = ILColors.ink
        label.numberOfLines = 0
        label.accessibilityTraits = .header
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private lazy var editButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.title = "profile.header.edit".localized
        configuration.baseForegroundColor = ILColors.inkOnDark
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = ILTypography.subheadMedium
            return attributes
        }
        let button = UIButton(configuration: configuration)
        button.backgroundColor = ILColors.coverPill
        button.layer.cornerRadius = ILMetrics.radiusPill
        button.clipsToBounds = true
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.addTarget(self, action: #selector(handleEditTapped), for: .touchUpInside)
        return button
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
        coverGradient.frame = coverMedia.bounds
        fadeGradient.frame = fadeView.bounds
        avatarGradient.frame = avatarView.bounds
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = .clear

        coverMedia.layer.insertSublayer(coverGradient, at: 0)
        coverGradient.startPoint = CGPoint(x: 0.5, y: 0)
        coverGradient.endPoint = CGPoint(x: 0.5, y: 1)
        fadeView.layer.insertSublayer(fadeGradient, at: 0)
        fadeView.isUserInteractionEnabled = false

        initialLabel.translatesAutoresizingMaskIntoConstraints = false
        avatarView.addSubview(initialLabel)

        let textStack = UIStackView(arrangedSubviews: [nameLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.translatesAutoresizingMaskIntoConstraints = false

        // Text sits Layout.textBottomInset above the avatar's bottom edge (flex-end row in the design).
        let textHolder = UIView()
        textHolder.addSubview(textStack)
        NSLayoutConstraint.activate([
            textStack.topAnchor.constraint(equalTo: textHolder.topAnchor),
            textStack.leadingAnchor.constraint(equalTo: textHolder.leadingAnchor),
            textStack.trailingAnchor.constraint(equalTo: textHolder.trailingAnchor),
            textStack.bottomAnchor.constraint(equalTo: textHolder.bottomAnchor, constant: -Layout.textBottomInset)
        ])

        let rowStack = UIStackView(arrangedSubviews: [avatarView, textHolder])
        rowStack.axis = .horizontal
        rowStack.alignment = .bottom
        rowStack.spacing = ILMetrics.spaceMedium + 2

        [coverContainer, rowStack, avatarRingView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        [coverMedia, coverImageView, fadeView, editButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        coverContainer.addSubview(coverMedia)
        coverMedia.addSubview(coverImageView)
        coverContainer.addSubview(fadeView)
        coverContainer.addSubview(editButton)

        NSLayoutConstraint.activate([
            coverContainer.topAnchor.constraint(equalTo: topAnchor),
            coverContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            coverContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            coverContainer.heightAnchor.constraint(equalToConstant: Layout.coverHeight),

            coverMedia.topAnchor.constraint(equalTo: coverContainer.topAnchor),
            coverMedia.leadingAnchor.constraint(equalTo: coverContainer.leadingAnchor),
            coverMedia.trailingAnchor.constraint(equalTo: coverContainer.trailingAnchor),
            coverMedia.bottomAnchor.constraint(equalTo: coverContainer.bottomAnchor),

            coverImageView.topAnchor.constraint(equalTo: coverMedia.topAnchor),
            coverImageView.leadingAnchor.constraint(equalTo: coverMedia.leadingAnchor),
            coverImageView.trailingAnchor.constraint(equalTo: coverMedia.trailingAnchor),
            coverImageView.bottomAnchor.constraint(equalTo: coverMedia.bottomAnchor),

            fadeView.leadingAnchor.constraint(equalTo: coverContainer.leadingAnchor),
            fadeView.trailingAnchor.constraint(equalTo: coverContainer.trailingAnchor),
            fadeView.bottomAnchor.constraint(equalTo: coverContainer.bottomAnchor),
            fadeView.heightAnchor.constraint(equalToConstant: Layout.fadeHeight),

            editButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Layout.pillTopInset),
            editButton.trailingAnchor.constraint(equalTo: coverContainer.trailingAnchor, constant: -ILMetrics.screenHorizontal),

            avatarView.widthAnchor.constraint(equalToConstant: Layout.avatarSize),
            avatarView.heightAnchor.constraint(equalToConstant: Layout.avatarSize),
            initialLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            initialLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            avatarRingView.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarRingView.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            avatarRingView.widthAnchor.constraint(equalToConstant: Layout.avatarSize + Layout.avatarRingWidth * 2),
            avatarRingView.heightAnchor.constraint(equalToConstant: Layout.avatarSize + Layout.avatarRingWidth * 2),

            rowStack.topAnchor.constraint(equalTo: coverContainer.bottomAnchor, constant: -Layout.avatarOverlap),
            rowStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.screenHorizontal),
            rowStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.screenHorizontal),
            rowStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Configure
    func configure(with model: ILProfileHeaderModel) {
        initialLabel.text = model.initial
        nameLabel.text = model.fullName
        subtitleLabel.attributedText = makeSubtitle(model)
    }

    /// Ảnh bìa của người dùng; nil trở lại nền gradient mặc định.
    // @ai: assumption — see Docs/Assumptions/Profile/AS-Profile-001-cover-image-source.md
    func setCoverImage(_ image: UIImage?) {
        coverImageView.image = image
    }

    // MARK: - Scroll
    /// Gọi từ `scrollViewDidScroll` với `contentOffset.y` (scroll view phải để
    /// `contentInsetAdjustmentBehavior = .never` và header nằm ở đầu nội dung).
    func update(contentOffsetY offsetY: CGFloat) {
        if offsetY < 0 {
            // Pull down: scale from the top edge so the top stays glued to the screen top while the
            // bottom follows the content (same maths as `ILStretchyHeaderView`).
            coverContainer.clipsToBounds = false
            let stretch = -offsetY
            let scale = (Layout.coverHeight + stretch) / Layout.coverHeight
            coverMedia.transform = CGAffineTransform(scaleX: scale, y: scale)
                .translatedBy(x: 0, y: -stretch / (2 * scale))
        } else {
            coverContainer.clipsToBounds = true
            coverMedia.transform = CGAffineTransform(translationX: 0, y: (offsetY * Layout.parallaxFactor).rounded())
        }
    }

    private func makeSubtitle(_ model: ILProfileHeaderModel) -> NSAttributedString {
        let text = NSMutableAttributedString(
            string: model.subtitle,
            attributes: [.font: ILTypography.subhead, .foregroundColor: ILColors.inkTertiary]
        )
        if let highlight = model.subtitleHighlight {
            let range = (model.subtitle as NSString).range(of: highlight)
            if range.location != NSNotFound {
                text.addAttribute(.foregroundColor, value: ILColors.link, range: range)
            }
        }
        return text
    }

    // `CGColor` tĩnh (viền, gradient) không tự đảo theo trait — dựng lại khi đổi light/dark.
    private func applyDynamicColors() {
        let canvas = ILColors.canvas.resolvedColor(with: traitCollection)
        coverGradient.colors = [
            ILColors.canvasWarmEnd1.resolvedColor(with: traitCollection).cgColor,
            ILColors.tint.resolvedColor(with: traitCollection).cgColor
        ]
        fadeGradient.colors = [canvas.withAlphaComponent(0).cgColor, canvas.cgColor]
        avatarGradient.colors = [
            ILColors.canvasWarmEnd1.resolvedColor(with: traitCollection).cgColor,
            ILColors.tint.resolvedColor(with: traitCollection).cgColor
        ]
        avatarView.layer.borderColor = canvas.cgColor
        avatarRingView.layer.borderColor = ILColors.goldBorder.cgColor
    }

    private func registerForAppearanceChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.applyDynamicColors()
        }
    }

    @objc private func handleEditTapped() {
        onEditTapped?()
    }
}
