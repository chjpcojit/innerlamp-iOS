//
//  ILStepProgressBar.swift
//  InnerLamp
//
//  Created by ChjpCoj on 12/9/26.
//

import UIKit

/// Thanh tiến trình nhiều bước dùng chung (vd: onboarding, form nhiều màn hình).
/// Mỗi step là 1 track; khi step chuyển sang active, phần fill chạy trái→phải trong `fillDuration`.
public final class ILStepProgressBar: UIView {

    /// Thời lượng chuẩn để 1 step chạy từ rỗng đến đầy.
    public static let fillDuration: TimeInterval = 0.3

    // MARK: - Properties
    public var numberOfSteps: Int {
        didSet {
            guard numberOfSteps != oldValue else { return }
            numberOfSteps = max(1, numberOfSteps)
            rebuildSegments()
        }
    }

    /// Step hiện tại (0-based). Set giá trị mới sẽ tự animate các step liên quan.
    public var currentStep: Int = 0 {
        didSet {
            guard isSetupComplete else { return }
            currentStep = max(0, min(currentStep, numberOfSteps - 1))
            updateSegments(animated: true)
        }
    }

    private let activeColor: UIColor
    private let inactiveColor: UIColor
    private let spacing: CGFloat
    private let fillDuration: TimeInterval

    private let stackView = UIStackView()
    private var segments: [Segment] = []
    private var isSetupComplete = false

    // MARK: - Initializer
    public init(
        numberOfSteps: Int,
        currentStep: Int = 0,
        activeColor: UIColor = ILColors.gold,
        inactiveColor: UIColor = ILColors.ink.withAlphaComponent(0.14),
        spacing: CGFloat = 6,
        fillDuration: TimeInterval = ILStepProgressBar.fillDuration
    ) {
        self.numberOfSteps = max(1, numberOfSteps)
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.spacing = spacing
        self.fillDuration = fillDuration
        super.init(frame: .zero)
        self.currentStep = max(0, min(currentStep, self.numberOfSteps - 1))
        setupViews()
        isSetupComplete = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        stackView.axis = .horizontal
        stackView.spacing = spacing
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 3),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        rebuildSegments()
    }

    private func rebuildSegments() {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        segments = (0..<numberOfSteps).map { _ in
            Segment(activeColor: activeColor, inactiveColor: inactiveColor)
        }
        segments.forEach { stackView.addArrangedSubview($0) }

        updateSegments(animated: false)
    }

    private func updateSegments(animated: Bool) {
        for (index, segment) in segments.enumerated() {
            segment.setFilled(index <= currentStep, animated: animated, duration: fillDuration)
        }
    }

    // MARK: - Segment
    private final class Segment: UIView {
        private let fillView = UIView()
        private var fillWidthConstraint: NSLayoutConstraint!
        private var isFilled = false

        init(activeColor: UIColor, inactiveColor: UIColor) {
            super.init(frame: .zero)
            backgroundColor = inactiveColor
            layer.cornerRadius = 1.5
            clipsToBounds = true

            fillView.backgroundColor = activeColor
            fillView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(fillView)

            fillWidthConstraint = fillView.widthAnchor.constraint(equalToConstant: 0)
            NSLayoutConstraint.activate([
                fillView.leadingAnchor.constraint(equalTo: leadingAnchor),
                fillView.topAnchor.constraint(equalTo: topAnchor),
                fillView.bottomAnchor.constraint(equalTo: bottomAnchor),
                fillWidthConstraint
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func setFilled(_ filled: Bool, animated: Bool, duration: TimeInterval) {
            isFilled = filled
            layoutIfNeeded()
            fillWidthConstraint.constant = filled ? bounds.width : 0

            if animated {
                UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) {
                    self.layoutIfNeeded()
                }
            } else {
                layoutIfNeeded()
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            // Track resize (vd: xoay máy) → giữ đúng tỉ lệ đầy/rỗng hiện tại, không animate lại.
            fillWidthConstraint.constant = isFilled ? bounds.width : 0
        }
    }
}
