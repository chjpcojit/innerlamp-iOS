//
//  ILMemorialReminderCardView.swift
//  InnerLamp
//

import UIKit

/// "Nhắc nhở" card of the form (design handoff reminder block): the "Nhắc trước ngày giỗ" switch;
/// while on, the lead-time chips, the hour chips and the "Thêm vào Lời nhắc" switch.
final class ILMemorialReminderCardView: UIView {

    // MARK: - Properties
    var onReminderToggled: ((Bool) -> Void)?
    var onLeadSelected: ((Int) -> Void)?
    var onTimeSelected: ((Int) -> Void)?
    var onSyncToggled: ((Bool) -> Void)?

    // MARK: - UI Elements
    private let reminderRow = ILSwitchRowView(
        title: "memorial.edit.reminder.title".localized,
        subtitle: "memorial.edit.reminder.subtitle".localized
    )
    private let leadGroup = ILMemorialChipGroupView()
    private let timeGroup = ILMemorialChipGroupView()
    private let syncRow = ILSwitchRowView(
        title: "memorial.edit.sync.title".localized,
        subtitle: "memorial.edit.sync.subtitle".localized
    )
    private let detailStack = UIStackView()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public API
    func configure(with model: ILMemorialEditStateModel) {
        reminderRow.isOn = model.reminderOn
        syncRow.isOn = model.syncOn
        leadGroup.configure(options: model.leadOptions)
        timeGroup.configure(options: model.timeOptions)
        detailStack.isHidden = !model.reminderOn
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardRegular
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor

        reminderRow.onToggle = { [weak self] isOn in self?.onReminderToggled?(isOn) }
        syncRow.onToggle = { [weak self] isOn in self?.onSyncToggled?(isOn) }
        leadGroup.onSelect = { [weak self] id in self?.onLeadSelected?(id) }
        timeGroup.onSelect = { [weak self] id in self?.onTimeSelected?(id) }

        detailStack.axis = .vertical
        detailStack.spacing = ILMetrics.spaceMedium
        detailStack.addArrangedSubview(makeDivider())
        detailStack.addArrangedSubview(makeCaption("memorial.edit.reminder.lead".localized))
        detailStack.addArrangedSubview(leadGroup)
        detailStack.addArrangedSubview(makeCaption("memorial.edit.reminder.time".localized))
        detailStack.addArrangedSubview(timeGroup)
        detailStack.addArrangedSubview(makeDivider())
        detailStack.addArrangedSubview(syncRow)

        let content = UIStackView(arrangedSubviews: [reminderRow, detailStack])
        content.axis = .vertical
        content.spacing = ILMetrics.spaceMedium
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: topAnchor, constant: ILMetrics.spaceStandard),
            content.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -ILMetrics.spaceStandard),
            content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.spaceStandard),
            content.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.spaceStandard)
        ])

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILMemorialReminderCardView, _) in
            view.layer.borderColor = ILColors.border.cgColor
        }
    }

    private func makeCaption(_ text: String) -> UILabel {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.inkSubtle
        label.text = text
        return label
    }

    private func makeDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = ILColors.borderSoft
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return divider
    }
}
