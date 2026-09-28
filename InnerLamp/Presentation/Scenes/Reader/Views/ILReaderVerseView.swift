//
//  ILReaderVerseView.swift
//  InnerLamp
//

import UIKit

/// Khối câu kinh trên màn Tụng kinh: viền trái vàng 2pt + kệ Việt (Lora 21px) + bản dịch Anh
/// (Lora 13.5px nghiêng). Khớp `isReader` trong design handoff. Chứa nội dung riêng của màn đọc
/// kinh (câu kinh + bản dịch) nên ở feature-scoped, không đưa lên DesignSystem.
final class ILReaderVerseView: UIView {

    // MARK: - Properties
    var verseText: String = "" {
        didSet {
            verseLabel.attributedText = ILTypography.makeParagraph(
                text: verseText,
                font: ILTypography.readerVerse,
                color: ILColors.ink,
                cssLineHeight: 1.6
            )
        }
    }

    var translationText: String = "" {
        didSet {
            translationLabel.attributedText = ILTypography.makeParagraph(
                text: translationText,
                font: ILTypography.readerTranslation,
                color: ILColors.inkTertiary,
                cssLineHeight: 1.7
            )
        }
    }

    // MARK: - UI Elements
    private let borderView = UIView()
    private let verseLabel = UILabel()
    private let translationLabel = UILabel()

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
        borderView.backgroundColor = ILColors.goldBorder

        verseLabel.numberOfLines = 0
        verseLabel.translatesAutoresizingMaskIntoConstraints = false

        translationLabel.numberOfLines = 0
        translationLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(borderView)
        addSubview(verseLabel)
        addSubview(translationLabel)

        NSLayoutConstraint.activate([
            borderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            borderView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            borderView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            borderView.widthAnchor.constraint(equalToConstant: 2),

            verseLabel.topAnchor.constraint(equalTo: topAnchor),
            verseLabel.leadingAnchor.constraint(equalTo: borderView.trailingAnchor, constant: 16),
            verseLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            translationLabel.topAnchor.constraint(equalTo: verseLabel.bottomAnchor, constant: ILMetrics.spaceMedium),
            translationLabel.leadingAnchor.constraint(equalTo: verseLabel.leadingAnchor),
            translationLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            translationLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
