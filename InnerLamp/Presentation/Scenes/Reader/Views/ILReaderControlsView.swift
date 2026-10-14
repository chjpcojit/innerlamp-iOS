//
//  ILReaderControlsView.swift
//  InnerLamp
//

import UIKit

/// Bottom block of the Reader screen: position/progress/duration (only when the sutra has audio),
/// the −10s / play-pause / +10s row, and the speed chips. Matches the footer of `isReader`.
final class ILReaderControlsView: UIView {

    // MARK: - Properties
    var onPlayPauseTap: (() -> Void)?
    var onSeekBackTap: (() -> Void)?
    var onSeekForwardTap: (() -> Void)?
    var onSpeedSelect: ((Double) -> Void)?

    private static let playButtonDiameter: CGFloat = 58
    private static let seekButtonDiameter: CGFloat = 44

    // MARK: - UI Elements
    private lazy var topBorder: UIView = {
        let v = UIView()
        return v
    }()
    private lazy var positionLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.caption
        return v
    }()
    private lazy var durationLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.caption
        return v
    }()
    private lazy var trackView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 1.5
        return v
    }()
    private lazy var fillView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 1.5
        v.backgroundColor = ILColors.gold
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private var fillWidthConstraint: NSLayoutConstraint?
    private lazy var progressRow: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [positionLabel, trackView, durationLabel])
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        return stack
    }()
    private lazy var seekBackButton: ILReaderRoundButton = {
        let v = ILReaderRoundButton(diameter: ILReaderControlsView.seekButtonDiameter)
        return v
    }()
    private lazy var seekForwardButton: ILReaderRoundButton = {
        let v = ILReaderRoundButton(diameter: ILReaderControlsView.seekButtonDiameter)
        return v
    }()
    private lazy var playPauseButton: ILPlayPauseButton = {
        let v = ILPlayPauseButton(
            diameter: ILReaderControlsView.playButtonDiameter,
            glyphColor: ILColors.inkOnGold,
            fillColor: ILColors.goldBright,
            glyphScale: 1.1,
            playGlyphSize: CGSize(width: 15, height: 18),
            playGlyphOffsetX: 2
        )
        return v
    }()
    private lazy var speedLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.label
        return v
    }()
    private lazy var speedRow: UIStackView = {
        let v = UIStackView()
        v.axis = .horizontal
        v.spacing = 6
        v.alignment = .center
        return v
    }()
    private var speedChips: [ILReaderSpeedChip] = []

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
        trackView.addSubview(fillView)

        seekBackButton.onTap = { [weak self] in self?.onSeekBackTap?() }
        seekForwardButton.onTap = { [weak self] in self?.onSeekForwardTap?() }
        playPauseButton.onTap = { [weak self] in self?.onPlayPauseTap?() }

        let transportRow = UIStackView(arrangedSubviews: [seekBackButton, playPauseButton, seekForwardButton])
        transportRow.axis = .horizontal
        transportRow.spacing = 22
        transportRow.alignment = .center

        speedRow.addArrangedSubview(speedLabel)
        speedRow.setCustomSpacing(10, after: speedLabel)

        let transportContainer = UIStackView(arrangedSubviews: [transportRow])
        transportContainer.alignment = .center
        transportContainer.axis = .vertical
        let speedContainer = UIStackView(arrangedSubviews: [speedRow])
        speedContainer.alignment = .center
        speedContainer.axis = .vertical

        let stack = UIStackView(arrangedSubviews: [progressRow, transportContainer, speedContainer])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill

        [topBorder, stack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        let widthConstraint = fillView.widthAnchor.constraint(equalTo: trackView.widthAnchor, multiplier: 0.001)
        fillWidthConstraint = widthConstraint
        NSLayoutConstraint.activate([
            topBorder.topAnchor.constraint(equalTo: topAnchor),
            topBorder.leadingAnchor.constraint(equalTo: leadingAnchor),
            topBorder.trailingAnchor.constraint(equalTo: trailingAnchor),
            topBorder.heightAnchor.constraint(equalToConstant: 1),

            trackView.heightAnchor.constraint(equalToConstant: 3),
            fillView.topAnchor.constraint(equalTo: trackView.topAnchor),
            fillView.bottomAnchor.constraint(equalTo: trackView.bottomAnchor),
            fillView.leadingAnchor.constraint(equalTo: trackView.leadingAnchor),
            widthConstraint,

            stack.topAnchor.constraint(equalTo: topAnchor, constant: ILMetrics.spaceMedium - 2),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.screenHorizontal),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.screenHorizontal),
            stack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -ILMetrics.spaceSmall)
        ])
    }

    // MARK: - Render
    func configure(with state: ILReaderStateModel, palette: ILReaderPalette) {
        backgroundColor = palette.background
        topBorder.backgroundColor = palette.line

        progressRow.isHidden = !state.hasAudio
        positionLabel.text = state.positionText
        durationLabel.text = state.durationText
        positionLabel.textColor = palette.subtle
        durationLabel.textColor = palette.subtle
        trackView.backgroundColor = palette.line
        updateFill(progress: state.progress)

        playPauseButton.isPlaying = state.isPlaying
        seekBackButton.configure(title: state.seekBackTitle, ink: palette.ink, border: palette.line)
        seekForwardButton.configure(title: state.seekForwardTitle, ink: palette.ink, border: palette.line)

        speedLabel.text = state.speedLabel
        speedLabel.textColor = palette.subtle
        rebuildSpeedChipsIfNeeded(count: state.speedOptions.count)
        for (chip, option) in zip(speedChips, state.speedOptions) {
            chip.configure(option: option, palette: palette)
            chip.onTap = { [weak self] in self?.onSpeedSelect?(option.speed) }
        }
    }

    private func updateFill(progress: Double) {
        guard let current = fillWidthConstraint else { return }
        // Multiplier is immutable, so swap the constraint; clamp away from 0 (invalid multiplier).
        let clamped = max(0.001, min(1, progress))
        current.isActive = false
        let replacement = fillView.widthAnchor.constraint(equalTo: trackView.widthAnchor, multiplier: clamped)
        replacement.isActive = true
        fillWidthConstraint = replacement
    }

    private func rebuildSpeedChipsIfNeeded(count: Int) {
        guard speedChips.count != count else { return }
        speedChips.forEach { $0.removeFromSuperview() }
        speedChips = (0..<count).map { _ in
            let chip = ILReaderSpeedChip()
            speedRow.addArrangedSubview(chip)
            return chip
        }
    }
}

