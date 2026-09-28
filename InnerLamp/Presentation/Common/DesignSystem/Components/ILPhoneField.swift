//
//  ILPhoneField.swift
//  InnerLamp
//

import UIKit

/// Ô nhập số điện thoại kèm bộ chọn mã vùng (cờ + mã quay số + mũi tên) — chỉ phụ thuộc dữ liệu
/// chung (`ILCountry`, text, trạng thái hợp lệ), không có nội dung riêng của feature nào nên đặt
/// ở Design System, không phải `Scenes/<Feature>/Views/`. Khớp field "Số điện thoại" trong design
/// handoff (`InnerLamp Prototype.dc.html`, block `isSignup`/`isLogin`).
public final class ILPhoneField: UIView, UITextFieldDelegate {

    public enum State {
        case normal
        case error(String?)
    }

    // MARK: - Properties
    public var label: String = "" {
        didSet { labelView.text = label.uppercased() }
    }

    public var country: ILCountry = .default {
        didSet { updateCountrySelector() }
    }

    public var text: String {
        get { textField.text ?? "" }
        set { textField.text = newValue }
    }

    public var placeholder: String = "" {
        didSet { updatePlaceholder() }
    }

    /// `true` khi số chữ số nằm trong `country.nationalDigitRange` — bật dấu tick xanh + viền
    /// bình thường. Khi `false`, viền chuyển vàng nhấn nhẹ (đúng `phoneBd` trong design handoff)
    /// thay vì đỏ lỗi — chỉ là gợi ý nhập tiếp, chưa phải lỗi thật.
    public var isValid: Bool = false {
        didSet { updateAppearance() }
    }

    /// Text phụ dưới field — đổi nội dung theo `isValid` (định dạng gợi ý / số sẽ nhận mã) do
    /// nơi gọi tính toán, field chỉ hiển thị.
    public var hint: String? {
        didSet { updateAppearance() }
    }

    public var fieldState: State = .normal {
        didSet { updateAppearance() }
    }

    public var onTextChanged: ((String) -> Void)?
    public var onCountryTap: (() -> Void)?
    public var onReturn: (() -> Void)?

    public var innerTextField: UITextField { textField }

    // MARK: - UI Elements
    private let labelView = UILabel()
    private let inputContainer = UIView()
    private let flagLabel = UILabel()
    private let dialLabel = UILabel()
    private let chevronView = UIView()
    private let dividerView = UIView()
    private let selectorTapArea = UIControl()
    private let textField = UITextField()
    private let checkBadge = UIView()
    private let checkLayer = CAShapeLayer()
    private let hintLabel = UILabel()

