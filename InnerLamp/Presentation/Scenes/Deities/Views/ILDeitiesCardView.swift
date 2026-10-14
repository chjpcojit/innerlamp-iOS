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
    static let contentInset = UIEdgeInsets(top: 12, left: 14, bottom: 14, right: 14)

    // MARK: - Properties
    var onTap: (() -> Void)?

    // MARK: - UI Elements
    private lazy var imageArea: ILRemoteImageView = {
        let v = ILRemoteImageView(frame: .zero)
        v.backgroundColor = ILColors.sunk2
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var kindBadge: UIView = {
        let v = UIView()
        v.backgroundColor = ILColors.scrim.withAlphaComponent(0.6)
        v.layer.cornerRadius = ILMetrics.radiusPill
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var kindLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.captionSmall
        v.textColor = ILColors.inkOnDark
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var nameLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.scriptureBodySmall
        v.textColor = ILColors.ink
        v.numberOfLines = 2
        v.lineBreakMode = .byTruncatingTail
        return v
    }()
    private lazy var roleLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.label
        v.textColor = ILColors.inkTertiary
        v.numberOfLines = 2
        v.lineBreakMode = .byTruncatingTail
        return v
    }()
    private lazy var memorialLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.captionMedium
        v.textColor = ILColors.link
        v.numberOfLines = 1
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

    // MARK: - Configure
    func configure(with model: ILDeitiesItemModel) {
        kindLabel.text = model.kindLabel
        nameLabel.text = model.name
        roleLabel.text = model.role
        memorialLabel.text = model.memorialText
        memorialLabel.isHidden = model.memorialText.isEmpty
        imageArea.setImage(urlString: model.thumbnailURL)
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardRegular
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor
        clipsToBounds = true

        // Ô ảnh tôn tượng từ server (nền `sunk2` làm placeholder khi chưa có / lỗi) + badge loại.
        imageArea.addSubview(kindBadge)
        kindBadge.addSubview(kindLabel)

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
