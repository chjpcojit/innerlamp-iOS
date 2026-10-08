//
//  ILInputCardView.swift
//  InnerLamp
//

import UIKit

/// Card-style labeled input: a small muted label on top and the editable value below, both inside
/// one rounded surface card (design handoff `edit` screen fields). Unlike `ILField` (label outside
/// a bordered box), the label lives inside the card.
///
/// Two styles:
/// - `.singleLine` — `UITextField`, `ILTypography.fieldValue`.
/// - `.multiLine` — self-sizing `UITextView` in the scripture serif (`ILTypography.scriptureDescription`,
///   line height 1.7), for short free text such as a bio.
///
/// ```swift
/// let nameCard = ILInputCardView(label: "editProfile.field.displayName".localized)
/// nameCard.onTextChanged = { [weak self] text in self?.nameChangedSubject.send(text) }
/// ```
public final class ILInputCardView: UIView {

    public enum Style {
        case singleLine
        case multiLine
    }

    private enum Layout {
        static let insets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        static let singleLineGap: CGFloat = 3
        static let multiLineGap: CGFloat = 5
        static let errorGap: CGFloat = 6
        static let multiLineHeightMultiple: CGFloat = 1.7
    }

    // MARK: - Properties
    public var label: String = "" {
        didSet { titleLabel.text = label }
    }

    public var placeholder: String = "" {
        didSet { applyPlaceholder() }
    }

    /// Current text. Setting it does not fire `onTextChanged`, and is skipped while the user is
    /// typing with the same value (avoids resetting the caret on every state render).
    public var text: String {
        get {
            switch style {
            case .singleLine: return textField.text ?? ""
            case .multiLine: return textView.text ?? ""
            }
        }
        set {
            switch style {
            case .singleLine:
                guard textField.text != newValue else { return }
                textField.text = newValue
            case .multiLine:
                guard textView.text != newValue else { return }
                textView.text = newValue
                placeholderLabel.isHidden = !newValue.isEmpty
            }
        }
    }

    /// Error shown under the value, inside the card. `nil` hides it.
    public var errorText: String? {
        didSet {
            errorLabel.text = errorText
            errorLabel.isHidden = (errorText ?? "").isEmpty
            applyBorder()
        }
    }

    /// `false` renders the value as read-only text (e.g. a verified phone number).
    public var isEditable: Bool = true {
        didSet { applyEditable() }
    }

    public var keyboardType: UIKeyboardType = .default {
        didSet {
            textField.keyboardType = keyboardType
            textView.keyboardType = keyboardType
        }
    }

    public var onTextChanged: ((String) -> Void)?

    public let style: Style

    // MARK: - UI Elements
    private let titleLabel = UILabel()
    private let textField = UITextField()
    private let textView = UITextView()
    private let placeholderLabel = UILabel()
    private let errorLabel = UILabel()
    private let stack = UIStackView()

    // MARK: - Initializer
    public init(
        label: String,
        text: String = "",
        placeholder: String = "",
        style: Style = .singleLine,
        isEditable: Bool = true
    ) {
        self.label = label
        self.placeholder = placeholder
        self.style = style
        self.isEditable = isEditable
        super.init(frame: .zero)
        setupViews()
        self.text = text
        applyPlaceholder()
        applyEditable()
        applyBorder()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.applyBorder()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusField
        layer.borderWidth = 1

        titleLabel.font = ILTypography.caption
        titleLabel.textColor = ILColors.inkSubtle
        titleLabel.text = label

        errorLabel.font = ILTypography.caption
        errorLabel.textColor = ILColors.danger
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true

        stack.axis = .vertical
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        stack.addArrangedSubview(titleLabel)

        switch style {
        case .singleLine:
            textField.font = ILTypography.fieldValue
            textField.textColor = ILColors.ink
            textField.tintColor = ILColors.gold
            textField.borderStyle = .none
            textField.clearButtonMode = .never
            textField.returnKeyType = .done
            textField.addTarget(self, action: #selector(handleTextFieldChanged), for: .editingChanged)
            textField.addTarget(self, action: #selector(handleTextFieldReturn), for: .editingDidEndOnExit)
            stack.addArrangedSubview(textField)
            stack.setCustomSpacing(Layout.singleLineGap, after: titleLabel)

        case .multiLine:
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineHeightMultiple = Layout.multiLineHeightMultiple
            textView.typingAttributes = [
                .font: ILTypography.scriptureDescription,
                .foregroundColor: ILColors.inkStrong,
                .paragraphStyle: paragraph
            ]
            textView.font = ILTypography.scriptureDescription
            textView.textColor = ILColors.inkStrong
            textView.tintColor = ILColors.gold
            textView.backgroundColor = .clear
            textView.isScrollEnabled = false
            textView.textContainerInset = .zero
            textView.textContainer.lineFragmentPadding = 0
            textView.delegate = self

            placeholderLabel.font = ILTypography.scriptureDescription
            placeholderLabel.textColor = ILColors.inkMuted
            placeholderLabel.numberOfLines = 0
            placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
            textView.addSubview(placeholderLabel)

            NSLayoutConstraint.activate([
                placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor),
                placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor),
                placeholderLabel.widthAnchor.constraint(equalTo: textView.widthAnchor)
            ])

            stack.addArrangedSubview(textView)
            stack.setCustomSpacing(Layout.multiLineGap, after: titleLabel)
        }

        stack.addArrangedSubview(errorLabel)
        stack.setCustomSpacing(Layout.errorGap, after: style == .singleLine ? textField : textView)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: Layout.insets.top),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.insets.left),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.insets.right),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.insets.bottom)
        ])

        // Tapping anywhere on the card focuses the input.
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleCardTap)))
    }

    // MARK: - Appearance
    private func applyPlaceholder() {
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: ILColors.inkMuted, .font: ILTypography.fieldValue]
        )
        placeholderLabel.text = placeholder
        placeholderLabel.isHidden = !textView.text.isEmpty
    }

    private func applyEditable() {
        textField.isEnabled = isEditable
        textView.isEditable = isEditable
        textView.isSelectable = isEditable
        textField.textColor = isEditable ? ILColors.ink : ILColors.inkSecondary
    }

    // `layer.borderColor` is a static CGColor — refreshed manually on appearance change.
    private func applyBorder() {
        let hasError = !(errorText ?? "").isEmpty
        layer.borderColor = (hasError ? ILColors.dangerBorder : ILColors.borderMedium).cgColor
    }

    // MARK: - Actions
    @objc private func handleTextFieldChanged() {
        onTextChanged?(textField.text ?? "")
    }

    @objc private func handleTextFieldReturn() {
        textField.resignFirstResponder()
    }

    /// Puts the caret in the field (same as tapping the card) — used to jump to an invalid field.
    public func focus() {
        handleCardTap()
    }

    @objc private func handleCardTap() {
        guard isEditable else { return }
        switch style {
        case .singleLine: textField.becomeFirstResponder()
        case .multiLine: textView.becomeFirstResponder()
        }
    }
}

// MARK: - UITextViewDelegate
extension ILInputCardView: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        onTextChanged?(textView.text)
    }
}
