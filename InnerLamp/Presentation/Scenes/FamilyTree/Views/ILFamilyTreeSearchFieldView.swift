//
//  ILFamilyTreeSearchFieldView.swift
//  InnerLamp
//

import UIKit

/// Tree-palette pill search field with a trailing result count ("3 người"). Typing and Return are
/// reported through closures; there is no magnifier (the header button already shows one).
final class ILFamilyTreeSearchFieldView: UIView, UITextFieldDelegate {

    private typealias Tree = ILColors.FamilyTree

    // MARK: - Properties
    var onTextChanged: ((String) -> Void)?
    var onReturn: (() -> Void)?

    var text: String {
        get { textField.text ?? "" }
        set { textField.text = newValue }
    }

    /// Hidden while empty.
    var trailingText: String = "" {
        didSet {
            countLabel.text = trailingText
            countLabel.isHidden = trailingText.isEmpty
        }
    }

    // MARK: - UI Elements
    private let textField = UITextField()
    private let countLabel = UILabel()

    // MARK: - Initializer
    init(placeholder: String) {
        super.init(frame: .zero)
        setupViews(placeholder: placeholder)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews(placeholder: String) {
        backgroundColor = Tree.fieldSurface
        layer.cornerRadius = ILMetrics.FamilyTree.controlSize / 2
        layer.borderWidth = 1
        layer.borderColor = Tree.border.cgColor
        accessibilityIdentifier = "familyTree.search.field"

        textField.font = ILTypography.fieldValue
        textField.textColor = Tree.ink
        textField.tintColor = Tree.selected
        textField.returnKeyType = .search
        textField.autocorrectionType = .no
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.font: ILTypography.fieldValue, .foregroundColor: Tree.searchPlaceholder]
        )
        textField.delegate = self
        textField.addTarget(self, action: #selector(handleEditingChanged), for: .editingChanged)

        countLabel.font = ILTypography.subheadMedium
        countLabel.textColor = Tree.inkTertiary
        countLabel.isHidden = true
        countLabel.setContentHuggingPriority(.required, for: .horizontal)
        countLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [textField, countLabel])
        stack.axis = .horizontal
        stack.spacing = ILMetrics.spaceSmall
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: ILMetrics.FamilyTree.controlSize),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.spaceStandard),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.spaceStandard),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Focus
    @discardableResult
    func focus() -> Bool {
        textField.becomeFirstResponder()
    }

    @discardableResult
    func unfocus() -> Bool {
        textField.resignFirstResponder()
    }

    // MARK: - Actions
    @objc private func handleEditingChanged() {
        onTextChanged?(textField.text ?? "")
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onReturn?()
        return true
    }
}
