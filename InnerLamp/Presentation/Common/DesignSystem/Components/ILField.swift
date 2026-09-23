//
//  ILField.swift
//  InnerLamp
//
//  Created by ChjpCoj on 11/9/26.
//

import UIKit

public final class ILField: UIView, UITextFieldDelegate {
    
    public enum State {
        case normal
        case focused
        case error(String?)
        case success(String?)
        case disabled
    }
    
    // MARK: - Properties
    public var fieldState: State = .normal {
        didSet { updateAppearance() }
    }
    
    public var label: String = "" {
        didSet {
            labelView.text = label.uppercased()
            updateTopStackVisibility()
        }
    }
    
    public var placeholder: String = "" {
        didSet { updatePlaceholder() }
    }
    
    public var text: String {
        get { textField.text ?? "" }
        set {
            textField.text = newValue
            updateCounter()
        }
    }
    
    public var hint: String? {
        didSet { updateHintText() }
    }
    
    public var trailingText: String? {
        didSet {
            trailingLabel.text = trailingText
            trailingLabel.isHidden = (trailingText == nil || trailingText?.isEmpty == true)
        }
    }

    public var maxCount: Int? {
        didSet {
            updateCounter()
            updateTopStackVisibility()
        }
    }
    
    public var onTextChanged: ((String) -> Void)?
    public var onReturn: (() -> Void)?

    /// Gọi khi người dùng bấm vào `trailingText` (vd. nút "Hiện"/"Ẩn" mật khẩu, "Quên?").
    /// Chỉ nhận tap khi `trailingText` không rỗng (label ẩn thì gesture cũng vô nghĩa).
    public var onTrailingTap: (() -> Void)?

    public var innerTextField: UITextField { textField }
    
    // MARK: - UI Elements
    private let topStack = UIStackView()
    private let labelView = UILabel()
    private let counterLabel = UILabel()
    
    private let inputContainer = UIView()
    private let textField = UITextField()
    private let trailingLabel = UILabel()
    
    private let hintLabel = UILabel()
    
