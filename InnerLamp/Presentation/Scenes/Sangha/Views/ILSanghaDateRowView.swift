//
//  ILSanghaDateRowView.swift
//  InnerLamp
//

import UIKit

/// Hàng có cột ngày-tháng bên trái (số ngày + "TH10"), tiêu đề / dòng phụ / gợi ý ở giữa và nút
/// pill hoặc mũi tên bên phải. Dùng cho "Khóa tu & lễ sắp tới", "Khóa tu sắp diễn ra" và "Ngày lễ &
/// ngày chay sắp tới" — vỏ thẻ do `ILSanghaCardView` đảm nhiệm.
final class ILSanghaDateRowView: UIView {

    enum Accessory {
        case none
        case chevron
        case pill(title: String, style: ILSanghaPillButton.Style)
    }

    // MARK: - Properties
    var onTap: (() -> Void)?
    var onAction: (() -> Void)?

    // MARK: - UI Elements
    private lazy var dayLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.dateNumber
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
        label.numberOfLines = 0
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.inkTertiary
        label.numberOfLines = 0
        return label
    }()

    private lazy var suggestionLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.note
        label.textColor = ILColors.link
        label.numberOfLines = 0
        return label
    }()

    private lazy var pillButton: ILSanghaPillButton = {
        let button = ILSanghaPillButton()
        return button
    }()

    private lazy var chevronLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.chevron
        label.textColor = ILColors.inkFaint
        label.text = "›"
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    func configure(
        dayNumber: String,
        monthLabel month: String,
        title: String,
        subtitle: String,
        suggestion: String? = nil,
        isHighlighted: Bool = false,
        accessory: Accessory
    ) {
        dayLabel.text = dayNumber
        dayLabel.textColor = isHighlighted ? ILColors.link : ILColors.ink
        monthLabel.attributedText = ILTypography.makeAttributedString(
            text: month, font: ILTypography.eyebrowSmall, color: ILColors.inkMuted, letterSpacingEm: 0.1
        )
        titleLabel.text = title
        subtitleLabel.text = subtitle
        suggestionLabel.text = suggestion
        suggestionLabel.isHidden = suggestion == nil

        pillButton.isHidden = true
        chevronLabel.isHidden = true
        switch accessory {
        case .none:
            break
        case .chevron:
            chevronLabel.isHidden = false
        case .pill(let title, let style):
            pillButton.isHidden = false
            pillButton.configure(title: title, style: style)
        }
    }

    // MARK: - Setup
    private func setupViews() {
        pillButton.addTarget(self, action: #selector(handleAction), for: .touchUpInside)

        let dateColumn = UIStackView(arrangedSubviews: [dayLabel, monthLabel])
        dateColumn.axis = .vertical
        dateColumn.spacing = 4
        dateColumn.widthAnchor.constraint(equalToConstant: 40).isActive = true

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, suggestionLabel])
        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.setCustomSpacing(6, after: subtitleLabel)

        let row = UIStackView(arrangedSubviews: [dateColumn, textStack, pillButton, chevronLabel])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = ILMetrics.spaceMedium
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor, constant: ILMetrics.spaceMedium),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -ILMetrics.spaceMedium),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.spaceStandard),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.spaceStandard)
        ])

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }

    // MARK: - Actions
    @objc private func handleTap() {
        onTap?()
    }

    @objc private func handleAction() {
        onAction?()
    }
}
