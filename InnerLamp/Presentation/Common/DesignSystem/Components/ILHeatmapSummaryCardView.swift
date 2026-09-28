//
//  ILHeatmapSummaryCardView.swift
//  InnerLamp
//

import UIKit

/// Thẻ nổi bật (bộ token `--il-feat-*`) gồm 1 số liệu lớn kiểu serif + nhãn đơn vị, 1 dòng ghi chú,
/// lưới heatmap và 2 nhãn mốc thời gian ở chân thẻ. Cả thẻ là 1 vùng chạm. Chỉ nhận chuỗi + mảng
/// alpha nên dùng chung được cho mọi màn cần "số liệu + mật độ theo ngày" (vd. thẻ "7 ngày thiền
/// liên tục" ở màn Thiền định).
public final class ILHeatmapSummaryCardView: UIControl {

    // MARK: - Constants
    private enum Layout {
        static let cornerRadius: CGFloat = ILMetrics.radiusCardMedium
        static let padding: CGFloat = 18
        static let noteTopSpacing: CGFloat = 6
        static let heatmapTopSpacing: CGFloat = 14
        static let footerTopSpacing: CGFloat = 6
        static let glowSize: CGFloat = 200
        static let glowOffset: CGFloat = 60
    }

    // MARK: - Properties
    public var valueText: String = "" {
        didSet { valueLabel.text = valueText }
    }

    public var unitText: String = "" {
        didSet { unitLabel.text = unitText }
    }

    /// Ẩn khi rỗng.
    public var noteText: String = "" {
        didSet {
            noteLabel.text = noteText
            noteLabel.isHidden = noteText.isEmpty
        }
    }

    public var startLabelText: String = "" {
        didSet { startLabel.text = startLabelText }
    }

    public var endLabelText: String = "" {
        didSet { endLabel.text = endLabelText }
    }

    public var onTap: (() -> Void)?

    /// Số cột của lưới heatmap (mặc định 12 tuần).
    public let columns: Int

    // MARK: - UI Elements
    private let gradientLayer = CAGradientLayer()
    private let glowLayer = CAGradientLayer()
    private let valueLabel = UILabel()
    private let unitLabel = UILabel()
    private let noteLabel = UILabel()
    private let heatmapView: ILHeatmapGridView
    private let startLabel = UILabel()
    private let endLabel = UILabel()
    private let contentStack = UIStackView()

    // MARK: - Initializer
    public init(columns: Int = 12) {
        self.columns = max(columns, 1)
        self.heatmapView = ILHeatmapGridView(columns: max(columns, 1))
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        glowLayer.frame = CGRect(
            x: bounds.width - Layout.glowSize + Layout.glowOffset,
            y: -Layout.glowOffset,
            width: Layout.glowSize,
            height: Layout.glowSize
        )
        glowLayer.cornerRadius = Layout.glowSize / 2
    }

    // MARK: - Configure
    /// `intensities[i]` là alpha (0...1) của ô thứ i, điền theo hàng (khớp `ILHeatmapGridView`).
    public func configure(intensities: [CGFloat]) {
        heatmapView.configure(intensities: intensities)
    }

    // MARK: - Setup
    private func setupViews() {
        layer.cornerRadius = Layout.cornerRadius
        layer.borderWidth = 1
        clipsToBounds = true

        gradientLayer.startPoint = CGPoint(x: 0.1, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.9, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)

        glowLayer.type = .radial
        glowLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        glowLayer.endPoint = CGPoint(x: 1, y: 1)
        glowLayer.locations = [0, 0.66]
        layer.insertSublayer(glowLayer, above: gradientLayer)

        valueLabel.font = ILTypography.statDisplay
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)
        unitLabel.font = ILTypography.bodyCompact

        let valueRow = UIStackView(arrangedSubviews: [valueLabel, unitLabel])
        valueRow.axis = .horizontal
        valueRow.alignment = .lastBaseline
        valueRow.spacing = ILMetrics.spaceSmall

        noteLabel.font = ILTypography.subhead
        noteLabel.numberOfLines = 0

        startLabel.font = ILTypography.microCaption
        endLabel.font = ILTypography.microCaption
        startLabel.setContentHuggingPriority(.required, for: .horizontal)
        endLabel.setContentHuggingPriority(.required, for: .horizontal)

        let footerRow = UIStackView(arrangedSubviews: [startLabel, UIView(), endLabel])
        footerRow.axis = .horizontal
        footerRow.alignment = .center

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.isUserInteractionEnabled = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        [valueRow, noteLabel, heatmapView, footerRow].forEach { contentStack.addArrangedSubview($0) }
        contentStack.setCustomSpacing(Layout.noteTopSpacing, after: valueRow)
        contentStack.setCustomSpacing(Layout.heatmapTopSpacing, after: noteLabel)
        contentStack.setCustomSpacing(Layout.footerTopSpacing, after: heatmapView)
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: Layout.padding),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.padding),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.padding),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.padding)
        ])

        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)

        updateAppearance()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILHeatmapSummaryCardView, _) in
            view.updateAppearance()
        }
    }

    // MARK: - Appearance
    private func updateAppearance() {
        gradientLayer.colors = [ILColors.featBackgroundStart.cgColor, ILColors.featBackgroundEnd.cgColor]
        glowLayer.colors = [ILColors.featGlow.cgColor, ILColors.featGlowClear.cgColor]
        layer.borderColor = ILColors.featBorder.cgColor
        valueLabel.textColor = ILColors.ink
        unitLabel.textColor = ILColors.ink
        noteLabel.textColor = ILColors.featSub
        startLabel.textColor = ILColors.featSub
        endLabel.textColor = ILColors.featSub
    }

    // MARK: - Touch Animations
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
