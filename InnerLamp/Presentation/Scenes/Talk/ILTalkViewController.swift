//
//  ILTalkViewController.swift
//  InnerLamp
//
//  Created by ChjpCoj on 27/9/26.
//

import UIKit
import Combine

final class ILTalkViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: ILTalkViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let playPauseTappedSubject = PassthroughSubject<Void, Never>()
    private let rewindTappedSubject = PassthroughSubject<Void, Never>()
    private let forwardTappedSubject = PassthroughSubject<Void, Never>()
    private let meditateTappedSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    /// Glass band behind the nav bar: see-through over the hero, blurs once the content scrolls under it.
    private let headerBand = ILStickyHeaderBand(tintRestAlpha: 0)
    private let navBar = ILNavBar(showBack: true)

    private let heroView = ILTalkHeroView()

    private let playerCard = ILTalkPlayerCardView()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private lazy var sectionsTitleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.bodyMedium
        label.textColor = ILColors.ink
        return label
    }()

    private let chapterListView = ILTalkChapterListView()
    private let chaptersEmptyView = ILTalkChaptersEmptyView()

    /// Holds the chapter list or the empty block — the hidden one collapses, so the meditate
    /// card always anchors to a single view.
    private lazy var sectionsStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [chapterListView, chaptersEmptyView])
        stack.axis = .vertical
        return stack
    }()

    private let meditateCard = ILTalkMeditateCardView()

    // MARK: - Initializer
    init(viewModel: ILTalkViewModel) {
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

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        heroView.topInset = view.safeAreaInsets.top
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.canvas

        navBar.onBack = { [weak self] in self?.backTappedSubject.send(()) }

        playerCard.onPlayPause = { [weak self] in self?.playPauseTappedSubject.send(()) }
        playerCard.onRewind = { [weak self] in self?.rewindTappedSubject.send(()) }
        playerCard.onForward = { [weak self] in self?.forwardTappedSubject.send(()) }

        meditateCard.onTap = { [weak self] in self?.meditateTappedSubject.send(()) }

        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.contentInsetAdjustmentBehavior = .never
        headerBand.bind(to: scrollView)
        headerBand.addSubview(navBar)

        scrollView.addSubview(contentView)

        [
            heroView, playerCard, descriptionLabel, sectionsTitleLabel, sectionsStack, meditateCard
        ].forEach { contentView.addSubview($0) }

        view.addSubview(scrollView)
        view.addSubview(headerBand)
    }

    override func setupConstraints() {
        super.setupConstraints()
        [
            scrollView, contentView, headerBand, navBar, heroView, playerCard, descriptionLabel,
            sectionsTitleLabel, sectionsStack, meditateCard
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let horizontal = ILMetrics.screenHorizontal

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Header ‹ đè lên hero, dán cố định khi cuộn (xem `ILStickyHeaderBand`).
            headerBand.topAnchor.constraint(equalTo: view.topAnchor),
            headerBand.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBand.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall / 2),
            navBar.leadingAnchor.constraint(equalTo: headerBand.leadingAnchor, constant: horizontal),
            navBar.trailingAnchor.constraint(equalTo: headerBand.trailingAnchor, constant: -horizontal),
            navBar.bottomAnchor.constraint(equalTo: headerBand.bottomAnchor, constant: -ILMetrics.rowSpacing),

            // Hero full-bleed nằm trên cùng nội dung cuộn.
            heroView.topAnchor.constraint(equalTo: contentView.topAnchor),
            heroView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            heroView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            playerCard.topAnchor.constraint(equalTo: heroView.bottomAnchor, constant: horizontal),
            playerCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontal),
            playerCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontal),

            descriptionLabel.topAnchor.constraint(equalTo: playerCard.bottomAnchor, constant: ILMetrics.groupSpacing),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontal),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontal),

            sectionsTitleLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 22),
            sectionsTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontal),
            sectionsTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontal),

            sectionsStack.topAnchor.constraint(equalTo: sectionsTitleLabel.bottomAnchor, constant: 12),
            sectionsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontal),
            sectionsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontal),

            meditateCard.topAnchor.constraint(equalTo: sectionsStack.bottomAnchor, constant: 18),
            meditateCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontal),
            meditateCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontal),
            meditateCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -ILMetrics.spaceLarge)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILTalkViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            playPauseTapped: playPauseTappedSubject.eraseToAnyPublisher(),
            rewindTapped: rewindTappedSubject.eraseToAnyPublisher(),
            forwardTapped: forwardTappedSubject.eraseToAnyPublisher(),
            meditateTapped: meditateTappedSubject.eraseToAnyPublisher()
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
    private func render(state: ViewState<ILTalkStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILTalkStateModel) {
        navBar.title = model.headerTitle
        heroView.configure(
            eyebrow: model.eyebrow,
            title: model.title,
            initial: model.narratorInitial,
            metaText: model.metaText
        )

        playerCard.elapsedText = model.elapsedText
        playerCard.remainingText = model.remainingText
        playerCard.progress = model.playbackProgress
        playerCard.isPlaying = model.isPlaying
        playerCard.rewindTitle = model.rewindTitle
        playerCard.forwardTitle = model.forwardTitle

        descriptionLabel.attributedText = ILTypography.makeParagraph(
            text: model.descriptionText,
            font: ILTypography.scriptureDescription,
            color: ILColors.inkSecondary,
            cssLineHeight: 1.75
        )

        sectionsTitleLabel.text = model.sectionsTitle
        chapterListView.chapters = model.chapters
        chapterListView.isHidden = model.chapters.isEmpty
        chaptersEmptyView.isHidden = !model.chapters.isEmpty
        chaptersEmptyView.title = model.sectionsEmptyTitle
        chaptersEmptyView.subtitle = model.sectionsEmptySubtitle

        meditateCard.title = model.meditateTitle
        meditateCard.subtitle = model.meditateSubtitle
    }
}
