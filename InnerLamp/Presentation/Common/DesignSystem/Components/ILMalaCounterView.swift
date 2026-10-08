//
//  ILMalaCounterView.swift
//  InnerLamp
//

import UIKit

/// Thẻ tràng hạt — vòng tròn có viền tiến trình theo `count`/`goal`, câu niệm + mô tả và mũi tên
/// "›". Cả thẻ là một vùng chạm (`onTap`) dẫn tới màn Niệm Phật. Dữ liệu-hóa hoàn toàn nên dùng
/// lại được, không riêng cho Trang chủ.
public final class ILMalaCounterView: UIView {

    // MARK: - Properties
    public var count: Int = 0 {
        didSet { updateCount() }
    }

    public var goal: Int = 108 {
        didSet { updateCount() }
    }

    /// Chuỗi hiển thị dưới số đếm (vd: "/ 108") — truyền sẵn từ caller thay vì format nội bộ,
    /// vì component này dùng chung nên không tự tra `.localized` theo key riêng của 1 feature.
    public var goalText: String = "" {
        didSet { goalLabel.text = goalText }
    }

    public var mantraText: String = "" {
        didSet { mantraLabel.text = mantraText }
    }

    public var helperText: String = "" {
        didSet { helperLabel.text = helperText }
    }

    public var onTap: (() -> Void)?

    // MARK: - UI Elements
    private let beadControl = UIView()
    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let innerCircle = UIView()
    private let countLabel = UILabel()
    private let goalLabel = UILabel()
    private let mantraLabel = UILabel()
    private let helperLabel = UILabel()
    private let chevronLabel = UILabel()

    private let ringDiameter: CGFloat = 92
    private let ringLineWidth: CGFloat = 6

    // MARK: - Initializer
    public init(count: Int = 0, goal: Int = 108, goalText: String = "", mantraText: String = "", helperText: String = "") {
        self.count = count
        self.goal = goal
        self.goalText = goalText
        self.mantraText = mantraText
        self.helperText = helperText
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardLarge
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor

        beadControl.translatesAutoresizingMaskIntoConstraints = false
        beadControl.isUserInteractionEnabled = false

        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = ILColors.gold.withAlphaComponent(0.16).cgColor
        trackLayer.lineWidth = ringLineWidth
        trackLayer.lineCap = .round
        beadControl.layer.addSublayer(trackLayer)

        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = ILColors.gold.cgColor
        progressLayer.lineWidth = ringLineWidth
        progressLayer.lineCap = .round
        beadControl.layer.addSublayer(progressLayer)

        innerCircle.isUserInteractionEnabled = false
        innerCircle.backgroundColor = ILColors.canvasWarm
        innerCircle.translatesAutoresizingMaskIntoConstraints = false

        countLabel.font = ILTypography.title1
        countLabel.textColor = ILColors.ink
        countLabel.textAlignment = .center

        goalLabel.font = ILTypography.caption
        goalLabel.textColor = ILColors.inkMuted
        goalLabel.textAlignment = .center

        let countStack = UIStackView(arrangedSubviews: [countLabel, goalLabel])
        countStack.axis = .vertical
        countStack.spacing = 1
        countStack.alignment = .center
        countStack.isUserInteractionEnabled = false
        countStack.translatesAutoresizingMaskIntoConstraints = false

        innerCircle.addSubview(countStack)
        beadControl.addSubview(innerCircle)

        mantraLabel.font = ILTypography.scriptureBodySmall
        mantraLabel.textColor = ILColors.ink
        mantraLabel.numberOfLines = 0

        helperLabel.font = ILTypography.bodySmall
        helperLabel.textColor = ILColors.inkTertiary
        helperLabel.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [mantraLabel, helperLabel])
        textStack.axis = .vertical
        textStack.spacing = 6
        textStack.alignment = .leading
        textStack.translatesAutoresizingMaskIntoConstraints = false

        chevronLabel.text = "›"
        chevronLabel.font = ILTypography.title2
        chevronLabel.textColor = ILColors.inkTertiary
        chevronLabel.setContentHuggingPriority(.required, for: .horizontal)
        chevronLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let contentStack = UIStackView(arrangedSubviews: [beadControl, textStack, chevronLabel])
        contentStack.axis = .horizontal
        contentStack.spacing = 20
        contentStack.alignment = .center
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            beadControl.widthAnchor.constraint(equalToConstant: ringDiameter),
            beadControl.heightAnchor.constraint(equalToConstant: ringDiameter),

            innerCircle.leadingAnchor.constraint(equalTo: beadControl.leadingAnchor, constant: ringLineWidth),
            innerCircle.trailingAnchor.constraint(equalTo: beadControl.trailingAnchor, constant: -ringLineWidth),
            innerCircle.topAnchor.constraint(equalTo: beadControl.topAnchor, constant: ringLineWidth),
            innerCircle.bottomAnchor.constraint(equalTo: beadControl.bottomAnchor, constant: -ringLineWidth),

            countStack.centerXAnchor.constraint(equalTo: innerCircle.centerXAnchor),
            countStack.centerYAnchor.constraint(equalTo: innerCircle.centerYAnchor),

            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        isAccessibilityElement = true
        accessibilityTraits = .button

        updateCount()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILMalaCounterView, _) in
            view.applyColorAppearanceChange()
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let rect = CGRect(x: 0, y: 0, width: ringDiameter, height: ringDiameter)
        let center = CGPoint(x: ringDiameter / 2, y: ringDiameter / 2)
        let radius = (ringDiameter - ringLineWidth) / 2
        let circlePath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 1.5 * .pi,
            clockwise: true
        )
        trackLayer.frame = rect
        trackLayer.path = circlePath.cgPath
        progressLayer.frame = rect
        progressLayer.path = circlePath.cgPath
        innerCircle.layer.cornerRadius = (ringDiameter - ringLineWidth * 2) / 2
    }

    private func updateCount() {
        countLabel.text = "\(count)"
        let progress = goal > 0 ? min(1, max(0, Double(count) / Double(goal))) : 0
        progressLayer.strokeEnd = CGFloat(progress)
    }

    private func applyColorAppearanceChange() {
        layer.borderColor = ILColors.border.cgColor
        trackLayer.strokeColor = ILColors.gold.withAlphaComponent(0.16).cgColor
        progressLayer.strokeColor = ILColors.gold.cgColor
    }

    @objc private func handleTap() {
        onTap?()
    }
}
