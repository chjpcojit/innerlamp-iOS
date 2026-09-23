//
//  ILDividerRow.swift
//  InnerLamp
//

import UIKit

/// Hàng chia hai gạch ngang co giãn quanh một nhãn ở giữa (vd. "hoặc") — chỉ phụ thuộc `text`,
/// không có nội dung riêng của feature nào nên đặt ở Design System, không phải
/// `Scenes/<Feature>/Views/` (dùng đầu tiên ở màn Đăng nhập, tái dùng được cho bất kỳ màn nào
/// cần phân tách hai nhóm CTA).
public final class ILDividerRow: UIStackView {

    // MARK: - UI Elements
    private let leftLine = UIView()
    private let label = UILabel()
    private let rightLine = UIView()

    // MARK: - Initializer
    public init(text: String) {
        super.init(frame: .zero)
        label.text = text
        setupViews()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        leftLine.backgroundColor = ILColors.ink.withAlphaComponent(0.12)
        leftLine.translatesAutoresizingMaskIntoConstraints = false
        leftLine.heightAnchor.constraint(equalToConstant: 1).isActive = true

        rightLine.backgroundColor = ILColors.ink.withAlphaComponent(0.12)
        rightLine.translatesAutoresizingMaskIntoConstraints = false
        rightLine.heightAnchor.constraint(equalToConstant: 1).isActive = true

        label.font = ILTypography.label
        label.textColor = ILColors.ink.withAlphaComponent(0.38)
        label.setContentHuggingPriority(.required, for: .horizontal)

        [leftLine, label, rightLine].forEach { addArrangedSubview($0) }

        axis = .horizontal
        alignment = .center
        spacing = 12

        // `UIView` không có intrinsic width — ép 2 gạch bằng nhau thay vì trông chờ
        // content-hugging (cùng priority 250 nhưng dễ lệch, một bên co về 0).
        leftLine.widthAnchor.constraint(equalTo: rightLine.widthAnchor).isActive = true
    }
}
