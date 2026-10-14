//
//  ILFamilyTreeMemberPillView.swift
//  InnerLamp
//

import UIKit

/// Rounded label chip: status, role and "Với bạn" on the member profile.
final class ILFamilyTreeMemberPillView: UIView {

    private enum Layout {
        static let verticalPadding: CGFloat = 3
        static let horizontalPadding: CGFloat = 10
    }

    private lazy var label: UILabel = {
        let v = UILabel()
        v.font = ILTypography.captionMedium
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    init() {
        super.init(frame: .zero)
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: Layout.verticalPadding),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.verticalPadding),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalPadding),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalPadding)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(text: String, background: UIColor, foreground: UIColor) {
        label.text = text
        label.textColor = foreground
        backgroundColor = background
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }
}
