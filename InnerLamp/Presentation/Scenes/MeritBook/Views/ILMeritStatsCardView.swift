//
//  ILMeritStatsCardView.swift
//  InnerLamp
//

import UIKit

/// Three equal columns (serif value + caption) separated by hairlines: tịnh tài năm / đèn thỉnh tại
/// chùa / chùa đã cúng dường.
final class ILMeritStatsCardView: ILMeritCardView {

    private lazy var columns: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .fill
        return stack
    }()

    init() {
        super.init()
        embed(columns, insets: UIEdgeInsets(top: 18, left: 6, bottom: 18, right: 6))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(stats: [ILMeritBookStateModel.Stat]) {
        columns.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, stat) in stats.enumerated() {
            columns.addArrangedSubview(makeColumn(stat, showsDivider: index > 0))
        }
    }

    private func makeColumn(_ stat: ILMeritBookStateModel.Stat, showsDivider: Bool) -> UIView {
        let value = UILabel()
        value.font = ILTypography.displayMedium
        value.textColor = ILColors.ink
        value.textAlignment = .center
        value.adjustsFontSizeToFitWidth = true
        value.minimumScaleFactor = 0.7
        value.text = stat.value

        let caption = UILabel()
        caption.font = ILTypography.note
        caption.textColor = ILColors.inkTertiary
        caption.textAlignment = .center
        caption.numberOfLines = 0
        caption.text = stat.caption

        let stack = UIStackView(arrangedSubviews: [value, caption])
        stack.axis = .vertical
        stack.spacing = 4
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)

        let container = UIView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        if showsDivider {
            let divider = UIView()
            divider.backgroundColor = ILColors.border
            divider.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(divider)
            NSLayoutConstraint.activate([
                divider.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                divider.topAnchor.constraint(equalTo: container.topAnchor),
                divider.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                divider.widthAnchor.constraint(equalToConstant: 1)
            ])
        }
        return container
    }
}
