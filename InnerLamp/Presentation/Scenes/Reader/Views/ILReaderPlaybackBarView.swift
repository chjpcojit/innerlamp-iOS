//
//  ILReaderPlaybackBarView.swift
//  InnerLamp
//

import UIKit

/// Thanh phát dính đáy màn Tụng kinh: nút play/pause, dòng "Đang phát · Thầy Minh Đạo", tiến
/// trình + thời lượng, và nút tốc độ "1.0×". Khớp `isReader` trong design handoff (thẻ nổi, bo góc
/// 22px). Chứa nội dung riêng của màn đọc kinh nên ở feature-scoped.
final class ILReaderPlaybackBarView: UIView {

    // MARK: - Properties
    var isPlaying: Bool = false {
        didSet { playPauseButton.isPlaying = isPlaying }
    }

    var nowPlayingText: String = "" {
        didSet { nowPlayingLabel.text = nowPlayingText }
    }

    var elapsedText: String = "" {
        didSet { timeLabel.text = elapsedText }
    }

    var progress: Double = 0 {
        didSet { progressBar.progress = progress }
    }

    var speedText: String = "" {
        didSet { speedButton.title = speedText }
    }

    var onPlayPauseTap: (() -> Void)?
    var onSpeedTap: (() -> Void)?

    // MARK: - UI Elements
    private let playPauseButton = ILPlayPauseButton(diameter: 46)
    private let nowPlayingLabel = UILabel()
    private let progressBar = ILLinearProgressBarView()
    private let timeLabel = UILabel()
    private let speedButton = ILReaderSpeedButton()

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
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardMedium
        layer.borderWidth = 1
        layer.borderColor = ILColors.ink.withAlphaComponent(0.10).cgColor
        ILMetrics.shadowFloatingBar.apply(to: layer)

        nowPlayingLabel.font = ILTypography.bodySmallMedium
        nowPlayingLabel.textColor = ILColors.ink
        nowPlayingLabel.numberOfLines = 1
        nowPlayingLabel.lineBreakMode = .byTruncatingTail

        timeLabel.font = ILTypography.caption
        timeLabel.textColor = ILColors.inkSubtle

        playPauseButton.onTap = { [weak self] in self?.onPlayPauseTap?() }
        speedButton.onTap = { [weak self] in self?.onSpeedTap?() }

        let middleStack = UIStackView(arrangedSubviews: [nowPlayingLabel, progressTimeRow])
        middleStack.axis = .vertical
        middleStack.spacing = 7
        middleStack.alignment = .fill

        let rootStack = UIStackView(arrangedSubviews: [playPauseButton, middleStack, speedButton])
        rootStack.axis = .horizontal
        rootStack.spacing = ILMetrics.spaceMedium
        rootStack.alignment = .center
        rootStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.topAnchor.constraint(equalTo: topAnchor, constant: ILMetrics.spaceMedium),
            rootStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.spaceStandard),
            rootStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.spaceStandard),
            rootStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -ILMetrics.spaceMedium)
        ])
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILReaderPlaybackBarView, _) in
            view.applyColorAppearanceChange()
        }
    }

    private lazy var progressTimeRow: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [progressBar, timeLabel])
        stack.axis = .horizontal
        stack.spacing = ILMetrics.spaceSmall
        stack.alignment = .center
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)
        return stack
    }()

    // `layer.borderColor`/`shadowColor` là CGColor tĩnh, không tự đảo theo trait — refresh thủ
    // công khi hệ thống đổi light/dark.
    private func applyColorAppearanceChange() {
        layer.borderColor = ILColors.ink.withAlphaComponent(0.10).cgColor
    }
}

// MARK: - Speed Pill Button

/// Nút pill tốc độ "1.0×" — nền vàng nhạt, chữ `link` (khớp nút tốc độ trong design handoff).
private final class ILReaderSpeedButton: UIControl {

    var title: String = "" {
        didSet { titleLabel.text = title }
    }

    var onTap: (() -> Void)?

    private let titleLabel = UILabel()

    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = ILColors.gold.withAlphaComponent(0.14)
        layer.cornerRadius = ILMetrics.radiusPill

        titleLabel.font = ILTypography.subheadMedium
        titleLabel.textColor = ILColors.link

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 7),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -7),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        ])

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    @objc private func handleTap() {
        onTap?()
    }
}
