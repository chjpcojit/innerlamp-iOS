//
//  ILMeritBookViewController.swift
//  InnerLamp
//

import UIKit
import Combine

/// "Sổ công đức" (prototype screen `merit`): sticky `ILNavBar` header (title + "Cúng dường" pill)
/// over a scrolling stack — stats, offering history, temple letter, monthly support and the
/// temple's financial disclosure.
final class ILMeritBookViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: ILMeritBookViewModel
    private var cancellables = Set<AnyCancellable>()

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let donateTappedSubject = PassthroughSubject<Void, Never>()
    private let stopMonthlyTappedSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    private lazy var headerBand = ILStickyHeaderBand()
    private lazy var navBar = ILNavBar(
        title: "meritBook.header.title".localized,
        subtitle: "meritBook.header.subtitle".localized,
        rightActionTitle: "meritBook.header.donate".localized,
        showBack: true
    )

    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.contentInsetAdjustmentBehavior = .never
        return scroll
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        return stack
    }()

    private lazy var statsCard = ILMeritStatsCardView()
    private lazy var historyTitle = ILMeritBookViewController.makeSectionTitle("meritBook.section.history".localized)
    private lazy var historyCard = ILMeritHistoryCardView()
    private lazy var letterTitle = ILMeritBookViewController.makeSectionTitle("meritBook.section.letter".localized)
    private lazy var letterCard = ILMeritLetterCardView()
    private lazy var monthlyTitle = ILMeritBookViewController.makeSectionTitle("meritBook.section.monthly".localized)
    private lazy var monthlyCard = ILMeritMonthlyCardView()
    private lazy var buildTitle = ILMeritBookViewController.makeSectionTitle("meritBook.section.build".localized)
    private lazy var buildCard = ILMeritBuildCardView()

    private lazy var errorStateView: ILStateView = {
        let view = ILStateView(
            kind: .error,
            title: "meritBook.error.title".localized,
            message: "meritBook.error.message".localized
        )
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    // MARK: - Initializer
    init(viewModel: ILMeritBookViewModel) {
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
        // Child screens hide the tab's bottom bar (design handoff).
        (tabBarController as? ILMainTabBarController)?.setBottomNavHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        (tabBarController as? ILMainTabBarController)?.setBottomNavHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyHeaderInset()
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.canvas
        headerBand.bind(to: scrollView)

        navBar.onBack = { [weak self] in self?.backTappedSubject.send(()) }
        navBar.onAction = { [weak self] in self?.donateTappedSubject.send(()) }
        monthlyCard.onStop = { [weak self] in self?.stopMonthlyTappedSubject.send(()) }

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        let blocks: [UIView] = [
            statsCard, historyTitle, historyCard, letterTitle, letterCard,
            monthlyTitle, monthlyCard, buildTitle, buildCard
        ]
        blocks.forEach { contentStack.addArrangedSubview($0) }
        contentStack.setCustomSpacing(ILMetrics.groupSpacing + 4, after: statsCard)
        [historyTitle, letterTitle, monthlyTitle, buildTitle].forEach {
            contentStack.setCustomSpacing(ILMetrics.spaceMedium - 2, after: $0)
        }
        [historyCard, letterCard, monthlyCard].forEach {
            contentStack.setCustomSpacing(ILMetrics.groupSpacing + 4, after: $0)
        }

        view.addSubview(errorStateView)

        // Header band goes last so it floats above the scrolling content.
        view.addSubview(headerBand)
        navBar.translatesAutoresizingMaskIntoConstraints = false
        headerBand.addSubview(navBar)
    }

    override func setupConstraints() {
        super.setupConstraints()

        NSLayoutConstraint.activate([
            headerBand.topAnchor.constraint(equalTo: view.topAnchor),
            headerBand.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBand.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall / 2),
            navBar.leadingAnchor.constraint(equalTo: headerBand.leadingAnchor, constant: ILMetrics.screenHorizontal),
            navBar.trailingAnchor.constraint(equalTo: headerBand.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            navBar.bottomAnchor.constraint(equalTo: headerBand.bottomAnchor, constant: -ILMetrics.rowSpacing),

            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: ILMetrics.spaceMedium + 4),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: ILMetrics.screenHorizontal),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -ILMetrics.spaceLarge - 6),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -ILMetrics.screenHorizontal * 2),

            errorStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorStateView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: ILMetrics.screenHorizontal),
            errorStateView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -ILMetrics.screenHorizontal)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILMeritBookViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            donateTapped: donateTappedSubject.eraseToAnyPublisher(),
            stopMonthlyTapped: stopMonthlyTappedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        // No `.receive(on:)`: state is already emitted on main (MainActor default isolation).
        output.state
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
    }

    // MARK: - Render
    private func render(state: ViewState<ILMeritBookStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            errorStateView.isHidden = true
            scrollView.isHidden = false
            updateUI(with: model)
        case .failure:
            scrollView.isHidden = true
            errorStateView.isHidden = false
        }
    }

    private func updateUI(with model: ILMeritBookStateModel) {
        statsCard.configure(stats: model.stats)
        historyCard.configure(rows: model.history)

        let hasLetter = model.letter != nil
        letterTitle.isHidden = !hasLetter
        letterCard.isHidden = !hasLetter
        if let letter = model.letter {
            letterCard.configure(letter: letter)
        }

        monthlyCard.configure(monthly: model.monthly)

        let hasProject = model.buildProject != nil
        buildTitle.isHidden = !hasProject
        buildCard.isHidden = !hasProject
        if let project = model.buildProject {
            buildCard.configure(project: project)
        }
    }

    // MARK: - Helpers
    private static func makeSectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.font = ILTypography.sectionTitle
        label.textColor = ILColors.ink
        label.text = text
        label.accessibilityTraits = .header
        return label
    }

    /// Pushes the content below the sticky header; on the first layout the offset starts at the top
    /// of the content rather than under the header.
    private func applyHeaderInset() {
        let top = headerBand.bounds.height
        guard top > 0, scrollView.contentInset.top != top else { return }
        let wasAtTop = scrollView.contentOffset.y <= -scrollView.contentInset.top
        scrollView.contentInset.top = top
        scrollView.verticalScrollIndicatorInsets.top = top
        if wasAtTop { scrollView.contentOffset.y = -top }
    }
}
