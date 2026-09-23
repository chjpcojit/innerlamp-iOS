//
//  ILMalaCountDisplayView.swift
//  InnerLamp
//

import UIKit

/// Số đếm lớn kèm mục tiêu ("27 / 108") và thanh tiến trình mảnh bên dưới, dùng trên nền
/// immersive. Số "nảy" nhẹ (scale .93 trong 120ms) mỗi khi tăng — giống `beadScale` trong thiết kế.
public final class ILMalaCountDisplayView: UIView {

    // MARK: - Properties
    public var count: Int = 0 {
        didSet {
            guard count != oldValue else { return }
            countLabel.text = "\(count)"
            updateProgress()
            if count > oldValue { pop() }
        }
    }

    public var goal: Int = 108 {
        didSet { updateProgress() }
    }

    /// Chuỗi hiển thị cạnh số đếm (vd: "/ 108") — truyền sẵn từ caller vì component dùng chung
    /// không tự tra `.localized` theo key riêng của một feature.
    public var goalText: String = "" {
        didSet { goalLabel.text = goalText }
    }

    // MARK: - UI Elements
    private let countLabel = UILabel()
    private let goalLabel = UILabel()
    private let trackView = UIView()
    private let fillView = UIView()
    private var fillWidthConstraint: NSLayoutConstraint!

    private let barWidth: CGFloat = 150
    private let barHeight: CGFloat = 2

    // MARK: - Initializer
    public init(count: Int = 0, goal: Int = 108, goalText: String = "") {
        self.count = count
        self.goal = goal
        self.goalText = goalText
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        countLabel.font = ILTypography.immersiveCount
        countLabel.textColor = ILColors.medInk
        countLabel.text = "\(count)"

        goalLabel.font = ILTypography.bodyCompact
        goalLabel.textColor = ILColors.medInkSecondary
        goalLabel.text = goalText

        let numberStack = UIStackView(arrangedSubviews: [countLabel, goalLabel])
        numberStack.axis = .horizontal
        numberStack.alignment = .lastBaseline
        numberStack.spacing = ILMetrics.spaceSmall

        trackView.backgroundColor = ILColors.medTrack
        trackView.layer.cornerRadius = barHeight / 2
        trackView.clipsToBounds = true

        fillView.backgroundColor = ILColors.medGold
        fillView.translatesAutoresizingMaskIntoConstraints = false
        trackView.addSubview(fillView)

        let contentStack = UIStackView(arrangedSubviews: [numberStack, trackView])
        contentStack.axis = .vertical
        contentStack.alignment = .center
        contentStack.spacing = ILMetrics.spaceMedium
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        fillWidthConstraint = fillView.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor),

            trackView.widthAnchor.constraint(equalToConstant: barWidth),
            trackView.heightAnchor.constraint(equalToConstant: barHeight),

            fillView.leadingAnchor.constraint(equalTo: trackView.leadingAnchor),
            fillView.topAnchor.constraint(equalTo: trackView.topAnchor),
            fillView.bottomAnchor.constraint(equalTo: trackView.bottomAnchor),
            fillWidthConstraint
        ])

        updateProgress()
    }

    // MARK: - Update
    private func updateProgress() {
        let progress = goal > 0 ? min(1, max(0, Double(count) / Double(goal))) : 0
        fillWidthConstraint.constant = barWidth * CGFloat(progress)
    }

    private func pop() {
        UIView.animate(withDuration: 0.06, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.countLabel.transform = CGAffineTransform(scaleX: 0.93, y: 0.93)
        } completion: { _ in
            UIView.animate(withDuration: 0.06, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
                self.countLabel.transform = .identity
            }
        }
    }
}
