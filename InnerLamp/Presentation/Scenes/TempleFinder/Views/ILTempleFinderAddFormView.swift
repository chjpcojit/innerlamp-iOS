//
//  ILTempleFinderAddFormView.swift
//  InnerLamp
//

import UIKit

/// Form "Đề xuất thêm chùa": tên chùa, địa chỉ, tỉnh / thành phố, số điện thoại (không bắt buộc),
/// nút "Hủy" / "Gửi đề xuất". Giữ nguyên chữ đã nhập khi `ViewController` render lại state; chỉ
/// `open(prefillName:)` mới ghi đè ô tên.
final class ILTempleFinderAddFormView: UIView {

    // MARK: - Properties
    var onCancel: (() -> Void)?
    var onSubmit: ((ILTempleFinderProposal) -> Void)?

    // MARK: - UI Elements
    private let nameField = ILField(
        label: "templeFinder.form.name.label".localized, placeholder: "templeFinder.form.name.placeholder".localized
    )
    private let addressField = ILField(
        label: "templeFinder.form.address.label".localized, placeholder: "templeFinder.form.address.placeholder".localized
    )
    private let provinceField = ILField(
        label: "templeFinder.form.province.label".localized, placeholder: "templeFinder.form.province.placeholder".localized
    )
    private let phoneField = ILField(
        label: "templeFinder.form.phone.label".localized, placeholder: "templeFinder.form.phone.placeholder".localized
    )
    private lazy var cancelButton = ILButton(title: "templeFinder.form.cancel".localized, variant: .ghost)
    private lazy var submitButton = ILButton(title: "templeFinder.form.submit".localized, variant: .primary)

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    /// Xóa form và điền sẵn tên — gọi mỗi lần form vừa mở.
    func open(prefillName: String) {
        nameField.text = prefillName
        addressField.text = ""
        provinceField.text = ""
        phoneField.text = ""
        apply(errorMessage: nil, field: nil)
    }

    func apply(errorMessage: String?, field: ILTempleFinderAddField?) {
        nameField.fieldState = field == .name ? .error(errorMessage) : .normal
        provinceField.fieldState = field == .province ? .error(errorMessage) : .normal
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardRegular
        layer.borderWidth = 1
        layer.borderColor = ILColors.goldCardBorder.cgColor
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.layer.borderColor = ILColors.goldCardBorder.cgColor
        }

        let title = UILabel()
        title.font = ILTypography.heroCardTitle
        title.textColor = ILColors.ink
        title.text = "templeFinder.form.title".localized
        let body = UILabel()
        body.numberOfLines = 0
        body.attributedText = ILTypography.makeAttributedString(
            text: "templeFinder.form.subtitle".localized,
            font: ILTypography.note, color: ILColors.inkTertiary, lineHeightMultiple: 1.6
        )
        let header = UIStackView(arrangedSubviews: [title, body])
        header.axis = .vertical
        header.spacing = 4

        cancelButton.onTap = { [weak self] in self?.onCancel?() }
        submitButton.onTap = { [weak self] in self?.handleSubmit() }
        phoneField.innerTextField.keyboardType = .phonePad
        let buttons = UIStackView(arrangedSubviews: [cancelButton, submitButton])
        buttons.axis = .horizontal
        buttons.spacing = ILMetrics.rowSpacing
        buttons.distribution = .fill
        cancelButton.widthAnchor.constraint(equalTo: submitButton.widthAnchor, multiplier: 0.5).isActive = true

        let stack = UIStackView(arrangedSubviews: [header, nameField, addressField, provinceField, phoneField, buttons])
        stack.axis = .vertical
        stack.spacing = ILMetrics.spaceMedium - 2
        stack.setCustomSpacing(ILMetrics.spaceStandard, after: phoneField)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        let inset = ILMetrics.spaceStandard + 2
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: inset),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset)
        ])
    }

    // MARK: - Actions
    private func handleSubmit() {
        endEditing(true)
        onSubmit?(
            ILTempleFinderProposal(
                name: nameField.text, address: addressField.text,
                province: provinceField.text, phone: phoneField.text
            )
        )
    }
}
