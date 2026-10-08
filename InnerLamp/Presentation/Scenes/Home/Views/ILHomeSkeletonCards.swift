//
//  ILHomeSkeletonCards.swift
//  InnerLamp
//

import UIKit

/// Card-shaped loading placeholders for Home's server-backed sections (temples, deities, articles),
/// sized to match the real cards so the layout does not jump when the data arrives. Built from the
/// shared `ILSkeletonBarView`; none of them is interactive.
enum ILHomeSkeletonCards {

    /// Sections show this many placeholder cards while their first load is in flight.
    static let carouselCount = 3
    static let articleRowCount = 3

    /// Placeholder for `ILHomeTempleCardView` — image block + name / place / note lines. The caller
    /// pins its width.
    static func templeCard(index: Int) -> UIView {
        let card = makeCard()
        let delay = Double(index) * ILMetrics.Skeleton.rowPulseDelayStep

        let image = ILSkeletonBarView(color: ILColors.Skeleton.blockStrong, cornerRadius: ILMetrics.radiusCardSmall, pulseDelay: delay)
        let name = ILSkeletonBarView(color: ILColors.Skeleton.line, pulseDelay: delay)
        let place = ILSkeletonBarView(color: ILColors.Skeleton.lineSoft, pulseDelay: delay)
        let note = ILSkeletonBarView(color: ILColors.Skeleton.lineSoft, pulseDelay: delay)
        [image, name, place, note].forEach(card.addSubview)

        NSLayoutConstraint.activate([
            image.topAnchor.constraint(equalTo: card.topAnchor),
            image.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            image.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            image.heightAnchor.constraint(equalToConstant: 150),

            name.topAnchor.constraint(equalTo: image.bottomAnchor, constant: 12),
            name.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            name.heightAnchor.constraint(equalToConstant: ILMetrics.Skeleton.rowLineHeight),
            name.widthAnchor.constraint(equalTo: card.widthAnchor, multiplier: 0.6),

            place.topAnchor.constraint(equalTo: name.bottomAnchor, constant: ILMetrics.spaceSmall),
            place.leadingAnchor.constraint(equalTo: name.leadingAnchor),
            place.heightAnchor.constraint(equalToConstant: ILMetrics.Skeleton.rowSubLineHeight),
            place.widthAnchor.constraint(equalTo: card.widthAnchor, multiplier: 0.4),

            note.topAnchor.constraint(equalTo: place.bottomAnchor, constant: ILMetrics.spaceSmall),
            note.leadingAnchor.constraint(equalTo: name.leadingAnchor),
            note.heightAnchor.constraint(equalToConstant: ILMetrics.Skeleton.rowSubLineHeight),
            note.widthAnchor.constraint(equalTo: card.widthAnchor, multiplier: 0.7),
            note.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])
        return card
    }

