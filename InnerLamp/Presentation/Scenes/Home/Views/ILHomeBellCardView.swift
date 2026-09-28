//
//  ILHomeBellCardView.swift
//  InnerLamp
//

import UIKit

/// Thẻ "Chuông mõ" ở Trang chủ — icon vòng vàng + tiêu đề + mô tả + mũi tên "›", dẫn tới màn
/// `bell` (chưa build). Riêng cho Trang chủ (copy + tổ hợp này không màn nào khác dùng) nên ở
/// `Scenes/Home`, không phải component dùng chung.
final class ILHomeBellCardView: UIControl {

    // MARK: - Properties
    var title: String = "" {
        didSet { titleLabel.text = title }
    }

    var subtitle: String = "" {
        didSet { subtitleLabel.text = subtitle }
    }

    var onTap: (() -> Void)?

    // MARK: - UI Elements
    private let iconCircle = UIView()
    private let iconInner = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let chevronLabel = UILabel()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardLarge
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor

        iconCircle.backgroundColor = ILColors.gold.withAlphaComponent(0.14)
        iconCircle.layer.borderWidth = 1
        iconCircle.layer.borderColor = ILColors.goldBorder.cgColor
        iconCircle.translatesAutoresizingMaskIntoConstraints = false

        iconInner.backgroundColor = .clear
        iconInner.layer.borderWidth = 1.5
        iconInner.layer.borderColor = ILColors.gold.cgColor
        iconInner.translatesAutoresizingMaskIntoConstraints = false
        iconCircle.addSubview(iconInner)

        titleLabel.font = ILTypography.scriptureBodySmall
        titleLabel.textColor = ILColors.ink
        titleLabel.text = title
        titleLabel.numberOfLines = 1

        subtitleLabel.font = ILTypography.bodySmall
        subtitleLabel.textColor = ILColors.inkTertiary
        subtitleLabel.text = subtitle
        subtitleLabel.numberOfLines = 2

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.alignment = .leading
        textStack.isUserInteractionEnabled = false

        chevronLabel.font = ILTypography.chevron
        chevronLabel.textColor = ILColors.inkFaint
        chevronLabel.text = "›"
        chevronLabel.setContentHuggingPriority(.required, for: .horizontal)
        chevronLabel.isUserInteractionEnabled = false

        let contentStack = UIStackView(arrangedSubviews: [iconCircle, textStack, chevronLabel])
        contentStack.axis = .horizontal
        contentStack.spacing = 14
        contentStack.alignment = .center
        contentStack.isUserInteractionEnabled = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            iconCircle.widthAnchor.constraint(equalToConstant: 46),
            iconCircle.heightAnchor.constraint(equalToConstant: 46),

            iconInner.centerXAnchor.constraint(equalTo: iconCircle.centerXAnchor),
            iconInner.centerYAnchor.constraint(equalTo: iconCircle.centerYAnchor),
            iconInner.widthAnchor.constraint(equalToConstant: 16),
            iconInner.heightAnchor.constraint(equalToConstant: 16),

            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])

        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILHomeBellCardView, _) in
            view.applyColorAppearanceChange()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        iconCircle.layer.cornerRadius = 23
        iconInner.layer.cornerRadius = 8
    }

    private func applyColorAppearanceChange() {
        layer.borderColor = ILColors.border.cgColor
        iconCircle.layer.borderColor = ILColors.goldBorder.cgColor
        iconInner.layer.borderColor = ILColors.gold.cgColor
    }

    @objc private func handleTouchDown() {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = CGAffineTransform(scaleX: 0.99, y: 0.99)
        }
    }

    @objc private func handleTouchUp() {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = .identity
        }
    }

    @objc private func handleTapAction() {
        onTap?()
    }
}