    // MARK: - Initializer
    public init(
        label: String = "",
        placeholder: String = "",
        text: String = "",
        hint: String? = nil,
        trailingText: String? = nil,
        maxCount: Int? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.hint = hint
        self.trailingText = trailingText
        self.maxCount = maxCount
        super.init(frame: .zero)
        self.text = text
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupViews() {
        labelView.font = ILTypography.label
        labelView.text = label.uppercased()
        
        counterLabel.font = ILTypography.caption
        counterLabel.textAlignment = .right
        counterLabel.isHidden = (maxCount == nil)
        
        topStack.axis = .horizontal
        topStack.distribution = .equalSpacing
        topStack.alignment = .firstBaseline
        topStack.translatesAutoresizingMaskIntoConstraints = false
        topStack.addArrangedSubview(labelView)
        topStack.addArrangedSubview(counterLabel)
        
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.layer.cornerRadius = ILMetrics.radiusInput
        inputContainer.layer.borderWidth = 1

        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.font = ILTypography.bodyLarge
        textField.delegate = self
        textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        
        trailingLabel.translatesAutoresizingMaskIntoConstraints = false
        trailingLabel.font = ILTypography.subheadMedium
        trailingLabel.text = trailingText
        trailingLabel.isHidden = (trailingText == nil || trailingText?.isEmpty == true)
        trailingLabel.setContentHuggingPriority(.required, for: .horizontal)
        trailingLabel.isUserInteractionEnabled = true
        trailingLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTrailingTap)))
        
        let inputContentStack = UIStackView(arrangedSubviews: [textField, trailingLabel])
        inputContentStack.axis = .horizontal
        inputContentStack.spacing = 10
        inputContentStack.alignment = .center
        inputContentStack.translatesAutoresizingMaskIntoConstraints = false

        inputContainer.addSubview(inputContentStack)

        NSLayoutConstraint.activate([
            inputContainer.heightAnchor.constraint(equalToConstant: ILMetrics.inputHeight),
            inputContentStack.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 16),
            inputContentStack.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -16),
            inputContentStack.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor)
        ])
        
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        hintLabel.font = ILTypography.label
        hintLabel.numberOfLines = 0
        
        let mainStack = UIStackView(arrangedSubviews: [topStack, inputContainer, hintLabel])
        mainStack.axis = .vertical
        mainStack.spacing = 7
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStack.topAnchor.constraint(equalTo: topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        updatePlaceholder()
        updateCounter()
        updateAppearance()
        updateTopStackVisibility()
    }

    /// Ẩn hàng nhãn khi không có `label`/`maxCount` — tránh khoảng trống rỗng phía trên ô nhập
    /// (design handoff dùng field "phẳng" không nhãn cho Mật khẩu ở màn Đăng nhập, `isLogin`).
    /// `UIStackView` tự loại view ẩn khỏi layout/spacing nên không cần chỉnh constraint riêng.
    private func updateTopStackVisibility() {
        topStack.isHidden = label.isEmpty && maxCount == nil
    }

    private func updatePlaceholder() {
        let color = ILColors.ink.withAlphaComponent(0.36)
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: color, .font: ILTypography.bodyLarge]
        )
    }
    
    private func updateCounter() {
        if let max = maxCount {
            counterLabel.isHidden = false
            counterLabel.text = "\(text.count)/\(max)"
        } else {
            counterLabel.isHidden = true
        }
    }
    
    private func updateHintText() {
        switch fieldState {
        case .error(let msg):
            let text = msg ?? hint ?? "Thông tin chưa hợp lệ"
            hintLabel.text = text
            hintLabel.isHidden = false
            hintLabel.textColor = ILColors.danger
        case .success(let msg):
            let text = msg ?? hint ?? ""
            hintLabel.text = text
            hintLabel.isHidden = text.isEmpty
            hintLabel.textColor = ILColors.greenText
        case .normal, .focused, .disabled:
            hintLabel.text = hint
            hintLabel.isHidden = (hint == nil || hint?.isEmpty == true)
            hintLabel.textColor = ILColors.ink.withAlphaComponent(0.45)
        }
    }

    private func updateAppearance() {
        updatePlaceholder()
        updateHintText()

        // Token động (ink*) tự đảo theo trait — không cần nhánh isDark thủ công.
        labelView.textColor = ILColors.ink.withAlphaComponent(0.48)
        counterLabel.textColor = ILColors.ink.withAlphaComponent(0.40)

        switch fieldState {
        case .disabled:
            textField.isEnabled = false
            inputContainer.backgroundColor = ILColors.ink.withAlphaComponent(0.035)
            inputContainer.layer.borderColor = ILColors.ink.withAlphaComponent(0.07).cgColor
            textField.textColor = ILColors.ink.withAlphaComponent(0.30)
            trailingLabel.textColor = textField.textColor

        case .error:
            textField.isEnabled = true
            inputContainer.backgroundColor = ILColors.surface
            inputContainer.layer.borderColor = ILColors.rose.cgColor
            textField.textColor = ILColors.ink
            trailingLabel.textColor = ILColors.danger

        case .success:
            textField.isEnabled = true
            inputContainer.backgroundColor = ILColors.surface
            inputContainer.layer.borderColor = ILColors.green.cgColor
            textField.textColor = ILColors.ink
            trailingLabel.textColor = ILColors.greenText

        case .focused:
            textField.isEnabled = true
            inputContainer.backgroundColor = ILColors.surface
            inputContainer.layer.borderColor = ILColors.gold.cgColor
            textField.textColor = ILColors.ink
            trailingLabel.textColor = ILColors.ink.withAlphaComponent(0.42)

        case .normal:
            textField.isEnabled = true
            inputContainer.backgroundColor = ILColors.surface
            inputContainer.layer.borderColor = ILColors.ink.withAlphaComponent(0.12).cgColor
            textField.textColor = ILColors.ink
            trailingLabel.textColor = ILColors.ink.withAlphaComponent(0.42)
        }
    }
    
    // `layer.borderColor` là CGColor tĩnh (surface/ink/gold/rose/green giờ có biến thể
    // dark) nên không tự đảo theo trait như `backgroundColor`/`textColor` — refresh
    // thủ công khi hệ thống đổi light/dark.
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateAppearance()
    }

    @objc private func handleTrailingTap() {
        guard trailingText?.isEmpty == false else { return }
        onTrailingTap?()
    }

    // MARK: - UITextFieldDelegate
    @objc private func textDidChange() {
        updateCounter()
        onTextChanged?(text)
    }
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        if case .error = fieldState { return }
        fieldState = .focused
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        if case .error = fieldState { return }
        fieldState = .normal
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onReturn?()
        textField.resignFirstResponder()
        return true
    }
}
