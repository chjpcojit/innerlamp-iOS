//
//  ILProfileHeatmapCardView.swift
//  InnerLamp
//

import UIKit

/// Thẻ "Nhật ký 12 tuần qua": tiêu đề + chú thích "84 / 84 ngày ghi" + lưới heatmap 21 cột. Cả
/// thẻ là 1 vùng chạm (mở Tiến trình). Biết `ILProfileHeatmapModel` nên thuộc riêng màn Tôi.
final class ILProfileHeatmapCardView: UIControl {

    // MARK: - Constants
    private enum Layout {
        static let padding: CGFloat = 18
        static let heatmapColumns = 21
    }

    // MARK: - Properties
    var title: String = "" {
        didSet { titleLabel.text = title }
    }

    var onTap: (() -> Void)?

    // MARK: - UI Elements
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.headerTitle
        label.textColor = ILColors.ink
        return label
    }()

    private lazy var summaryLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.inkSubtle
        label.textAlignment = .right
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()

    private lazy var gridView = ILHeatmapGridView(columns: Layout.heatmapColumns)

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
        registerForAppearanceChanges()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardSmall + 2
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor

        let headerRow = UIStackView(arrangedSubviews: [titleLabel, summaryLabel])
        headerRow.axis = .horizontal
        headerRow.alignment = .firstBaseline
        headerRow.spacing = ILMetrics.spaceSmall

        let contentStack = UIStackView(arrangedSubviews: [headerRow, gridView])
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = ILMetrics.spaceMedium
        contentStack.isUserInteractionEnabled = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
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
    }

    // MARK: - Configure
    func configure(with model: ILProfileHeatmapModel) {
        summaryLabel.text = model.summaryText
        gridView.configure(intensities: model.intensities)
    }

    // `layer.borderColor` là CGColor tĩnh, không tự đảo theo trait — refresh thủ công khi đổi
    // light/dark.
    private func registerForAppearanceChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.layer.borderColor = ILColors.border.cgColor
        }
    }

    // MARK: - Touch
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
