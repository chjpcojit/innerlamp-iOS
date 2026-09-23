//
//  ILMalaStrandView.swift
//  InnerLamp
//

import UIKit

/// Dây tràng hạt dọc, dùng trên nền immersive. Hạt gần vạch giữa to và rõ nhất, xa dần thì nhỏ và
/// mờ, mép trên/dưới tan vào nền. Chạm hoặc kéo lên/xuống một lần → đúng một hạt trượt về giữa
/// vạch, gọi `onAdvance` một lần rồi caller tăng `count`.
///
/// - Chạm (dịch < 6pt): dây trượt lên một hạt.
/// - Kéo: dây đi theo ngón tay (nửa tốc độ); quá 22pt thì "chốt" một hạt theo hướng kéo
///   (kéo xuống → hạt phía trên về giữa, kéo lên → hạt phía dưới về giữa); nhả sớm hơn thì trượt về chỗ cũ.
///
/// Hạt mẹ (mỗi `motherInterval` hạt) nằm cố định trên dây nên trượt về giữa đúng lúc — không nhảy
/// vị trí khi kết thúc animation dù kéo theo hướng nào.
public final class ILMalaStrandView: UIView {

    // MARK: - Properties
    /// Số hạt hiện tại. Đổi từ ngoài (khởi tạo, "Bắt đầu lại", vòng mới) thì dây được căn lại về
    /// hạt này; thay đổi do chính lần chốt hạt vừa rồi gây ra thì giữ nguyên vị trí dây.
    public var count: Int = 0 {
        didSet {
            guard count != oldValue else { return }
            if isAwaitingCountUpdate {
                isAwaitingCountUpdate = false
            } else {
                anchor = count
                layoutBeads()
            }
        }
    }

    /// Cứ mỗi `motherInterval` hạt có một hạt mẹ (mặc định 27 → 4 hạt mẹ trên 108).
    public var motherInterval: Int = 27 {
        didSet { layoutBeads() }
    }

    /// Gọi đúng một lần sau khi một hạt đã trượt xong về giữa vạch.
    public var onAdvance: (() -> Void)?

    // MARK: - Constants
    /// Khoảng cách giữa hai hạt liền kề (chính là quãng dây trượt cho mỗi lần đếm).
    private let pitch: CGFloat = 52
    private let baseBeadSize: CGFloat = 27
    private let maxBeadGrowth: CGFloat = 13
    private let growthFalloff: CGFloat = 72
    private let minBeadOpacity: Float = 0.16
    private let markerDiameter: CGFloat = 74
    private let tickWidth: CGFloat = 22
    private let tickInset: CGFloat = 8
    private let stringWidth: CGFloat = 1.5
    private let dragSnapDistance: CGFloat = 22
    private let tapMaxDistance: CGFloat = 6
    private let dragFollowRatio: CGFloat = 0.5
    private let snapDuration: CFTimeInterval = 0.23

    // MARK: - State
    /// Id của hạt đang nằm ở vạch giữa — hạt ở hàng `i` (âm = phía trên) có id `anchor + i`.
    private var anchor: Int = 0
    /// Độ dời dây (pt) — dương: dây đi lên, âm: dây đi xuống.
    private var offset: CGFloat = 0
    private var isAwaitingCountUpdate = false

    private var touchStartY: CGFloat = 0
    private var touchMoved: CGFloat = 0
    private var didFireSnap = false
    private var isTracking = false

    private var pendingCommit: (() -> Void)?
    private var displayLink: CADisplayLink?
    private var animationStart: CFTimeInterval = 0
    private var animationFrom: CGFloat = 0
    private var animationTarget: CGFloat = 0
    private var animationCompletion: (() -> Void)?

    // MARK: - Layers
    private let maskLayer = CAGradientLayer()
    private let stringLayer = CAGradientLayer()
    private let markerLayer = CAShapeLayer()
    private let leftTickLayer = CALayer()
    private let rightTickLayer = CALayer()
    private var beadLayers: [BeadLayer] = []

