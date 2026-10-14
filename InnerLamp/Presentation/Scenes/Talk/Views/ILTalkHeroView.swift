//
//  ILTalkHeroView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 27/9/26.
//

import UIKit

/// Hero màn Pháp thoại — khớp `isTalk` trong design handoff: nền `--il-th-bg` (đổi theo
/// light/dark), quầng sáng vàng ở góc trên phải, eyebrow chữ hoa, tiêu đề Lora, avatar chữ cái
/// giảng sư + dòng meta. Chỉ nhận chuỗi nên không phụ thuộc nội dung cụ thể của 1 bài pháp thoại.
///
/// Header (nút ‹) không nằm ở đây mà là `ILNavBar` trong suốt đè lên trên — xem
/// `ILTalkViewController`.
final class ILTalkHeroView: UIView {

    private enum Layout {
        static let horizontalInset: CGFloat = 22
        static let bottomInset: CGFloat = 34
        static let avatarSize: CGFloat = 32
        static let glowDiameter: CGFloat = 230
    }

    // MARK: - Properties
    /// Khoảng cách từ mép trên màn hình tới phần nội dung hero (bằng safe area top + clearance
    /// cho nav bar) — set từ `ILTalkViewController`.
    var topInset: CGFloat = 0 {
        didSet { contentTopConstraint?.constant = topInset + 62 }
    }

    // MARK: - UI Elements
    private let gradientLayer = CAGradientLayer()
    private let glowLayer = CAGradientLayer()

    private lazy var eyebrowLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        return label
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    // Avatar chữ cái giảng sư — nền `--il-feat-glow`, chữ `--il-hero-acc`.
    private lazy var avatarView: UIView = {
        let view = UIView()
        view.backgroundColor = ILColors.featGlow
        view.layer.cornerRadius = Layout.avatarSize / 2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private lazy var avatarLetterLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.scriptureDescription
        label.textAlignment = .center
        label.textColor = ILColors.heroAccent
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var metaLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.bodySmall
        label.numberOfLines = 0
        return label
    }()

    private lazy var metaRow: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [avatarView, metaLabel])
        stack.axis = .horizontal
        stack.spacing = ILMetrics.rowSpacing
        stack.alignment = .center
        return stack
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [eyebrowLabel, titleLabel, metaRow])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = ILMetrics.rowSpacing
        stack.setCustomSpacing(16, after: titleLabel)
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private var contentTopConstraint: NSLayoutConstraint?

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration
    func configure(eyebrow: String, title: String, initial: String, metaText: String) {
        eyebrowLabel.attributedText = ILTypography.makeAttributedString(
            text: eyebrow,
            font: ILTypography.eyebrowSmall,
            color: ILColors.heroAccent,
            letterSpacingEm: 0.16
        )
        titleLabel.attributedText = ILTypography.makeParagraph(
            text: title,
            font: ILTypography.talkTitle,
            color: ILColors.templeHeaderInk,
            cssLineHeight: 1.32
        )
        avatarLetterLabel.text = initial
        metaLabel.text = metaText
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = true

        // Nền `--il-th-bg` (hai chặng gradient, đổi theo light/dark) — dừng ở mép dưới, không tan
        // vào `canvas` như hero Trang chùa.
        gradientLayer.colors = [ILColors.templeHeaderTop.cgColor, ILColors.templeHeaderMid.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)

        // Quầng sáng vàng ở góc trên phải (`--il-th-glow`).
        glowLayer.type = .radial
        glowLayer.colors = [ILColors.templeHeaderGlow.cgColor, ILColors.goldGlowClear.cgColor]
        glowLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        glowLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        glowLayer.cornerRadius = Layout.glowDiameter / 2
        layer.insertSublayer(glowLayer, above: gradientLayer)

        avatarView.addSubview(avatarLetterLabel)
        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: Layout.avatarSize),
            avatarView.heightAnchor.constraint(equalToConstant: Layout.avatarSize),
            avatarLetterLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarLetterLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor)
        ])

        addSubview(contentStack)

        contentTopConstraint = contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 62)
        NSLayoutConstraint.activate([
            contentTopConstraint!,
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalInset),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalInset),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.bottomInset)
        ])

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILTalkHeroView, _) in
            view.applyColorAppearanceChange()
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        glowLayer.frame = CGRect(
            x: bounds.width - Layout.glowDiameter / 2 + 20,
            y: -Layout.glowDiameter / 4,
            width: Layout.glowDiameter,
            height: Layout.glowDiameter
        )
    }

    // `CAGradientLayer` màu là CGColor tĩnh, không tự đảo theo trait — resolve lại khi hệ thống
    // đổi light/dark (bộ `--il-th-*` có hai biến thể).
    private func applyColorAppearanceChange() {
        gradientLayer.colors = [
            ILColors.templeHeaderTop.resolvedColor(with: traitCollection).cgColor,
            ILColors.templeHeaderMid.resolvedColor(with: traitCollection).cgColor
        ]
        glowLayer.colors = [
            ILColors.templeHeaderGlow.resolvedColor(with: traitCollection).cgColor,
            ILColors.goldGlowClear.cgColor
        ]
    }
}
