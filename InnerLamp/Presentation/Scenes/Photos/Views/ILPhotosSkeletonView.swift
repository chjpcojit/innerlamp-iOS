//
//  ILPhotosSkeletonView.swift
//  InnerLamp
//

import UIKit

/// Loading placeholder for the "Ảnh chùa đẹp" grid: the same 2-column geometry as
/// `ILPhotosMasonryGridView` / `ILPhotosPhotoCardView` (4:3 image block + title / place lines),
/// built from the shared pulsing `ILSkeletonBarView`, so the layout does not jump when the first
/// page arrives. Not interactive and not scrollable — it only fills the first screenful.
final class ILPhotosSkeletonView: UIView {

    // MARK: - Layout constants
    private static let columnCount = 2
    private static let rowCount = 4

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
        backgroundColor = ILColors.canvas
        isAccessibilityElement = true
        accessibilityLabel = "loading.caption".localized
        accessibilityTraits = .updatesFrequently

        let rowsStack = UIStackView()
        rowsStack.axis = .vertical
        rowsStack.spacing = ILPhotosMasonryGridView.itemGap
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rowsStack)

        for row in 0..<Self.rowCount {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = ILPhotosMasonryGridView.columnGap
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
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        let delay = Double(index) * ILMetrics.Skeleton.rowPulseDelayStep

        let image = ILSkeletonBarView(
            color: ILColors.Skeleton.blockStrong,
            cornerRadius: ILMetrics.radiusCardSmall,
            pulseDelay: delay
        )
        let title = ILSkeletonBarView(color: ILColors.Skeleton.line, pulseDelay: delay)
        let place = ILSkeletonBarView(color: ILColors.Skeleton.lineSoft, pulseDelay: delay)
        [image, title, place].forEach(card.addSubview)

        NSLayoutConstraint.activate([
            image.topAnchor.constraint(equalTo: card.topAnchor),
            image.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            image.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            image.heightAnchor.constraint(
                equalTo: image.widthAnchor,
                multiplier: ILPhotosPhotoCardView.imageAspectRatio
            ),

            title.topAnchor.constraint(equalTo: image.bottomAnchor, constant: ILPhotosPhotoCardView.imageToTitleSpacing),
            title.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            title.heightAnchor.constraint(equalToConstant: ILMetrics.Skeleton.rowLineHeight),
            title.widthAnchor.constraint(equalTo: card.widthAnchor, multiplier: 0.8),

            place.topAnchor.constraint(equalTo: title.bottomAnchor, constant: ILMetrics.spaceSmall),
            place.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            place.heightAnchor.constraint(equalToConstant: ILMetrics.Skeleton.rowSubLineHeight),
            place.widthAnchor.constraint(equalTo: card.widthAnchor, multiplier: 0.5),
            place.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        return card
    }
}