// MARK: - Round seek button

/// 44pt outlined round button holding "−10s" / "+10s".
private final class ILReaderRoundButton: UIControl {

    var onTap: (() -> Void)?
    private lazy var titleLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.labelMedium
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    init(diameter: CGFloat) {
        super.init(frame: .zero)
        layer.cornerRadius = diameter / 2
        layer.borderWidth = 1
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: diameter),
            heightAnchor.constraint(equalToConstant: diameter),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, ink: UIColor, border: UIColor) {
        titleLabel.text = title
        titleLabel.textColor = ink
        layer.borderColor = border.cgColor
    }

    @objc private func handleTap() {
        onTap?()
    }
}

// MARK: - Speed chip

/// Pill chip ("1x" / "1.2x" / "1.5x"); the selected one is filled gold with dark text.
private final class ILReaderSpeedChip: UIControl {

    var onTap: (() -> Void)?
    private lazy var titleLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.labelMedium
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    init() {
        super.init(frame: .zero)
        layer.cornerRadius = 15
        layer.borderWidth = 1
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 11),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -11)
        ])
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(option: ILReaderSpeedOptionState, palette: ILReaderPalette) {
        titleLabel.text = option.title
        titleLabel.textColor = option.isSelected ? ILColors.inkOnGold : palette.ink
        backgroundColor = option.isSelected ? ILColors.goldBright : .clear
        layer.borderColor = (option.isSelected ? ILColors.gold : palette.line).cgColor
    }

    @objc private func handleTap() {
        onTap?()
    }
}
