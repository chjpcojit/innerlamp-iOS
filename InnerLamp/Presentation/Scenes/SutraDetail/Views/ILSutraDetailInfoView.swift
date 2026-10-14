//
//  ILSutraDetailInfoView.swift
//  InnerLamp
//

import UIKit

/// Các khối thông tin dưới hero của màn Chi tiết bài kinh — mỗi khối là tiêu đề + 1 thẻ bo góc chứa
/// các hàng nhãn / giá trị (hoặc 1 đoạn văn khi `label` rỗng), ngăn cách bằng hairline. Hàng có
/// `url` chạm được và báo qua `onLinkTap`. View chỉ nhận chuỗi đã format từ ViewModel.
final class ILSutraDetailInfoView: UIView {

    // MARK: - Properties
    var sections: [ILSutraDetailInfoSectionModel] = [] {
        didSet {
            guard sections != oldValue else { return }
            rebuild()
        }
    }

    var onLinkTap: ((URL) -> Void)?

    // MARK: - UI Elements
    private lazy var sectionsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = ILMetrics.spaceMedium
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(sectionsStack)
        NSLayoutConstraint.activate([
            sectionsStack.topAnchor.constraint(equalTo: topAnchor),
            sectionsStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            sectionsStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            sectionsStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Build
    private func rebuild() {
        sectionsStack.arrangedSubviews.forEach {
            sectionsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for section in sections {
            sectionsStack.addArrangedSubview(makeSection(section))
        }
    }

    private func makeSection(_ section: ILSutraDetailInfoSectionModel) -> UIView {
        let title = UILabel()
        title.text = section.title
        title.font = ILTypography.headerTitle
        title.textColor = ILColors.ink
        title.numberOfLines = 0

        let card = ILSutraDetailInfoCardView()
        for (index, row) in section.rows.enumerated() {
            let rowView = ILSutraDetailInfoRowView(row: row, showsDivider: index > 0)
            rowView.onTap = { [weak self] url in self?.onLinkTap?(url) }
            card.addRow(rowView)
        }

        let stack = UIStackView(arrangedSubviews: [title, card])
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }
}

// MARK: - Card

/// Thẻ bo góc `surface` + viền `border` chứa các hàng thông tin.
private final class ILSutraDetailInfoCardView: UIView {

    private lazy var rowsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardSmall
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor
        clipsToBounds = true

        addSubview(rowsStack)
        NSLayoutConstraint.activate([
            rowsStack.topAnchor.constraint(equalTo: topAnchor),
            rowsStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            rowsStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            rowsStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILSutraDetailInfoCardView, _) in
            view.layer.borderColor = ILColors.border.cgColor
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addRow(_ row: UIView) {
        rowsStack.addArrangedSubview(row)
    }
}

// MARK: - Row

/// 1 hàng: nhãn nhỏ phía trên, giá trị bên dưới (xuống dòng tự do — ghi chú giấy phép có thể dài).
/// `label` rỗng → chỉ có đoạn văn. Hàng có `url` hiện giá trị màu nhấn và chạm được.
private final class ILSutraDetailInfoRowView: UIView {

    var onTap: ((URL) -> Void)?

    private let url: URL?
    private lazy var divider: UIView = {
        let v = UIView()
        v.backgroundColor = ILColors.border
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    init(row: ILSutraDetailInfoRowModel, showsDivider: Bool) {
        self.url = row.url
        super.init(frame: .zero)

        let valueLabel = UILabel()
        valueLabel.numberOfLines = 0
        if row.label.isEmpty {
            valueLabel.attributedText = ILTypography.makeParagraph(
                text: row.value,
                font: ILTypography.scriptureDescription,
                color: ILColors.inkSecondary,
                cssLineHeight: 1.75
            )
        } else {
            valueLabel.text = row.value
            valueLabel.font = ILTypography.bodySmall
            valueLabel.textColor = row.url == nil ? ILColors.ink : ILColors.goldDeep
        }

        var labels: [UIView] = []
        if !row.label.isEmpty {
            let caption = UILabel()
            caption.text = row.label
            caption.font = ILTypography.label
            caption.textColor = ILColors.inkSubtle
            caption.numberOfLines = 0
            labels.append(caption)
        }
        labels.append(valueLabel)

        let stack = UIStackView(arrangedSubviews: labels)
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        divider.isHidden = !showsDivider
        addSubview(divider)

        NSLayoutConstraint.activate([
            divider.topAnchor.constraint(equalTo: topAnchor),
            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),

            stack.topAnchor.constraint(equalTo: topAnchor, constant: ILMetrics.spaceMedium),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.spaceStandard),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.spaceStandard),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -ILMetrics.spaceMedium)
        ])

        if url != nil {
            isAccessibilityElement = true
            accessibilityTraits = .link
            accessibilityLabel = "\(row.label), \(row.value)"
            addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        }
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILSutraDetailInfoRowView, _) in
            view.divider.backgroundColor = ILColors.border
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func handleTap() {
        guard let url else { return }
        onTap?(url)
    }
}
