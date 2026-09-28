//
//  ILOptionCard.swift
//  InnerLamp
//

import UIKit

/// Thẻ lựa chọn 1-trong-nhiều: glyph tròn + tiêu đề/phụ đề, cả thẻ bấm được để chọn — dùng
/// cho mọi danh sách "chọn 1 trong nhiều thẻ ngang hàng" (cách nhận mã, phương thức thanh
/// toán, ...). Dữ liệu hoàn toàn động qua init, không phụ thuộc nội dung màn cụ thể nào.
public final class ILOptionCard: UIControl {

    // MARK: - Properties
    public var title: String = "" {
        didSet { titleLabel.text = title }
    }

    public var subtitle: String = "" {
        didSet {
            subtitleLabel.text = subtitle
            subtitleLabel.isHidden = subtitle.isEmpty
        }
    }

    // `isSelected` overrides `UIControl.isSelected` — dùng lại đúng ngữ nghĩa "đang được chọn"
    // sẵn có thay vì đặt tên riêng, chỉ thêm hook cập nhật giao diện.
    public override var isSelected: Bool {
        didSet { updateAppearance() }
    }

    public var onTap: (() -> Void)?

    // MARK: - UI Elements
    private let glyphContainer = UIView()
    private let glyph = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    // MARK: - Initializer
    public init(title: String, subtitle: String = "", isSelected: Bool = false) {
        self.title = title
        self.subtitle = subtitle
        super.init(frame: .zero)
        self.isSelected = isSelected
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        layer.cornerRadius = ILMetrics.radiusCardSmall
        layer.borderWidth = 1

        glyphContainer.translatesAutoresizingMaskIntoConstraints = false
        glyphContainer.layer.cornerRadius = 14
        glyphContainer.isUserInteractionEnabled = false

        glyph.translatesAutoresizingMaskIntoConstraints = false
        glyph.layer.cornerRadius = ILMetrics.radiusGlyph
        glyphContainer.addSubview(glyph)

        NSLayoutConstraint.activate([
            glyphContainer.widthAnchor.constraint(equalToConstant: 28),
            glyphContainer.heightAnchor.constraint(equalToConstant: 28),
            glyph.centerXAnchor.constraint(equalTo: glyphContainer.centerXAnchor),
            glyph.centerYAnchor.constraint(equalTo: glyphContainer.centerYAnchor),
            glyph.widthAnchor.constraint(equalToConstant: 11),
            glyph.heightAnchor.constraint(equalToConstant: 8)
        ])

        titleLabel.font = ILTypography.bodySmallMedium
        titleLabel.text = title
        titleLabel.numberOfLines = 1

        subtitleLabel.font = ILTypography.caption
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle.isEmpty
        subtitleLabel.numberOfLines = 1

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.alignment = .leading
        textStack.isUserInteractionEnabled = false
        textStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(glyphContainer)
        addSubview(textStack)

        NSLayoutConstraint.activate([
            glyphContainer.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            glyphContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),

            textStack.topAnchor.constraint(equalTo: glyphContainer.bottomAnchor, constant: 12),
            textStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])

        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)

        updateAppearance()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILOptionCard, _) in
            view.applyColorAppearanceChange()
        }
    }

    private func updateAppearance() {
        backgroundColor = ILColors.surface

        // Token động (ink/gold) tự đảo theo trait thay vì set cứng hex light-only.
        if isSelected {
            layer.borderColor = ILColors.goldBorder.cgColor
            glyphContainer.backgroundColor = ILColors.gold.withAlphaComponent(0.18)
            glyph.backgroundColor = ILColors.goldDeep
        } else {
            layer.borderColor = ILColors.ink.withAlphaComponent(0.10).cgColor
            glyphContainer.backgroundColor = ILColors.ink.withAlphaComponent(0.07)
            glyph.backgroundColor = ILColors.ink.withAlphaComponent(0.40)
        }

        titleLabel.textColor = ILColors.ink
        subtitleLabel.textColor = ILColors.inkMuted
    }

    // `layer.borderColor` là CGColor tĩnh, không tự đảo theo trait — refresh thủ công
    // khi hệ thống đổi light/dark (ink/gold/surface giờ có biến thể dark).
    private func applyColorAppearanceChange() {
        updateAppearance()
    }

    @objc private func handleTouchDown() {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
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
