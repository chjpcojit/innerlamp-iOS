//
//  ILMeditationHubGuidedSectionView.swift
//  InnerLamp
//

import UIKit

/// Khối "Thiền có dẫn · quý thầy hướng dẫn" của màn Thiền định: eyebrow + danh sách thẻ bài thiền
/// dẫn (phương pháp, tên bài, giảng sư · số phút, nút phát, mô tả, nút Tải về). Biết
/// `ILMeditationHubGuidedModel` nên thuộc riêng màn này.
final class ILMeditationHubGuidedSectionView: UIView {

    // MARK: - Properties
    var onSessionTapped: ((String) -> Void)?
    var onDownloadTapped: ((String) -> Void)?

    // MARK: - UI Elements
    /// Design `medhub` viết eyebrow inline (9.5px / letter-spacing .16em / `--il-ink-45`), khác
    /// `ILSectionEyebrowView` dùng chung (10px / .14em / .42) nên dùng nhãn riêng ở đây.
    private lazy var eyebrow: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        return label
    }()
    private lazy var cardsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = ILMetrics.rowSpacing
        return stack
    }()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    func configure(sectionTitle: String, sessions: [ILMeditationHubGuidedModel]) {
        eyebrow.attributedText = ILTypography.makeAttributedString(
            text: sectionTitle.uppercased(),
            font: ILTypography.eyebrowSmall,
            color: ILColors.inkSubtle,
            letterSpacingEm: 0.16
        )
        rebuild(sessions: sessions)
    }

    // MARK: - Setup
    private func setupViews() {
        let contentStack = UIStackView(arrangedSubviews: [eyebrow, cardsStack])
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = ILMetrics.rowSpacing
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    private func rebuild(sessions: [ILMeditationHubGuidedModel]) {
        cardsStack.arrangedSubviews.forEach {
            cardsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for session in sessions {
            let card = GuidedCardView(model: session)
            card.onSessionTap = { [weak self] in self?.onSessionTapped?(session.id) }
            card.onDownloadTap = { [weak self] in self?.onDownloadTapped?(session.id) }
            cardsStack.addArrangedSubview(card)
        }
    }
}

// MARK: - Guided Card

/// 1 thẻ bài thiền dẫn: vùng trên (phương pháp + tên + giảng sư · số phút + nút phát) chạm để bắt
/// đầu, hàng dưới (mô tả + pill Tải về) tách bằng hairline.
private final class GuidedCardView: UIView {

    private enum Layout {
        static let cornerRadius: CGFloat = ILMetrics.radiusCardRegular
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 14
        /// Khoảng cách giữa khối chữ và nút phát (`gap:12px`).
        static let headerPlaySpacing: CGFloat = 12
        /// Khoảng cách từ khối chữ lên hairline (`margin-top:12px`).
        static let footerTopSpacing: CGFloat = 12
        /// Khoảng cách từ hairline xuống hàng chân thẻ (`padding-top:10px`).
        static let separatorTopSpacing: CGFloat = 10
        /// Khoảng cách giữa mô tả và pill Tải về (`gap:8px`).
        static let footerSpacing: CGFloat = ILMetrics.spaceSmall
        static let playButtonSize: CGFloat = 40
    }

    var onSessionTap: (() -> Void)?
    var onDownloadTap: (() -> Void)?

    private lazy var openArea: UIControl = {
        let control = UIControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        control.isAccessibilityElement = true
        control.accessibilityTraits = .button
        return control
    }()

    private lazy var methodLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        return label
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        return label
    }()

    private lazy var metaLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.numberOfLines = 1
        return label
    }()

    private lazy var summaryLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.label
        label.numberOfLines = 0
        // Mô tả nhường chỗ cho pill: co lại để xuống dòng thay vì ép pill "Tải về" hẹp đi. Pill tự
        // khai báo `intrinsicContentSize` nên stack luôn biết kích thước thật của nó.
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private lazy var separator: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var playButton: ILPlayPauseButton = {
        let button = ILPlayPauseButton(
            diameter: Layout.playButtonSize,
            glyphColor: ILColors.canvas,
            fillColor: ILColors.ink,
            // Design: tam giác CSS 10×12, `margin-left:3px` trong vòng tròn căn giữa → lệch +1.5pt.
            playGlyphSize: CGSize(width: 10, height: 12),
            playGlyphOffsetX: 1.5
        )
        // Added with `addSubview` (not a stack view), so autoresizing must be turned off here —
        // otherwise its zero-frame autoresizing constraints fight the 40pt size + edge anchors,
        // Auto Layout drops constraints and the button and the text block collapse to zero width.
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isAccessibilityElement = false
        return button
    }()

    private lazy var downloadButton: DownloadPillButton = {
        let button = DownloadPillButton()
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()

    init(model: ILMeditationHubGuidedModel) {
        super.init(frame: .zero)
        setupViews()

        methodLabel.attributedText = ILTypography.makeAttributedString(
            text: model.method.uppercased(),
            font: ILTypography.eyebrowSmall,
            color: ILColors.link,
            letterSpacingEm: 0.12
        )
        // Design `font:400 16px/1.35 Lora`.
        nameLabel.attributedText = ILTypography.makeParagraph(
            text: model.name,
            font: ILTypography.serifCardTitle,
            color: ILColors.ink,
            cssLineHeight: 1.35
        )
        metaLabel.text = model.metaText
        // Design `font:400 11px/1.5`, màu `--il-ink-45`.
        summaryLabel.attributedText = ILTypography.makeParagraph(
            text: model.summary,
            font: ILTypography.label,
            color: ILColors.inkSubtle,
            cssLineHeight: 1.5
        )
        downloadButton.title = model.downloadTitle
        downloadButton.isDownloaded = model.isDownloaded
        openArea.accessibilityLabel = model.accessibilityLabel
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        layer.cornerRadius = Layout.cornerRadius
        layer.borderWidth = 1

        let textStack = UIStackView(arrangedSubviews: [methodLabel, nameLabel, metaLabel])
        textStack.axis = .vertical
        // `.fill` pins every label to the stack width so the multi-line name wraps instead of
        // resolving to an ambiguous width.
        textStack.alignment = .fill
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false

        openArea.addTarget(self, action: #selector(handleSessionTap), for: .touchUpInside)

        playButton.onTap = { [weak self] in self?.onSessionTap?() }

        openArea.addSubview(textStack)
        openArea.addSubview(playButton)

        NSLayoutConstraint.activate([
            textStack.topAnchor.constraint(equalTo: openArea.topAnchor),
            textStack.bottomAnchor.constraint(equalTo: openArea.bottomAnchor),
            textStack.leadingAnchor.constraint(equalTo: openArea.leadingAnchor),

            playButton.leadingAnchor.constraint(equalTo: textStack.trailingAnchor, constant: Layout.headerPlaySpacing),
            playButton.trailingAnchor.constraint(equalTo: openArea.trailingAnchor),
            // Design canh nút phát theo **đỉnh** khối chữ (`display:flex` mặc định stretch → nút
            // cao cố định nằm ở flex-start), không phải canh giữa.
            playButton.topAnchor.constraint(equalTo: openArea.topAnchor),
            playButton.bottomAnchor.constraint(lessThanOrEqualTo: openArea.bottomAnchor)
        ])

        downloadButton.onTap = { [weak self] in self?.onDownloadTap?() }

        let footerStack = UIStackView(arrangedSubviews: [summaryLabel, downloadButton])
        footerStack.axis = .horizontal
        footerStack.alignment = .center
        footerStack.spacing = Layout.footerSpacing

        let cardStack = UIStackView(arrangedSubviews: [openArea, separator, footerStack])
        cardStack.axis = .vertical
        cardStack.alignment = .fill
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        cardStack.setCustomSpacing(Layout.footerTopSpacing, after: openArea)
        cardStack.setCustomSpacing(Layout.separatorTopSpacing, after: separator)
        addSubview(cardStack)

        NSLayoutConstraint.activate([
            separator.heightAnchor.constraint(equalToConstant: 1),

            cardStack.topAnchor.constraint(equalTo: topAnchor, constant: Layout.verticalPadding),
            cardStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.verticalPadding),
            cardStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalPadding),
            cardStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalPadding)
        ])

        updateAppearance()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: GuidedCardView, _) in
            view.updateAppearance()
        }
    }

    private func updateAppearance() {
        backgroundColor = ILColors.surface
        layer.borderColor = ILColors.border.cgColor
        // `nameLabel` dùng attributed text với màu động (`ILColors.ink`) nên tự đổi theo theme.
        metaLabel.textColor = ILColors.inkTertiary
        // `summaryLabel` dùng attributed text với màu động (`ILColors.inkSubtle`) nên tự đổi theo theme.
        separator.backgroundColor = ILColors.borderSoft
    }

    @objc private func handleSessionTap() {
        onSessionTap?()
    }
}

