//
//  ILHomeViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILHomeViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: ILHomeViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let beadTappedSubject = PassthroughSubject<Void, Never>()
    private let resetBeadsTappedSubject = PassthroughSubject<Void, Never>()
    private let malaFullscreenTappedSubject = PassthroughSubject<Void, Never>()
    private let lunarCalendarTappedSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let headerView = ILHomeGreetingHeaderView()
    private let weekCalendarView = ILHomeWeekCalendarView()
    private let lunarHeroCard = ILHomeLunarHeroCardView()

    private let eventsHeader = ILSectionHeaderView(title: "home.events.title".localized, trailingText: "home.events.viewAll".localized)
    private let eventsCarousel = ILHomeEventsCarouselView()

    private let todayCard = ILStatProgressCardView(title: "home.today.title".localized)
    private let streakCard = ILStatStreakCardView(title: "home.streak.title".localized, unitText: "home.streak.unit".localized)
    private let statsStack = UIStackView()

    private let malaHeader = ILSectionHeaderView(title: "home.mala.title".localized, trailingText: "home.mala.fullscreen".localized)
    private let malaCounter = ILMalaCounterView(resetTitle: "home.mala.reset".localized)

    private let suggestedHeader = ILSectionHeaderView(title: "home.suggested.title".localized)
    private let suggestedStack = UIStackView()


    // MARK: - Initializer
    init(viewModel: ILHomeViewModel) {
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
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.canvasWarm

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.onNotificationTap = { [weak self] in self?.handleNotificationTapped() }
        headerView.onAvatarTap = { [weak self] in self?.handleAvatarTapped() }

        weekCalendarView.translatesAutoresizingMaskIntoConstraints = false
        weekCalendarView.onCalendarLinkTap = { [weak self] in self?.handleCalendarLinkTapped() }

        lunarHeroCard.translatesAutoresizingMaskIntoConstraints = false
        lunarHeroCard.onTap = { [weak self] in self?.handleLunarHeroTapped() }

        eventsHeader.translatesAutoresizingMaskIntoConstraints = false
        eventsHeader.onTrailingTap = { [weak self] in self?.handleEventsViewAllTapped() }

        eventsCarousel.translatesAutoresizingMaskIntoConstraints = false
        eventsCarousel.onEventTap = { [weak self] event in self?.handleEventTapped(event) }

        statsStack.addArrangedSubview(todayCard)
        statsStack.addArrangedSubview(streakCard)
        statsStack.axis = .horizontal
        statsStack.spacing = ILMetrics.rowSpacing
        statsStack.distribution = .fillEqually
        statsStack.translatesAutoresizingMaskIntoConstraints = false

        malaHeader.translatesAutoresizingMaskIntoConstraints = false
        malaHeader.onTrailingTap = { [weak self] in self?.handleMalaFullscreenTapped() }

        malaCounter.translatesAutoresizingMaskIntoConstraints = false
        malaCounter.onTapBead = { [weak self] in self?.handleBeadTapped() }
        malaCounter.onReset = { [weak self] in self?.handleResetBeadsTapped() }

        suggestedHeader.translatesAutoresizingMaskIntoConstraints = false

        suggestedStack.axis = .vertical
        suggestedStack.spacing = ILMetrics.rowSpacing
        suggestedStack.translatesAutoresizingMaskIntoConstraints = false

        [
            headerView, weekCalendarView, lunarHeroCard, eventsHeader, eventsCarousel,
            statsStack, malaHeader, malaCounter, suggestedHeader, suggestedStack
        ].forEach {
            contentView.addSubview($0)
        }
    }

    override func setupConstraints() {
        super.setupConstraints()

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceMedium),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: ILMetrics.screenHorizontal),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -ILMetrics.bottomNavHeight),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -ILMetrics.screenHorizontal * 2),

            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            weekCalendarView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: ILMetrics.groupSpacing),
            weekCalendarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            weekCalendarView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            lunarHeroCard.topAnchor.constraint(equalTo: weekCalendarView.bottomAnchor, constant: ILMetrics.groupSpacing - 2),
            lunarHeroCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            lunarHeroCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            eventsHeader.topAnchor.constraint(equalTo: lunarHeroCard.bottomAnchor, constant: ILMetrics.groupSpacing),
            eventsHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            eventsHeader.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            eventsCarousel.topAnchor.constraint(equalTo: eventsHeader.bottomAnchor, constant: ILMetrics.rowSpacing),
            eventsCarousel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            eventsCarousel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            statsStack.topAnchor.constraint(equalTo: eventsCarousel.bottomAnchor, constant: ILMetrics.groupSpacing),
            statsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            statsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            malaHeader.topAnchor.constraint(equalTo: statsStack.bottomAnchor, constant: ILMetrics.groupSpacing),
            malaHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            malaHeader.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            malaCounter.topAnchor.constraint(equalTo: malaHeader.bottomAnchor, constant: ILMetrics.rowSpacing),
            malaCounter.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            malaCounter.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            suggestedHeader.topAnchor.constraint(equalTo: malaCounter.bottomAnchor, constant: ILMetrics.groupSpacing),
            suggestedHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            suggestedHeader.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            suggestedStack.topAnchor.constraint(equalTo: suggestedHeader.bottomAnchor, constant: ILMetrics.rowSpacing),
            suggestedStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            suggestedStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            suggestedStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILHomeViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            beadTapped: beadTappedSubject.eraseToAnyPublisher(),
            resetBeadsTapped: resetBeadsTappedSubject.eraseToAnyPublisher(),
            malaFullscreenTapped: malaFullscreenTappedSubject.eraseToAnyPublisher(),
            lunarCalendarTapped: lunarCalendarTappedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
    }

    // MARK: - Render
    private func render(state: ViewState<ILHomeStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILHomeStateModel) {
        headerView.greetingText = model.greetingText
        headerView.dateText = model.dateText
        headerView.avatarInitial = model.avatarInitial

        weekCalendarView.weekLabelText = model.weekLabelText
        weekCalendarView.calendarLinkText = model.weekCalendarLinkText
        weekCalendarView.days = model.weekDays

        lunarHeroCard.eyebrowText = model.lunarHero.eyebrowText
        lunarHeroCard.solarLabel = model.lunarHero.solarLabel
        lunarHeroCard.lunarDay = model.lunarHero.lunarDay
        lunarHeroCard.lunarMonthLabel = model.lunarHero.lunarMonthLabel
        lunarHeroCard.lunarYearLabel = model.lunarHero.lunarYearLabel
        lunarHeroCard.verseLines = model.lunarHero.verseLines
        lunarHeroCard.verseSource = model.lunarHero.verseSource

        eventsHeader.title = model.eventsTitle
        eventsHeader.trailingText = model.eventsViewAllText
        eventsCarousel.months = model.eventMonths

        todayCard.valueText = String(format: "home.today.valueFormat".localized, model.sessionMinutesDone, model.sessionMinutesGoal)
        todayCard.progress = model.sessionProgress

        streakCard.valueText = "\(model.streakDays)"
        streakCard.weekProgress = model.streakWeekProgress

        malaCounter.count = model.malaCount
        malaCounter.goal = model.malaGoal
        malaCounter.goalText = String(format: "home.mala.goalFormat".localized, model.malaGoal)
        malaCounter.mantraText = model.malaMantraText
        malaCounter.helperText = model.malaHelperText

        renderSuggestedSessions(model.suggestedSessions)
    }

    private func renderSuggestedSessions(_ sessions: [ILHomeSuggestedSessionModel]) {
        suggestedStack.arrangedSubviews.forEach {
            suggestedStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        for session in sessions {
            let row = ILRow(
                title: session.title,
                subtitle: session.subtitle,
                trailingText: session.trailingText,
                tone: mapTone(session.tone),
                glyph: mapGlyph(session.glyph)
            )
            row.onTap = { [weak self] in self?.handleSuggestedSessionTapped(session) }
            suggestedStack.addArrangedSubview(row)
        }
    }

    private func mapTone(_ tone: ILHomeSessionTone) -> ILColors.Tone {
        switch tone {
        case .gold: return .gold
        case .green: return .green
        case .rose: return .rose
        case .ink: return .ink
        }
    }

    private func mapGlyph(_ glyph: ILHomeSessionGlyph) -> ILRow.Glyph {
        switch glyph {
        case .leaf: return .leaf
        case .book: return .book
        case .circle: return .circle
        case .dot: return .dot
        }
    }

    // MARK: - Actions
    private func handleBeadTapped() {
        beadTappedSubject.send(())
    }

    private func handleResetBeadsTapped() {
        resetBeadsTappedSubject.send(())
    }

    /// Thông báo chưa có màn riêng trong scope hiện tại.
    private func handleNotificationTapped() {
        // TODO: điều hướng sang màn Thông báo khi có ILNotificationsCoordinator.
    }

    /// Hồ sơ cá nhân chưa có màn riêng trong scope hiện tại.
    private func handleAvatarTapped() {
        // TODO: điều hướng sang màn Hồ sơ khi có ILProfileCoordinator.
    }

    private func handleCalendarLinkTapped() {
        lunarCalendarTappedSubject.send(())
    }

    private func handleLunarHeroTapped() {
        lunarCalendarTappedSubject.send(())
    }

    /// Danh sách sự kiện đầy đủ (màn `events`) chưa có màn riêng trong scope hiện tại.
    private func handleEventsViewAllTapped() {
        // TODO: điều hướng sang màn Sự kiện & khóa học khi có coordinator tương ứng.
    }

    /// Chi tiết 1 sự kiện chưa có màn riêng trong scope hiện tại.
    private func handleEventTapped(_ event: ILHomeEventItemModel) {
        // TODO: điều hướng theo `event.id` khi có màn Sự kiện & khóa học.
    }

    private func handleMalaFullscreenTapped() {
        malaFullscreenTappedSubject.send(())
    }

    /// Thời khóa gợi ý (thiền, tụng kinh, cúng đèn) chưa có màn riêng trong scope hiện tại.
    private func handleSuggestedSessionTapped(_ session: ILHomeSuggestedSessionModel) {
        // TODO: điều hướng theo `session.id` khi có màn Thiết lập thời khóa/Đọc kinh/Cúng dường.
    }
}
