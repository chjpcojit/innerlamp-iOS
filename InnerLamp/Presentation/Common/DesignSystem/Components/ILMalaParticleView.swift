//
//  ILMalaParticleView.swift
//  InnerLamp
//

import UIKit

/// Lớp hiệu ứng hạt phía sau nội dung màn Niệm Phật (design `mlFx`): bụi sáng vàng trôi chậm
/// liên tục, cộng với "chấm bi" toả ra và vòng sóng mỗi lần lần hạt (`burst`). `big` dùng cho hạt
/// mẹ — nhiều hạt và vòng sóng rộng hơn. Không nhận chạm.
///
/// Vật lý theo "khung 60fps" của thiết kế, chuẩn hoá theo thời gian thực nên không phụ thuộc tần
/// số quét màn hình. Display link chỉ chạy khi view nằm trong window.
public final class ILMalaParticleView: UIView {

    // MARK: - Types
    private struct Mote {
        var x: CGFloat, y: CGFloat
        let radius: CGFloat
        let vx: CGFloat, vy: CGFloat
        var phase: CGFloat
        let phaseSpeed: CGFloat
        let alpha: CGFloat
    }

    private struct Spark {
        var x: CGFloat, y: CGFloat
        var vx: CGFloat, vy: CGFloat
        let radius: CGFloat
        let alpha: CGFloat
        var age: CGFloat = 0
        let life: CGFloat
    }

    private struct Ring {
        let x: CGFloat, y: CGFloat
        let startRadius: CGFloat, endRadius: CGFloat
        var age: CGFloat
        let life: CGFloat
    }

    // MARK: - Constants
    private let moteCount = 46

    // MARK: - State
    private var motes: [Mote] = []
    private var sparks: [Spark] = []
    private var rings: [Ring] = []
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0

