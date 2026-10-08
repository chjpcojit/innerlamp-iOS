//
//  ILMalaProgressBarView.swift
//  InnerLamp
//

import UIKit

/// Thanh tiến trình mảnh (150 × 2pt, fill vàng) dưới hàng chip mục tiêu trên nền immersive.
/// Khác `ILLinearProgressBarView` (thẻ thống kê, nền sáng): track/fill lấy từ bộ token `--il-med-*`.
public final class ILMalaProgressBarView: UIView {

    // MARK: - Properties
    /// 0...1
    public var progress: Double = 0 {
        didSet {
            progress = min(1, max(0, progress))
            fillWidthConstraint.constant = barWidth * CGFloat(progress)
        }
    }

    // MARK: - UI Elements
    private let fillView = UIView()
    private var fillWidthConstraint: NSLayoutConstraint!

    private let barWidth: CGFloat = 150
    private let barHeight: CGFloat = 2

    // MARK: - Initializer
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.medTrack
        layer.cornerRadius = barHeight / 2
        clipsToBounds = true
        isAccessibilityElement = false

        fillView.backgroundColor = ILColors.medGold
        fillView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(fillView)

        fillWidthConstraint = fillView.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: barWidth),
            heightAnchor.constraint(equalToConstant: barHeight),
            fillView.leadingAnchor.constraint(equalTo: leadingAnchor),
            fillView.topAnchor.constraint(equalTo: topAnchor),
            fillView.bottomAnchor.constraint(equalTo: bottomAnchor),
            fillWidthConstraint
        ])
    }
}
