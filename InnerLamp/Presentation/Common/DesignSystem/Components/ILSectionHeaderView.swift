//
//  ILSectionHeaderView.swift
//  InnerLamp
//

import UIKit

/// Tiêu đề 1 section (vd: "Thời khóa gợi ý") kèm link phải tùy chọn (vd: "Toàn màn hình").
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
    private let titleLabel = UILabel()
    private let trailingButton = UIButton(type: .system)

    // MARK: - Initializer
    public init(title: String, trailingText: String? = nil) {
        self.title = title
        self.trailingText = trailingText
        super.init(frame: .zero)
        setupViews()
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

        addSubview(titleLabel)
        addSubview(trailingButton)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),

            trailingButton.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),
            trailingButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            trailingButton.centerYAnchor.constraint(equalTo: titleLabel.firstBaselineAnchor)
        ])
    }

    @objc private func handleTrailingTap() {
        onTrailingTap?()
    }
}