    /// Placeholder for `ILHomeDeityCardView` — portrait image block + name / vía lines. The caller
    /// pins its width.
    static func deityCard(index: Int, imageHeight: CGFloat) -> UIView {
        let card = makeCard(background: nil)
        let delay = Double(index) * ILMetrics.Skeleton.rowPulseDelayStep

        let image = ILSkeletonBarView(color: ILColors.Skeleton.blockStrong, cornerRadius: ILMetrics.radiusCardSmall, pulseDelay: delay)
        let name = ILSkeletonBarView(color: ILColors.Skeleton.line, pulseDelay: delay)
        let memorial = ILSkeletonBarView(color: ILColors.Skeleton.lineSoft, pulseDelay: delay)
        [image, name, memorial].forEach(card.addSubview)

        NSLayoutConstraint.activate([
            image.topAnchor.constraint(equalTo: card.topAnchor),
            image.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            image.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            image.heightAnchor.constraint(equalToConstant: imageHeight),

            name.topAnchor.constraint(equalTo: image.bottomAnchor, constant: ILMetrics.spaceSmall),
            name.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            name.heightAnchor.constraint(equalToConstant: ILMetrics.Skeleton.rowLineHeight),
            name.widthAnchor.constraint(equalTo: card.widthAnchor, multiplier: 0.8),

            memorial.topAnchor.constraint(equalTo: name.bottomAnchor, constant: ILMetrics.spaceSmall),
            memorial.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            memorial.heightAnchor.constraint(equalToConstant: ILMetrics.Skeleton.rowSubLineHeight),
            memorial.widthAnchor.constraint(equalTo: card.widthAnchor, multiplier: 0.55),
            memorial.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        return card
    }

    /// Placeholder for `ILArticleCardView` — 84pt thumbnail + category / title / meta lines in the
    /// card's 12pt padding.
    static func articleRow(index: Int) -> UIView {
        let card = makeCard()
        let delay = Double(index) * ILMetrics.Skeleton.rowPulseDelayStep

        let thumbnail = ILSkeletonBarView(color: ILColors.Skeleton.bar, cornerRadius: ILMetrics.radiusIconTile, pulseDelay: delay)
        let category = ILSkeletonBarView(color: ILColors.Skeleton.lineSoft, pulseDelay: delay)
        let title = ILSkeletonBarView(color: ILColors.Skeleton.line, pulseDelay: delay)
        let meta = ILSkeletonBarView(color: ILColors.Skeleton.lineSoft, pulseDelay: delay)
        let textColumn = UIView()
        textColumn.translatesAutoresizingMaskIntoConstraints = false
        [category, title, meta].forEach(textColumn.addSubview)
        [thumbnail, textColumn].forEach(card.addSubview)

        NSLayoutConstraint.activate([
            thumbnail.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            thumbnail.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            thumbnail.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            thumbnail.widthAnchor.constraint(equalToConstant: 84),
            thumbnail.heightAnchor.constraint(equalToConstant: 84),

            textColumn.leadingAnchor.constraint(equalTo: thumbnail.trailingAnchor, constant: ILMetrics.spaceMedium),
            textColumn.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            textColumn.centerYAnchor.constraint(equalTo: thumbnail.centerYAnchor),

            category.topAnchor.constraint(equalTo: textColumn.topAnchor),
            category.leadingAnchor.constraint(equalTo: textColumn.leadingAnchor),
            category.heightAnchor.constraint(equalToConstant: ILMetrics.Skeleton.rowSubLineHeight),
            category.widthAnchor.constraint(equalTo: textColumn.widthAnchor, multiplier: 0.3),

            title.topAnchor.constraint(equalTo: category.bottomAnchor, constant: ILMetrics.spaceSmall),
            title.leadingAnchor.constraint(equalTo: textColumn.leadingAnchor),
            title.heightAnchor.constraint(equalToConstant: ILMetrics.Skeleton.rowLineHeight),
            title.widthAnchor.constraint(equalTo: textColumn.widthAnchor, multiplier: 0.9),

            meta.topAnchor.constraint(equalTo: title.bottomAnchor, constant: ILMetrics.spaceSmall),
            meta.leadingAnchor.constraint(equalTo: textColumn.leadingAnchor),
            meta.bottomAnchor.constraint(equalTo: textColumn.bottomAnchor),
            meta.heightAnchor.constraint(equalToConstant: ILMetrics.Skeleton.rowSubLineHeight),
            meta.widthAnchor.constraint(equalTo: textColumn.widthAnchor, multiplier: ILMetrics.Skeleton.rowSubLineWidthRatio)
        ])
        return card
    }

    // MARK: - Private
    private static func makeCard(background: UIColor? = ILColors.Skeleton.rowBackground) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = background
        card.layer.cornerRadius = ILMetrics.radiusCardRegular
        card.clipsToBounds = true
        card.isUserInteractionEnabled = false
        card.isAccessibilityElement = false
        return card
    }
}
