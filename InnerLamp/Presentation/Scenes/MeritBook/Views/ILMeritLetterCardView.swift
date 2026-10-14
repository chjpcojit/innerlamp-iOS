//
//  ILMeritLetterCardView.swift
//  InnerLamp
//

import UIKit

/// "Thư tùy hỷ": the temple's thank-you letter — warm card with a gold hairline, serif body and an
/// italic right-aligned signature.
final class ILMeritLetterCardView: ILMeritCardView {

    private lazy var bodyLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.scriptureBodyLarge
        label.textColor = ILColors.inkStrong
        label.numberOfLines = 0
        return label
    }()

    private lazy var signatureLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.heroSubtitleItalic
        label.textColor = ILColors.inkTertiary
        label.numberOfLines = 0
        label.textAlignment = .right
        return label
    }()

    init() {
        super.init(fillColor: ILColors.canvasWarm, strokeColor: ILColors.goldCardBorder)

        let stack = UIStackView(arrangedSubviews: [bodyLabel, signatureLabel])
        stack.axis = .vertical
        stack.spacing = 12
        embed(stack, insets: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(letter: ILMeritBookStateModel.Letter) {
        bodyLabel.attributedText = ILTypography.makeScriptureText(
            text: letter.body,
            size: 16,
            color: ILColors.inkStrong,
            alignment: .left
        )
        signatureLabel.text = letter.signature
    }
}
