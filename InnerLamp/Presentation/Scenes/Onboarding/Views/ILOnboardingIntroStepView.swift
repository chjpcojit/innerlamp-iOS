//
//  ILOnboardingIntroStepView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 12/9/26.
//

import UIKit

/// Step chào mừng — nội dung/ảnh minh họa cố định, không có gì để cấu hình động,
/// nên đây là một trong số ít "hình dạng" step thực sự đặc thù cần file riêng.
final class ILOnboardingIntroStepView: UIView {

    // MARK: - UI Elements
    /// Ảnh minh họa đèn + quầng sáng (full-color, không tô màu).
    private lazy var lampImageView: UIImageView = {
        let imageView = UIImageView(image: ILIcons.onboardingLamp)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = ILTypography.makeAttributedString(
            text: "onboarding.intro.title".localized,
            font: ILTypography.introDisplay,
            color: ILColors.ink,
            lineHeightMultiple: 1.16
        )
        return label
    }()

    private lazy var subtitleItalicLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.taglineItalic.italic()
        label.textColor = ILColors.inkTertiary
        label.text = "onboarding.intro.subtitle".localized
        return label
    }()

    private lazy var descLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = ILTypography.makeAttributedString(
            text: "onboarding.intro.description".localized,
            font: ILTypography.introBody,
            color: ILColors.inkDim,
            lineHeightMultiple: 1.45
        )
        return label
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(lampImageView)
        stack.setCustomSpacing(22, after: lampImageView)
        stack.addArrangedSubview(titleLabel)
        stack.setCustomSpacing(12, after: titleLabel)
        stack.addArrangedSubview(subtitleItalicLabel)
        stack.setCustomSpacing(16, after: subtitleItalicLabel)
        stack.addArrangedSubview(descLabel)
        return stack
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            lampImageView.widthAnchor.constraint(equalToConstant: ILMetrics.onboardingLampSize.width),
            lampImageView.heightAnchor.constraint(equalToConstant: ILMetrics.onboardingLampSize.height),

            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            descLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 300)
        ])
    }
}

// MARK: - UIFont Italic Helper
private extension UIFont {
    func italic() -> UIFont {
        return UIFont(descriptor: fontDescriptor.withSymbolicTraits(.traitItalic) ?? fontDescriptor, size: pointSize)
    }
}
