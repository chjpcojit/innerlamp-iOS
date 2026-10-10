//
//  ILSutrasSkeletonView.swift
//  InnerLamp
//

import UIKit

/// Loading placeholder for the "Kinh sách" list: the same card chrome and geometry as
/// `ILSutrasCardView` (name / original-name / translator lines + a badge pill), built from the
/// shared pulsing `ILSkeletonBarView`, so the layout does not jump when the first page arrives.
/// Not interactive and not scrollable — it only fills the first screenful.
final class ILSutrasSkeletonView: UIView {

    // MARK: - Layout constants
    private static let cardCount = 6
    private static let badgeSize = CGSize(width: 64, height: 22)

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

        let cardsStack = UIStackView()
        cardsStack.axis = .vertical
        cardsStack.spacing = ILMetrics.rowSpacing
        cardsStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cardsStack)

        (0..<Self.cardCount).forEach { cardsStack.addArrangedSubview(Self.makeCard(index: $0)) }

        let horizontal = ILMetrics.screenHorizontal
        NSLayoutConstraint.activate([
            cardsStack.topAnchor.constraint(equalTo: topAnchor, constant: ILMetrics.spaceMedium),
            cardsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontal),
            cardsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontal)
        ])
    }

    // MARK: - Factory
    private static func makeCard(index: Int) -> UIView {
        let card = SkeletonCardView()
        let delay = Double(index) * ILMetrics.Skeleton.rowPulseDelayStep
        let spec = ILMetrics.Skeleton.self

        let name = ILSkeletonBarView(color: ILColors.Skeleton.line, pulseDelay: delay)
        let original = ILSkeletonBarView(color: ILColors.Skeleton.lineSoft, pulseDelay: delay)
        let translator = ILSkeletonBarView(color: ILColors.Skeleton.lineSoft, pulseDelay: delay)
        let badge = ILSkeletonBarView(
            color: ILColors.Skeleton.bar, cornerRadius: ILMetrics.radiusPill, pulseDelay: delay
        )
        [name, original, translator, badge].forEach(card.addSubview)

        let leading = ILMetrics.spaceStandard
        NSLayoutConstraint.activate([
            name.topAnchor.constraint(equalTo: card.topAnchor, constant: ILMetrics.spaceMedium),
            name.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: leading),
            name.heightAnchor.constraint(equalToConstant: spec.rowLineHeight),
            name.widthAnchor.constraint(equalTo: card.widthAnchor, multiplier: 0.6),

            original.topAnchor.constraint(equalTo: name.bottomAnchor, constant: ILMetrics.spaceSmall),
            original.leadingAnchor.constraint(equalTo: name.leadingAnchor),
            original.heightAnchor.constraint(equalToConstant: spec.rowSubLineHeight),
            original.widthAnchor.constraint(equalTo: card.widthAnchor, multiplier: 0.4),

            translator.topAnchor.constraint(equalTo: original.bottomAnchor, constant: ILMetrics.spaceSmall),
            translator.leadingAnchor.constraint(equalTo: name.leadingAnchor),
            translator.heightAnchor.constraint(equalToConstant: spec.rowSubLineHeight),
            translator.widthAnchor.constraint(equalTo: card.widthAnchor, multiplier: 0.55),

            badge.topAnchor.constraint(equalTo: translator.bottomAnchor, constant: ILMetrics.rowSpacing),
            badge.leadingAnchor.constraint(equalTo: name.leadingAnchor),
            badge.widthAnchor.constraint(equalToConstant: badgeSize.width),
            badge.heightAnchor.constraint(equalToConstant: badgeSize.height),
            badge.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -ILMetrics.spaceMedium)
        ])
        return card
    }
}

/// Bordered surface card matching `ILSutrasCardView`'s chrome.
private final class SkeletonCardView: UIView {
    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardSmall
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor
        // CGColor does not follow dark mode on its own.
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: SkeletonCardView, _) in
            view.layer.borderColor = ILColors.border.resolvedColor(with: view.traitCollection).cgColor
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