// MARK: - Download Pill

/// Pill "Tải về" / "✓ Đã tải về" ở chân thẻ thiền dẫn.
private final class DownloadPillButton: UIControl {

    /// `padding:6px 12px` trong design handoff.
    private enum Layout {
        static let verticalInset: CGFloat = 6
        static let horizontalInset: CGFloat = 12
    }

    var title: String = "" {
        didSet {
            titleLabel.text = title
            invalidateIntrinsicContentSize()
        }
    }

    var isDownloaded: Bool = false {
        didSet { updateAppearance() }
    }

    var onTap: (() -> Void)?

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.labelMedium
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Pill là `UIControl` nên không có intrinsic size sẵn: khai báo theo nhãn bên trong để stack
    /// ngang (mô tả + pill) luôn phân bổ được chỗ cho pill trước khi mô tả xuống dòng.
    override var intrinsicContentSize: CGSize {
        let labelSize = titleLabel.intrinsicContentSize
        return CGSize(
            width: labelSize.width + Layout.horizontalInset * 2,
            height: labelSize.height + Layout.verticalInset * 2
        )
    }

    private func setupViews() {
        isAccessibilityElement = true
        accessibilityTraits = .button

        layer.cornerRadius = ILMetrics.radiusPill
        layer.borderWidth = 1

        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: Layout.verticalInset),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.verticalInset),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalInset),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalInset)
        ])

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        updateAppearance()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: DownloadPillButton, _) in
            view.updateAppearance()
        }
    }

    private func updateAppearance() {
        if isDownloaded {
            backgroundColor = ILColors.greenTint
            layer.borderColor = ILColors.greenBorder.cgColor
            titleLabel.textColor = ILColors.greenText
        } else {
            backgroundColor = .clear
            layer.borderColor = ILColors.borderPill.cgColor
            titleLabel.textColor = ILColors.ink
        }
    }

    @objc private func handleTap() {
        onTap?()
    }
}