    // MARK: - Initializer
    public override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        isOpaque = false
        backgroundColor = .clear
        isAccessibilityElement = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        displayLink?.invalidate()
    }

    // MARK: - Lifecycle
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            displayLink?.invalidate()
            displayLink = nil
        } else if displayLink == nil {
            let link = CADisplayLink(target: ParticleLinkProxy(self), selector: #selector(ParticleLinkProxy.tick(_:)))
            link.add(to: .main, forMode: .common)
            displayLink = link
            lastTimestamp = 0
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if motes.isEmpty, bounds.width > 0, bounds.height > 0 { seedMotes() }
    }

    // MARK: - Public API
    /// Toả hạt + vòng sóng từ `point` (toạ độ của view này).
    public func burst(at point: CGPoint, big: Bool) {
        let count = big ? 54 : 26
        for _ in 0..<count {
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let speed = (big ? 2.2 : 1.6) + CGFloat.random(in: 0..<(big ? 4.2 : 2.6))
            sparks.append(Spark(
                x: point.x + cos(angle) * 18,
                y: point.y + sin(angle) * 18,
                vx: cos(angle) * speed,
                vy: sin(angle) * speed,
                radius: 0.8 + CGFloat.random(in: 0..<(big ? 2.6 : 1.8)),
                alpha: 0.6 + CGFloat.random(in: 0..<0.4),
                life: 50 + CGFloat.random(in: 0..<(big ? 60 : 36))
            ))
        }
        rings.append(Ring(x: point.x, y: point.y, startRadius: 22, endRadius: big ? 170 : 96, age: 0, life: big ? 70 : 46))
        if big {
            rings.append(Ring(x: point.x, y: point.y, startRadius: 22, endRadius: 120, age: -10, life: 60))
        }
    }

    // MARK: - Simulation
    private func seedMotes() {
        motes = (0..<moteCount).map { _ in
            Mote(
                x: .random(in: 0..<bounds.width),
                y: .random(in: 0..<bounds.height),
                radius: 0.6 + .random(in: 0..<2.2),
                vx: .random(in: -0.06..<0.06),
                vy: -(0.08 + .random(in: 0..<0.28)),
                phase: .random(in: 0..<(2 * .pi)),
                phaseSpeed: 0.01 + .random(in: 0..<0.025),
                alpha: 0.1 + .random(in: 0..<0.22)
            )
        }
    }

    fileprivate func step(timestamp: CFTimeInterval) {
        defer { lastTimestamp = timestamp }
        guard lastTimestamp > 0 else { return }
        // Number of design "frames" (1/60s) elapsed, capped so a hitch doesn't teleport particles.
        let frames = min(4, CGFloat(timestamp - lastTimestamp) * 60)

        for index in motes.indices {
            motes[index].y += motes[index].vy * frames
            motes[index].x += (motes[index].vx + sin(motes[index].phase) * 0.12) * frames
            motes[index].phase += motes[index].phaseSpeed * frames
            if motes[index].y < -6 {
                motes[index].y = bounds.height + 6
                motes[index].x = .random(in: 0..<max(1, bounds.width))
            }
        }

        let damping = pow(0.955, frames)
        for index in sparks.indices.reversed() {
            sparks[index].age += frames
            if sparks[index].age >= sparks[index].life {
                sparks.remove(at: index)
                continue
            }
            sparks[index].vx *= damping
            sparks[index].vy = sparks[index].vy * damping - 0.012 * frames
            sparks[index].x += sparks[index].vx * frames
            sparks[index].y += sparks[index].vy * frames
        }
        for index in rings.indices.reversed() {
            rings[index].age += frames
            if rings[index].age >= rings[index].life { rings.remove(at: index) }
        }

        setNeedsDisplay()
    }

    // MARK: - Drawing
    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let traits = traitCollection
        let bright = ILColors.goldBright.resolvedColor(with: traits)
        let deep = ILColors.gold.resolvedColor(with: traits)

        for mote in motes {
            let alpha = mote.alpha * (0.55 + 0.45 * sin(mote.phase * 1.7))
            drawGlow(in: context, center: CGPoint(x: mote.x, y: mote.y), radius: mote.radius * 3,
                     colors: [bright.withAlphaComponent(alpha), bright.withAlphaComponent(0)], locations: [0, 1])
        }

        for ring in rings where ring.age >= 0 {
            let k = ring.age / ring.life
            let eased = 1 - pow(1 - k, 3)
            let radius = ring.startRadius + (ring.endRadius - ring.startRadius) * eased
            context.setStrokeColor(bright.withAlphaComponent(0.55 * (1 - k)).cgColor)
            context.setLineWidth(1.5 * (1 - k) + 0.3)
            context.strokeEllipse(in: CGRect(x: ring.x - radius, y: ring.y - radius, width: radius * 2, height: radius * 2))
        }

        for spark in sparks {
            let k = spark.age / spark.life
            let alpha = (1 - k) * spark.alpha
            let radius = spark.radius * (1 - k * 0.4)
            drawGlow(in: context, center: CGPoint(x: spark.x, y: spark.y), radius: radius * 2.6,
                     colors: [bright.withAlphaComponent(alpha), deep.withAlphaComponent(alpha * 0.7), deep.withAlphaComponent(0)],
                     locations: [0, 0.4, 1])
        }
    }

    private func drawGlow(in context: CGContext, center: CGPoint, radius: CGFloat, colors: [UIColor], locations: [CGFloat]) {
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors.map(\.cgColor) as CFArray,
            locations: locations
        ) else { return }
        context.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
    }
}

// MARK: - ParticleLinkProxy
/// `CADisplayLink` giữ mạnh target — dùng proxy giữ yếu view để view vẫn `deinit` được.
private final class ParticleLinkProxy {
    private weak var target: ILMalaParticleView?

    init(_ target: ILMalaParticleView) {
        self.target = target
    }

    @objc func tick(_ link: CADisplayLink) {
        target?.step(timestamp: link.timestamp)
    }
}
