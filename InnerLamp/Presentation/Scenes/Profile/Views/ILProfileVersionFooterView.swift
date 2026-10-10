//
//  ILProfileVersionFooterView.swift
//  InnerLamp
//

import UIKit

/// Chân trang màn Tôi: 2 dòng căn giữa "InnerLamp · Phiên bản x" và "Bản dựng y". Chỉ hiển thị,
/// không nhận chạm. Nội dung riêng màn Tôi.
final class ILProfileVersionFooterView: UIView {

    // MARK: - UI Elements
    private lazy var versionLabel = makeLabel()
    private lazy var buildLabel = makeLabel()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        let stack = UIStackView(arrangedSubviews: [versionLabel, buildLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    private func makeLabel() -> UILabel {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.inkTertiary
        label.textAlignment = .center
        return label
    }

    // MARK: - Configure
    func configure(versionText: String, buildText: String) {
        versionLabel.text = versionText
        buildLabel.text = buildText
    }
}
