//
//  ILDeitiesSkeletonView.swift
//  InnerLamp
//

import UIKit

/// Loading placeholder for the "Chư Phật & Bồ Tát" grid: the same 2-column layout and card
/// geometry as `ILDeitiesGridView` / `ILDeitiesCardView` (image block + name / role / vía lines),
/// built from the shared pulsing `ILSkeletonBarView`, so the layout does not jump when the server
/// data arrives. Not interactive and not scrollable — it only fills the first screenful.
final class ILDeitiesSkeletonView: UIView {

    // MARK: - Layout constants
    private static let columnCount = 2
    private static let rowCount = 4
    private static let gap: CGFloat = ILMetrics.spaceMedium

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
        isUserInteractionEnabled = false
        clipsToBounds = true
        isAccessibilityElement = true
        accessibilityLabel = "loading.caption".localized
        accessibilityTraits = .updatesFrequently

        let rowsStack = UIStackView()
        rowsStack.axis = .vertical
        rowsStack.spacing = Self.gap
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rowsStack)

        for row in 0..<Self.rowCount {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = Self.gap
            rowStack.distribution = .fillEqually
            rowStack.alignment = .top
            for column in 0..<Self.columnCount {
                rowStack.addArrangedSubview(Self.makeCard(index: row * Self.columnCount + column))
            }
            rowsStack.addArrangedSubview(rowStack)
        }

        let horizontal = ILMetrics.screenHorizontal
        NSLayoutConstraint.activate([
            rowsStack.topAnchor.constraint(equalTo: topAnchor, constant: ILMetrics.spaceStandard),
            rowsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontal),
            rowsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontal)
        ])
    }

    // MARK: - Factory
    private static func makeCard(index: Int) -> UIView {
        let card = SkeletonCardView()
        let delay = Double(index) * ILMetrics.Skeleton.rowPulseDelayStep
        let inset = ILDeitiesCardView.contentInset

        let image = ILSkeletonBarView(color: ILColors.Skeleton.blockStrong, cornerRadius: 0, pulseDelay: delay)
        let name = ILSkeletonBarView(color: ILColors.Skeleton.line, pulseDelay: delay)
        let role = ILSkeletonBarView(color: ILColors.Skeleton.lineSoft, pulseDelay: delay)
        let memorial = ILSkeletonBarView(color: ILColors.Skeleton.lineSoft, pulseDelay: delay)
        [image, name, role, memorial].forEach(card.addSubview)

        NSLayoutConstraint.activate([
            image.topAnchor.constraint(equalTo: card.topAnchor),
            image.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            image.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            image.heightAnchor.constraint(equalToConstant: ILDeitiesCardView.imageHeight),

            name.topAnchor.constraint(equalTo: image.bottomAnchor, constant: inset.top),
            name.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: inset.left),
            name.heightAnchor.constraint(equalToConstant: ILMetrics.Skeleton.rowLineHeight),
            name.widthAnchor.constraint(equalTo: card.widthAnchor, multiplier: 0.62),

            role.topAnchor.constraint(equalTo: name.bottomAnchor, constant: ILMetrics.spaceSmall),
            role.leadingAnchor.constraint(equalTo: name.leadingAnchor),
            role.heightAnchor.constraint(equalToConstant: ILMetrics.Skeleton.rowSubLineHeight),
            role.widthAnchor.constraint(equalTo: card.widthAnchor, multiplier: 0.72),

            memorial.topAnchor.constraint(equalTo: role.bottomAnchor, constant: ILMetrics.spaceSmall),
            memorial.leadingAnchor.constraint(equalTo: name.leadingAnchor),
            memorial.heightAnchor.constraint(equalToConstant: ILMetrics.Skeleton.rowSubLineHeight),
            memorial.widthAnchor.constraint(equalTo: card.widthAnchor, multiplier: 0.4),
            memorial.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -inset.bottom)
        ])
        return card
    }
}

/// Bordered surface card matching `ILDeitiesCardView`'s chrome.
private final class SkeletonCardView: UIView {
    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardRegular
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor
        clipsToBounds = true
        // CGColor does not follow dark mode on its own.
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: SkeletonCardView, _) in
            view.layer.borderColor = ILColors.border.resolvedColor(with: view.traitCollection).cgColor
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
