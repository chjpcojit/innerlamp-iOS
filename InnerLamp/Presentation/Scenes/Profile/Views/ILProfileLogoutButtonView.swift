//
//  ILProfileLogoutButtonView.swift
//  InnerLamp
//

import UIKit

/// Nút "Đăng xuất" cuối màn Tôi (khớp `loOpen` trong design handoff): thẻ bo góc, viền mảnh, nhãn
/// màu `danger` căn giữa. Chỉ phát `onTap` — hộp xác nhận do màn chủ hiển thị. Nội dung riêng màn Tôi.
final class ILProfileLogoutButtonView: UIControl {

    // MARK: - Constants
    private enum Layout {
        static let height: CGFloat = 52
        static let disabledAlpha: CGFloat = 0.5
    }

    // MARK: - Properties
    var title: String = "" {
        didSet {
            titleLabel.text = title
            accessibilityLabel = title
        }
    }

    var onTap: (() -> Void)?

    override var isEnabled: Bool {
        didSet { alpha = isEnabled ? 1 : Layout.disabledAlpha }
    }

    // MARK: - UI Elements
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.destructiveRowLabel
        label.textColor = ILColors.danger
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
        return label
    }()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
        registerForAppearanceChanges()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardRegular
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor
        isAccessibilityElement = true
        accessibilityTraits = .button

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Layout.height),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: ILMetrics.spaceMedium),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -ILMetrics.spaceMedium),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])

        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)
    }

    // `layer.borderColor` là CGColor tĩnh, không tự đảo theo trait — refresh thủ công khi đổi
    // light/dark.
    private func registerForAppearanceChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.layer.borderColor = ILColors.border.cgColor
        }
    }

    // MARK: - Touch
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
