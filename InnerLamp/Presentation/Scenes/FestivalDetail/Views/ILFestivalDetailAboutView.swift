//
//  ILFestivalDetailAboutView.swift
//  InnerLamp
//

import UIKit

/// EN: "About" block — a hairline divider followed by the description paragraphs. The caller hides the
///     block when there are no paragraphs (BR-CAL-14).
/// VI: Khối giới thiệu — đường kẻ mảnh rồi các đoạn mô tả. Nơi gọi ẩn khối khi không có đoạn nào
///     (BR-CAL-14).
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
    func configure(paragraphs: [String]) {
        paragraphStack.arrangedSubviews.forEach {
            paragraphStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for text in paragraphs {
            let label = UILabel()
            label.numberOfLines = 0
            label.attributedText = ILTypography.makeParagraph(
                text: text,
                font: ILTypography.postBody,
                color: ILColors.inkSecondary,
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
