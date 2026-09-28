//
//  ILDeityVowRowView.swift
//  InnerLamp
//

import UIKit

/// 1 đại nguyện đánh số (số Lora màu nhấn + nội dung) trong mục "Đại nguyện" của màn chi tiết
/// Phật & Bồ Tát — thẻ nền `surface` viền nhẹ, bo 16. Riêng cho màn này nên ở `Scenes/Deity`.
final class ILDeityVowRowView: UIView {

    private enum Layout {
        static let numberWidth: CGFloat = 24
        static let radius: CGFloat = 16
        static let verticalInset: CGFloat = 12
        static let horizontalInset: CGFloat = 14
    }

    // MARK: - UI Elements
    private let numberLabel = UILabel()
    private let textLabel = UILabel()

    // MARK: - Initializer
    init(model: ILDeityVowModel) {
        super.init(frame: .zero)
        setupViews()
        numberLabel.text = model.number
        textLabel.attributedText = ILTypography.makeParagraph(
            text: model.text,
            font: ILTypography.bodyCompact,
            color: ILColors.ink,
            cssLineHeight: 1.55
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = ILColors.surface
        layer.cornerRadius = Layout.radius
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor

        numberLabel.font = ILTypography.scriptureBodySmall
        numberLabel.textColor = ILColors.link

        textLabel.numberOfLines = 0

        [numberLabel, textLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            numberLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalInset),
            numberLabel.firstBaselineAnchor.constraint(equalTo: textLabel.firstBaselineAnchor),
            numberLabel.widthAnchor.constraint(equalToConstant: Layout.numberWidth),

            textLabel.leadingAnchor.constraint(equalTo: numberLabel.trailingAnchor, constant: 12),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalInset),
            textLabel.topAnchor.constraint(equalTo: topAnchor, constant: Layout.verticalInset),
            textLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.verticalInset)
        ])

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILDeityVowRowView, _) in
            view.layer.borderColor = ILColors.border.cgColor
        }
    }
}