    // MARK: - Initializer
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        displayLink?.invalidate()
    }

    // MARK: - Setup
    private func setupViews() {
        clipsToBounds = true
        isMultipleTouchEnabled = false
        isAccessibilityElement = true
        accessibilityTraits = .adjustable

        maskLayer.colors = [UIColor.clear.cgColor, UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
        maskLayer.locations = [0, 0.16, 0.84, 1]
        layer.mask = maskLayer

        stringLayer.locations = [0, 0.14, 0.86, 1]
        layer.addSublayer(stringLayer)

        markerLayer.fillColor = UIColor.clear.cgColor
        markerLayer.lineWidth = 1
        layer.addSublayer(markerLayer)

        layer.addSublayer(leftTickLayer)
        layer.addSublayer(rightTickLayer)

        updateColors()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        maskLayer.frame = bounds

        let centerX = bounds.midX
        let centerY = bounds.midY
        stringLayer.frame = CGRect(x: centerX - stringWidth / 2, y: 0, width: stringWidth, height: bounds.height)
        markerLayer.frame = CGRect(
            x: centerX - markerDiameter / 2,
            y: centerY - markerDiameter / 2,
            width: markerDiameter,
            height: markerDiameter
        )
        // Nét 1pt vẽ dọc mép ngoài của khung -> thu vào nửa nét để vòng tròn nằm gọn trong 74pt.
        markerLayer.path = UIBezierPath(ovalIn: markerLayer.bounds.insetBy(dx: 0.5, dy: 0.5)).cgPath
        leftTickLayer.frame = CGRect(x: tickInset, y: centerY - 1, width: tickWidth, height: 1)
        rightTickLayer.frame = CGRect(x: bounds.width - tickInset - tickWidth, y: centerY - 1, width: tickWidth, height: 1)

        rebuildBeadPoolIfNeeded()
        layoutBeads()

        CATransaction.commit()
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateColors()
    }

    public override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil { stopAnimation() }
    }

    private func updateColors() {
        // Các CGColor bên dưới không tự đảo theo trait — resolve thủ công.
        let traits = traitCollection
        let clear = UIColor.clear.cgColor
        let line = ILColors.medStrandLine.resolvedColor(with: traits).cgColor
        stringLayer.colors = [clear, line, line, clear]
        markerLayer.strokeColor = ILColors.medMarkerRing.resolvedColor(with: traits).cgColor
        leftTickLayer.backgroundColor = ILColors.medMarkerTick.resolvedColor(with: traits).cgColor
        rightTickLayer.backgroundColor = ILColors.medMarkerTick.resolvedColor(with: traits).cgColor
    }

    // MARK: - Beads
    private var visibleRowSpan: Int {
        guard bounds.height > 0 else { return 0 }
        return Int(ceil(bounds.height / 2 / pitch)) + 1
    }

    private func rebuildBeadPoolIfNeeded() {
        let needed = visibleRowSpan * 2 + 1
        guard needed != beadLayers.count else { return }
        beadLayers.forEach { $0.removeFromSuperlayer() }
        beadLayers = (0..<needed).map { _ in BeadLayer() }
        beadLayers.forEach { layer.addSublayer($0) }
    }

    private func layoutBeads() {
        guard bounds.height > 0, !beadLayers.isEmpty else { return }
        let centerX = bounds.midX
        let centerY = bounds.midY
        let span = visibleRowSpan

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for (index, bead) in beadLayers.enumerated() {
            let row = index - span
            let y = centerY + CGFloat(row) * pitch - offset
            let distance = abs(y - centerY)
            let size = baseBeadSize + maxBeadGrowth * max(0, 1 - distance / growthFalloff)
            let opacity = max(minBeadOpacity, Float(1 - distance / (centerY * 0.95)))

            bead.configure(
                isMother: isMotherBead(id: anchor + row),
                size: size,
                center: CGPoint(x: centerX, y: y),
                opacity: opacity
            )
        }
        CATransaction.commit()
    }

    private func isMotherBead(id: Int) -> Bool {
        guard motherInterval > 0 else { return false }
        return ((id % motherInterval) + motherInterval) % motherInterval == 0
    }

    // MARK: - Touch handling
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        drainPendingCommit()
        stopAnimation()
        isTracking = true
        didFireSnap = false
        touchMoved = 0
        touchStartY = touch.location(in: self).y
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isTracking, !didFireSnap, let touch = touches.first else { return }
        let dy = touch.location(in: self).y - touchStartY
        touchMoved = abs(dy)
        if touchMoved >= dragSnapDistance {
            didFireSnap = true
            snap(direction: dy > 0 ? -1 : 1)
        } else {
            offset = -dy * dragFollowRatio
            layoutBeads()
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isTracking else { return }
        isTracking = false
        guard !didFireSnap else { return }
        if touchMoved < tapMaxDistance {
            snap(direction: 1)
        } else {
            animateOffset(to: 0, completion: nil)
        }
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isTracking else { return }
        isTracking = false
        guard !didFireSnap else { return }
        animateOffset(to: 0, completion: nil)
    }

    // MARK: - Accessibility
    public override func accessibilityIncrement() {
        snap(direction: 1)
    }

    // MARK: - Snap
    /// `direction` +1: dây đi lên (hạt phía dưới về giữa). -1: dây đi xuống (hạt phía trên về giữa).
    private func snap(direction: CGFloat) {
        drainPendingCommit()
        let commit: () -> Void = { [weak self] in
            guard let self else { return }
            self.pendingCommit = nil
            self.anchor += direction > 0 ? 1 : -1
            self.offset = 0
            self.isAwaitingCountUpdate = true
            self.layoutBeads()
            self.pulseMarker()
            self.onAdvance?()
        }
        pendingCommit = commit
        animateOffset(to: direction * pitch, completion: commit)
    }

    /// Hoàn tất ngay lần chốt đang trượt dở (người dùng chạm tiếp khi hạt chưa về tới giữa).
    private func drainPendingCommit() {
        stopAnimation()
        guard let commit = pendingCommit else { return }
        pendingCommit = nil
        commit()
    }

    private func pulseMarker() {
        let traits = traitCollection
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.12)
        markerLayer.setAffineTransform(CGAffineTransform(scaleX: 1.1, y: 1.1))
        markerLayer.strokeColor = ILColors.medMarkerRingActive.resolvedColor(with: traits).cgColor
        CATransaction.commit()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) { [weak self] in
            guard let self else { return }
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.12)
            self.markerLayer.setAffineTransform(.identity)
            self.markerLayer.strokeColor = ILColors.medMarkerRing.resolvedColor(with: self.traitCollection).cgColor
            CATransaction.commit()
        }
    }

    // MARK: - Offset animation (ease-out cubic, 230ms)
    private func animateOffset(to target: CGFloat, completion: (() -> Void)?) {
        stopAnimation()
        animationFrom = offset
        animationTarget = target
        animationCompletion = completion
        animationStart = CACurrentMediaTime()

        let link = CADisplayLink(target: DisplayLinkProxy(self), selector: #selector(DisplayLinkProxy.tick))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopAnimation() {
        displayLink?.invalidate()
        displayLink = nil
        animationCompletion = nil
    }

    fileprivate func handleDisplayLinkTick() {
        let progress = min(1, (CACurrentMediaTime() - animationStart) / snapDuration)
        let eased = 1 - pow(1 - CGFloat(progress), 3)
        offset = animationFrom + (animationTarget - animationFrom) * eased
        layoutBeads()

        guard progress >= 1 else { return }
        let completion = animationCompletion
        stopAnimation()
        completion?()
    }
}

