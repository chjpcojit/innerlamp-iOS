//
//  ILSanghaOnlineCardView.swift
//  InnerLamp
//

import UIKit

/// Thẻ buổi tu học trực tuyến: chấm + lịch (eyebrow), tiêu đề, dòng phụ. Cả thẻ là 1 vùng chạm.
final class ILSanghaOnlineCardView: UIControl {

    // MARK: - Properties
    var onTap: (() -> Void)?

    // MARK: - UI Elements
    private let dotView = UIView()
    private let scheduleLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    func configure(with model: ILSanghaOnlineRowModel) {
        scheduleLabel.attributedText = ILTypography.makeAttributedString(
            text: model.schedule, font: ILTypography.eyebrowSmall, color: ILColors.inkMuted, letterSpacingEm: 0.14
        )
        dotView.backgroundColor = model.isDaily ? ILColors.goldBright : ILColors.inkFaint
        titleLabel.text = model.title
        subtitleLabel.text = model.subtitle
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardRegular
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor

        dotView.layer.cornerRadius = 4
        dotView.widthAnchor.constraint(equalToConstant: 8).isActive = true
        dotView.heightAnchor.constraint(equalToConstant: 8).isActive = true
        let tagRow = UIStackView(arrangedSubviews: [dotView, scheduleLabel])
        tagRow.axis = .horizontal
        tagRow.alignment = .center
        tagRow.spacing = 8

        titleLabel.font = ILTypography.rowTitle
        titleLabel.textColor = ILColors.ink
        titleLabel.numberOfLines = 0
        subtitleLabel.font = ILTypography.subhead
        subtitleLabel.textColor = ILColors.inkTertiary
        subtitleLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [tagRow, titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 3
        stack.setCustomSpacing(8, after: tagRow)
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: ILMetrics.spaceStandard),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -ILMetrics.spaceStandard),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.spaceStandard),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.spaceStandard)
        ])

        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)

        // `layer.borderColor` là CGColor tĩnh — refresh thủ công khi đổi light/dark.
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.layer.borderColor = ILColors.border.cgColor
        }
    }

    @objc private func handleTapAction() {
        onTap?()
    }
}
