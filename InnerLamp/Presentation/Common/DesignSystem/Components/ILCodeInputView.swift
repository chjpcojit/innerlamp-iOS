//
//  ILCodeInputView.swift
//  InnerLamp
//

import UIKit

/// Hàng N ô vuông nhập mã số (vd. OTP, PIN) — chỉ phụ thuộc số lượng ô, mã đang nhập và
/// trạng thái lỗi, không có nội dung riêng của feature nào nên đặt ở Design System, không
/// phải `Scenes/<Feature>/Views/`. Tự làm first responder và bắt bàn phím số qua `UIKeyInput`
/// thay vì nhúng `UITextField` ẩn — không có input carret thật để quản lý.
public final class ILCodeInputView: UIControl, UIKeyInput {

    // MARK: - Properties
    public let numberOfDigits: Int

    /// Mã đang nhập (chỉ chứa chữ số, độ dài 0...numberOfDigits). Set từ ngoài để reset
    /// (vd. sau khi gửi lại mã) — không tự động resign/become first responder khi set.
    public var code: String = "" {
        didSet {
            guard oldValue != code else { return }
            refreshBoxes()
        }
    }

    /// `true` khi mã vừa xác thực sai — tô viền đỏ toàn bộ ô đã điền.
    public var hasError: Bool = false {
        didSet { refreshBoxes() }
    }

    public var isCodeComplete: Bool { code.count == numberOfDigits }

    /// Gọi mỗi khi `code` đổi (gõ thêm số hoặc xóa).
    public var onCodeChanged: ((String) -> Void)?
    /// Gọi đúng 1 lần khi ô cuối cùng vừa được điền đủ.
    public var onCodeComplete: ((String) -> Void)?

    // MARK: - UIKeyInput
    public var hasText: Bool { !code.isEmpty }

    public func insertText(_ text: String) {
        guard text.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil else { return }
        guard code.count < numberOfDigits else { return }

        hasError = false
        code += text
        onCodeChanged?(code)
        if code.count == numberOfDigits {
            onCodeComplete?(code)
        }
    }

    public func deleteBackward() {
        guard !code.isEmpty else { return }
        hasError = false
        code.removeLast()
        onCodeChanged?(code)
    }

    public override var canBecomeFirstResponder: Bool { true }

    // MARK: - UI Elements
    private let boxesStack = UIStackView()
    private var boxViews: [UIView] = []
    private var digitLabels: [UILabel] = []

    // MARK: - Initializer
    public init(numberOfDigits: Int = 6) {
        self.numberOfDigits = max(numberOfDigits, 1)
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        boxesStack.axis = .horizontal
        boxesStack.spacing = 9
        boxesStack.alignment = .fill
        boxesStack.distribution = .fillEqually
        boxesStack.isUserInteractionEnabled = false
        boxesStack.translatesAutoresizingMaskIntoConstraints = false

        (0..<numberOfDigits).forEach { _ in
            let box = UIView()
            box.translatesAutoresizingMaskIntoConstraints = false
            box.layer.cornerRadius = ILMetrics.radiusInput
            box.layer.borderWidth = 1
            box.backgroundColor = ILColors.surface
            box.heightAnchor.constraint(equalToConstant: ILMetrics.otpDigitBoxHeight).isActive = true

            let digitLabel = UILabel()
            digitLabel.translatesAutoresizingMaskIntoConstraints = false
            digitLabel.font = ILTypography.otpDigit
            digitLabel.textColor = ILColors.ink
            digitLabel.textAlignment = .center
            box.addSubview(digitLabel)

            NSLayoutConstraint.activate([
                digitLabel.centerXAnchor.constraint(equalTo: box.centerXAnchor),
                digitLabel.centerYAnchor.constraint(equalTo: box.centerYAnchor)
            ])

            boxViews.append(box)
            digitLabels.append(digitLabel)
            boxesStack.addArrangedSubview(box)
        }

        addSubview(boxesStack)

        NSLayoutConstraint.activate([
            boxesStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            boxesStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            boxesStack.topAnchor.constraint(equalTo: topAnchor),
            boxesStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        refreshBoxes()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILCodeInputView, _) in
            view.applyColorAppearanceChange()
        }
    }

    private func refreshBoxes() {
        let digits = Array(code)
        for (index, box) in boxViews.enumerated() {
            digitLabels[index].text = index < digits.count ? String(digits[index]) : ""

            let isFilled = index < digits.count
            let isActive = isFirstResponder && index == digits.count

            if hasError {
                box.layer.borderColor = ILColors.rose.cgColor
            } else if isFilled || isActive {
                box.layer.borderColor = ILColors.gold.cgColor
            } else {
                // Viền ô rỗng — khớp `rgba(34,30,25,.12)` trong design handoff, cùng cách
                // derive alpha inline mà `ILField` đã dùng cho border rỗng của nó.
                box.layer.borderColor = ILColors.ink.withAlphaComponent(0.12).cgColor
            }
        }
    }

    // `layer.borderColor` là CGColor tĩnh, không tự đảo theo trait — refresh thủ công
    // khi hệ thống đổi light/dark (ink/gold/rose giờ có biến thể dark).
    private func applyColorAppearanceChange() {
        refreshBoxes()
    }

    public override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        refreshBoxes()
        return result
    }

    public override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        refreshBoxes()
        return result
    }

    @objc private func handleTap() {
        _ = becomeFirstResponder()
    }
}

// MARK: - UITextInputTraits
// Khai báo conform tường minh — UIKit tra các trait này qua `as? UITextInputTraits` để
// quyết định loại bàn phím và gợi ý autofill mã SMS phía trên bàn phím.
extension ILCodeInputView: UITextInputTraits {
    public var keyboardType: UIKeyboardType {
        get { .numberPad }
        set { /* luôn số — không cho override */ }
    }

    public var textContentType: UITextContentType? {
        get { .oneTimeCode }
        set { /* luôn one-time-code để hệ thống gợi ý mã SMS tự động điền */ }
    }
}