    // MARK: - Initializer
    public init(label: String = "", placeholder: String = "") {
        self.label = label
        self.placeholder = placeholder
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        labelView.font = ILTypography.label
        labelView.text = label.uppercased()

        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.layer.cornerRadius = ILMetrics.radiusInput
        inputContainer.layer.borderWidth = 1
        inputContainer.backgroundColor = ILColors.surface

        flagLabel.translatesAutoresizingMaskIntoConstraints = false
        flagLabel.font = .systemFont(ofSize: 19)

        dialLabel.translatesAutoresizingMaskIntoConstraints = false
        dialLabel.font = ILTypography.bodyLarge
        dialLabel.textColor = ILColors.ink

        chevronView.translatesAutoresizingMaskIntoConstraints = false
        chevronView.backgroundColor = .clear
        let chevronLayer = CAShapeLayer()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 3, y: 3))
        path.addLine(to: CGPoint(x: 6, y: 0))
        chevronLayer.path = path.cgPath
        chevronLayer.strokeColor = ILColors.inkSubtle.cgColor
        chevronLayer.fillColor = UIColor.clear.cgColor
        chevronLayer.lineWidth = 1.4
        chevronLayer.lineCap = .round
        chevronLayer.lineJoin = .round
        chevronLayer.frame = CGRect(x: 0, y: 3, width: 6, height: 3)
        chevronView.layer.addSublayer(chevronLayer)

        let selectorStack = UIStackView(arrangedSubviews: [flagLabel, dialLabel, chevronView])
        selectorStack.axis = .horizontal
        selectorStack.spacing = 7
        selectorStack.alignment = .center
        selectorStack.isUserInteractionEnabled = false
        selectorStack.translatesAutoresizingMaskIntoConstraints = false

        dividerView.translatesAutoresizingMaskIntoConstraints = false
        dividerView.backgroundColor = ILColors.ink.withAlphaComponent(0.12)

        // Nhóm "cờ + mã vùng + mũi tên + |" thành 1 khối riêng, độ rộng fix theo nội dung (không
        // co giãn khi UIStackView phân bổ khoảng trống dư) — chỉ `textField` được co giãn để lấp
        // phần còn lại. Không gộp, hugging priority của selectorStack/textField ngang nhau (250)
        // khiến layout ambiguous, chia đôi khoảng trống thay vì đúng như design handoff (`flex:none`
        // cho nhóm chọn mã, `flex:1` cho input).
        let selectorGroupView = UIView()
        selectorGroupView.translatesAutoresizingMaskIntoConstraints = false
        selectorGroupView.setContentHuggingPriority(.required, for: .horizontal)
        selectorGroupView.setContentCompressionResistancePriority(.required, for: .horizontal)
        selectorGroupView.addSubview(selectorStack)
        selectorGroupView.addSubview(dividerView)

        // Vùng tap riêng cho nhóm "cờ + mã vùng + |" — kéo dài hết chiều cao ô nhập (thay vì chỉ
        // bằng chiều cao chữ) để dễ bấm hơn, độ rộng khớp đúng nhóm này (không lấn sang divider
        // hay ô nhập số).
        selectorTapArea.translatesAutoresizingMaskIntoConstraints = false
        selectorTapArea.backgroundColor = .clear
        selectorTapArea.addTarget(self, action: #selector(handleCountryTap), for: .touchUpInside)

        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.font = ILTypography.bodyLarge
        textField.textColor = ILColors.ink
        textField.keyboardType = .phonePad
        textField.delegate = self
        textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        textField.setContentHuggingPriority(.init(1), for: .horizontal)
        updatePlaceholder()

        checkBadge.translatesAutoresizingMaskIntoConstraints = false
        checkBadge.layer.cornerRadius = 9
        checkBadge.backgroundColor = ILColors.greenText
        let checkPath = UIBezierPath()
        checkPath.move(to: CGPoint(x: 0, y: 2))
        checkPath.addLine(to: CGPoint(x: 3, y: 5))
        checkPath.addLine(to: CGPoint(x: 7, y: 0))
        checkLayer.path = checkPath.cgPath
        checkLayer.strokeColor = ILColors.canvas.cgColor
        checkLayer.fillColor = UIColor.clear.cgColor
        checkLayer.lineWidth = 1.5
        checkLayer.lineCap = .round
        checkLayer.lineJoin = .round
        checkLayer.frame = CGRect(x: 5, y: 6, width: 7, height: 5)
        checkBadge.layer.addSublayer(checkLayer)

        let contentStack = UIStackView(arrangedSubviews: [selectorGroupView, textField, checkBadge])
        contentStack.axis = .horizontal
        contentStack.spacing = 10
        contentStack.alignment = .center
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        inputContainer.addSubview(contentStack)
        inputContainer.addSubview(selectorTapArea)

        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        hintLabel.font = ILTypography.label
        hintLabel.numberOfLines = 0

        let mainStack = UIStackView(arrangedSubviews: [labelView, inputContainer, hintLabel])
        mainStack.axis = .vertical
        mainStack.spacing = 7
        mainStack.setCustomSpacing(6, after: inputContainer)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStack.topAnchor.constraint(equalTo: topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor),

            inputContainer.heightAnchor.constraint(equalToConstant: ILMetrics.inputHeight + 16),
            contentStack.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -16),
            contentStack.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),

            selectorStack.leadingAnchor.constraint(equalTo: selectorGroupView.leadingAnchor),
            selectorStack.topAnchor.constraint(equalTo: selectorGroupView.topAnchor),
            selectorStack.bottomAnchor.constraint(equalTo: selectorGroupView.bottomAnchor),

            dividerView.leadingAnchor.constraint(equalTo: selectorStack.trailingAnchor, constant: 10),
            dividerView.trailingAnchor.constraint(equalTo: selectorGroupView.trailingAnchor),
            dividerView.centerYAnchor.constraint(equalTo: selectorGroupView.centerYAnchor),
            dividerView.widthAnchor.constraint(equalToConstant: 1),
            dividerView.heightAnchor.constraint(equalToConstant: 20),

            selectorTapArea.topAnchor.constraint(equalTo: inputContainer.topAnchor),
            selectorTapArea.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor),
            selectorTapArea.leadingAnchor.constraint(equalTo: contentStack.leadingAnchor),
            selectorTapArea.trailingAnchor.constraint(equalTo: selectorGroupView.trailingAnchor),

            chevronView.widthAnchor.constraint(equalToConstant: 6),
            chevronView.heightAnchor.constraint(equalToConstant: 6),

            checkBadge.widthAnchor.constraint(equalToConstant: 18),
            checkBadge.heightAnchor.constraint(equalToConstant: 18)
        ])

        updateCountrySelector()
        updateAppearance()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILPhoneField, _) in
            view.applyColorAppearanceChange()
        }
    }

    private func updatePlaceholder() {
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: ILColors.ink.withAlphaComponent(0.36), .font: ILTypography.bodyLarge]
        )
    }

    private func updateCountrySelector() {
        flagLabel.text = country.flag
        dialLabel.text = country.dialCode
    }

    private func updateAppearance() {
        labelView.textColor = ILColors.inkSubtle

        switch fieldState {
        case .error(let message):
            inputContainer.layer.borderColor = ILColors.rose.cgColor
            hintLabel.text = message ?? hint
            hintLabel.textColor = ILColors.danger
            checkBadge.isHidden = true
        case .normal:
            inputContainer.layer.borderColor = isValid
                ? ILColors.ink.withAlphaComponent(0.12).cgColor
                : ILColors.gold.withAlphaComponent(0.55).cgColor
            hintLabel.text = hint
            hintLabel.textColor = ILColors.inkSubtle
            checkBadge.isHidden = !isValid
            checkBadge.alpha = isValid ? 1 : 0
        }

        hintLabel.isHidden = (hintLabel.text ?? "").isEmpty
    }

    // `layer.borderColor` là CGColor tĩnh, không tự đảo theo trait — refresh thủ công khi hệ
    // thống đổi light/dark.
    private func applyColorAppearanceChange() {
        checkLayer.strokeColor = ILColors.canvas.cgColor
        updateAppearance()
    }

    @objc private func handleCountryTap() {
        onCountryTap?()
    }

    @objc private func textDidChange() {
        onTextChanged?(text)
    }

    // MARK: - UITextFieldDelegate
    /// Chặn gõ/dán vượt `country.nationalDigitRange.upperBound` chữ số quốc gia — đếm cùng quy tắc
    /// với `nationalDigits` ở các StateModel (chỉ chữ số, bỏ số 0 đầu), nên `0912345678` và
    /// `912345678` đều gõ được đủ.
    public func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard let currentText = textField.text, let textRange = Range(range, in: currentText) else { return true }
        let updatedText = currentText.replacingCharacters(in: textRange, with: string)
        let digitsOnly = updatedText.filter(\.isNumber).drop(while: { $0 == "0" })
        return digitsOnly.count <= country.nationalDigitRange.upperBound
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onReturn?()
        textField.resignFirstResponder()
        return true
    }
}
