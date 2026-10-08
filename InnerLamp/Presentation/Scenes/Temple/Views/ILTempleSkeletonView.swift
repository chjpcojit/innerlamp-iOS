//
//  ILTempleSkeletonView.swift
//  InnerLamp
//

import UIKit

/// Whole-screen loading placeholder for the temple profile (`GET /v1/temples/{id}`): a full-bleed
/// hero block, the action buttons row (overlapping the hero like the real screen), the status card,
/// the 2×2 facts grid, the introduction lines and the organisation card — built from the shared
/// pulsing `ILSkeletonBarView` so the layout does not jump when the server data arrives.
///
/// Not interactive. Overlay it under the pinned header so Back stays reachable.
final class ILTempleSkeletonView: UIView {

    // MARK: - Layout constants
    private enum Layout {
        static let heroHeight: CGFloat = 270
        static let buttonHeight: CGFloat = 44
        static let buttonOverlap: CGFloat = 20
        static let statusCardHeight: CGFloat = 64
        static let factTileHeight: CGFloat = 64
        static let gridSpacing: CGFloat = 8
        static let orgCardHeight: CGFloat = 120
        static let introLineWidthRatios: [CGFloat] = [1, 0.94, 0.78]
        static let eyebrowWidthRatio: CGFloat = 0.3
        static let eyebrowHeight: CGFloat = 11
    }

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
        backgroundColor = ILColors.canvas
        clipsToBounds = true
        isUserInteractionEnabled = false
        isAccessibilityElement = true
        accessibilityLabel = "loading.caption".localized
        accessibilityTraits = .updatesFrequently

        let horizontal = ILMetrics.screenHorizontal

        // Hero: full-bleed under the pinned header.
        let hero = ILSkeletonBarView(color: ILColors.Skeleton.blockStrong, cornerRadius: 0)

        // Buttons row: overlaps the hero's bottom edge.
        let buttonsRow = UIStackView()
        buttonsRow.axis = .horizontal
        buttonsRow.spacing = ILMetrics.rowSpacing
        buttonsRow.distribution = .fillEqually
        for index in 0..<2 {
            let button = ILSkeletonBarView(
                color: ILColors.Skeleton.bar,
                cornerRadius: ILMetrics.radiusCardRegular,
                pulseDelay: Double(index) * ILMetrics.Skeleton.rowPulseDelayStep
            )
            button.heightAnchor.constraint(equalToConstant: Layout.buttonHeight).isActive = true
            buttonsRow.addArrangedSubview(button)
        }

        let body = UIStackView()
        body.axis = .vertical
        body.spacing = ILMetrics.rowSpacing

        let statusCard = ILSkeletonBarView(
            color: ILColors.Skeleton.rowBackground,
            cornerRadius: ILMetrics.radiusCardRegular,
            pulseDelay: ILMetrics.Skeleton.rowPulseDelayStep
        )
        statusCard.heightAnchor.constraint(equalToConstant: Layout.statusCardHeight).isActive = true
        body.addArrangedSubview(statusCard)
        body.addArrangedSubview(makeFactsGrid())
        body.setCustomSpacing(ILMetrics.groupSpacing, after: body.arrangedSubviews[1])

        let eyebrow = ILSkeletonBarView(color: ILColors.Skeleton.line, pulseDelay: ILMetrics.Skeleton.rowPulseDelayStep)
        eyebrow.heightAnchor.constraint(equalToConstant: Layout.eyebrowHeight).isActive = true
        let eyebrowRow = UIView()
        eyebrowRow.addSubview(eyebrow)
        NSLayoutConstraint.activate([
            eyebrow.topAnchor.constraint(equalTo: eyebrowRow.topAnchor),
            eyebrow.bottomAnchor.constraint(equalTo: eyebrowRow.bottomAnchor),
            eyebrow.leadingAnchor.constraint(equalTo: eyebrowRow.leadingAnchor),
            eyebrow.widthAnchor.constraint(equalTo: eyebrowRow.widthAnchor, multiplier: Layout.eyebrowWidthRatio)
        ])
        body.addArrangedSubview(eyebrowRow)

        let introLines = UIStackView()
        introLines.axis = .vertical
        introLines.spacing = ILMetrics.spaceSmall
        for (index, ratio) in Layout.introLineWidthRatios.enumerated() {
            introLines.addArrangedSubview(makeLine(widthRatio: ratio, index: index))
        }
        body.addArrangedSubview(introLines)
        body.setCustomSpacing(ILMetrics.groupSpacing, after: introLines)

        let orgCard = ILSkeletonBarView(
            color: ILColors.Skeleton.rowBackground,
            cornerRadius: ILMetrics.radiusCardRegular,
            pulseDelay: ILMetrics.Skeleton.rowPulseDelayStep * 2
        )
        orgCard.heightAnchor.constraint(equalToConstant: Layout.orgCardHeight).isActive = true
        body.addArrangedSubview(orgCard)

        [hero, buttonsRow, body].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            hero.topAnchor.constraint(equalTo: topAnchor),
            hero.leadingAnchor.constraint(equalTo: leadingAnchor),
            hero.trailingAnchor.constraint(equalTo: trailingAnchor),
            hero.heightAnchor.constraint(equalToConstant: Layout.heroHeight),

            buttonsRow.topAnchor.constraint(equalTo: hero.bottomAnchor, constant: -Layout.buttonOverlap),
            buttonsRow.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontal),
            buttonsRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontal),

            body.topAnchor.constraint(equalTo: buttonsRow.bottomAnchor, constant: ILMetrics.spaceStandard),
            body.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontal),
            body.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontal)
        ])
    }

    // MARK: - Factory
    /// 2×2 grid matching the real facts grid (4 tiles, `gridSpacing` apart).
    private func makeFactsGrid() -> UIView {
        let rows = UIStackView()
        rows.axis = .vertical
        rows.spacing = Layout.gridSpacing

        for row in 0..<2 {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = Layout.gridSpacing
            rowStack.distribution = .fillEqually
            for column in 0..<2 {
                let tile = ILSkeletonBarView(
                    color: ILColors.Skeleton.rowBackground,
                    cornerRadius: ILMetrics.radiusCardRegular,
                    pulseDelay: Double(row * 2 + column) * ILMetrics.Skeleton.rowPulseDelayStep
                )
                tile.heightAnchor.constraint(equalToConstant: Layout.factTileHeight).isActive = true
                rowStack.addArrangedSubview(tile)
            }
            rows.addArrangedSubview(rowStack)
        }
        return rows
    }

    /// One text line at `widthRatio` of the container width, leading-aligned.
    private func makeLine(widthRatio: CGFloat, index: Int) -> UIView {
        let container = UIView()
        let line = ILSkeletonBarView(
            color: ILColors.Skeleton.lineSoft,
            pulseDelay: Double(index) * ILMetrics.Skeleton.rowPulseDelayStep
        )
        container.addSubview(line)
        NSLayoutConstraint.activate([
            line.topAnchor.constraint(equalTo: container.topAnchor),
            line.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            line.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            line.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: widthRatio),
            line.heightAnchor.constraint(equalToConstant: ILMetrics.Skeleton.rowLineHeight)
        ])
        return container
    }
}
