//
//  ILSplashWordmarkLabel.swift
//  InnerLamp
//

import UIKit

/// Wordmark "InnerLamp" của màn Splash với hiệu ứng `ilword` của design: chữ hiện ra từ mờ,
/// đồng thời **co khoảng cách chữ** từ 0.34em về 0 và **nét** từ nhoè về rõ.
///
/// Không dùng `CAKeyframeAnimation` được vì `.kern` là thuộc tính của `NSAttributedString`,
/// không phải thuộc tính layer — Core Animation không nội suy được. Nên tự chạy `CADisplayLink`
/// và vẽ lại chuỗi mỗi frame; hiệu ứng chỉ kéo dài ~1.65s nên chi phí không đáng kể.
///
/// `blur(6px)` của CSS không có tương đương trên `UILabel` — xấp xỉ bằng bóng loang cùng màu
/// chữ (`shadowRadius` giảm dần), cho cảm giác nét chữ đang lấy lại tiêu cự.
final class ILSplashWordmarkLabel: UILabel {

    // MARK: - Spec
    private enum Timing {
        /// `ilword 1.1s cubic-bezier(.2,.8,.3,1) .55s both`.
        static let duration: TimeInterval = 1.1
        static let delay: TimeInterval = 0.55
        /// `letter-spacing: .34em` lúc bắt đầu, về 0 khi kết thúc.
        static let startLetterSpacingEm: CGFloat = 0.34
    }

    private enum Blur {
        /// `filter: blur(6px)` → `blur(0)`.
        static let startRadius: CGFloat = 6
        static let startOpacity: Float = 0.9
    }

    // MARK: - Properties
    private let wordmark: String
    private var displayLink: CADisplayLink?
    private var animationStart: CFTimeInterval = 0
    /// Tiến độ `ilword` hiện tại — giữ lại để vẽ lại khi theme đổi (màu chữ resolve theo
    /// light/dark, `attributedText`/`shadowColor` không tự đảo theo trait).
    private var progress: CGFloat = 0

    // MARK: - Initializer
    init(text: String) {
        self.wordmark = text
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        numberOfLines = 1
        textAlignment = .center
        // Bóng loang thay cho blur — cùng màu chữ để không ám màu lạ lên nền.
        layer.shadowColor = ILColors.splashInk.cgColor
        layer.shadowOffset = .zero
        apply(progress: 0)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILSplashWordmarkLabel, _) in
            view.applyColorAppearanceChange()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        displayLink?.invalidate()
    }

    // MARK: - Animation
    // CAAnimation add trước khi view có window sẽ bị Core Animation bỏ qua — chỉ gọi sau khi
    // view đã lên màn (vd. trong `viewDidAppear`), không phải lúc khởi tạo.

    /// Chạy `ilword`. Gọi lại khi đang chạy thì bỏ qua, không chồng hiệu ứng.
    func startRevealAnimation() {
        guard displayLink == nil else { return }

        // Mốc bắt đầu đặt ở tương lai để giữ nguyên trạng thái ẩn trong suốt `delay`.
        animationStart = CACurrentMediaTime() + Timing.delay

        let link = CADisplayLink(target: self, selector: #selector(handleFrame))
        displayLink = link
        link.add(to: .main, forMode: .common)
    }

    @objc private func handleFrame(_ link: CADisplayLink) {
        let elapsed = link.timestamp - animationStart
        guard elapsed > 0 else { return }

        let linear = min(elapsed / Timing.duration, 1.0)
        apply(progress: Self.easeOut(linear))

        if linear >= 1.0 {
            link.invalidate()
            displayLink = nil
        }
    }

    /// Xấp xỉ `cubic-bezier(.2,.8,.3,1)` — đường ease-out bậc ba, đủ khớp cảm giác của design.
    private static func easeOut(_ t: Double) -> CGFloat {
        CGFloat(1 - pow(1 - t, 3))
    }

    /// Vẽ lại chuỗi ở mức tiến độ `progress` (0 = trạng thái đầu, 1 = trạng thái nghỉ).
    private func apply(progress: CGFloat) {
        self.progress = progress

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let font = ILTypography.splashWordmark
        let letterSpacingEm = Timing.startLetterSpacingEm * (1 - progress)
        let ink = ILColors.splashInk.resolvedColor(with: traitCollection)

        attributedText = NSAttributedString(
            string: wordmark,
            attributes: [
                .font: font,
                .foregroundColor: ink,
                .kern: font.pointSize * letterSpacingEm,
                .paragraphStyle: paragraph
            ]
        )

        layer.shadowColor = ink.cgColor
        layer.opacity = Float(progress)
        layer.shadowRadius = Blur.startRadius * (1 - progress)
        layer.shadowOpacity = Blur.startOpacity * Float(1 - progress)
    }

    private func applyColorAppearanceChange() {
        // Vẽ lại đúng tiến độ hiện tại — `apply(progress:)` chỉ đổi màu, không chạy lại hiệu ứng.
        apply(progress: progress)
    }
}
