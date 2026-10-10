//
//  ILQuoteCardView.swift
//  InnerLamp
//

import UIKit

/// Thẻ trích dẫn nền tối có vầng sáng vàng lan tỏa — dùng cho "Lời Phật dạy hôm nay" ở Trang chủ,
/// tái dùng được cho mọi màn cần hiển thị 1 câu trích dẫn nổi bật (eyebrow + quote + dịch nghĩa).
public final class ILQuoteCardView: UIControl {

    // MARK: - Properties
    public var eyebrow: String = "" {
        didSet { eyebrowLabel.attributedText = ILTypography.makeEyebrow(text: eyebrow, color: ILColors.goldBright.withAlphaComponent(0.9)) }
    }

    public var quote: String = "" {
        didSet {
            quoteLabel.attributedText = ILTypography.makeAttributedString(
                text: quote,
                font: ILTypography.cormorant(size: 22),
                color: ILColors.inkOnDark,
                lineHeightMultiple: 1.5
            )
        }
    }

    public var translation: String = "" {
        didSet { translationLabel.text = translation }
    }

    public var onTap: (() -> Void)?

    // MARK: - UI Elements
    private let gradientLayer = CAGradientLayer()
    private let glowLayer = CAGradientLayer()
    private let eyebrowLabel = UILabel()
    private let quoteLabel = UILabel()
    private let translationLabel = UILabel()

    // MARK: - Initializer
    public init(eyebrow: String = "", quote: String = "", translation: String = "") {
        self.eyebrow = eyebrow
        self.quote = quote
        self.translation = translation
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        glowLayer.frame = CGRect(x: bounds.width - 130, y: -60, width: 190, height: 190)
        glowLayer.cornerRadius = 95
    }

    // MARK: - Setup
    private func setupViews() {
        layer.cornerRadius = ILMetrics.radiusCardLarge
        clipsToBounds = true

        gradientLayer.colors = [ILColors.darkBackgroundTop.cgColor, ILColors.darkBackground.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.2, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.8, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)

        glowLayer.type = .radial
        glowLayer.colors = [ILColors.goldGlow.cgColor, ILColors.goldGlowClear.cgColor]
        glowLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        glowLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(glowLayer, above: gradientLayer)

        eyebrowLabel.numberOfLines = 1
        eyebrowLabel.translatesAutoresizingMaskIntoConstraints = false

        quoteLabel.numberOfLines = 0
        quoteLabel.translatesAutoresizingMaskIntoConstraints = false

        translationLabel.font = italicTranslationFont
        translationLabel.textColor = ILColors.inkOnDarkSecondary
        translationLabel.numberOfLines = 0
        translationLabel.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [eyebrowLabel, quoteLabel, translationLabel])
        stack.axis = .vertical
        stack.spacing = 10
        stack.setCustomSpacing(12, after: eyebrowLabel)
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24)
        ])

        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)
    }

    /// Lora 12.5 nghiêng — không có preset sẵn khớp size này trong `ILTypography`
    /// (`taglineItalic` là 14), nên derive trực tiếp từ `lora(size:)` giống cách
    /// `ILSplashViewController`/`ILOnboardingIntroStepView` tự tạo font nghiêng cục bộ.
    private var italicTranslationFont: UIFont {
        let base = ILTypography.literata(size: 13, italic: true)
        guard let descriptor = base.fontDescriptor.withSymbolicTraits(.traitItalic) else { return base }
        return UIFont(descriptor: descriptor, size: 12.5)
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
