//
//  ILLinearProgressBarView.swift
//  InnerLamp
//

import UIKit

/// Thanh tiến trình đơn, fill gradient vàng — dùng cho thẻ thống kê (vd: phút thiền hôm nay).
/// Khác `ILStepProgressBar` (nhiều bước rời nhau), đây là 1 track liên tục theo tỉ lệ `progress`.
public final class ILLinearProgressBarView: UIView {

    // MARK: - Properties
    /// 0...1
    public var progress: Double = 0 {
        didSet {
            progress = min(1, max(0, progress))
            setNeedsLayout()
        }
    }

    // MARK: - UI Elements
    private let fillLayer = CAGradientLayer()
    private var fillWidthConstraint: NSLayoutConstraint!
    private let fillView = UIView()

    // MARK: - Initializer
    public init(progress: Double = 0) {
        self.progress = min(1, max(0, progress))
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        layer.cornerRadius = 2.5
        clipsToBounds = true
        backgroundColor = ILColors.ink.withAlphaComponent(0.09)

        fillView.translatesAutoresizingMaskIntoConstraints = false
        fillView.layer.cornerRadius = 2.5
        fillView.clipsToBounds = true
        addSubview(fillView)

        fillLayer.colors = [ILColors.gold.cgColor, ILColors.goldDeep.cgColor]
        fillLayer.startPoint = CGPoint(x: 0, y: 0.5)
        fillLayer.endPoint = CGPoint(x: 1, y: 0.5)
        fillView.layer.addSublayer(fillLayer)

        fillWidthConstraint = fillView.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 5),
            fillView.leadingAnchor.constraint(equalTo: leadingAnchor),
            fillView.topAnchor.constraint(equalTo: topAnchor),
            fillView.bottomAnchor.constraint(equalTo: bottomAnchor),
            fillWidthConstraint
        ])
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        fillWidthConstraint.constant = bounds.width * CGFloat(progress)
        layoutIfNeeded()
        fillLayer.frame = fillView.bounds
    }
}
