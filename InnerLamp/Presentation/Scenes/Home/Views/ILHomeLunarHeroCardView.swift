//
//  ILHomeLunarHeroCardView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 11/9/26.
//

import UIKit

/// Thẻ âm lịch lớn Trang chủ: nền gradient ấm + vầng sáng vàng, ngày dương ở đỉnh, ngày/tháng/năm
/// âm cỡ lớn, câu kinh trích trong ngày ở đáy. Riêng cho Trang chủ (không màn nào khác dùng bố cục
/// này) nên nằm ở `Scenes/Home`, không phải component dùng chung.
///
/// Đổi theo light/dark qua bộ `--il-hero-*` trong design handoff: nền `--il-sunk2 → --il-tint`,
/// overlay `--il-hero-ov`, chữ `--il-hero-ink / -ink2 / -sub`, nhấn `--il-hero-acc / -acc2`.
///
/// Ảnh của ngày (`GET /v1/calendar/image`) phủ kín thẻ phía trên gradient; gradient vẫn là
/// placeholder khi chưa có ảnh/ảnh lỗi. Một lớp phủ màu nền (`sunk2`) giữ cho chữ đọc được trên ảnh,
/// và dòng ghi công tác giả/giấy phép nằm dưới cùng.
final class ILHomeLunarHeroCardView: UIControl {

    // MARK: - Properties
    var eyebrowText: String = "" {
        didSet { applyEyebrow() }
    }

    var solarLabel: String = "" {
        didSet { solarLabelView.text = solarLabel }
    }

    var lunarDay: Int = 1 {
        didSet {
            lunarDayText = String(format: "%02d", lunarDay)
            if pendingRoll {
                playRollAnimation()
            } else if window != nil, !shownDayText.isEmpty, shownDayText != lunarDayText {
                rollLunarDay(from: shownDayText)
            } else {
                finishRoll()
            }
        }
    }

    var lunarMonthLabel: String = "" {
        didSet { lunarMonthLabelView.text = lunarMonthLabel }
    }

    var lunarYearLabel: String = "" {
        didSet { lunarYearLabelView.text = lunarYearLabel }
    }

    var verseLines: [String] = [] {
        didSet { rebuildVerse() }
    }

    var verseSource: String = "" {
        didSet { verseSourceLabel.text = verseSource }
    }

    var imageURL: String? {
        didSet { applyImage(oldValue: oldValue) }
    }

    var imageCreditText: String = "" {
        didSet {
            // The line is always laid out (a blank placeholder when there is no credit) so the
            // verse never shifts when the image and its credit arrive.
            creditLabel.text = imageCreditText.isEmpty ? " " : imageCreditText
        }
    }

    var onTap: (() -> Void)?

    /// "Numeric text" roll of the lunar day number: each digit slides vertically — the old digit
    /// moves up and fades out while the new one rises from below and fades in, staggered per digit.
    private static let cardHeight: CGFloat = 440
    private static let rollDuration: TimeInterval = 0.55
    private static let rollStagger: TimeInterval = 0.07
    private var lunarDayText = ""
    /// The day text the user last saw rolled in, so a replay only moves the digits that changed
    /// since the previous appearance.
    private var shownDayText = ""
    private var rollOverlays: [UIView] = []
    private var rollDisplayLink: CADisplayLink?
    private var rollItems: [RollItem] = []
    private var rollStart: CFTimeInterval = 0
    /// Set when `playRollAnimation()` is called before the lunar data has arrived.
    private var pendingRoll = false

    // MARK: - UI Elements
    private let gradientLayer = CAGradientLayer()
    private let overlayLayer = CAGradientLayer()
    private let glowLayer = CAGradientLayer()

