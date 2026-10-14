//
//  ILMeditationHubTimerSectionView.swift
//  InnerLamp
//

import UIKit

/// Khối "Thiền chuông · tự hành trì" của màn Thiền định: eyebrow + danh sách preset (vòng tròn số
/// phút + tên + mô tả + mũi tên) + nút viền nét đứt "+ Tự thiết lập đồng hồ & chuông". Biết
/// `ILMeditationHubPresetModel` nên thuộc riêng màn này.
final class ILMeditationHubTimerSectionView: UIView {

    // MARK: - Properties
    var onPresetTapped: ((String) -> Void)?
    var onCustomTimerTapped: (() -> Void)?

    // MARK: - UI Elements
    private lazy var eyebrow = ILSectionEyebrowView()
    private lazy var rowsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = ILMetrics.rowSpacing
        return stack
    }()
    private let customButton = DashedOutlineButton()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    func configure(sectionTitle: String, presets: [ILMeditationHubPresetModel], customTitle: String) {
        eyebrow.title = sectionTitle
        customButton.title = customTitle
        rebuild(presets: presets)
    }

    // MARK: - Setup
    private func setupViews() {
        let contentStack = UIStackView(arrangedSubviews: [eyebrow, rowsStack, customButton])
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = ILMetrics.rowSpacing
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        customButton.onTap = { [weak self] in self?.onCustomTimerTapped?() }

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    private func rebuild(presets: [ILMeditationHubPresetModel]) {
        rowsStack.arrangedSubviews.forEach {
            rowsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for preset in presets {
            let row = PresetRowView(model: preset)
            row.onTap = { [weak self] in self?.onPresetTapped?(preset.id) }
            rowsStack.addArrangedSubview(row)
        }
    }
}

// MARK: - Preset Row

/// 1 hàng preset thiền chuông: vòng tròn viền vàng chứa số phút + "PHÚT", tên serif, mô tả, mũi tên.
private final class PresetRowView: UIControl {

    private enum Layout {
        static let cornerRadius: CGFloat = ILMetrics.radiusCardRegular
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 14
        static let minutesCircleSize: CGFloat = 52
        static let contentSpacing: CGFloat = 14
    }

    var onTap: (() -> Void)?

    private lazy var minutesLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.serifNumber
        label.textAlignment = .center
        return label
    }()

    private lazy var minutesUnitLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.microLabel
        label.textAlignment = .center
        return label
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.serifCardTitle
        label.numberOfLines = 1
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.numberOfLines = 2
        return label
    }()

    private lazy var chevronLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.chevron
        label.text = "›"
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()

    init(model: ILMeditationHubPresetModel) {
        super.init(frame: .zero)
        setupViews()
        minutesLabel.text = model.minutesText
        minutesUnitLabel.text = model.minutesUnitText
        nameLabel.text = model.name
        subtitleLabel.text = model.subtitle
        accessibilityLabel = model.accessibilityLabel
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        isAccessibilityElement = true
        accessibilityTraits = .button

        layer.cornerRadius = Layout.cornerRadius
        layer.borderWidth = 1

        let circle = UIView()
        circle.layer.cornerRadius = Layout.minutesCircleSize / 2
        circle.layer.borderWidth = 1
        circle.translatesAutoresizingMaskIntoConstraints = false

        let circleTextStack = UIStackView(arrangedSubviews: [minutesLabel, minutesUnitLabel])
        circleTextStack.axis = .vertical
        circleTextStack.alignment = .center
        circleTextStack.spacing = 2
        circleTextStack.translatesAutoresizingMaskIntoConstraints = false
        circle.addSubview(circleTextStack)

        let textStack = UIStackView(arrangedSubviews: [nameLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 3

        let contentStack = UIStackView(arrangedSubviews: [circle, textStack, chevronLabel])
        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = Layout.contentSpacing
        contentStack.isUserInteractionEnabled = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            circle.widthAnchor.constraint(equalToConstant: Layout.minutesCircleSize),
            circle.heightAnchor.constraint(equalToConstant: Layout.minutesCircleSize),

            circleTextStack.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
            circleTextStack.centerYAnchor.constraint(equalTo: circle.centerYAnchor),

            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: Layout.verticalPadding),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.verticalPadding),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalPadding),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalPadding)
        ])

        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)

        updateAppearance(circle: circle)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: PresetRowView, _) in
            view.updateAppearance(circle: circle)
        }
    }

    private func updateAppearance(circle: UIView) {
        backgroundColor = ILColors.surface
        layer.borderColor = ILColors.border.cgColor
        circle.backgroundColor = ILColors.featGlow
        circle.layer.borderColor = ILColors.heroAccentBorder.cgColor
        minutesLabel.textColor = ILColors.link
        minutesUnitLabel.textColor = ILColors.link
        nameLabel.textColor = ILColors.ink
        subtitleLabel.textColor = ILColors.inkTertiary
        chevronLabel.textColor = ILColors.inkDisabled
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

// MARK: - Dashed Outline Button

/// Nút "+ Tự thiết lập đồng hồ & chuông": chữ `ink` 13 medium trong khung bo tròn viền nét đứt.
private final class DashedOutlineButton: UIControl {

    var title: String = "" {
        didSet { titleLabel.text = title }
    }

    var onTap: (() -> Void)?

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.button
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let borderLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        borderLayer.frame = bounds
        borderLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: bounds.height / 2).cgPath
    }

    private func setupViews() {
        heightAnchor.constraint(equalToConstant: ILMetrics.buttonHeight).isActive = true

        borderLayer.fillColor = nil
        borderLayer.lineWidth = 1
        borderLayer.lineDashPattern = [5, 4]
        layer.addSublayer(borderLayer)

        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16)
        ])

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        updateAppearance()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: DashedOutlineButton, _) in
            view.updateAppearance()
        }
    }

    private func updateAppearance() {
        borderLayer.strokeColor = ILColors.borderStrong.cgColor
        titleLabel.textColor = ILColors.ink
    }

    @objc private func handleTap() {
        onTap?()
    }
}
