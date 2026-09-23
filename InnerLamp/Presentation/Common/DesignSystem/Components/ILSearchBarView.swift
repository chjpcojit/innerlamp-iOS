//
//  ILSearchBarView.swift
//  InnerLamp
//

import UIKit

/// Ô tìm kiếm dạng chạm (icon kính lúp + placeholder) — không phải text field: màn Tìm kiếm mới
/// là nơi nhập chữ, ô này chỉ mở nó. Không chứa nội dung riêng của màn nào nên dùng chung.
public final class ILSearchBarView: UIControl {

    // MARK: - Properties
    public var placeholder: String = "" {
        didSet { placeholderLabel.text = placeholder }
    }

    public var onTap: (() -> Void)?

    // MARK: - UI Elements
    private let iconView = UIView()
    private let placeholderLabel = UILabel()
    private let contentStack = UIStackView()

    // MARK: - Initializer
    public init(placeholder: String = "") {
        self.placeholder = placeholder
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusInput
        layer.borderWidth = 1
        isAccessibilityElement = true
        accessibilityTraits = .searchField
        accessibilityIdentifier = "library.searchBar"

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.layer.cornerRadius = Self.iconSize / 2
        iconView.layer.borderWidth = 1.5
        iconView.isUserInteractionEnabled = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: Self.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Self.iconSize)
        ])

        placeholderLabel.font = ILTypography.body
        placeholderLabel.textColor = ILColors.inkMuted
        placeholderLabel.text = placeholder

        contentStack.axis = .horizontal
        contentStack.spacing = 10
        contentStack.alignment = .center
        contentStack.isUserInteractionEnabled = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(iconView)
        contentStack.addArrangedSubview(placeholderLabel)
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -14)
        ])

        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)
        updateBorders()
    }

    private static let iconSize: CGFloat = 14

    private func updateBorders() {
        layer.borderColor = ILColors.border.cgColor
        iconView.layer.borderColor = ILColors.inkFaint.cgColor
    }

    // `layer.borderColor` là CGColor tĩnh, không tự đảo theo trait — refresh thủ công khi
    // hệ thống đổi light/dark.
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateBorders()
    }

    @objc private func handleTapAction() {
        onTap?()
    }
}
