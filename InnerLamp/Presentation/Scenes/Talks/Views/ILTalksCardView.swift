//
//  ILTalksCardView.swift
//  InnerLamp
//

import UIKit

/// 1 thẻ bài pháp thoại trong danh sách: ô icon theo hình thức (nghe / xem / đọc), eyebrow, tiêu
/// đề (Lora), dòng giảng sư · thời lượng và — với bài nghe dở — thanh tiến độ. Riêng cho màn `Talks`.
final class ILTalksCardView: UIControl {

    // MARK: - Layout
    private static let tileSize: CGFloat = 48
    private static let progressHeight: CGFloat = 3

    // MARK: - Properties
    var onTap: (() -> Void)?

    // MARK: - UI Elements
    private let tileView = UIView()
    private let iconView = UIImageView()
    private let eyebrowLabel = UILabel()
    private let titleLabel = UILabel()
    private let metaLabel = UILabel()
    private let progressBar = UIProgressView(progressViewStyle: .bar)
    private let progressLabel = UILabel()
    private let progressRow = UIStackView()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    func configure(with model: ILTalksItemModel) {
        switch model.mediaType {
        case .audio: iconView.image = ILIcons.talkAudio
        case .video: iconView.image = ILIcons.talkVideo
        case .text: iconView.image = ILIcons.talkText
        }
        eyebrowLabel.text = model.eyebrow
        titleLabel.text = model.title
        metaLabel.text = model.metaText
        progressRow.isHidden = model.progress <= 0
        progressBar.progress = Float(model.progress)
        progressLabel.text = model.progressText
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardRegular
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor

        tileView.backgroundColor = ILColors.Tone.rose.tintBackground
        tileView.layer.cornerRadius = ILMetrics.radiusInput
        tileView.isUserInteractionEnabled = false
        iconView.tintColor = ILColors.Tone.rose.textColor
        iconView.contentMode = .center
        iconView.translatesAutoresizingMaskIntoConstraints = false
        tileView.addSubview(iconView)

        eyebrowLabel.font = ILTypography.captionSmall
        eyebrowLabel.textColor = ILColors.link
        eyebrowLabel.numberOfLines = 0

        titleLabel.font = ILTypography.serifCardTitle
        titleLabel.textColor = ILColors.ink
        titleLabel.numberOfLines = 0

        metaLabel.font = ILTypography.subhead
        metaLabel.textColor = ILColors.inkTertiary
        metaLabel.numberOfLines = 0

        progressBar.progressTintColor = ILColors.goldDeep
        progressBar.trackTintColor = ILColors.border
        progressBar.layer.cornerRadius = Self.progressHeight / 2
        progressBar.clipsToBounds = true
        progressLabel.font = ILTypography.captionMedium
        progressLabel.textColor = ILColors.goldDeep
        progressLabel.setContentHuggingPriority(.required, for: .horizontal)
        progressRow.axis = .horizontal
        progressRow.alignment = .center
        progressRow.spacing = ILMetrics.spaceSmall
        progressRow.addArrangedSubview(progressBar)
        progressRow.addArrangedSubview(progressLabel)

        let textStack = UIStackView(arrangedSubviews: [eyebrowLabel, titleLabel, metaLabel, progressRow])
        textStack.axis = .vertical
        textStack.setCustomSpacing(4, after: eyebrowLabel)
        textStack.setCustomSpacing(ILMetrics.spaceSmall - 2, after: titleLabel)
        textStack.setCustomSpacing(ILMetrics.rowSpacing, after: metaLabel)

        let content = UIStackView(arrangedSubviews: [tileView, textStack])
        content.axis = .horizontal
        content.alignment = .top
        content.spacing = ILMetrics.spaceMedium
        content.isUserInteractionEnabled = false
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)

        NSLayoutConstraint.activate([
            tileView.widthAnchor.constraint(equalToConstant: Self.tileSize),
            tileView.heightAnchor.constraint(equalToConstant: Self.tileSize),
            iconView.centerXAnchor.constraint(equalTo: tileView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: tileView.centerYAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: Self.progressHeight),

            content.topAnchor.constraint(equalTo: topAnchor, constant: ILMetrics.spaceMedium),
            content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.spaceMedium),
            content.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.spaceMedium),
            content.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -ILMetrics.spaceMedium)
        ])

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILTalksCardView, _) in
            view.layer.borderColor = ILColors.border.cgColor
        }
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.7 : 1 }
    }

    @objc private func handleTap() {
        onTap?()
    }
}
