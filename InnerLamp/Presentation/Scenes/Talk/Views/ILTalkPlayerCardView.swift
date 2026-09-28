//
//  ILTalkPlayerCardView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 27/9/26.
//

import UIKit

/// Thẻ trình phát gọn của màn Pháp thoại (khác trình phát toàn màn `player`): thanh tiến trình,
/// dòng thời gian "12:48 / -33:12", tua 15s/30s và nút play/pause 58pt. Nhận toàn bộ state dạng
/// chuỗi đã format từ `ILTalkViewModel` nên không biết gì về business logic.
final class ILTalkPlayerCardView: UIView {

    // MARK: - Properties
    var elapsedText: String = "" { didSet { elapsedLabel.text = elapsedText } }
    var remainingText: String = "" { didSet { remainingLabel.text = remainingText } }
    var progress: Double = 0 { didSet { progressBar.progress = progress } }
    var isPlaying: Bool = false { didSet { playPauseButton.isPlaying = isPlaying } }
    var rewindTitle: String = "" { didSet { rewindButton.setTitle(rewindTitle, for: .normal) } }
    var forwardTitle: String = "" { didSet { forwardButton.setTitle(forwardTitle, for: .normal) } }

    var onPlayPause: (() -> Void)?
    var onRewind: (() -> Void)?
    var onForward: (() -> Void)?

    // MARK: - UI Elements
    private let progressBar = ILLinearProgressBarView()

    private lazy var elapsedLabel: UILabel = makeTimeLabel()
    private lazy var remainingLabel: UILabel = makeTimeLabel()

    private lazy var timeRow: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [elapsedLabel, remainingLabel])
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        return stack
    }()

    private lazy var rewindButton: UIButton = makeSeekButton()
    private lazy var forwardButton: UIButton = makeSeekButton()
    private let playPauseButton = ILPlayPauseButton(diameter: 58)

    private lazy var controlsRow: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [rewindButton, playPauseButton, forwardButton])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 22
        return stack
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [progressBar, timeRow, controlsRow])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = ILMetrics.spaceSmall
        stack.setCustomSpacing(ILMetrics.spaceMedium, after: timeRow)
        return stack
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
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
        layer.borderColor = ILColors.borderMedium.cgColor
        ILMetrics.shadowFloatingBar.apply(to: layer)

        controlsRow.isUserInteractionEnabled = true

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18)
        ])

        rewindButton.addTarget(self, action: #selector(handleRewind), for: .touchUpInside)
        forwardButton.addTarget(self, action: #selector(handleForward), for: .touchUpInside)
        playPauseButton.onTap = { [weak self] in self?.onPlayPause?() }

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILTalkPlayerCardView, _) in
            view.applyColorAppearanceChange()
        }
    }

    private func makeTimeLabel() -> UILabel {
        let label = UILabel()
        label.font = ILTypography.caption
        label.textColor = ILColors.inkSubtle
        return label
    }

    private func makeSeekButton() -> UIButton {
        let button = UIButton(type: .system)
        button.titleLabel?.font = ILTypography.chip
        button.setTitleColor(ILColors.inkTertiary, for: .normal)
        return button
    }

    private func applyColorAppearanceChange() {
        layer.borderColor = ILColors.borderMedium.cgColor
    }

    @objc private func handleRewind() {
        onRewind?()
    }

    @objc private func handleForward() {
        onForward?()
    }
}
