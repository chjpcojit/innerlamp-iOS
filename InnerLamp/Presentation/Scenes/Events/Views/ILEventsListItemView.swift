//
//  ILEventsListItemView.swift
//  InnerLamp
//

import UIKit

/// 1 hàng sự kiện / khóa học trong màn Sự kiện & khóa học: ô ngày tint, tiêu đề + mô tả phụ, và
/// nhãn trạng thái bên phải. Cả thẻ là 1 vùng chạm. Biết `ILEventsListItemModel` nên thuộc riêng
/// màn Sự kiện.
final class ILEventsListItemView: UIControl {

    // MARK: - Constants
    private enum Layout {
        static let tileWidth: CGFloat = 46
        static let tileVerticalPadding: CGFloat = 8
        static let padding: CGFloat = 16
        static let verticalPadding: CGFloat = 14
        static let gap: CGFloat = 14
    }

    // MARK: - Properties
    var onTap: (() -> Void)?

    // MARK: - UI Elements
    private lazy var dateTile: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = ILMetrics.radiusIconTile
        view.clipsToBounds = true
        return view
    }()

    private lazy var dayLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.dateTileDay
        label.textAlignment = .center
        return label
    }()

    private lazy var monthLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.rowTitle
        label.textColor = ILColors.ink
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.inkTertiary
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subheadMedium
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

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

        let dateStack = UIStackView(arrangedSubviews: [dayLabel, monthLabel])
        dateStack.axis = .vertical
        dateStack.spacing = 2
        dateStack.alignment = .center
        dateStack.translatesAutoresizingMaskIntoConstraints = false
        dateTile.addSubview(dateStack)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 3
        textStack.isUserInteractionEnabled = false

        let contentStack = UIStackView(arrangedSubviews: [dateTile, textStack, statusLabel])
        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = Layout.gap
        contentStack.isUserInteractionEnabled = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            dateTile.widthAnchor.constraint(equalToConstant: Layout.tileWidth),

            dateStack.topAnchor.constraint(equalTo: dateTile.topAnchor, constant: Layout.tileVerticalPadding),
            dateStack.bottomAnchor.constraint(equalTo: dateTile.bottomAnchor, constant: -Layout.tileVerticalPadding),
            dateStack.leadingAnchor.constraint(equalTo: dateTile.leadingAnchor, constant: 4),
            dateStack.trailingAnchor.constraint(equalTo: dateTile.trailingAnchor, constant: -4),

            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: Layout.verticalPadding),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.verticalPadding),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.padding),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.padding)
        ])

        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)
    }

    // MARK: - Configure
    func configure(with model: ILEventsListItemModel) {
        let tone = Self.tone(for: model.tone)

        dateTile.backgroundColor = tone.tintBackground
        dayLabel.text = model.day
        dayLabel.textColor = tone.textColor
        monthLabel.attributedText = ILTypography.makeAttributedString(
            text: model.monthLabel.uppercased(),
            font: ILTypography.captionSmall,
            color: tone.textColor.withAlphaComponent(0.70),
            letterSpacingEm: 0.10
        )
        titleLabel.text = model.title
        subtitleLabel.text = model.subtitle
        statusLabel.text = model.statusText
        statusLabel.textColor = tone.textColor
    }

    /// Ánh xạ hạng mục sự kiện (nghiệp vụ) sang tone màu (hiển thị) — việc riêng của tầng view.
    private static func tone(for tone: ILEventsTone) -> ILColors.Tone {
        switch tone {
        case .gold: return .gold
        case .green: return .green
        case .rose: return .rose
        case .ink: return .ink
        }
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
