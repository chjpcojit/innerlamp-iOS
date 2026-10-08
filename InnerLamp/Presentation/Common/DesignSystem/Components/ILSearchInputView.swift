//
//  ILSearchInputView.swift
//  InnerLamp
//

import UIKit

/// Pill-shaped search text field with a magnifier icon and an optional trailing result count
/// ("3 người"). Unlike `ILSearchBarView` (a tap target that opens the Search screen) this one takes
/// the typing itself. Generic: no screen-specific copy — callers pass placeholder and count text.
public final class ILSearchInputView: UIView, UITextFieldDelegate {

    // MARK: - Properties
    public var placeholder: String = "" {
        didSet { applyPlaceholder() }
    }

    public var text: String {
        get { textField.text ?? "" }
        set {
            textField.text = newValue
            updateClearButtonVisibility()
        }
    }

    /// Shows a round "×" at the trailing edge while the field has text; tapping it empties the field
    /// and reports `""` through `onTextChanged`. Off by default so existing callers are unchanged.
    public var showsClearButton: Bool = false {
        didSet { updateClearButtonVisibility() }
    }

    /// Result count shown at the trailing edge; hidden while empty.
    public var trailingText: String = "" {
        didSet {
            trailingLabel.text = trailingText
            trailingLabel.isHidden = trailingText.isEmpty
        }
    }

    public var onTextChanged: ((String) -> Void)?
    public var onReturn: (() -> Void)?

    // MARK: - UI Elements
    private let iconView = UIView()
    private let textField = UITextField()
    private let clearButton = UIButton(type: .custom)
    private let trailingLabel = UILabel()

    // MARK: - Initializer
    public init(placeholder: String = "") {
        self.placeholder = placeholder
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.inputHeight / 2
        layer.borderWidth = 1
        layer.borderColor = ILColors.borderStrong.cgColor

        iconView.layer.cornerRadius = Self.iconSize / 2
        iconView.layer.borderWidth = 1.5
        iconView.layer.borderColor = ILColors.inkFaint.cgColor
        iconView.translatesAutoresizingMaskIntoConstraints = false

        textField.font = ILTypography.fieldValue
        textField.textColor = ILColors.ink
        textField.tintColor = ILColors.gold
        textField.returnKeyType = .search
        textField.clearButtonMode = .never
        textField.autocorrectionType = .no
        textField.delegate = self
        textField.addTarget(self, action: #selector(handleEditingChanged), for: .editingChanged)
        applyPlaceholder()

        trailingLabel.font = ILTypography.subheadMedium
        trailingLabel.textColor = ILColors.inkTertiary
        trailingLabel.isHidden = true
        trailingLabel.setContentHuggingPriority(.required, for: .horizontal)
        trailingLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        clearButton.setTitle("×", for: .normal)
        clearButton.setTitleColor(ILColors.inkSecondary, for: .normal)
        clearButton.titleLabel?.font = ILTypography.bodyCompact
        clearButton.backgroundColor = ILColors.searchClearFill
        clearButton.layer.cornerRadius = ILMetrics.searchClearSize / 2
        clearButton.accessibilityLabel = "common.clear".localized
        clearButton.isHidden = true
        clearButton.addTarget(self, action: #selector(handleClearTapped), for: .touchUpInside)
        clearButton.setContentHuggingPriority(.required, for: .horizontal)
        clearButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [iconView, textField, clearButton, trailingLabel])
        stack.axis = .horizontal
        stack.spacing = ILMetrics.spaceSmall
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: Self.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Self.iconSize),
            clearButton.widthAnchor.constraint(equalToConstant: ILMetrics.searchClearSize),
            clearButton.heightAnchor.constraint(equalToConstant: ILMetrics.searchClearSize),
            heightAnchor.constraint(equalToConstant: ILMetrics.inputHeight),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.spaceStandard),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.spaceStandard),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILSearchInputView, _) in
            view.layer.borderColor = ILColors.borderStrong.cgColor
            view.iconView.layer.borderColor = ILColors.inkFaint.cgColor
        }
    }

    private static let iconSize: CGFloat = 14

    private func applyPlaceholder() {
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.font: ILTypography.fieldValue, .foregroundColor: ILColors.inkMuted]
        )
    }

    // MARK: - Focus
    @discardableResult
    public func focus() -> Bool {
        textField.becomeFirstResponder()
    }

    @discardableResult
    public func unfocus() -> Bool {
        textField.resignFirstResponder()
    }

    // MARK: - Actions
    @objc private func handleEditingChanged() {
        updateClearButtonVisibility()
        onTextChanged?(text)
    }

    @objc private func handleClearTapped() {
        text = ""
        onTextChanged?("")
    }

    private func updateClearButtonVisibility() {
        clearButton.isHidden = !showsClearButton || text.isEmpty
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onReturn?()
        textField.resignFirstResponder()
        return true
    }
}
