//
//  ILMeritBuildCardView.swift
//  InnerLamp
//

import UIKit

/// "Công khai tài chính": project name + temple/round, gold progress bar with the raised/goal line
/// and percentage, the itemised spend rows and the "cập nhật" footnote.
final class ILMeritBuildCardView: ILMeritCardView {

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.serifCardTitle
        label.textColor = ILColors.ink
        label.numberOfLines = 0
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.note
        label.textColor = ILColors.inkTertiary
        label.numberOfLines = 0
        return label
    }()

    private lazy var progressBar = ILLinearProgressBarView()

    private lazy var lineLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.note
        label.textColor = ILColors.inkDim
        label.numberOfLines = 0
        return label
    }()

    private lazy var percentLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.note
        label.textColor = ILColors.ink
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()

    private lazy var spendStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var updatedLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.note
        label.textColor = ILColors.inkSubtle
        label.numberOfLines = 0
        return label
    }()

    init() {
        super.init()

        let progressRow = UIStackView(arrangedSubviews: [lineLabel, percentLabel])
        progressRow.axis = .horizontal
        progressRow.alignment = .firstBaseline
        progressRow.spacing = 12

        let spendBox = UIView()
        spendBox.addSubview(spendStack)
        let separator = UIView()
        separator.backgroundColor = ILColors.borderSoft
        separator.translatesAutoresizingMaskIntoConstraints = false
        spendBox.addSubview(separator)
        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(equalTo: spendBox.topAnchor),
            separator.leadingAnchor.constraint(equalTo: spendBox.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: spendBox.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),
            spendStack.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 14),
            spendStack.bottomAnchor.constraint(equalTo: spendBox.bottomAnchor),
            spendStack.leadingAnchor.constraint(equalTo: spendBox.leadingAnchor),
            spendStack.trailingAnchor.constraint(equalTo: spendBox.trailingAnchor)
        ])

        let stack = UIStackView(arrangedSubviews: [nameLabel, subtitleLabel, progressBar, progressRow, spendBox, updatedLabel])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 8
        stack.setCustomSpacing(3, after: nameLabel)
        stack.setCustomSpacing(14, after: subtitleLabel)
        stack.setCustomSpacing(14, after: progressRow)
        stack.setCustomSpacing(12, after: spendBox)
        embed(stack, insets: UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(project: ILMeritBookStateModel.BuildProject) {
        nameLabel.text = project.name
        subtitleLabel.text = project.subtitle
        progressBar.progress = project.progress
        lineLabel.text = project.progressLine
        percentLabel.text = project.percentText
        updatedLabel.text = project.updatedText

        spendStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for line in project.lines {
            let key = UILabel()
            key.font = ILTypography.note
            key.textColor = ILColors.inkTertiary
            key.numberOfLines = 0
            key.text = line.label
            key.setContentHuggingPriority(.required, for: .horizontal)

            let value = UILabel()
            value.font = ILTypography.bodySmallMedium
            value.textColor = ILColors.ink
            value.textAlignment = .right
            value.numberOfLines = 0
            value.text = line.value

            let row = UIStackView(arrangedSubviews: [key, value])
            row.axis = .horizontal
            row.alignment = .firstBaseline
            row.spacing = 12
            spendStack.addArrangedSubview(row)
        }
    }
}
