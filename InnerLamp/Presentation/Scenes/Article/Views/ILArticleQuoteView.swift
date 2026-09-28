//
//  ILArticleQuoteView.swift
//  InnerLamp
//

import UIKit

/// Khối trích dẫn nổi bật trong bài viết: viền trái vàng 2pt + câu quote nghiêng Lora + nguồn
/// trích dẫn (khớp `curArt.quote`/`curArt.quoteSrc` trong design handoff). Khác `ILQuoteCardView`
/// (thẻ tối có vầng sáng) — đây là trích dẫn nội tuyến trên nền sáng, nên ở feature-scoped.
final class ILArticleQuoteView: UIView {

    // MARK: - Properties
    var quote: String = "" {
        didSet {
            quoteLabel.attributedText = ILTypography.makeAttributedString(
                text: quote,
                font: ILTypography.articleQuote,
                color: ILColors.ink,
                lineHeightMultiple: 1.6
            )
        }
    }

    var source: String = "" {
        didSet { sourceLabel.text = source }
    }

    // MARK: - UI Elements
    private let borderView = UIView()
    private let quoteLabel = UILabel()
    private let sourceLabel = UILabel()

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
        translatesAutoresizingMaskIntoConstraints = false

        borderView.translatesAutoresizingMaskIntoConstraints = false
        borderView.backgroundColor = ILColors.gold.withAlphaComponent(0.5)

        quoteLabel.numberOfLines = 0
        quoteLabel.translatesAutoresizingMaskIntoConstraints = false

        sourceLabel.font = ILTypography.subhead
        sourceLabel.textColor = ILColors.inkTertiary
        sourceLabel.numberOfLines = 0
        sourceLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(borderView)
        addSubview(quoteLabel)
        addSubview(sourceLabel)

        NSLayoutConstraint.activate([
            borderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            borderView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            borderView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            borderView.widthAnchor.constraint(equalToConstant: 2),

            quoteLabel.topAnchor.constraint(equalTo: topAnchor),
            quoteLabel.leadingAnchor.constraint(equalTo: borderView.trailingAnchor, constant: 14),
            quoteLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            sourceLabel.topAnchor.constraint(equalTo: quoteLabel.bottomAnchor, constant: ILMetrics.spaceSmall),
            sourceLabel.leadingAnchor.constraint(equalTo: quoteLabel.leadingAnchor),
            sourceLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            sourceLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
