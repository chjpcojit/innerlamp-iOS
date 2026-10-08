//
//  ILFamilyTreeChronicleMilestoneEditorView.swift
//  InnerLamp
//

import UIKit

/// "MỐC LỊCH SỬ" in edit mode: one editable row per milestone (year, event, delete) and a dashed
/// "+ Thêm mốc" button. Rows are kept across `configure` calls (matched by id) so typing never
/// loses focus.
final class ILFamilyTreeChronicleMilestoneEditorView: UIView {

    private enum Layout {
        static let rowGap: CGFloat = 8
        static let yearWidth: CGFloat = 96
        static let addHeight: CGFloat = 44
    }

    // MARK: - Properties
    var onYearChanged: ((String, String) -> Void)?
    var onTextChanged: ((String, String) -> Void)?
    var onDelete: ((String) -> Void)?
    var onAdd: (() -> Void)?

    private var rows: [String: Row] = [:]
    private let stack = UIStackView()
    private lazy var addButton: ILFamilyTreeChroniclePillButton = {
        let button = ILFamilyTreeChroniclePillButton(
            title: "familyTreeChronicle.milestone.add".localized, style: .dashed,
            font: ILTypography.bodySmallMedium, height: Layout.addHeight
        )
        button.onTap = { [weak self] in self?.onAdd?() }
        return button
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        stack.axis = .vertical
        stack.spacing = Layout.rowGap
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        stack.addArrangedSubview(addButton)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    func configure(milestones: [ILFamilyTreeChronicleMilestoneDraft], yearError: (String) -> String?) {
        let ids = Set(milestones.map(\.id))
        for (id, row) in rows where !ids.contains(id) {
            stack.removeArrangedSubview(row)
            row.removeFromSuperview()
            rows[id] = nil
        }
        for (index, milestone) in milestones.enumerated() {
            let row = rows[milestone.id] ?? makeRow(id: milestone.id)
            if rows[milestone.id] == nil {
                rows[milestone.id] = row
                stack.insertArrangedSubview(row, at: index)
            } else if stack.arrangedSubviews[index] !== row {
                stack.removeArrangedSubview(row)
                stack.insertArrangedSubview(row, at: index)
            }
            row.yearCard.text = milestone.year
            row.yearCard.errorText = yearError(milestone.id)
            row.textCard.text = milestone.text
        }
    }

    /// The year field of a milestone, to scroll to / focus when it fails validation.
    func yearCard(of id: String) -> ILInputCardView? {
        rows[id]?.yearCard
    }

    // MARK: - Rows
    private final class Row: UIStackView {
        let yearCard = ILInputCardView(
            label: "familyTreeChronicle.milestone.year".localized,
            placeholder: "familyTreeChronicle.milestone.year.placeholder".localized
        )
        let textCard = ILInputCardView(
            label: "familyTreeChronicle.milestone.text".localized,
            placeholder: "familyTreeChronicle.milestone.text.placeholder".localized,
            style: .multiLine
        )
        let deleteButton = ILFamilyTreeChronicleDeleteButton()
    }

    private func makeRow(id: String) -> Row {
        let row = Row(frame: .zero)
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = Layout.rowGap
        row.yearCard.keyboardType = .numberPad
        row.yearCard.onTextChanged = { [weak self] text in self?.onYearChanged?(id, text) }
        row.textCard.onTextChanged = { [weak self] text in self?.onTextChanged?(id, text) }
        row.deleteButton.onTap = { [weak self] in self?.onDelete?(id) }
        [row.yearCard, row.textCard, row.deleteButton].forEach { row.addArrangedSubview($0) }
        row.yearCard.widthAnchor.constraint(equalToConstant: Layout.yearWidth).isActive = true
        return row
    }
}
