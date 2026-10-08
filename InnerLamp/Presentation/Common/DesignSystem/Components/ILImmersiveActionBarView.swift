//
//  ILImmersiveActionBarView.swift
//  InnerLamp
//

import UIKit

/// Hàng 2 nút pill đáy màn immersive: nút phụ viền mảnh (vd. "Bắt đầu lại") và nút chính nền
/// vàng nhạt (vd. "Xong"). Hai nút chia đều chiều ngang; để `primaryTitle` rỗng thì nút chính ẩn và
/// nút phụ chiếm cả hàng. Khác `ILButton` ở chỗ palette lấy từ bộ
/// token `--il-med-*` (đổi theo light/dark của nền immersive) và nền trong suốt.
public final class ILImmersiveActionBarView: UIView {

    // MARK: - Properties
    public var secondaryTitle: String = "" {
        didSet { secondaryButton.configuration?.title = secondaryTitle }
    }

    public var primaryTitle: String = "" {
        didSet {
            primaryButton.configuration?.title = primaryTitle
            primaryButton.isHidden = primaryTitle.isEmpty
        }
    }

    public var onSecondaryTap: (() -> Void)?
    public var onPrimaryTap: (() -> Void)?

    // MARK: - UI Elements
    private let secondaryButton = UIButton(type: .system)
    private let primaryButton = UIButton(type: .system)

    // MARK: - Initializer
    public init(secondaryTitle: String = "", primaryTitle: String = "") {
        self.secondaryTitle = secondaryTitle
        self.primaryTitle = primaryTitle
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        configure(secondaryButton, title: secondaryTitle, foreground: ILColors.medInk)
        secondaryButton.addTarget(self, action: #selector(handleSecondaryTap), for: .touchUpInside)

        configure(primaryButton, title: primaryTitle, foreground: ILColors.link)
        primaryButton.addTarget(self, action: #selector(handlePrimaryTap), for: .touchUpInside)

        updateBorders()
        primaryButton.isHidden = primaryTitle.isEmpty

        let stack = UIStackView(arrangedSubviews: [secondaryButton, primaryButton])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = ILMetrics.rowSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            heightAnchor.constraint(equalToConstant: ILMetrics.inputHeight)
        ])
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILImmersiveActionBarView, _) in
            view.applyColorAppearanceChange()
        }
    }

    private func configure(_ button: UIButton, title: String, foreground: UIColor) {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.baseForegroundColor = foreground
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = ILTypography.sectionTitle
            return outgoing
        }
        config.cornerStyle = .capsule
        config.background.strokeWidth = 1
        button.configuration = config
        button.configurationUpdateHandler = { button in
            UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
                button.transform = button.isHighlighted ? CGAffineTransform(scaleX: 0.978, y: 0.978) : .identity
            }
        }
    }

    private func applyColorAppearanceChange() {
        updateBorders()
    }

    // Màu trong `UIButton.Configuration` được resolve lúc gán, không tự đảo theo trait — gán lại
    // thủ công mỗi khi light/dark đổi.
    private func updateBorders() {
        secondaryButton.configuration?.baseForegroundColor = ILColors.medInk.resolvedColor(with: traitCollection)
        primaryButton.configuration?.baseForegroundColor = ILColors.link.resolvedColor(with: traitCollection)
        secondaryButton.configuration?.background.strokeColor = ILColors.medBorder.resolvedColor(with: traitCollection)
        primaryButton.configuration?.background.strokeColor = ILColors.medGoldTintBorder.resolvedColor(with: traitCollection)
        primaryButton.configuration?.background.backgroundColor = ILColors.medGoldTint.resolvedColor(with: traitCollection)
    }

    // MARK: - Actions
    @objc private func handleSecondaryTap() {
        onSecondaryTap?()
    }

    @objc private func handlePrimaryTap() {
        onPrimaryTap?()
    }
}
