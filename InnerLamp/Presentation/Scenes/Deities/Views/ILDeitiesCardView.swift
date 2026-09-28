//
//  ILDeitiesCardView.swift
//  InnerLamp
//

import UIKit

/// 1 thẻ Phật / Bồ Tát trong lưới 2 cột màn "Chư Phật & Bồ Tát": ô ảnh placeholder (170pt) + badge
/// loại ở góc trên-trái, bên dưới là danh xưng (Lora), dòng đức hạnh cốt lõi và ngày vía chính.
/// Riêng cho màn `Deities` nên ở `Scenes/Deities` (không phải component dùng chung).
final class ILDeitiesCardView: UIControl {

    // MARK: - Layout constants
    /// Chiều cao ô ảnh (design handoff `height:170px`).
    static let imageHeight: CGFloat = 170
    /// Padding nội dung chữ (design handoff `padding:12px 14px 14px`).
    private static let contentInset = UIEdgeInsets(top: 12, left: 14, bottom: 14, right: 14)

    // MARK: - Properties
    var onTap: (() -> Void)?

    // MARK: - UI Elements
    private let imageArea = UIView()
    private let kindBadge = UIView()
    private let kindLabel = UILabel()
    private let nameLabel = UILabel()
    private let roleLabel = UILabel()
    private let memorialLabel = UILabel()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    func configure(with model: ILDeitiesItemModel) {
        kindLabel.text = model.kindLabel
        nameLabel.text = model.name
        roleLabel.text = model.role
        memorialLabel.text = model.memorialText
        memorialLabel.isHidden = model.memorialText.isEmpty
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardRegular
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor
        clipsToBounds = true

        // Ô ảnh placeholder (chưa có ảnh tôn tượng thật) + badge loại.
        imageArea.backgroundColor = ILColors.sunk2
        imageArea.isUserInteractionEnabled = false
        imageArea.translatesAutoresizingMaskIntoConstraints = false

        kindBadge.backgroundColor = ILColors.scrim.withAlphaComponent(0.6)
        kindBadge.layer.cornerRadius = ILMetrics.radiusPill
        kindBadge.clipsToBounds = true
        kindBadge.translatesAutoresizingMaskIntoConstraints = false
        imageArea.addSubview(kindBadge)

        kindLabel.font = ILTypography.captionSmall
        kindLabel.textColor = ILColors.inkOnDark
        kindLabel.translatesAutoresizingMaskIntoConstraints = false
        kindBadge.addSubview(kindLabel)

        nameLabel.font = ILTypography.scriptureBodySmall
        nameLabel.textColor = ILColors.ink
        nameLabel.numberOfLines = 2
        nameLabel.lineBreakMode = .byTruncatingTail

        roleLabel.font = ILTypography.label
        roleLabel.textColor = ILColors.inkTertiary
        roleLabel.numberOfLines = 2
        roleLabel.lineBreakMode = .byTruncatingTail

        memorialLabel.font = ILTypography.captionMedium
        memorialLabel.textColor = ILColors.link
        memorialLabel.numberOfLines = 1

        let textStack = UIStackView(arrangedSubviews: [nameLabel, roleLabel, memorialLabel])
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 4
        textStack.setCustomSpacing(8, after: roleLabel)
        textStack.isUserInteractionEnabled = false
        textStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(imageArea)
        addSubview(textStack)

        NSLayoutConstraint.activate([
            imageArea.topAnchor.constraint(equalTo: topAnchor),
            imageArea.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageArea.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageArea.heightAnchor.constraint(equalToConstant: Self.imageHeight),

            kindBadge.leadingAnchor.constraint(equalTo: imageArea.leadingAnchor, constant: ILMetrics.rowSpacing),
            kindBadge.topAnchor.constraint(equalTo: imageArea.topAnchor, constant: ILMetrics.rowSpacing),

            kindLabel.topAnchor.constraint(equalTo: kindBadge.topAnchor, constant: 3),
            kindLabel.bottomAnchor.constraint(equalTo: kindBadge.bottomAnchor, constant: -3),
            kindLabel.leadingAnchor.constraint(equalTo: kindBadge.leadingAnchor, constant: ILMetrics.spaceSmall),
            kindLabel.trailingAnchor.constraint(equalTo: kindBadge.trailingAnchor, constant: -ILMetrics.spaceSmall),

            textStack.topAnchor.constraint(equalTo: imageArea.bottomAnchor, constant: Self.contentInset.top),
            textStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.contentInset.left),
            textStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.contentInset.right),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Self.contentInset.bottom)
        ])

        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILDeitiesCardView, _) in
            view.applyColorAppearanceChange()
        }
    }

    // `layer.borderColor` là CGColor tĩnh, không tự đảo theo trait — refresh thủ công khi hệ thống
    // đổi light/dark.
    private func applyColorAppearanceChange() {
        layer.borderColor = ILColors.border.cgColor
    }

    @objc private func handleTouchDown() {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
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
