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
/// Chưa có ảnh tượng Phật thật (`image-slot` trong design handoff) — overlay wash hiện đặt trên
/// gradient nền (thay cho ảnh), khớp ghi chú "Ảnh chùa/sự kiện hiện là gradient tối; cần ảnh thật
/// từ phía sản phẩm" ở README design handoff.
final class ILHomeLunarHeroCardView: UIControl {

    // MARK: - Properties
    var eyebrowText: String = "" {
        didSet { applyEyebrow() }
    }

    var solarLabel: String = "" {
        didSet { solarLabelView.text = solarLabel }
    }

    var lunarDay: Int = 1 {
        didSet { lunarDayLabel.text = "\(lunarDay)" }
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

    var onTap: (() -> Void)?

    // MARK: - UI Elements
    private let gradientLayer = CAGradientLayer()
    private let overlayLayer = CAGradientLayer()
    private let glowLayer = CAGradientLayer()

    private let solarLabelView = UILabel()
    private let eyebrowDot = UIView()
    private let eyebrowLabel = UILabel()
    private let lunarDayLabel = UILabel()
    private let lunarMonthLabelView = UILabel()
    private let lunarYearLabelView = UILabel()
    private let verseStack = UIStackView()
    private let verseSourceLabel = UILabel()

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
        glowLayer.frame = CGRect(x: bounds.width - 150, y: -70, width: 220, height: 220)
        glowLayer.cornerRadius = 110
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

        solarLabelView.font = ILTypography.bodySmallMedium
        solarLabelView.textColor = ILColors.heroInk
        solarLabelView.numberOfLines = 1

        eyebrowDot.layer.cornerRadius = 7
        eyebrowDot.layer.borderWidth = 1
        eyebrowDot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            eyebrowDot.widthAnchor.constraint(equalToConstant: 14),
            eyebrowDot.heightAnchor.constraint(equalToConstant: 14)
        ])
        applyEyebrowDot()

        eyebrowLabel.numberOfLines = 1

        let eyebrowRow = UIStackView(arrangedSubviews: [eyebrowDot, eyebrowLabel])
        eyebrowRow.axis = .horizontal
        eyebrowRow.spacing = 7
        eyebrowRow.alignment = .center

        lunarDayLabel.font = ILTypography.lora(size: 52)
        lunarDayLabel.textColor = ILColors.heroInk
        lunarDayLabel.numberOfLines = 1

        lunarMonthLabelView.font = ILTypography.lora(size: 17)
        lunarMonthLabelView.textColor = ILColors.heroInk2
        lunarMonthLabelView.numberOfLines = 1

        lunarYearLabelView.font = ILTypography.bodySmall
        lunarYearLabelView.textColor = ILColors.heroSub
        lunarYearLabelView.numberOfLines = 1

        verseStack.axis = .vertical
        verseStack.spacing = 4
        verseStack.alignment = .center
        verseStack.isUserInteractionEnabled = false

        verseSourceLabel.font = verseSourceFont
        verseSourceLabel.textColor = ILColors.heroSub
        verseSourceLabel.textAlignment = .center
        verseSourceLabel.numberOfLines = 1

        let topStack = UIStackView(arrangedSubviews: [solarLabelView, eyebrowRow, lunarDayLabel, lunarMonthLabelView, lunarYearLabelView])
        topStack.axis = .vertical
        topStack.alignment = .leading
        topStack.spacing = 6
        topStack.setCustomSpacing(14, after: eyebrowRow)
        topStack.setCustomSpacing(2, after: lunarDayLabel)
        topStack.isUserInteractionEnabled = false
        topStack.translatesAutoresizingMaskIntoConstraints = false

        let verseBlock = UIStackView(arrangedSubviews: [verseStack, verseSourceLabel])
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

            verseBlock.topAnchor.constraint(greaterThanOrEqualTo: topStack.bottomAnchor, constant: 24),
            verseBlock.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22),
            verseBlock.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22),
            verseBlock.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -26),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 340)
        ])

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
        let base = ILTypography.lora(size: 12)
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
                font: ILTypography.lora(size: 18.5),
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
        overlayLayer.colors = [
            ILColors.heroOverlayStart.resolvedColor(with: trait).cgColor,
            ILColors.heroOverlayMid.resolvedColor(with: trait).cgColor,
            ILColors.heroOverlayEnd.resolvedColor(with: trait).cgColor
        ]
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
