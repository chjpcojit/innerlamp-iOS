//
//  ILSectionEyebrowView.swift
//  InnerLamp
//

import UIKit

/// Nhãn eyebrow viết hoa cho 1 nhóm cài đặt (vd: "THỜI KHÓA", "RIÊNG TƯ") — 10px semi-bold, kern
/// .14em, màu mờ. Tái dùng được cho mọi màn có section kiểu cài đặt.
public final class ILSectionEyebrowView: UIView {

    public var title: String = "" {
        didSet { titleLabel.attributedText = ILTypography.makeEyebrow(text: title) }
    }

    private let titleLabel = UILabel()

    public init(title: String = "") {
        self.title = title
        super.init(frame: .zero)
        titleLabel.attributedText = ILTypography.makeEyebrow(text: title)
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
