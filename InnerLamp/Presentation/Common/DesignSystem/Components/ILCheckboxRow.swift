//
//  ILCheckboxRow.swift
//  InnerLamp
//

import UIKit

/// Hàng checkbox + đoạn text mô tả (vd. đồng ý điều khoản sử dụng) — chỉ phụ thuộc dữ liệu
/// chung (text, trạng thái check), không có nội dung riêng của feature nào nên đặt ở
/// Design System, không phải `Scenes/<Feature>/Views/`.
public final class ILCheckboxRow: UIControl {

    // MARK: - Properties
    public var isChecked: Bool = false {
        didSet { updateAppearance() }
    }

    public var text: String = "" {
        didSet { textLabel.text = text }
    }

    public var onToggle: (() -> Void)?

    // MARK: - UI Elements
    private let boxView = UIView()
    private let checkmarkLabel = UILabel()
    private let textLabel = UILabel()

    // MARK: - Initializer
    public init(text: String = "", isChecked: Bool = false) {
        self.text = text
        self.isChecked = isChecked
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        boxView.translatesAutoresizingMaskIntoConstraints = false
        boxView.layer.cornerRadius = 6
        boxView.layer.borderWidth = 1
        boxView.isUserInteractionEnabled = false

        checkmarkLabel.translatesAutoresizingMaskIntoConstraints = false
        checkmarkLabel.text = "✓"
        checkmarkLabel.font = ILTypography.captionSmall
        checkmarkLabel.textAlignment = .center
        checkmarkLabel.textColor = ILColors.canvas
        boxView.addSubview(checkmarkLabel)

        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.font = ILTypography.subhead
        textLabel.textColor = ILColors.inkDim
        textLabel.numberOfLines = 0
        textLabel.text = text
        textLabel.isUserInteractionEnabled = false

        addSubview(boxView)
        addSubview(textLabel)

        NSLayoutConstraint.activate([
            boxView.leadingAnchor.constraint(equalTo: leadingAnchor),
            boxView.topAnchor.constraint(equalTo: topAnchor, constant: 1),
            boxView.widthAnchor.constraint(equalToConstant: 20),
            boxView.heightAnchor.constraint(equalToConstant: 20),

            checkmarkLabel.centerXAnchor.constraint(equalTo: boxView.centerXAnchor),
            checkmarkLabel.centerYAnchor.constraint(equalTo: boxView.centerYAnchor, constant: -1),

            textLabel.leadingAnchor.constraint(equalTo: boxView.trailingAnchor, constant: 11),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            textLabel.topAnchor.constraint(equalTo: topAnchor),
            textLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        updateAppearance()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILCheckboxRow, _) in
            view.applyColorAppearanceChange()
        }
    }

    private func updateAppearance() {
        if isChecked {
            boxView.backgroundColor = ILColors.ink
            boxView.layer.borderColor = ILColors.ink.cgColor
            checkmarkLabel.alpha = 1
        } else {
            boxView.backgroundColor = .clear
            boxView.layer.borderColor = ILColors.borderStrong.cgColor
            checkmarkLabel.alpha = 0
        }
    }

    // `layer.borderColor` là CGColor tĩnh, không tự đảo theo trait — refresh thủ công
    // khi hệ thống đổi light/dark (ink giờ có biến thể dark).
    private func applyColorAppearanceChange() {
        updateAppearance()
    }

    @objc private func handleTap() {
        onToggle?()
    }
}
