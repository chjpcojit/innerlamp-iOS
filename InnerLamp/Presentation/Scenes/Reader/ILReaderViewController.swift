//
//  ILReaderViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILReaderViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: ILReaderViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let fontSizeTappedSubject = PassthroughSubject<Void, Never>()
    private let shareTappedSubject = PassthroughSubject<Void, Never>()
    private let downloadTappedSubject = PassthroughSubject<Void, Never>()
    private let playPauseTappedSubject = PassthroughSubject<Void, Never>()
    private let speedTappedSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    private let headerContainer = UIView()

    private lazy var headerView = ILNavBar(showBack: true)

    private lazy var headerDivider: UIView = {
        let divider = UIView()
        divider.backgroundColor = ILColors.border
        return divider
    }()

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let readingProgressBar = ILLinearProgressBarView()

    private let verseView = ILReaderVerseView()

    private lazy var shareChip = ILChip(label: "")
    private lazy var downloadChip = ILChip(label: "")

    private lazy var chipsStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [shareChip, downloadChip])
        stack.axis = .horizontal
        stack.spacing = ILMetrics.spaceSmall
        stack.alignment = .leading
        return stack
    }()

    private lazy var nextVerseLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private let playbackBar = ILReaderPlaybackBarView()

    // MARK: - Initializer
    init(viewModel: ILReaderViewModel) {
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
        view.backgroundColor = ILColors.canvasWarm

        headerView.onBack = { [weak self] in self?.backTappedSubject.send(()) }
        headerView.onAction = { [weak self] in self?.fontSizeTappedSubject.send(()) }

        headerContainer.addSubview(headerView)
        headerContainer.addSubview(headerDivider)

        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true

        shareChip.onTap = { [weak self] in self?.shareTappedSubject.send(()) }
        downloadChip.onTap = { [weak self] in self?.downloadTappedSubject.send(()) }

        playbackBar.onPlayPauseTap = { [weak self] in self?.playPauseTappedSubject.send(()) }
        playbackBar.onSpeedTap = { [weak self] in self?.speedTappedSubject.send(()) }

        scrollView.addSubview(contentView)

        [
            readingProgressBar, verseView, chipsStack, nextVerseLabel
        ].forEach { contentView.addSubview($0) }

        view.addSubview(headerContainer)
        view.addSubview(scrollView)
        view.addSubview(playbackBar)
    }

    override func setupConstraints() {
        super.setupConstraints()
        [
            headerContainer, headerView, headerDivider, scrollView, contentView,
            readingProgressBar, verseView, chipsStack, nextVerseLabel, playbackBar
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let horizontal = ILMetrics.screenHorizontal

        NSLayoutConstraint.activate([
            headerContainer.topAnchor.constraint(equalTo: view.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall / 2),
            headerView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: horizontal),
            headerView.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -horizontal),

            headerDivider.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: ILMetrics.rowSpacing),
            headerDivider.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            headerDivider.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            headerDivider.heightAnchor.constraint(equalToConstant: 1),
            headerDivider.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: playbackBar.topAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: horizontal),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -horizontal),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -horizontal * 2),

            readingProgressBar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: ILMetrics.spaceStandard),
            readingProgressBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            readingProgressBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            verseView.topAnchor.constraint(equalTo: readingProgressBar.bottomAnchor, constant: ILMetrics.spaceLarge),
            verseView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            verseView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            chipsStack.topAnchor.constraint(equalTo: verseView.bottomAnchor, constant: ILMetrics.spaceStandard),
            chipsStack.leadingAnchor.constraint(equalTo: verseView.leadingAnchor),
            chipsStack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),

            nextVerseLabel.topAnchor.constraint(equalTo: chipsStack.bottomAnchor, constant: 26),
            nextVerseLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nextVerseLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            nextVerseLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -ILMetrics.spaceLarge),

            playbackBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontal),
            playbackBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontal),
            playbackBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -ILMetrics.spaceMedium)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILReaderViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            fontSizeTapped: fontSizeTappedSubject.eraseToAnyPublisher(),
            shareTapped: shareTappedSubject.eraseToAnyPublisher(),
            downloadTapped: downloadTappedSubject.eraseToAnyPublisher(),
            playPauseTapped: playPauseTappedSubject.eraseToAnyPublisher(),
            speedTapped: speedTappedSubject.eraseToAnyPublisher()
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
    private func render(state: ViewState<ILReaderStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILReaderStateModel) {
        headerView.title = model.title
        headerView.subtitle = model.subtitle
        headerView.rightActionTitle = model.fontSizeActionTitle

        readingProgressBar.progress = model.readingProgress

        verseView.verseText = model.verseText
        verseView.translationText = model.translationText

        shareChip.label = model.shareChipTitle
        downloadChip.label = model.downloadChipTitle

        nextVerseLabel.attributedText = model.nextVerseText.isEmpty
            ? nil
            : ILTypography.makeParagraph(
                text: model.nextVerseText,
                font: ILTypography.scriptureBodyLarge,
                color: ILColors.inkSubtle,
                cssLineHeight: 1.6
            )

        playbackBar.nowPlayingText = model.nowPlayingText
        playbackBar.elapsedText = model.elapsedText
        playbackBar.progress = model.playbackProgress
        playbackBar.speedText = model.speedText
        playbackBar.isPlaying = model.isPlaying
    }
}
