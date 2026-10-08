//
//  ILTempleFinderSkeletonView.swift
//  InnerLamp
//

import UIKit

/// Skeleton shown while the temple catalog is loading: a hairline card of placeholder rows that fills the screen shaped
/// like `ILTempleFinderRowCell` (name line + address line + pill button) so the layout does not
/// jump when the real list arrives. Built from the shared `ILSkeletonBarView`; not interactive.
final class ILTempleFinderSkeletonView: UIView {

    private static let rowCount = 14

    init() {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        // More rows than any screen shows — the card runs past the bottom edge and is clipped, so the
        // skeleton always fills the whole screen under the header.
        clipsToBounds = true
        isAccessibilityElement = true
        accessibilityLabel = "loading.caption".localized
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        let card = UIView()
        card.backgroundColor = ILColors.surface
        card.layer.cornerRadius = ILMetrics.radiusCardRegular
        card.layer.borderWidth = 1
        card.layer.borderColor = ILColors.border.cgColor
        card.clipsToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false
        addSubview(card)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        for index in 0..<Self.rowCount {
            if index > 0 { stack.addArrangedSubview(makeDivider()) }
            stack.addArrangedSubview(makeRow(index: index))
        }

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: topAnchor, constant: ILMetrics.spaceSmall),
            card.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.screenHorizontal),
            card.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.screenHorizontal),

            stack.topAnchor.constraint(equalTo: card.topAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor)
        ])

        // `layer.borderColor` is a static CGColor — refresh by hand on light/dark change.
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILTempleFinderSkeletonView, _) in
            card.layer.borderColor = ILColors.border.cgColor
        }
    }

    private func makeDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = ILColors.border
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return divider
    }

    private func makeRow(index: Int) -> UIView {
        let row = UIView()
        let delay = Double(index) * ILMetrics.Skeleton.rowPulseDelayStep
        let inset = ILMetrics.spaceMedium - 2

        let name = ILSkeletonBarView(color: ILColors.Skeleton.line, pulseDelay: delay)
        let address = ILSkeletonBarView(color: ILColors.Skeleton.lineSoft, pulseDelay: delay)
        let pill = ILSkeletonBarView(
            color: ILColors.Skeleton.blockStrong,
            cornerRadius: ILMetrics.Skeleton.rowPillHeight / 2,
            pulseDelay: delay
        )
        [name, address, pill].forEach(row.addSubview)

        NSLayoutConstraint.activate([
            name.topAnchor.constraint(equalTo: row.topAnchor, constant: inset + 2),
            name.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: ILMetrics.spaceMedium),
            name.heightAnchor.constraint(equalToConstant: ILMetrics.Skeleton.rowLineHeight),
            name.widthAnchor.constraint(equalTo: row.widthAnchor, multiplier: 0.5),

            address.topAnchor.constraint(equalTo: name.bottomAnchor, constant: ILMetrics.spaceSmall),
            address.leadingAnchor.constraint(equalTo: name.leadingAnchor),
            address.heightAnchor.constraint(equalToConstant: ILMetrics.Skeleton.rowSubLineHeight),
            address.widthAnchor.constraint(equalTo: row.widthAnchor, multiplier: 0.35),
            address.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -(inset + 2)),

            pill.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            pill.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -ILMetrics.spaceMedium),
            pill.widthAnchor.constraint(equalToConstant: ILMetrics.Skeleton.rowPillWidth),
            pill.heightAnchor.constraint(equalToConstant: ILMetrics.Skeleton.rowPillHeight)
        ])
        return row
    }
}
