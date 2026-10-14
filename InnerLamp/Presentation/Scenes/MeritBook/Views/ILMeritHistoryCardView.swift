//
//  ILMeritHistoryCardView.swift
//  InnerLamp
//

import UIKit

/// "Lịch sử cúng dường": one card holding a divided list of offerings — purpose, temple · date on
/// the left, amount + confirmation pill on the right. Shows a dashed note when there are none.
final class ILMeritHistoryCardView: UIView {

    private lazy var card: ILMeritCardView = {
        let card = ILMeritCardView()
        card.translatesAutoresizingMaskIntoConstraints = false
        return card
    }()

    private lazy var rowsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        return stack
    }()

    private lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.note
        label.textColor = ILColors.inkTertiary
        label.numberOfLines = 0
        label.text = "meritBook.history.empty".localized
        return label
    }()

    private var rows: [ILMeritBookStateModel.HistoryRow] = [] {
        didSet {
            guard rows != oldValue else { return }
            rebuild()
        }
    }

    init() {
        super.init(frame: .zero)
        addSubview(card)
        card.embed(rowsStack, insets: UIEdgeInsets(top: 2, left: 16, bottom: 2, right: 16))
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: topAnchor),
            card.bottomAnchor.constraint(equalTo: bottomAnchor),
            card.leadingAnchor.constraint(equalTo: leadingAnchor),
            card.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(rows: [ILMeritBookStateModel.HistoryRow]) {
        self.rows = rows
    }

    private func rebuild() {
        rowsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard !rows.isEmpty else {
            let padded = UIView()
            emptyLabel.translatesAutoresizingMaskIntoConstraints = false
            padded.addSubview(emptyLabel)
            NSLayoutConstraint.activate([
                emptyLabel.topAnchor.constraint(equalTo: padded.topAnchor, constant: 14),
                emptyLabel.bottomAnchor.constraint(equalTo: padded.bottomAnchor, constant: -14),
                emptyLabel.leadingAnchor.constraint(equalTo: padded.leadingAnchor),
                emptyLabel.trailingAnchor.constraint(equalTo: padded.trailingAnchor)
            ])
            rowsStack.addArrangedSubview(padded)
            return
        }
        for (index, row) in rows.enumerated() {
            rowsStack.addArrangedSubview(ILMeritHistoryRowView(row: row, showsDivider: index < rows.count - 1))
        }
    }
}

private final class ILMeritHistoryRowView: UIView {

    init(row: ILMeritBookStateModel.HistoryRow, showsDivider: Bool) {
        super.init(frame: .zero)

        let title = UILabel()
        title.font = ILTypography.sectionTitle
        title.textColor = ILColors.ink
        title.numberOfLines = 0
        title.text = row.title

        let subtitle = UILabel()
        subtitle.font = ILTypography.note
        subtitle.textColor = ILColors.inkTertiary
        subtitle.numberOfLines = 0
        subtitle.text = row.subtitle

        let leading = UIStackView(arrangedSubviews: [title, subtitle])
        leading.axis = .vertical
        leading.spacing = 3

        let amount = UILabel()
        amount.font = ILTypography.sectionTitle
        amount.textColor = ILColors.ink
        amount.textAlignment = .right
        amount.text = row.amount

        let pill = ILMeritPillLabel()
        pill.font = ILTypography.eyebrow
        pill.textColor = row.isConfirmed ? ILColors.greenText : ILColors.goldDeep
        pill.backgroundColor = row.isConfirmed ? ILColors.greenTint : ILColors.goldDayTint
        pill.text = row.statusText

        let trailing = UIStackView(arrangedSubviews: [amount, pill])
        trailing.axis = .vertical
        trailing.alignment = .trailing
        trailing.spacing = 6
        trailing.setContentHuggingPriority(.required, for: .horizontal)
        trailing.setContentCompressionResistancePriority(.required, for: .horizontal)

        let content = UIStackView(arrangedSubviews: [leading, trailing])
        content.axis = .horizontal
        content.alignment = .top
        content.spacing = 12
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            content.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
            content.leadingAnchor.constraint(equalTo: leadingAnchor),
            content.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        if showsDivider {
            let divider = UIView()
            divider.backgroundColor = ILColors.borderSoft
            divider.translatesAutoresizingMaskIntoConstraints = false
            addSubview(divider)
            NSLayoutConstraint.activate([
                divider.leadingAnchor.constraint(equalTo: leadingAnchor),
                divider.trailingAnchor.constraint(equalTo: trailingAnchor),
                divider.bottomAnchor.constraint(equalTo: bottomAnchor),
                divider.heightAnchor.constraint(equalToConstant: 1)
            ])
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Capsule status label: `UILabel` has no content insets, so draw the text inside a padded rect.
private final class ILMeritPillLabel: UILabel {

    private let insets = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right, height: size.height + insets.top + insets.bottom)
    }
}
