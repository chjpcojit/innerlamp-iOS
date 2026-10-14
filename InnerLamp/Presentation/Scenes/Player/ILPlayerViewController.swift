//
//  ILPlayerViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILPlayerViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: ILPlayerViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let tableOfContentsTappedSubject = PassthroughSubject<Void, Never>()
    private let playPauseTappedSubject = PassthroughSubject<Void, Never>()
    private let rewindTappedSubject = PassthroughSubject<Void, Never>()
    private let forwardTappedSubject = PassthroughSubject<Void, Never>()
    private let speedSelectedSubject = PassthroughSubject<Int, Never>()
    private let sleepSelectedSubject = PassthroughSubject<Int, Never>()

    // MARK: - UI Elements
    private lazy var backgroundView = ILImmersiveBackgroundView(style: .player)

    private lazy var headerView = ILNavBar()

    private let centerGuide = UILayoutGuide()

    private lazy var artworkView = ILPlayerArtworkView()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.playerTitle
        label.textColor = ILColors.templeHeaderInk
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.bodySmall
        label.textColor = ILColors.playerSubtitle
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var centerStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [artworkView, titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = ILMetrics.spaceSmall
        stack.setCustomSpacing(32, after: artworkView)
        return stack
    }()

    private lazy var progressBar = ILLinearProgressBarView()

    private lazy var elapsedLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.caption
        label.textColor = ILColors.playerSubtitle
        return label
    }()

    private lazy var remainingLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.caption
        label.textColor = ILColors.playerSubtitle
        return label
    }()

    private lazy var timeRow: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [elapsedLabel, remainingLabel])
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        return stack
    }()

    private lazy var rewindButton = makeSeekButton()
    private lazy var forwardButton = makeSeekButton()
    private lazy var playPauseButton = ILPlayPauseButton(diameter: 72, glyphColor: ILColors.canvas)

    private lazy var controlsContainer = UIView()

    private lazy var controlsRow: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [rewindButton, playPauseButton, forwardButton])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 26
        return stack
    }()

    private lazy var speedSectionLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.playerSubtitle
        return label
    }()

    private lazy var speedRow = ILPlayerOptionRowView()

    private lazy var sleepSectionLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.playerSubtitle
        return label
    }()

    private lazy var sleepRow = ILPlayerOptionRowView()

    private lazy var sleepNoteLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.label
        label.textColor = ILColors.playerSubtitle
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var bottomStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            progressBar, timeRow, controlsContainer,
            speedSectionLabel, speedRow,
            sleepSectionLabel, sleepRow, sleepNoteLabel
        ])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = ILMetrics.rowSpacing
        stack.setCustomSpacing(22, after: timeRow)
        stack.setCustomSpacing(24, after: controlsContainer)
        stack.setCustomSpacing(18, after: speedRow)
        return stack
    }()

    // MARK: - Initializer
    init(viewModel: ILPlayerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        (tabBarController as? ILMainTabBarController)?.setBottomNavHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        (tabBarController as? ILMainTabBarController)?.setBottomNavHidden(false, animated: animated)
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.playerBackgroundEdge

        view.addSubview(backgroundView)

        headerView.onBack = { [weak self] in self?.backTappedSubject.send(()) }
        headerView.onAction = { [weak self] in self?.tableOfContentsTappedSubject.send(()) }
        view.addSubview(headerView)

        view.addSubview(centerStack)

        rewindButton.addTarget(self, action: #selector(handleRewindTap), for: .touchUpInside)
        forwardButton.addTarget(self, action: #selector(handleForwardTap), for: .touchUpInside)
        playPauseButton.onTap = { [weak self] in self?.playPauseTappedSubject.send(()) }
        controlsContainer.addSubview(controlsRow)

        speedRow.onSelect = { [weak self] index in self?.speedSelectedSubject.send(index) }
        sleepRow.onSelect = { [weak self] index in self?.sleepSelectedSubject.send(index) }

        view.addSubview(bottomStack)
    }

    override func setupConstraints() {
        super.setupConstraints()
        [
            backgroundView, headerView, centerStack, bottomStack, controlsRow
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let horizontal = ILMetrics.screenHorizontal

        // The space left between the header and the controls — the artwork + title are centered in it.
        view.addLayoutGuide(centerGuide)

        NSLayoutConstraint.activate([
            centerGuide.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            centerGuide.bottomAnchor.constraint(equalTo: bottomStack.topAnchor),

            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall / 2),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontal),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontal),

            centerStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerStack.centerYAnchor.constraint(equalTo: centerGuide.centerYAnchor),
            centerStack.topAnchor.constraint(greaterThanOrEqualTo: centerGuide.topAnchor),
            centerStack.bottomAnchor.constraint(lessThanOrEqualTo: centerGuide.bottomAnchor),
            centerStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: horizontal),
            centerStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -horizontal),

            // Seek + play/pause row centered within its full-width slot in the bottom stack.
            controlsRow.centerXAnchor.constraint(equalTo: controlsContainer.centerXAnchor),
            controlsRow.topAnchor.constraint(equalTo: controlsContainer.topAnchor),
            controlsRow.bottomAnchor.constraint(equalTo: controlsContainer.bottomAnchor),

            bottomStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontal),
            bottomStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontal),
            bottomStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -ILMetrics.spaceLarge)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILPlayerViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            tableOfContentsTapped: tableOfContentsTappedSubject.eraseToAnyPublisher(),
            playPauseTapped: playPauseTappedSubject.eraseToAnyPublisher(),
            rewindTapped: rewindTappedSubject.eraseToAnyPublisher(),
            forwardTapped: forwardTappedSubject.eraseToAnyPublisher(),
            speedSelected: speedSelectedSubject.eraseToAnyPublisher(),
            sleepSelected: sleepSelectedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        // No `.receive(on: DispatchQueue.main)`: state is already sent on main (MainActor default),
        // and deferring it renders the first state only after the appear transition has run.
        output.state
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
    }

    // MARK: - Render
    private func render(state: ViewState<ILPlayerStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILPlayerStateModel) {
        headerView.title = model.headerTitle
        headerView.rightActionTitle = model.tableOfContentsActionTitle

        titleLabel.text = model.trackTitle
        subtitleLabel.text = model.trackSubtitle

        elapsedLabel.text = model.elapsedText
        remainingLabel.text = model.remainingText
        progressBar.progress = model.playbackProgress
        playPauseButton.isPlaying = model.isPlaying

        rewindButton.setTitle(model.rewindTitle, for: .normal)
        forwardButton.setTitle(model.forwardTitle, for: .normal)

        speedSectionLabel.text = model.speedSectionTitle
        speedRow.options = model.speedOptions
        speedRow.selectedIndex = model.selectedSpeedIndex

        sleepSectionLabel.text = model.sleepSectionTitle
        sleepRow.options = model.sleepOptions
        sleepRow.selectedIndex = model.selectedSleepIndex

        sleepNoteLabel.text = model.sleepNote
    }

    // MARK: - Helpers
    private func makeSeekButton() -> UIButton {
        let button = UIButton(type: .system)
        button.titleLabel?.font = ILTypography.chip
        button.setTitleColor(ILColors.playerSubtitle, for: .normal)
        return button
    }

    @objc private func handleRewindTap() {
        rewindTappedSubject.send(())
    }

    @objc private func handleForwardTap() {
        forwardTappedSubject.send(())
    }
}
