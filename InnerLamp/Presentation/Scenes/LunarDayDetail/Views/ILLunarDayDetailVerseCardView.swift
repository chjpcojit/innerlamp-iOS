//
//  ILLunarDayDetailVerseCardView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 27/9/26.
//

import UIKit

/// Thẻ "câu kinh trong ngày" — nền gradient `--il-feat-*`, vầng sáng vàng ở đỉnh giữa, các dòng
/// kệ kinh Lora căn giữa và nguồn trích dẫn nghiêng ở đáy (khớp `dcVerse`/`dcSource` trong design
/// handoff).
final class ILLunarDayDetailVerseCardView: UIView {

    private enum Layout {
        static let horizontalPadding: CGFloat = 22
        static let verticalPadding: CGFloat = 24
        static let sourceTopSpacing: CGFloat = 12
        static let glowSize: CGFloat = 240
        static let glowTopInset: CGFloat = -80
    }

    // MARK: - Properties
    var verseLines: [String] = [] {
        didSet { rebuildVerse() }
    }

    var verseSource: String = "" {
        didSet { sourceLabel.text = verseSource }
    }

    // MARK: - UI Elements
    private let gradientLayer = CAGradientLayer()
    private let glowLayer = CAGradientLayer()
    private let verseStack = UIStackView()
    private let sourceLabel = UILabel()
    private let contentStack = UIStackView()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = ILMetrics.radiusCardMedium
        layer.borderWidth = 1
        clipsToBounds = true

        gradientLayer.startPoint = CGPoint(x: 0.1, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.9, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)

        glowLayer.type = .radial
        glowLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        glowLayer.endPoint = CGPoint(x: 1, y: 1)
        glowLayer.locations = [0, 0.66]
        layer.insertSublayer(glowLayer, above: gradientLayer)

        verseStack.axis = .vertical
        verseStack.spacing = 4
        verseStack.alignment = .center

        sourceLabel.font = sourceFont
        sourceLabel.textColor = ILColors.templeHeaderSub
        sourceLabel.textAlignment = .center
        sourceLabel.numberOfLines = 0

        contentStack.axis = .vertical
        contentStack.alignment = .center
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(verseStack)
        contentStack.addArrangedSubview(sourceLabel)
        contentStack.setCustomSpacing(Layout.sourceTopSpacing, after: verseStack)
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: Layout.verticalPadding),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.verticalPadding),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalPadding),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalPadding)
        ])

        updateAppearance()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILLunarDayDetailVerseCardView, _) in
            view.applyColorAppearanceChange()
        }
    }

    /// Lora 12 nghiêng — không có preset sẵn khớp size này trong `ILTypography`, cùng cách
    /// `ILQuoteCardView`/`ILHomeLunarHeroCardView` tự derive font nghiêng cục bộ từ `scriptureBodyTiny`.
    private var sourceFont: UIFont {
        let base = ILTypography.scriptureBodyTiny
        guard let descriptor = base.fontDescriptor.withSymbolicTraits(.traitItalic) else { return base }
        return UIFont(descriptor: descriptor, size: base.pointSize)
    }

    private func updateAppearance() {
        gradientLayer.colors = [ILColors.featBackgroundStart.cgColor, ILColors.featBackgroundEnd.cgColor]
        glowLayer.colors = [ILColors.featGlow.cgColor, ILColors.featGlowClear.cgColor]
        layer.borderColor = ILColors.featBorder.cgColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        glowLayer.frame = CGRect(
            x: bounds.midX - Layout.glowSize / 2,
            y: Layout.glowTopInset,
            width: Layout.glowSize,
            height: Layout.glowSize
        )
        glowLayer.cornerRadius = Layout.glowSize / 2
    }

    private func applyColorAppearanceChange() {
        updateAppearance()
    }

    // MARK: - Rebuild
    private func rebuildVerse() {
        verseStack.arrangedSubviews.forEach {
            verseStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for line in verseLines {
            let label = UILabel()
            label.attributedText = ILTypography.makeParagraph(
                text: line,
                font: ILTypography.dateTileDay,
                color: ILColors.templeHeaderInk,
                cssLineHeight: 1.55,
                alignment: .center
            )
            label.numberOfLines = 0
            label.textAlignment = .center
            verseStack.addArrangedSubview(label)
        }
    }
}
