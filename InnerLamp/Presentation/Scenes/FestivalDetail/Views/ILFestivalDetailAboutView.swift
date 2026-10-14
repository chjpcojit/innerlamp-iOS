//
//  ILFestivalDetailAboutView.swift
//  InnerLamp
//

import UIKit

/// EN: "About" block — a hairline divider followed by the description paragraphs. With no paragraphs
///     it shows `emptyText` in a muted style instead of hiding the block.
/// VI: Khối giới thiệu — đường kẻ mảnh rồi các đoạn mô tả. Không có đoạn nào thì hiện `emptyText`
///     (màu nhạt) thay vì ẩn khối.
final class ILFestivalDetailAboutView: UIStackView {

    // MARK: - UI Elements
    private lazy var divider: UIView = {
        let view = UIView()
        view.backgroundColor = ILColors.border
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var paragraphStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = ILMetrics.spaceMedium
        return stack
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupViews()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration
    func configure(paragraphs: [String], emptyText: String) {
        paragraphStack.arrangedSubviews.forEach {
            paragraphStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        let isEmpty = paragraphs.isEmpty
        for text in isEmpty ? [emptyText] : paragraphs {
            let label = UILabel()
            label.numberOfLines = 0
            label.attributedText = ILTypography.makeParagraph(
                text: text,
                font: ILTypography.postBody,
                color: isEmpty ? ILColors.inkSubtle : ILColors.inkSecondary,
                cssLineHeight: 1.75
            )
            paragraphStack.addArrangedSubview(label)
        }
    }

    // MARK: - Setup
    private func setupViews() {
        axis = .vertical
        spacing = ILMetrics.spaceMedium
        [divider, paragraphStack].forEach { addArrangedSubview($0) }
        divider.heightAnchor.constraint(equalToConstant: ILMetrics.hairline).isActive = true
    }
}
