//
//  ILReaderLineCell.swift
//  InnerLamp
//

import UIKit

/// A chanted line: cue glyph (◉ / •) on the left, the Vietnamese line in Lora and an optional
/// English gloss under it. The current line gets a soft gold highlight; the others are dimmed.
/// Matches the `data-rl` rows of `isReader` in the design handoff.
final class ILReaderLineCell: UITableViewCell {

    static let reuseIdentifier = "ILReaderLineCell"

    private static let currentAlpha: CGFloat = 1
    private static let dimmedAlpha: CGFloat = 0.6
    private static let highlightAlpha: CGFloat = 0.28
    private static let cueColumnWidth: CGFloat = 16

    private let cueLabel = UILabel()
    private let highlightView = UIView()
    private let lineLabel = UILabel()
    private let glossLabel = UILabel()
    private let contentStack = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = .clear
        selectionStyle = .none

        cueLabel.font = ILTypography.readerCue
        cueLabel.textColor = ILColors.goldBright
        cueLabel.textAlignment = .center

        highlightView.layer.cornerRadius = ILMetrics.radiusLineHighlight
        lineLabel.numberOfLines = 0
        glossLabel.numberOfLines = 0

        highlightView.translatesAutoresizingMaskIntoConstraints = false
        lineLabel.translatesAutoresizingMaskIntoConstraints = false
        highlightView.addSubview(lineLabel)

        contentStack.axis = .vertical
        contentStack.spacing = 4
        contentStack.alignment = .fill
        contentStack.addArrangedSubview(highlightView)
        contentStack.addArrangedSubview(glossLabel)

        [cueLabel, contentStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            cueLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cueLabel.widthAnchor.constraint(equalToConstant: Self.cueColumnWidth),
            cueLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 11),

            contentStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            contentStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            contentStack.leadingAnchor.constraint(equalTo: cueLabel.trailingAnchor, constant: 10),
            contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // 4pt inner padding so the highlight extends past the text (design `padding:0 4px`).
            lineLabel.topAnchor.constraint(equalTo: highlightView.topAnchor),
            lineLabel.bottomAnchor.constraint(equalTo: highlightView.bottomAnchor),
            lineLabel.leadingAnchor.constraint(equalTo: highlightView.leadingAnchor, constant: 4),
            lineLabel.trailingAnchor.constraint(equalTo: highlightView.trailingAnchor, constant: -4)
        ])
    }

    /// Updates content and styling. Pass `animated: true` to cross-fade the highlight when the
    /// current line moves (0.3s, like the prototype's `transition`).
    func configure(
        with row: ILReaderLineRowState,
        fontSizeIndex: Int,
        palette: ILReaderPalette,
        animated: Bool
    ) {
        let fonts = ILTypography.readerLineFonts
        let font = fonts[min(max(fontSizeIndex, 0), fonts.count - 1)]
        lineLabel.attributedText = ILTypography.makeParagraph(
            text: row.text, font: font, color: palette.ink, cssLineHeight: 1.55
        )
        cueLabel.text = row.cueGlyph
        glossLabel.isHidden = row.gloss.isEmpty
        glossLabel.attributedText = row.gloss.isEmpty ? nil : ILTypography.makeParagraph(
            text: row.gloss, font: ILTypography.readerGloss, color: palette.subtle, cssLineHeight: 1.6
        )

        let applyHighlight = {
            self.contentStack.alpha = row.isCurrent ? Self.currentAlpha : Self.dimmedAlpha
            self.cueLabel.alpha = row.isCurrent ? Self.currentAlpha : Self.dimmedAlpha
            self.highlightView.backgroundColor = row.isCurrent
                ? ILColors.goldBright.withAlphaComponent(Self.highlightAlpha)
                : .clear
        }
        if animated {
            UIView.animate(withDuration: 0.3, animations: applyHighlight)
        } else {
            applyHighlight()
        }
    }
}

/// Section heading ("KHAI KINH", "KỆ 2") — small tracked caps, indented to align with the lines.
final class ILReaderHeadingCell: UITableViewCell {

    static let reuseIdentifier = "ILReaderHeadingCell"

    private let titleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            // Design: `margin:22px 0 8px 26px` (16pt cue column + 10pt gap = 26pt indent).
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 22),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 26),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, palette: ILReaderPalette) {
        titleLabel.attributedText = ILTypography.makeAttributedString(
            text: title,
            font: ILTypography.eyebrowSmall,
            color: palette.subtle,
            letterSpacingEm: 0.16
        )
    }
}