// MARK: - DisplayLinkProxy
/// `CADisplayLink` giữ mạnh target — dùng proxy giữ yếu view để view vẫn `deinit` được.
private final class DisplayLinkProxy {
    private weak var target: ILMalaStrandView?

    init(_ target: ILMalaStrandView) {
        self.target = target
    }

    @objc func tick() {
        target?.handleDisplayLinkTick()
    }
}

// MARK: - BeadLayer
/// Một hạt: thân gradient radial, hai lớp giả inset-shadow (sáng phía trên, tối phía dưới), viền
/// và bóng đổ. Hạt mẹ dùng gradient vàng, hạt thường dùng gradient nâu.
private final class BeadLayer: CALayer {

    private let bodyLayer = CAGradientLayer()
    private let shineLayer = CAGradientLayer()
    private let shadeLayer = CAGradientLayer()
    private var isMother: Bool?

    override init() {
        super.init()
        setup()
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        borderWidth = 1

        shadowColor = ILColors.beadShadow.cgColor
        shadowOpacity = 1
        shadowOffset = CGSize(width: 0, height: 4)
        shadowRadius = 7

        bodyLayer.type = .radial
        bodyLayer.locations = [0, 0.58, 1]
        bodyLayer.startPoint = CGPoint(x: 0.34, y: 0.28)
        // Bán kính tới góc xa nhất (1, 1) của hạt tròn: hypot(0.66, 0.72) ≈ 0.977.
        bodyLayer.endPoint = CGPoint(x: 0.34 + 0.977, y: 0.28 + 0.977)
        addSublayer(bodyLayer)

        shineLayer.colors = [ILColors.beadHighlight.cgColor, UIColor.clear.cgColor]
        shineLayer.locations = [0, 0.25]
        addSublayer(shineLayer)

        shadeLayer.colors = [UIColor.clear.cgColor, ILColors.beadShade.cgColor]
        shadeLayer.locations = [0.7, 1]
        addSublayer(shadeLayer)
    }

    func configure(isMother: Bool, size: CGFloat, center: CGPoint, opacity: Float) {
        bounds = CGRect(x: 0, y: 0, width: size, height: size)
        position = center
        cornerRadius = size / 2
        shadowPath = UIBezierPath(ovalIn: bounds).cgPath
        self.opacity = opacity

        for sublayer in [bodyLayer, shineLayer, shadeLayer] {
            sublayer.frame = bounds
            sublayer.cornerRadius = size / 2
            sublayer.masksToBounds = true
        }

        guard self.isMother != isMother else { return }
        self.isMother = isMother
        if isMother {
            bodyLayer.colors = [ILColors.beadMotherLight.cgColor, ILColors.beadMotherMid.cgColor, ILColors.goldDeep.cgColor]
            borderColor = ILColors.beadMotherBorder.cgColor
        } else {
            bodyLayer.colors = [ILColors.beadLight.cgColor, ILColors.beadMid.cgColor, ILColors.beadDark.cgColor]
            borderColor = ILColors.beadBorder.cgColor
        }
    }
}
