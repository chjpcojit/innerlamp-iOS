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
    private lazy var iconTile: UIView = {
        let v = UIView()
        v.backgroundColor = ILColors.Tone.gold.tintBackground
        v.layer.cornerRadius = ILMetrics.radiusIconTileLarge
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var iconView: UIImageView = {
        let v = UIImageView()
        v.image = ILIcons.homeMo
        v.tintColor = ILColors.Tone.gold.accentColor
        v.contentMode = .scaleAspectFit
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var titleLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.scriptureBodySmall
        v.textColor = ILColors.ink
        v.text = title
        v.numberOfLines = 1
        return v
    }()
    private lazy var subtitleLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.bodySmall
        v.textColor = ILColors.inkTertiary
        v.text = subtitle
        v.numberOfLines = 2
        return v
    }()
    private lazy var chevronLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.chevron
        v.textColor = ILColors.inkFaint
        v.text = "›"
        v.setContentHuggingPriority(.required, for: .horizontal)
        v.isUserInteractionEnabled = false
        return v
    }()

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

        iconTile.addSubview(iconView)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.alignment = .leading
        textStack.isUserInteractionEnabled = false

        let contentStack = UIStackView(arrangedSubviews: [iconTile, textStack, chevronLabel])
        contentStack.axis = .horizontal
        contentStack.spacing = 14
        contentStack.alignment = .center
        contentStack.isUserInteractionEnabled = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            iconTile.widthAnchor.constraint(equalToConstant: ILMetrics.iconTileLargeSize),
            iconTile.heightAnchor.constraint(equalToConstant: ILMetrics.iconTileLargeSize),

            iconView.leadingAnchor.constraint(equalTo: iconTile.leadingAnchor),
            iconView.trailingAnchor.constraint(equalTo: iconTile.trailingAnchor),
            iconView.topAnchor.constraint(equalTo: iconTile.topAnchor),
            iconView.bottomAnchor.constraint(equalTo: iconTile.bottomAnchor),

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

    private func applyColorAppearanceChange() {
        layer.borderColor = ILColors.border.cgColor
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
