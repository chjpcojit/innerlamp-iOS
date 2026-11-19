//
//  ILMemorialReminderCardView.swift
//  InnerLamp
//

import UIKit

/// "Nhắc nhở" card of the form: the "Nhắc trước ngày giỗ" switch, then the lead-time chips and the
/// hour chips. Reminder delivery is local for now (D1); the account setting is shown even when the
/// system permission was denied, with a link to Settings instead of a dead switch.
final class ILMemorialReminderCardView: UIView {

    // MARK: - Properties
    var onReminderToggled: ((Bool) -> Void)?
    var onLeadSelected: ((Int) -> Void)?
    var onTimeSelected: ((Int) -> Void)?
    var onOpenSettings: (() -> Void)?

    // MARK: - UI Elements
    private lazy var reminderRow: ILSwitchRowView = {
        let row = ILSwitchRowView(
            title: "memorial.edit.reminder.title".localized,
            subtitle: "memorial.edit.reminder.subtitle".localized
        )
        return row
    }()

    private lazy var leadGroup: ILMemorialChipGroupView = {
        let group = ILMemorialChipGroupView()
        return group
    }()

    private lazy var timeGroup: ILMemorialChipGroupView = {
        let group = ILMemorialChipGroupView()
        return group
    }()

    private lazy var permissionLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.inkSubtle
        label.numberOfLines = 0
        label.text = "memorial.edit.reminder.permissionDenied".localized
        return label
    }()

    private lazy var settingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("memorial.edit.reminder.openSettings".localized, for: .normal)
        button.setTitleColor(ILColors.link, for: .normal)
        button.titleLabel?.font = ILTypography.subheadMedium
        button.addTarget(self, action: #selector(handleOpenSettings), for: .touchUpInside)
        return button
    }()

    private lazy var permissionStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [permissionLabel, settingsButton])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = ILMetrics.spaceSmall
        stack.isHidden = true
        return stack
    }()

    private lazy var detailStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = ILMetrics.spaceMedium
        return stack
    }()

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
        leadGroup.configure(options: model.leadOptions)
        timeGroup.configure(options: model.timeOptions)
        detailStack.isHidden = !model.reminderOn
        permissionStack.isHidden = !(model.reminderOn && model.notificationsDenied)
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardRegular
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor

        reminderRow.onToggle = { [weak self] isOn in self?.onReminderToggled?(isOn) }
        leadGroup.onSelect = { [weak self] id in self?.onLeadSelected?(id) }
        timeGroup.onSelect = { [weak self] id in self?.onTimeSelected?(id) }

        detailStack.addArrangedSubview(makeDivider())
        detailStack.addArrangedSubview(makeCaption("memorial.edit.reminder.lead".localized))
        detailStack.addArrangedSubview(leadGroup)
        detailStack.addArrangedSubview(makeCaption("memorial.edit.reminder.time".localized))
        detailStack.addArrangedSubview(timeGroup)
        detailStack.addArrangedSubview(permissionStack)

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

    @objc private func handleOpenSettings() {
        onOpenSettings?()
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