    /// Ảnh của ngày; nền trong suốt để gradient phía sau làm placeholder.
    private lazy var imageView: ILRemoteImageView = {
        let v = ILRemoteImageView(frame: .zero)
        v.backgroundColor = .clear
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isUserInteractionEnabled = false
        // A bitmap's intrinsic size must never size the card — the image only fills what the card is.
        v.setContentHuggingPriority(.fittingSizeLevel, for: .vertical)
        v.setContentCompressionResistancePriority(.fittingSizeLevel, for: .vertical)
        v.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        v.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        return v
    }()
    private lazy var scrimView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isUserInteractionEnabled = false
        v.alpha = 0
        return v
    }()
    private let scrimLayer = CAGradientLayer()
    private lazy var creditLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.caption
        v.textColor = ILColors.heroSub
        v.textAlignment = .center
        v.numberOfLines = 0
        v.text = " "
        return v
    }()

    private lazy var solarLabelView: UILabel = {
        let v = UILabel()
        v.font = ILTypography.bodySmallMedium
        v.textColor = ILColors.heroInk
        v.numberOfLines = 1
        return v
    }()
    private lazy var eyebrowDot: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 7
        v.layer.borderWidth = 1
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var eyebrowLabel: UILabel = {
        let v = UILabel()
        v.numberOfLines = 1
        return v
    }()
    private lazy var lunarDayLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.cormorant(size: 68)
        v.textColor = ILColors.heroInk
        v.numberOfLines = 1
        return v
    }()
    private lazy var lunarMonthLabelView: UILabel = {
        let v = UILabel()
        v.font = ILTypography.cormorant(size: 18)
        v.textColor = ILColors.heroInk2
        v.numberOfLines = 1
        return v
    }()
    private lazy var lunarYearLabelView: UILabel = {
        let v = UILabel()
        v.font = ILTypography.bodySmall
        v.textColor = ILColors.heroSub
        v.numberOfLines = 1
        return v
    }()
    private lazy var verseStack: UIStackView = {
        let v = UIStackView()
        v.axis = .vertical
        v.spacing = 4
        v.alignment = .center
        v.isUserInteractionEnabled = false
        return v
    }()
    private lazy var verseSourceLabel: UILabel = {
        let v = UILabel()
        v.font = verseSourceFont
        v.textColor = ILColors.heroSub
        v.textAlignment = .center
        v.numberOfLines = 1
        return v
    }()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        overlayLayer.frame = bounds
        scrimLayer.frame = bounds
        glowLayer.frame = CGRect(x: bounds.width - 150, y: -70, width: 220, height: 220)
        glowLayer.cornerRadius = 110
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // Never leave the number mid-roll if the card leaves the screen.
        if window == nil { finishRoll() }
    }

    // MARK: - Lunar day roll
    /// Replays the roll-in. Call every time the Home screen appears; if the lunar data has not
    /// arrived yet, the roll starts as soon as it does.
    func playRollAnimation() {
        guard !lunarDayText.isEmpty else {
            pendingRoll = true
            return
        }
        pendingRoll = false
        rollLunarDay(from: shownDayText)
    }

    /// Rolls `lunarDayText` in. Digits of `oldText` (if any) roll out upwards while the new ones
    /// rise from below; only the digits that differ animate.
    private func rollLunarDay(from oldText: String) {
        finishRoll()
        shownDayText = lunarDayText
        guard !UIAccessibility.isReduceMotionEnabled, window != nil else { return }

        let oldDigits = Array(oldText)
        let newDigits = Array(lunarDayText)
        // Only the digits that actually differ animate — e.g. 25 → 26 rolls just the last digit.
        let changedIndices = newDigits.indices.filter { index in
            !(oldDigits.count == newDigits.count && oldDigits[index] == newDigits[index])
        }
        guard let lastChanged = changedIndices.last else { return }

        let rise = lunarDayLabel.font.lineHeight * 0.4
        let font = lunarDayLabel.font ?? ILTypography.cormorant(size: 68)
        let newOffsets = digitOffsets(of: lunarDayText, font: font)
        let oldOffsets = digitOffsets(of: oldText, font: font)

        // The real label keeps the layout and the final text; the overlays only draw the motion.
        lunarDayLabel.alpha = 0

        // Unchanged digits stay still: draw them sharp from the start.
        for index in newDigits.indices where !changedIndices.contains(index) {
            _ = makeDigitView(newDigits[index], offset: newOffsets[index], font: font)
        }
        for index in changedIndices {
            let delay = Double(index) * Self.rollStagger
            if index < oldDigits.count, oldDigits.count == newDigits.count {
                let outgoing = makeDigitView(oldDigits[index], offset: oldOffsets[index], font: font)
                rollItems.append(RollItem(view: outgoing.view, source: outgoing.source, delay: delay, isIncoming: false))
            }
            let incoming = makeDigitView(newDigits[index], offset: newOffsets[index], font: font)
            rollItems.append(RollItem(view: incoming.view, source: incoming.source, delay: delay, isIncoming: true))
        }
        rollTravel = rise
        rollTotalDuration = Double(lastChanged) * Self.rollStagger + Self.rollDuration
        rollStart = CACurrentMediaTime()
        renderRollFrame(now: rollStart)

        let link = CADisplayLink(target: self, selector: #selector(handleRollTick))
        link.add(to: .main, forMode: .common)
        rollDisplayLink = link
    }

    private struct RollItem {
        let view: UIImageView
        let source: CIImage
        let delay: TimeInterval
        let isIncoming: Bool
    }

    private static let blurRadius: CGFloat = 4
    /// Photo scrim alphas, top → bottom: light enough to keep the photo visible, strong enough for the text.
    private static let scrimAlphas: [CGFloat] = [0.1, 0.15, 0.3]
    private var rollTravel: CGFloat = 0
    private var rollTotalDuration: TimeInterval = 0

    @objc private func handleRollTick() {
        let now = CACurrentMediaTime()
        renderRollFrame(now: now)
        if now - rollStart >= rollTotalDuration { finishRoll() }
    }

    /// One frame of the roll. UIKit cannot animate a content blur on a plain view (only
    /// `UIVisualEffectView`, which blurs what is *behind* it), so each digit is re-blurred every
    /// frame with `CIGaussianBlur` (GPU, tiny image) while position and alpha follow the same
    /// ease-out curve: the incoming digit sharpens and rises, the outgoing one blurs and lifts away.
    private func renderRollFrame(now: CFTimeInterval) {
        for item in rollItems {
            let u = min(1, max(0, (now - rollStart - item.delay) / Self.rollDuration))
            let eased = 1 - pow(1 - u, 3)
            // `away` is 1 when the digit is fully hidden/blurred/offset, 0 when sharp and in place.
            let away = item.isIncoming ? 1 - eased : eased
            let direction: CGFloat = item.isIncoming ? 1 : -1
            item.view.alpha = CGFloat(1 - away)
            item.view.transform = CGAffineTransform(translationX: 0, y: direction * rollTravel * CGFloat(away))

            let sigma = Double(Self.blurRadius * CGFloat(away)) * Double(item.view.traitCollection.displayScale)
            guard sigma > 0.1 else {
                item.view.image = UIImage(ciImage: item.source, scale: item.view.traitCollection.displayScale, orientation: .up)
                continue
            }
            let blurred = item.source.clampedToExtent()
                .applyingGaussianBlur(sigma: sigma)
                .cropped(to: item.source.extent)
            if let cg = Self.ciContext.createCGImage(blurred, from: item.source.extent) {
                item.view.image = UIImage(cgImage: cg, scale: item.view.traitCollection.displayScale, orientation: .up)
            }
        }
    }

    /// Exact x of each character, taken from CoreText so the overlay digits line up with the real
    /// label (kerning included) instead of drifting by per-digit widths.
    private func digitOffsets(of text: String, font: UIFont) -> [CGFloat] {
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [.font: font]))
        return (0..<text.count).map { CTLineGetOffsetForStringIndex(line, $0, nil) }
    }

    /// Adds one digit as an image view pinned to the day label. The view is padded by the blur
    /// spread so blurred frames are not clipped.
    private func makeDigitView(_ digit: Character, offset: CGFloat, font: UIFont) -> (view: UIImageView, source: CIImage) {
        let pad = Self.blurRadius * 3
        let text = String(digit)
        let size = (text as NSString).size(withAttributes: [.font: font])
        let canvas = CGSize(width: ceil(size.width) + pad * 2, height: ceil(font.lineHeight) + pad * 2)
        let color = ILColors.heroInk.resolvedColor(with: traitCollection)

        let sharp = UIGraphicsImageRenderer(size: canvas).image { _ in
            (text as NSString).draw(at: CGPoint(x: pad, y: pad), withAttributes: [.font: font, .foregroundColor: color])
        }
        let view = UIImageView(image: sharp)
        view.isUserInteractionEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: lunarDayLabel.leadingAnchor, constant: offset - pad),
            view.topAnchor.constraint(equalTo: lunarDayLabel.topAnchor, constant: -pad),
            view.widthAnchor.constraint(equalToConstant: canvas.width),
            view.heightAnchor.constraint(equalToConstant: canvas.height)
        ])
        rollOverlays.append(view)
        return (view, CIImage(image: sharp) ?? CIImage())
    }

    private static let ciContext = CIContext()

    private func finishRoll() {
        rollDisplayLink?.invalidate()
        rollDisplayLink = nil
        rollItems = []
        rollOverlays.forEach { $0.removeFromSuperview() }
        rollOverlays = []
        lunarDayLabel.alpha = 1
        lunarDayLabel.text = lunarDayText
    }

    // MARK: - Setup
    private func setupViews() {
        layer.cornerRadius = ILMetrics.radiusCardLarge + 2
        clipsToBounds = true

        // Nền container `linear-gradient(170deg, --il-sunk2, --il-tint)` — đổi theo light/dark.
        gradientLayer.startPoint = CGPoint(x: 0.2, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.8, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)

        glowLayer.type = .radial
        glowLayer.colors = [ILColors.goldGlowStrong.cgColor, ILColors.goldGlowClear.cgColor]
        glowLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        glowLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(glowLayer, above: gradientLayer)

        // Overlay `--il-hero-ov` (wash đổi theo light/dark) — nằm trên cùng, dưới các label.
        overlayLayer.startPoint = CGPoint(x: 0.5, y: 0)
        overlayLayer.endPoint = CGPoint(x: 0.5, y: 1)
        overlayLayer.locations = [0.0, 0.58, 1.0]
        layer.insertSublayer(overlayLayer, above: glowLayer)

        applyGradients()

        scrimLayer.startPoint = CGPoint(x: 0.5, y: 0)
        scrimLayer.endPoint = CGPoint(x: 0.5, y: 1)
        scrimView.layer.addSublayer(scrimLayer)
        // The scrim fades in together with the image (same crossfade), never before it.
        imageView.onImageLoaded = { [weak self] in
            self?.scrimView.alpha = 1
        }
        addSubview(imageView)
        addSubview(scrimView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrimView.topAnchor.constraint(equalTo: topAnchor),
            scrimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrimView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrimView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            eyebrowDot.widthAnchor.constraint(equalToConstant: 14),
            eyebrowDot.heightAnchor.constraint(equalToConstant: 14)
        ])
        applyEyebrowDot()

        let eyebrowRow = UIStackView(arrangedSubviews: [eyebrowDot, eyebrowLabel])
        eyebrowRow.axis = .horizontal
        eyebrowRow.spacing = 7
        eyebrowRow.alignment = .center

        let topStack = UIStackView(arrangedSubviews: [solarLabelView, eyebrowRow, lunarDayLabel, lunarMonthLabelView, lunarYearLabelView])
        topStack.axis = .vertical
        topStack.alignment = .leading
        topStack.spacing = 6
        topStack.setCustomSpacing(14, after: eyebrowRow)
        // Extra room below the day number so the rolling digits do not run over the month label.
        topStack.setCustomSpacing(14, after: lunarDayLabel)
        topStack.isUserInteractionEnabled = false
        topStack.translatesAutoresizingMaskIntoConstraints = false

        let verseBlock = UIStackView(arrangedSubviews: [verseStack, verseSourceLabel, creditLabel])
        verseBlock.axis = .vertical
        verseBlock.spacing = 8
        verseBlock.alignment = .center
        verseBlock.isUserInteractionEnabled = false
        verseBlock.translatesAutoresizingMaskIntoConstraints = false

        addSubview(topStack)
        addSubview(verseBlock)

        NSLayoutConstraint.activate([
            topStack.topAnchor.constraint(equalTo: topAnchor, constant: 22),
            topStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22),
            topStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -22),

            verseBlock.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22),
            verseBlock.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22),
            verseBlock.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -26),
            // Strictly fixed: the card is the same height with placeholder, image or any content.
            heightAnchor.constraint(equalToConstant: Self.cardHeight)
        ])
        // Soft gap so an over-long verse can never make the constraints unsatisfiable.
        let verseGap = verseBlock.topAnchor.constraint(greaterThanOrEqualTo: topStack.bottomAnchor, constant: 24)
        verseGap.priority = .defaultHigh
        verseGap.isActive = true

        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILHomeLunarHeroCardView, _) in
            view.applyColorAppearanceChange()
        }
    }

    /// Lora 12 nghiêng — không có preset sẵn khớp size này trong `ILTypography`, cùng cách
    /// `ILQuoteCardView`/`ILSplashViewController` tự derive font nghiêng cục bộ.
    private var verseSourceFont: UIFont {
        let base = ILTypography.literata(size: 13, italic: true)
        guard let descriptor = base.fontDescriptor.withSymbolicTraits(.traitItalic) else { return base }
        return UIFont(descriptor: descriptor, size: 12)
    }

    private func rebuildVerse() {
        verseStack.arrangedSubviews.forEach {
            verseStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for line in verseLines {
            let label = UILabel()
            label.attributedText = ILTypography.makeAttributedString(
                text: line,
                font: ILTypography.cormorant(size: 20, italic: true),
                color: ILColors.heroInk,
                lineHeightMultiple: 1.4,
                alignment: .center
            )
            label.numberOfLines = 0
            label.textAlignment = .center
            verseStack.addArrangedSubview(label)
        }
    }

    /// `CAGradientLayer` màu là CGColor tĩnh, không tự đảo theo trait — resolve lại khi hệ thống
    /// đổi light/dark (`--il-sunk2`/`--il-tint`/`--il-hero-ov` đều có hai biến thể).
    private func applyGradients() {
        let trait = traitCollection
        gradientLayer.colors = [
            ILColors.sunk2.resolvedColor(with: trait).cgColor,
            ILColors.tint.resolvedColor(with: trait).cgColor
        ]
        let sunk = ILColors.sunk2.resolvedColor(with: trait)
        scrimLayer.colors = Self.scrimAlphas.map { sunk.withAlphaComponent($0).cgColor }
        overlayLayer.colors = [
            ILColors.heroOverlayStart.resolvedColor(with: trait).cgColor,
            ILColors.heroOverlayMid.resolvedColor(with: trait).cgColor,
            ILColors.heroOverlayEnd.resolvedColor(with: trait).cgColor
        ]
    }

    /// `imageURL` is re-assigned on every state emission; `setImage` clears the bitmap and refetches,
    /// so only call it when the URL actually changed.
    private func applyImage(oldValue: String?) {
        guard imageURL != oldValue else { return }
        scrimView.alpha = 0
        imageView.setImage(urlString: imageURL)
    }

    private func applyEyebrow() {
        eyebrowLabel.attributedText = ILTypography.makeEyebrow(text: eyebrowText, color: ILColors.heroAccent)
    }

    private func applyEyebrowDot() {
        eyebrowDot.backgroundColor = ILColors.heroAccent
        eyebrowDot.layer.borderColor = ILColors.heroAccentBorder.cgColor
    }

    private func applyColorAppearanceChange() {
        applyGradients()
        applyEyebrow()
        applyEyebrowDot()
        rebuildVerse()
    }

    @objc private func handleTouchDown() {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = CGAffineTransform(scaleX: 0.99, y: 0.99)
        }
    }

    @objc private func handleTouchUp() {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = .identity
        }
    }

    @objc private func handleTapAction() {
        onTap?()
    }
}
