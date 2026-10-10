//
//  ILSectionHeaderView.swift
//  InnerLamp
//

import UIKit

/// Tiêu đề 1 section (vd: "Thời khóa gợi ý") kèm link phải tùy chọn (vd: "Toàn màn hình") và
/// ô icon đầu dòng tùy chọn (22×22, nền nhạt + icon cùng tông màu, như `IL-Icon` ở prototype).
public final class ILSectionHeaderView: UIView {

    // MARK: - Properties
    public var title: String = "" {
        didSet { titleLabel.text = title }
    }

    public var trailingText: String? {
        didSet {
            trailingButton.setTitle(trailingText, for: .normal)
            trailingButton.isHidden = trailingText == nil
        }
    }

    public var onTrailingTap: (() -> Void)?

    // MARK: - UI Elements
    private let iconTile = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let trailingButton = UIButton(type: .system)

    private let hasIcon: Bool

    // MARK: - Initializer
    public init(
        title: String,
        trailingText: String? = nil,
        icon: UIImage? = nil,
        iconTone: ILColors.Tone = .gold
    ) {
        self.title = title
        self.trailingText = trailingText
        self.hasIcon = icon != nil
        super.init(frame: .zero)
        setupViews()
        configureIcon(icon, tone: iconTone)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        titleLabel.font = ILTypography.sectionTitle
        titleLabel.textColor = ILColors.ink
        titleLabel.text = title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        trailingButton.titleLabel?.font = ILTypography.bodySmall
        trailingButton.setTitleColor(ILColors.goldDeep, for: .normal)
        trailingButton.setTitle(trailingText, for: .normal)
        trailingButton.isHidden = trailingText == nil
        trailingButton.translatesAutoresizingMaskIntoConstraints = false
        trailingButton.addTarget(self, action: #selector(handleTrailingTap), for: .touchUpInside)
        trailingButton.contentHorizontalAlignment = .trailing

        iconTile.isHidden = !hasIcon
        iconTile.layer.cornerRadius = ILMetrics.radiusSectionIcon
        iconTile.translatesAutoresizingMaskIntoConstraints = false

        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconTile.addSubview(iconView)

        addSubview(iconTile)
        addSubview(titleLabel)
        addSubview(trailingButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),

            trailingButton.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),
            trailingButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            trailingButton.centerYAnchor.constraint(equalTo: titleLabel.firstBaselineAnchor)
        ])

        if hasIcon {
            NSLayoutConstraint.activate([
                iconTile.leadingAnchor.constraint(equalTo: leadingAnchor),
                iconTile.centerYAnchor.constraint(equalTo: centerYAnchor),
                iconTile.widthAnchor.constraint(equalToConstant: ILMetrics.sectionIconSize),
                iconTile.heightAnchor.constraint(equalToConstant: ILMetrics.sectionIconSize),

                iconView.leadingAnchor.constraint(equalTo: iconTile.leadingAnchor),
                iconView.trailingAnchor.constraint(equalTo: iconTile.trailingAnchor),
                iconView.topAnchor.constraint(equalTo: iconTile.topAnchor),
                iconView.bottomAnchor.constraint(equalTo: iconTile.bottomAnchor),

                titleLabel.leadingAnchor.constraint(equalTo: iconTile.trailingAnchor, constant: ILMetrics.spaceSmall),
                // Keep the header at least as tall as the tile so the icon is never clipped.
                titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: ILMetrics.sectionIconSize)
            ])
        } else {
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        }
    }

    private func configureIcon(_ icon: UIImage?, tone: ILColors.Tone) {
        guard let icon else { return }
        iconView.image = icon
        iconView.tintColor = tone.accentColor
        iconTile.backgroundColor = tone.tintBackground
    }

    @objc private func handleTrailingTap() {
        onTrailingTap?()
    }
}
