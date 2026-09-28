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
    private lazy var eyebrow = ILSectionEyebrowView()
    private let cardsStack = UIStackView()

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
        eyebrow.title = sectionTitle
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

        cardsStack.axis = .vertical
        cardsStack.alignment = .fill
        cardsStack.spacing = ILMetrics.rowSpacing

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
        static let footerTopSpacing: CGFloat = 12
        static let separatorTopSpacing: CGFloat = 10
        static let playButtonSize: CGFloat = 40
    }

    var onSessionTap: (() -> Void)?
    var onDownloadTap: (() -> Void)?

    private let openArea = UIControl()
    private let methodLabel = UILabel()
    private let nameLabel = UILabel()
    private let metaLabel = UILabel()
    private let summaryLabel = UILabel()
    private let separator = UIView()
    private let playButton = ILPlayPauseButton(
        diameter: Layout.playButtonSize,
        glyphColor: ILColors.canvas,
        fillColor: ILColors.ink
    )
    private lazy var downloadButton = DownloadPillButton()

    init(model: ILMeditationHubGuidedModel) {
        super.init(frame: .zero)
        setupViews()

        methodLabel.attributedText = ILTypography.makeAttributedString(
            text: model.method.uppercased(),
            font: ILTypography.eyebrowSmall,
            color: ILColors.link,
            letterSpacingEm: 0.12
        )
        nameLabel.text = model.name
        metaLabel.text = model.metaText
        summaryLabel.text = model.summary
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

        methodLabel.numberOfLines = 1
        nameLabel.font = ILTypography.serifCardTitle
        nameLabel.numberOfLines = 2
        metaLabel.font = ILTypography.subhead
        metaLabel.numberOfLines = 1

        let textStack = UIStackView(arrangedSubviews: [methodLabel, nameLabel, metaLabel])
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false

        openArea.translatesAutoresizingMaskIntoConstraints = false
        openArea.isAccessibilityElement = true
        openArea.accessibilityTraits = .button
        openArea.addTarget(self, action: #selector(handleSessionTap), for: .touchUpInside)

        playButton.isAccessibilityElement = false
        playButton.onTap = { [weak self] in self?.onSessionTap?() }

        openArea.addSubview(textStack)
        openArea.addSubview(playButton)

        NSLayoutConstraint.activate([
            textStack.topAnchor.constraint(equalTo: openArea.topAnchor),
            textStack.bottomAnchor.constraint(equalTo: openArea.bottomAnchor),
            textStack.leadingAnchor.constraint(equalTo: openArea.leadingAnchor),

            playButton.leadingAnchor.constraint(equalTo: textStack.trailingAnchor, constant: 12),
            playButton.trailingAnchor.constraint(equalTo: openArea.trailingAnchor),
            playButton.centerYAnchor.constraint(equalTo: openArea.centerYAnchor),
            playButton.topAnchor.constraint(greaterThanOrEqualTo: openArea.topAnchor),
            playButton.bottomAnchor.constraint(lessThanOrEqualTo: openArea.bottomAnchor)
        ])

        summaryLabel.font = ILTypography.label
        summaryLabel.numberOfLines = 0

        downloadButton.onTap = { [weak self] in self?.onDownloadTap?() }

        let footerStack = UIStackView(arrangedSubviews: [summaryLabel, downloadButton])
        footerStack.axis = .horizontal
        footerStack.alignment = .center
        footerStack.spacing = ILMetrics.spaceSmall

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
        nameLabel.textColor = ILColors.ink
        metaLabel.textColor = ILColors.inkTertiary
        summaryLabel.textColor = ILColors.inkMuted
        separator.backgroundColor = ILColors.borderSoft
    }

    @objc private func handleSessionTap() {
        onSessionTap?()
    }
}

// MARK: - Download Pill

/// Pill "Tải về" / "✓ Đã tải về" ở chân thẻ thiền dẫn.
private final class DownloadPillButton: UIControl {

    var title: String = "" {
        didSet { titleLabel.text = title }
    }

    var isDownloaded: Bool = false {
        didSet { updateAppearance() }
    }

    var onTap: (() -> Void)?

    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        isAccessibilityElement = true
        accessibilityTraits = .button

        layer.cornerRadius = ILMetrics.radiusPill
        layer.borderWidth = 1

        titleLabel.font = ILTypography.labelMedium
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
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
            layer.borderColor = ILColors.borderStrong.cgColor
            titleLabel.textColor = ILColors.ink
        }
    }

    @objc private func handleTap() {
        onTap?()
    }
}
