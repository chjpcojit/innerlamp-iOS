//
//  ILDharmaNameSuggestionField.swift
//  InnerLamp
//

import UIKit

/// Hàng "Pháp danh hoặc tên gọi" của riêng màn Đăng ký — `UITextField` cho người dùng gõ tự do,
/// kèm chip "Gợi ý" (icon xoay vòng + text) ép sát mép phải để đổi sang tên do `ILSignUpUseCase`
/// gợi ý. Nội dung/hành vi gắn chặt với luồng Đăng ký nên đặt ở `Scenes/SignUp/Views/`, không phải
/// Design System dùng chung.
final class ILDharmaNameSuggestionField: UIView, UITextFieldDelegate {

    // MARK: - Properties
    var label: String = "" {
        didSet { labelView.text = label }
    }

    var value: String {
        get { textField.text ?? "" }
        set { textField.text = newValue }
    }

    var placeholder: String = "" {
        didSet { updatePlaceholder() }
    }

    var suggestTitle: String = "" {
        didSet { suggestLabel.text = suggestTitle }
    }

    var onTextChanged: ((String) -> Void)?
    var onSuggestTapped: (() -> Void)?
    var onReturn: (() -> Void)?

    var innerTextField: UITextField { textField }

    // MARK: - UI Elements
    private lazy var labelView: UILabel = {
        let view = UILabel()
        view.font = ILTypography.label
        view.textColor = ILColors.inkSubtle
        view.text = label
        return view
    }()

    private lazy var inputContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ILColors.surface
        view.layer.cornerRadius = ILMetrics.radiusInput
        view.layer.borderWidth = 1
        view.layer.borderColor = ILColors.ink.withAlphaComponent(0.12).cgColor
        return view
    }()

    private lazy var textField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.font = ILTypography.bodyLarge
        field.textColor = ILColors.ink
        // Hút hết khoảng trống còn lại trong hàng — chip gợi ý (hugging .required) nhờ đó luôn bị
        // đẩy sát mép phải thay vì nằm sát ngay cạnh chữ khi tên ngắn.
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return field
    }()

    private lazy var suggestButton: UIControl = {
        let control = UIControl()
        control.backgroundColor = ILColors.gold.withAlphaComponent(0.14)
        control.layer.cornerRadius = ILMetrics.radiusPill
        control.layer.borderWidth = 1
        control.layer.borderColor = ILColors.gold.withAlphaComponent(0.3).cgColor
        control.translatesAutoresizingMaskIntoConstraints = false
        control.setContentHuggingPriority(.required, for: .horizontal)
        return control
    }()

    private lazy var ringView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 6.5
        view.layer.borderWidth = 1.5
        view.layer.borderColor = ILColors.goldDeep.cgColor
        return view
    }()

    private lazy var suggestLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subheadMedium
        label.textColor = ILColors.goldDeep
        label.text = suggestTitle
        return label
    }()

    private var rotationTurns: CGFloat = 0

    // MARK: - Initializer
    init(label: String = "", value: String = "", placeholder: String = "", suggestTitle: String = "") {
        self.label = label
        self.placeholder = placeholder
        self.suggestTitle = suggestTitle
        super.init(frame: .zero)
        setupViews()
        self.value = value
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        textField.delegate = self
        textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        updatePlaceholder()

        let suggestContent = UIStackView(arrangedSubviews: [ringView, suggestLabel])
        suggestContent.axis = .horizontal
        suggestContent.spacing = 6
        suggestContent.alignment = .center
        suggestContent.isUserInteractionEnabled = false
        suggestContent.translatesAutoresizingMaskIntoConstraints = false

        suggestButton.addTarget(self, action: #selector(handleSuggestTap), for: .touchUpInside)
        suggestButton.addSubview(suggestContent)

        let contentStack = UIStackView(arrangedSubviews: [textField, suggestButton])
        contentStack.axis = .horizontal
        contentStack.spacing = 10
        contentStack.alignment = .center
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        inputContainer.addSubview(contentStack)

        let mainStack = UIStackView(arrangedSubviews: [labelView, inputContainer])
        mainStack.axis = .vertical
        mainStack.spacing = 7
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStack.topAnchor.constraint(equalTo: topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor),

            inputContainer.heightAnchor.constraint(equalToConstant: ILMetrics.inputHeight),
            contentStack.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -16),
            contentStack.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),

            // Vùng tap của chip gợi ý cao bằng cả ô nhập (dễ bấm hơn), rộng khít đúng icon + text.
            suggestButton.heightAnchor.constraint(equalTo: inputContainer.heightAnchor),
            suggestContent.leadingAnchor.constraint(equalTo: suggestButton.leadingAnchor, constant: 13),
            suggestContent.trailingAnchor.constraint(equalTo: suggestButton.trailingAnchor, constant: -13),
            suggestContent.centerYAnchor.constraint(equalTo: suggestButton.centerYAnchor),

            ringView.widthAnchor.constraint(equalToConstant: 13),
            ringView.heightAnchor.constraint(equalToConstant: 13)
        ])
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILDharmaNameSuggestionField, _) in
            view.applyColorAppearanceChange()
        }
    }

    private func updatePlaceholder() {
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: ILColors.ink.withAlphaComponent(0.36), .font: ILTypography.bodyLarge]
        )
    }

    // `layer.borderColor` là CGColor tĩnh, không tự đảo theo trait — refresh thủ công khi hệ
    // thống đổi light/dark.
    private func applyColorAppearanceChange() {
        inputContainer.layer.borderColor = ILColors.ink.withAlphaComponent(0.12).cgColor
        ringView.layer.borderColor = ILColors.goldDeep.cgColor
    }

    @objc private func handleSuggestTap() {
        rotationTurns += 1
        UIView.animate(withDuration: 0.45, delay: 0, options: [.curveEaseInOut]) {
            self.ringView.transform = CGAffineTransform(rotationAngle: .pi * self.rotationTurns)
        }
        onSuggestTapped?()
    }

    // MARK: - UITextFieldDelegate
    @objc private func textDidChange() {
        onTextChanged?(value)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onReturn?()
        textField.resignFirstResponder()
        return true
    }
}
