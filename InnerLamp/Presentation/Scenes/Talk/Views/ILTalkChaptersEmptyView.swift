//
//  ILTalkChaptersEmptyView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 3/10/26.
//

import UIKit

/// Khối thay cho "Các phần" khi bài giảng chưa chia phần (`talkNoParts` trong design handoff):
/// khung viền nét đứt bo góc 20, icon 3 dòng trong vòng tròn vàng, tiêu đề serif và dòng gợi ý.
final class ILTalkChaptersEmptyView: UIView {

    // MARK: - Properties
    var title: String = "" { didSet { titleLabel.text = title } }
    var subtitle: String = "" { didSet { updateSubtitle() } }

    // MARK: - UI Elements
    private let dashedBorder = CAShapeLayer()

    private let iconCircle: UIView = {
        let view = UIView()
        view.backgroundColor = ILColors.gold.withAlphaComponent(0.12)
        view.layer.cornerRadius = 22
        view.layer.borderWidth = 1
        view.layer.borderColor = ILColors.gold.withAlphaComponent(0.30).cgColor
        return view
    }()

    private let iconView: UIImageView = {
        let imageView = UIImageView(image: ILIcons.linesEmpty)
        imageView.tintColor = ILColors.gold
        imageView.contentMode = .center
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.serifCardTitle
        label.textColor = ILColors.ink
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false

        dashedBorder.fillColor = UIColor.clear.cgColor
        dashedBorder.strokeColor = ILColors.borderPill.cgColor
        dashedBorder.lineWidth = 1
        dashedBorder.lineDashPattern = [4, 3]
        layer.addSublayer(dashedBorder)

        [iconCircle, iconView, titleLabel, subtitleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            iconCircle.topAnchor.constraint(equalTo: topAnchor, constant: 22),
            iconCircle.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconCircle.widthAnchor.constraint(equalToConstant: 44),
            iconCircle.heightAnchor.constraint(equalToConstant: 44),

            iconView.centerXAnchor.constraint(equalTo: iconCircle.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconCircle.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: iconCircle.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            subtitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 18),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -18),
            subtitleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 260),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -22)
        ])

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILTalkChaptersEmptyView, _) in
            view.applyColorAppearanceChange()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        dashedBorder.frame = bounds
        dashedBorder.path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5),
            cornerRadius: ILMetrics.radiusCardRegular
        ).cgPath
    }

    // `CAShapeLayer`/`CALayer` colors are static CGColors — refresh by hand on light/dark change.
    private func applyColorAppearanceChange() {
        dashedBorder.strokeColor = ILColors.borderPill.cgColor
        iconCircle.layer.borderColor = ILColors.gold.withAlphaComponent(0.30).cgColor
    }

    private func updateSubtitle() {
        subtitleLabel.attributedText = ILTypography.makeParagraph(
            text: subtitle,
            font: ILTypography.note,
            color: ILColors.inkTertiary,
            cssLineHeight: 1.6,
            alignment: .center
        )
    }
}
