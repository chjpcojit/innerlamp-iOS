//
//  ILMalaCounterView.swift
//  InnerLamp
//

import UIKit

/// Thẻ tràng hạt — vòng 18 hạt nhỏ (sáng dần theo `count`/`goal`) kèm hạt mẹ và đuôi ở dưới, số
/// đếm ở giữa, câu niệm + mô tả và mũi tên "›". Cả thẻ là một vùng chạm (`onTap`) dẫn tới màn Niệm Phật. Dữ liệu-hóa hoàn toàn nên dùng
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
    private var beadLayers: [CALayer] = []
    private let motherBeadLayer = CALayer()
    private let tailLayer = CALayer()
    private let innerCircle = UIView()
    private let countLabel = UILabel()
    private let goalLabel = UILabel()
    private let mantraLabel = UILabel()
    private let helperLabel = UILabel()
    private let chevronLabel = UILabel()

    // Geometry of the bead ring (96×104 box in the design, ring centered at (48, 48)).
    private let beadAreaSize = CGSize(width: 96, height: 104)
    private let beadRingRadius: CGFloat = 40
    private let beadCount = 18
    private let beadSize: CGFloat = 9
    private let beadRingWidth: CGFloat = 1
    private let motherBeadSize: CGFloat = 12
    private let motherBeadRingWidth: CGFloat = 2
    private let motherBeadCenter = CGPoint(x: 48, y: 90)
    private let tailRect = CGRect(x: 47, y: 94, width: 2, height: 8)
    private let countCircleSize: CGFloat = 60

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
        layer.borderColor = cgColor(ILColors.border)

        beadControl.translatesAutoresizingMaskIntoConstraints = false
        beadControl.isUserInteractionEnabled = false

        beadLayers = (0..<beadCount).map { _ in
            let bead = CALayer()
            beadControl.layer.addSublayer(bead)
            return bead
        }

        tailLayer.backgroundColor = cgColor(ILColors.gold.withAlphaComponent(0.7))
        tailLayer.cornerRadius = 1
        beadControl.layer.addSublayer(tailLayer)

        beadControl.layer.addSublayer(motherBeadLayer)

        innerCircle.isUserInteractionEnabled = false
        innerCircle.translatesAutoresizingMaskIntoConstraints = false

        countLabel.font = ILTypography.malaCardCount
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
            beadControl.widthAnchor.constraint(equalToConstant: beadAreaSize.width),
            beadControl.heightAnchor.constraint(equalToConstant: beadAreaSize.height),

            innerCircle.centerXAnchor.constraint(equalTo: beadControl.leadingAnchor, constant: beadAreaSize.width / 2),
            innerCircle.centerYAnchor.constraint(equalTo: beadControl.topAnchor, constant: beadAreaSize.width / 2),
            innerCircle.widthAnchor.constraint(equalToConstant: countCircleSize),
            innerCircle.heightAnchor.constraint(equalToConstant: countCircleSize),

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

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil { applyColorAppearanceChange() }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layoutBeads()
    }

    /// Beads sit on a circle starting at the bottom and going clockwise (as in the design).
    private func layoutBeads() {
        let center = CGPoint(x: beadAreaSize.width / 2, y: beadAreaSize.width / 2)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for (index, bead) in beadLayers.enumerated() {
            let angle = CGFloat.pi / 2 + (CGFloat(index) + 0.5) * 2 * .pi / CGFloat(beadCount)
            bead.position = CGPoint(
                x: center.x + beadRingRadius * cos(angle),
                y: center.y + beadRingRadius * sin(angle)
            )
        }
        motherBeadLayer.position = motherBeadCenter
        tailLayer.frame = tailRect
        CATransaction.commit()
    }

    private func updateCount() {
        countLabel.text = "\(count)"
        let progress = goal > 0 ? min(1, max(0, Double(count) / Double(goal))) : 0
        let litCount = Int((progress * Double(beadCount)).rounded())

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for (index, bead) in beadLayers.enumerated() {
            let isLit = index < litCount
            // A lit bead has a 1px ring outside its 9px body, so its layer is 2px larger.
            let side = isLit ? beadSize + beadRingWidth * 2 : beadSize
            bead.bounds = CGRect(x: 0, y: 0, width: side, height: side)
            bead.cornerRadius = side / 2
            bead.backgroundColor = cgColor(isLit ? ILColors.malaBeadLit : ILColors.malaBeadIdle)
            bead.borderWidth = isLit ? beadRingWidth : 0
            bead.borderColor = cgColor(ILColors.malaBeadLitRing)
        }
        // Mother bead: 12px gold with a 2px ring in the card color.
        let motherSide = motherBeadSize + motherBeadRingWidth * 2
        motherBeadLayer.bounds = CGRect(x: 0, y: 0, width: motherSide, height: motherSide)
        motherBeadLayer.cornerRadius = motherSide / 2
        motherBeadLayer.backgroundColor = cgColor(ILColors.gold)
        motherBeadLayer.borderWidth = motherBeadRingWidth
        motherBeadLayer.borderColor = cgColor(ILColors.surface)
        CATransaction.commit()
    }

    private func applyColorAppearanceChange() {
        layer.borderColor = cgColor(ILColors.border)
        tailLayer.backgroundColor = cgColor(ILColors.gold.withAlphaComponent(0.7))
        updateCount()
    }

    /// EN: Resolves a dynamic color against this view's own traits — `UIColor.cgColor` alone uses `UITraitCollection.current`, which is stale in layer code and trait-change callbacks (beads stayed light-mode in dark mode).
    /// VI: Resolve màu dynamic theo trait của chính view — `UIColor.cgColor` đơn thuần dùng `UITraitCollection.current` nên bị cũ ở code layer/callback đổi trait (hạt giữ màu light khi sang dark mode).
    private func cgColor(_ color: UIColor) -> CGColor {
        color.resolvedColor(with: traitCollection).cgColor
    }

    @objc private func handleTap() {
        onTap?()
    }
}
