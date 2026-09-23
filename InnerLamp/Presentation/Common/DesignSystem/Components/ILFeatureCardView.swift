//
//  ILFeatureCardView.swift
//  InnerLamp
//

import UIKit

/// Thẻ nổi bật nền tối luôn tối ở cả light/dark (theo design handoff): eyebrow chữ hoa vàng,
/// tiêu đề serif nhiều dòng, nút pill vàng, vầng sáng góc dưới phải. Cả thẻ là 1 vùng chạm;
/// pill chỉ là nhãn hiển thị. Chỉ nhận chuỗi nên dùng chung được cho mọi màn cần thẻ "nổi bật".
public final class ILFeatureCardView: UIControl {

    // MARK: - Properties
    public var eyebrow: String = "" {
        didSet { eyebrowLabel.attributedText = ILTypography.makeEyebrow(text: eyebrow, color: ILColors.goldBright.withAlphaComponent(0.9)) }
    }

    public var title: String = "" {
        didSet { renderTitle() }
    }

    public var ctaTitle: String = "" {
        didSet { ctaLabel.text = ctaTitle }
    }

    public var onTap: (() -> Void)?

    // MARK: - UI Elements
    private let gradientLayer = CAGradientLayer()
    private let glowLayer = CAGradientLayer()
    private let eyebrowLabel = UILabel()
    private let titleLabel = UILabel()
    private let ctaPill = UIView()
    private let ctaLabel = UILabel()
    private let contentStack = UIStackView()

    // MARK: - Initializer
    public init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        glowLayer.frame = CGRect(x: bounds.width - 140, y: bounds.height - 120, width: 180, height: 180)
        glowLayer.cornerRadius = 90
    }

    // MARK: - Setup
    private func setupViews() {
        layer.cornerRadius = ILMetrics.radiusCardLarge - 2
        clipsToBounds = true

        gradientLayer.colors = [ILColors.darkBackgroundTop.cgColor, ILColors.darkBackground.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.2, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.8, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)

        glowLayer.type = .radial
        glowLayer.colors = [ILColors.goldGlowStrong.cgColor, ILColors.goldGlowClear.cgColor]
        glowLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        glowLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(glowLayer, above: gradientLayer)

        titleLabel.numberOfLines = 0

        ctaLabel.font = ILTypography.bodySmallMedium
        ctaLabel.textColor = ILColors.darkBackground

        ctaPill.backgroundColor = ILColors.goldBright
        ctaPill.layer.cornerRadius = ILMetrics.radiusPill
        ctaPill.translatesAutoresizingMaskIntoConstraints = false
        ctaLabel.translatesAutoresizingMaskIntoConstraints = false
        ctaPill.addSubview(ctaLabel)
        NSLayoutConstraint.activate([
            ctaLabel.topAnchor.constraint(equalTo: ctaPill.topAnchor, constant: 9),
            ctaLabel.bottomAnchor.constraint(equalTo: ctaPill.bottomAnchor, constant: -9),
            ctaLabel.leadingAnchor.constraint(equalTo: ctaPill.leadingAnchor, constant: 16),
            ctaLabel.trailingAnchor.constraint(equalTo: ctaPill.trailingAnchor, constant: -16)
        ])

        // Bọc pill để nó không bị stack kéo giãn hết chiều ngang.
        let ctaRow = UIStackView(arrangedSubviews: [ctaPill, UIView()])
        ctaRow.axis = .horizontal

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 10
        contentStack.isUserInteractionEnabled = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(eyebrowLabel)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(ctaRow)
        contentStack.setCustomSpacing(16, after: titleLabel)
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 22),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -22),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22)
        ])

        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)
    }

    private func renderTitle() {
        titleLabel.attributedText = ILTypography.makeAttributedString(
            text: title,
            font: ILTypography.scriptureTitle,
            color: ILColors.inkOnDark,
            lineHeightMultiple: 1.35,
            alignment: .left
        )
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
