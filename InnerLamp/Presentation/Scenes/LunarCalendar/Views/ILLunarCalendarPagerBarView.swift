//
//  ILLunarCalendarPagerBarView.swift
//  InnerLamp
//

import UIKit

/// Thanh điều khiển carousel tháng: nút ‹ · gợi ý "Trượt ngang để xem tháng khác" · nút ›.
final class ILLunarCalendarPagerBarView: UIView {

    // MARK: - Properties
    var hintText: String = "" {
        didSet { hintLabel.text = hintText }
    }

    var previousAccessibilityLabel: String? {
        didSet { previousButton.accessibilityLabel = previousAccessibilityLabel }
    }

    var nextAccessibilityLabel: String? {
        didSet { nextButton.accessibilityLabel = nextAccessibilityLabel }
    }

    var onPrevious: (() -> Void)?
    var onNext: (() -> Void)?

    // MARK: - UI Elements
    private let previousButton = ILChevronCircleButton(direction: .left)
    private let nextButton = ILChevronCircleButton(direction: .right)

    private let hintLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.chip
        label.textColor = ILColors.inkTertiary
        label.textAlignment = .center
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        return label
    }()

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
        previousButton.onTap = { [weak self] in self?.onPrevious?() }
        nextButton.onTap = { [weak self] in self?.onNext?() }

        [previousButton, hintLabel, nextButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            previousButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            previousButton.topAnchor.constraint(equalTo: topAnchor),
            previousButton.bottomAnchor.constraint(equalTo: bottomAnchor),

            nextButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            nextButton.topAnchor.constraint(equalTo: topAnchor),
            nextButton.bottomAnchor.constraint(equalTo: bottomAnchor),

            hintLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            hintLabel.leadingAnchor.constraint(equalTo: previousButton.trailingAnchor, constant: ILMetrics.spaceSmall),
            hintLabel.trailingAnchor.constraint(equalTo: nextButton.leadingAnchor, constant: -ILMetrics.spaceSmall)
        ])
    }
}
