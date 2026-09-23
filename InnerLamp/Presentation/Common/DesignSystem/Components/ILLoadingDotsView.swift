//
//  ILLoadingDotsView.swift
//  InnerLamp
//

import UIKit

/// Hàng chấm tròn nhấp nháy tuần tự — chỉ số lượng/kích thước/màu, không mang nội dung
/// riêng của màn nào, dùng làm chỉ báo "đang tải" chung (Splash, các màn chờ khác).
public final class ILLoadingDotsView: UIView {

    // MARK: - Properties
    private let dotCount: Int
    private let dotDiameter: CGFloat
    private let dotColor: UIColor
    private let stackView = UIStackView()
    private let dots: [UIView]

    // MARK: - Initializer
    public init(
        dotCount: Int = 3,
        dotDiameter: CGFloat = 6,
        spacing: CGFloat = ILMetrics.spaceSmall,
        color: UIColor = ILColors.gold
    ) {
        self.dotCount = dotCount
        self.dotDiameter = dotDiameter
        self.dotColor = color
        self.dots = (0..<dotCount).map { _ in
            let dot = UIView()
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.backgroundColor = color
            dot.layer.cornerRadius = dotDiameter / 2.0
            return dot
        }
        super.init(frame: .zero)
        setupViews(spacing: spacing)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews(spacing: CGFloat) {
        translatesAutoresizingMaskIntoConstraints = false

        stackView.axis = .horizontal
        stackView.spacing = spacing
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        dots.forEach { dot in
            stackView.addArrangedSubview(dot)
            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: dotDiameter),
                dot.heightAnchor.constraint(equalToConstant: dotDiameter)
            ])
        }
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Animation
    /// CAAnimation add trước khi view có window sẽ bị Core Animation bỏ qua — chỉ gọi
    /// sau khi view đã lên màn (vd. trong `viewDidAppear`), không phải lúc khởi tạo.
    public func startPulsingAnimation() {
        for (index, dot) in dots.enumerated() {
            let delay = Double(index) * Self.pulseDelayStep

            let pulseOpacity = CAKeyframeAnimation(keyPath: "opacity")
            pulseOpacity.values = [
                Self.pulseMinOpacity, Self.pulseMaxOpacity, Self.pulseMinOpacity
            ]
            pulseOpacity.keyTimes = [0, 0.5, 1]
            pulseOpacity.duration = Self.pulseDuration
            pulseOpacity.repeatCount = .infinity
            pulseOpacity.beginTime = CACurrentMediaTime() + delay
            pulseOpacity.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            dot.layer.add(pulseOpacity, forKey: "ilDotPulseOpacity")
        }
    }

    // MARK: - Spec
    /// `ildot` của design handoff — chỉ đổi độ mờ, không đổi kích thước.
    private static let pulseDuration: TimeInterval = 1.2
    private static let pulseDelayStep: TimeInterval = 0.2
    private static let pulseMinOpacity: Float = 0.25
    private static let pulseMaxOpacity: Float = 0.9
}
