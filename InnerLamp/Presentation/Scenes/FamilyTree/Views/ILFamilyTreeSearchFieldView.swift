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
    private lazy var textField: UITextField = {
        let field = UITextField()
        field.font = ILTypography.fieldValue
        field.textColor = Tree.ink
        field.tintColor = Tree.selected
        field.returnKeyType = .search
        field.autocorrectionType = .no
        return field
    }()

    private lazy var countLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subheadMedium
        label.textColor = Tree.inkTertiary
        label.isHidden = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

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

        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.font: ILTypography.fieldValue, .foregroundColor: Tree.searchPlaceholder]
        )
        textField.delegate = self
        textField.addTarget(self, action: #selector(handleEditingChanged), for: .editingChanged)

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
