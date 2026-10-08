//
//  ILReaderSettingsPanelView.swift
//  InnerLamp
//

import UIKit

/// "Cỡ chữ" (4 sizes) + "Màu nền" (3 themes) panel that drops under the Reader header when the
/// "Aa" button is tapped. Selection is owned by the ViewModel — this view only renders
/// `ILReaderStateModel` and reports taps.
final class ILReaderSettingsPanelView: UIView {

    // MARK: - Properties
    var onFontSizeSelect: ((Int) -> Void)?
    var onThemeSelect: ((Int) -> Void)?

    // MARK: - UI Elements
    private let fontSizeTitleLabel = UILabel()
    private let backgroundTitleLabel = UILabel()
    private let fontSizeRow = UIStackView()
    private let themeRow = UIStackView()
    private var fontSizeTiles: [ILReaderOptionTile] = []
    private var themeTiles: [ILReaderOptionTile] = []

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
        layer.cornerRadius = ILMetrics.radiusCardSmall
        layer.borderWidth = 1

        [fontSizeRow, themeRow].forEach {
            $0.axis = .horizontal
            $0.spacing = 6
            $0.distribution = .fillEqually
        }

        let stack = UIStackView(arrangedSubviews: [fontSizeTitleLabel, fontSizeRow, backgroundTitleLabel, themeRow])
        stack.axis = .vertical
        stack.spacing = 8
        stack.setCustomSpacing(12, after: fontSizeRow)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        let inset = ILMetrics.spaceMedium
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: inset),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset)
        ])
    }

    // MARK: - Render
    func configure(with state: ILReaderStateModel, palette: ILReaderPalette) {
        backgroundColor = palette.panel
        layer.borderColor = palette.line.cgColor

        [fontSizeTitleLabel, backgroundTitleLabel].forEach {
            $0.font = ILTypography.labelMedium
            $0.textColor = palette.subtle
        }
        fontSizeTitleLabel.text = state.fontSizeTitle
        backgroundTitleLabel.text = state.backgroundTitle

        rebuildFontSizeTilesIfNeeded(count: ILTypography.readerLineFonts.count)
        for (index, tile) in fontSizeTiles.enumerated() {
            tile.configure(
                title: state.fontSizeOptionTitle,
                font: ILTypography.readerOptionSize,
                ink: palette.ink,
                background: index == state.fontSizeIndex ? ILColors.goldBright.withAlphaComponent(0.16) : .clear,
                border: index == state.fontSizeIndex ? ILColors.gold : palette.line,
                borderWidth: 1
            )
        }

        rebuildThemeTilesIfNeeded(count: state.themeTitles.count)
        for (index, tile) in themeTiles.enumerated() {
            let swatch = ILReaderPalette.swatch(forThemeIndex: index)
            tile.configure(
                title: state.themeTitles[index],
                font: ILTypography.subheadMedium,
                ink: swatch.ink,
                background: swatch.background,
                border: index == state.themeIndex ? ILColors.goldBright : swatch.line,
                borderWidth: 1.5
            )
        }
    }

    private func rebuildFontSizeTilesIfNeeded(count: Int) {
        guard fontSizeTiles.count != count else { return }
        fontSizeRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        fontSizeTiles = (0..<count).map { index in
            let tile = ILReaderOptionTile(height: 34)
            tile.onTap = { [weak self] in self?.onFontSizeSelect?(index) }
            fontSizeRow.addArrangedSubview(tile)
            return tile
        }
    }

    private func rebuildThemeTilesIfNeeded(count: Int) {
        guard themeTiles.count != count else { return }
        themeRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        themeTiles = (0..<count).map { index in
            let tile = ILReaderOptionTile(height: 40)
            tile.pinsToSystemAppearance = true
            tile.onTap = { [weak self] in self?.onThemeSelect?(index) }
            themeRow.addArrangedSubview(tile)
            return tile
        }
    }
}

// MARK: - Option Tile

/// Rounded selectable tile (font-size "A" or background swatch).
private final class ILReaderOptionTile: UIControl {

    var onTap: (() -> Void)?

    /// Swatch tiles show a theme's own colors, so they must resolve adaptive tokens against the
    /// system appearance rather than the Reader's forced one.
    var pinsToSystemAppearance = false

    private let titleLabel = UILabel()

    init(height: CGFloat) {
        super.init(frame: .zero)
        layer.cornerRadius = ILMetrics.radiusOptionTile
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: height),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4)
        ])
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if pinsToSystemAppearance {
            overrideUserInterfaceStyle = window?.windowScene?.traitCollection.userInterfaceStyle ?? .unspecified
        }
    }

    func configure(
        title: String, font: UIFont, ink: UIColor, background: UIColor, border: UIColor, borderWidth: CGFloat
    ) {
        titleLabel.text = title
        titleLabel.font = font
        titleLabel.textColor = ink
        backgroundColor = background
        layer.borderColor = border.cgColor
        layer.borderWidth = borderWidth
    }

    @objc private func handleTap() {
        onTap?()
    }
}
