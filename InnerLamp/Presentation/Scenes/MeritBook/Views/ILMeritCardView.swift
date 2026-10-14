//
//  ILMeritCardView.swift
//  InnerLamp
//

import UIKit

/// Rounded bordered card shared by every block of the merit book (`radius 20`, 1pt border). The
/// border is a `CGColor`, so it is re-resolved when the system appearance flips.
class ILMeritCardView: UIView {

    private let fillColor: UIColor
    private let strokeColor: UIColor

    init(fillColor: UIColor = ILColors.surface, strokeColor: UIColor = ILColors.border) {
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        super.init(frame: .zero)
        backgroundColor = fillColor
        layer.cornerRadius = ILMetrics.radiusCardRegular
        layer.borderWidth = 1
        applyBorderColor()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILMeritCardView, _) in
            view.applyBorderColor()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func applyBorderColor() {
        layer.borderColor = strokeColor.resolvedColor(with: traitCollection).cgColor
    }
}

/// Pins `content` inside a card with the given insets.
extension ILMeritCardView {
    func embed(_ content: UIView, insets: UIEdgeInsets) {
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            content.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom),
            content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            content.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right)
        ])
    }
}
