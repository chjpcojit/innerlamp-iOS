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
    private let lunarHeroTappedSubject = PassthroughSubject<Void, Never>()
    private let dayTappedSubject = PassthroughSubject<String, Never>()
    private let photosTappedSubject = PassthroughSubject<Void, Never>()
    private let bellTappedSubject = PassthroughSubject<Void, Never>()
    private let eventsTappedSubject = PassthroughSubject<Void, Never>()
    private let articleTappedSubject = PassthroughSubject<String, Never>()
    private let articlesViewAllTappedSubject = PassthroughSubject<Void, Never>()
    private let templeTappedSubject = PassthroughSubject<String, Never>()
    private let deityTappedSubject = PassthroughSubject<String, Never>()
    private let deitiesViewAllTappedSubject = PassthroughSubject<Void, Never>()
    private let suggestedSessionTappedSubject = PassthroughSubject<String, Never>()

    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let headerView = ILHomeGreetingHeaderView()
    private let weekCalendarView = ILHomeWeekCalendarView()
    private let lunarHeroCard = ILHomeLunarHeroCardView()

    private let eventsHeader = ILSectionHeaderView(title: "home.events.title".localized, trailingText: "home.events.viewAll".localized)
    private let eventsCarousel = ILHomeEventsCarouselView()

    private let photosHeader = ILSectionHeaderView(title: "home.photos.title".localized, trailingText: "home.photos.viewAll".localized)
    private let photosGrid = ILHomePhotoGridView()

    private let templesHeader = ILSectionHeaderView(title: "home.temple.title".localized, trailingText: "home.temple.find".localized)
    private let templesCarousel = ILHomeTempleCarouselView()

    private let deitiesHeader = ILSectionHeaderView(title: "home.deity.title".localized, trailingText: "home.deity.viewAll".localized)
    private let deitiesCarousel = ILHomeDeityCarouselView()

    private let todayCard = ILStatProgressCardView(title: "home.today.title".localized)
    private let streakCard = ILStatStreakCardView(title: "home.streak.title".localized, unitText: "home.streak.unit".localized)
    private let statsStack = UIStackView()

    private let malaHeader = ILSectionHeaderView(title: "home.mala.title".localized, trailingText: "home.mala.fullscreen".localized)
    private let malaCounter = ILMalaCounterView(resetTitle: "home.mala.reset".localized)

    private let bellCard = ILHomeBellCardView()

    private let suggestedHeader = ILSectionHeaderView(title: "home.suggested.title".localized)
    private let suggestedStack = UIStackView()

    private let articlesHeader = ILSectionHeaderView(title: "home.article.title".localized, trailingText: "home.article.library".localized)
    private let articlesList = ILHomeArticleListView()


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
        weekCalendarView.onSelectDay = { [weak self] day in self?.dayTappedSubject.send(day.id) }

        lunarHeroCard.translatesAutoresizingMaskIntoConstraints = false
        lunarHeroCard.onTap = { [weak self] in self?.handleLunarHeroTapped() }

        eventsHeader.translatesAutoresizingMaskIntoConstraints = false
        eventsHeader.onTrailingTap = { [weak self] in self?.handleEventsViewAllTapped() }

        eventsCarousel.translatesAutoresizingMaskIntoConstraints = false
        eventsCarousel.onEventTap = { [weak self] event in self?.handleEventTapped(event) }

        photosHeader.translatesAutoresizingMaskIntoConstraints = false
        photosHeader.onTrailingTap = { [weak self] in self?.handlePhotosViewAllTapped() }

        photosGrid.translatesAutoresizingMaskIntoConstraints = false
        photosGrid.onTap = { [weak self] in self?.handlePhotoTapped() }

        templesHeader.translatesAutoresizingMaskIntoConstraints = false
        templesHeader.onTrailingTap = { [weak self] in self?.handleTemplesFindTapped() }

        templesCarousel.translatesAutoresizingMaskIntoConstraints = false
        templesCarousel.onTempleTap = { [weak self] temple in self?.handleTempleTapped(temple) }

        deitiesHeader.translatesAutoresizingMaskIntoConstraints = false
        deitiesHeader.onTrailingTap = { [weak self] in self?.handleDeitiesViewAllTapped() }

        deitiesCarousel.translatesAutoresizingMaskIntoConstraints = false
        deitiesCarousel.onDeityTap = { [weak self] deity in self?.handleDeityTapped(deity) }

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

        bellCard.translatesAutoresizingMaskIntoConstraints = false
        bellCard.onTap = { [weak self] in self?.handleBellTapped() }

        suggestedHeader.translatesAutoresizingMaskIntoConstraints = false

        suggestedStack.axis = .vertical
        suggestedStack.spacing = ILMetrics.rowSpacing
        suggestedStack.translatesAutoresizingMaskIntoConstraints = false

        articlesHeader.translatesAutoresizingMaskIntoConstraints = false
        articlesHeader.onTrailingTap = { [weak self] in self?.handleArticlesViewAllTapped() }

        articlesList.translatesAutoresizingMaskIntoConstraints = false
        articlesList.onArticleTap = { [weak self] article in self?.handleArticleTapped(article) }

        [
            headerView, weekCalendarView, lunarHeroCard, eventsHeader, eventsCarousel,
            photosHeader, photosGrid, templesHeader, templesCarousel, deitiesHeader, deitiesCarousel,
            statsStack,
            malaHeader, malaCounter, bellCard, suggestedHeader, suggestedStack,
            articlesHeader, articlesList
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

            photosHeader.topAnchor.constraint(equalTo: eventsCarousel.bottomAnchor, constant: ILMetrics.groupSpacing),
            photosHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            photosHeader.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            photosGrid.topAnchor.constraint(equalTo: photosHeader.bottomAnchor, constant: ILMetrics.rowSpacing),
            photosGrid.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            photosGrid.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            templesHeader.topAnchor.constraint(equalTo: photosGrid.bottomAnchor, constant: ILMetrics.groupSpacing),
            templesHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            templesHeader.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            templesCarousel.topAnchor.constraint(equalTo: templesHeader.bottomAnchor, constant: ILMetrics.rowSpacing),
            templesCarousel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            templesCarousel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            deitiesHeader.topAnchor.constraint(equalTo: templesCarousel.bottomAnchor, constant: ILMetrics.groupSpacing),
            deitiesHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            deitiesHeader.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            deitiesCarousel.topAnchor.constraint(equalTo: deitiesHeader.bottomAnchor, constant: ILMetrics.rowSpacing),
            deitiesCarousel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            deitiesCarousel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            statsStack.topAnchor.constraint(equalTo: deitiesCarousel.bottomAnchor, constant: ILMetrics.groupSpacing),
            statsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            statsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            malaHeader.topAnchor.constraint(equalTo: statsStack.bottomAnchor, constant: ILMetrics.groupSpacing),
            malaHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            malaHeader.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            malaCounter.topAnchor.constraint(equalTo: malaHeader.bottomAnchor, constant: ILMetrics.rowSpacing),
            malaCounter.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            malaCounter.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            bellCard.topAnchor.constraint(equalTo: malaCounter.bottomAnchor, constant: ILMetrics.rowSpacing),
            bellCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bellCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            suggestedHeader.topAnchor.constraint(equalTo: bellCard.bottomAnchor, constant: ILMetrics.groupSpacing),
            suggestedHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            suggestedHeader.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            suggestedStack.topAnchor.constraint(equalTo: suggestedHeader.bottomAnchor, constant: ILMetrics.rowSpacing),
            suggestedStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            suggestedStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            articlesHeader.topAnchor.constraint(equalTo: suggestedStack.bottomAnchor, constant: ILMetrics.groupSpacing),
            articlesHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            articlesHeader.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            articlesList.topAnchor.constraint(equalTo: articlesHeader.bottomAnchor, constant: ILMetrics.rowSpacing),
            articlesList.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            articlesList.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            articlesList.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILHomeViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            beadTapped: beadTappedSubject.eraseToAnyPublisher(),
            resetBeadsTapped: resetBeadsTappedSubject.eraseToAnyPublisher(),
            malaFullscreenTapped: malaFullscreenTappedSubject.eraseToAnyPublisher(),
            lunarCalendarTapped: lunarCalendarTappedSubject.eraseToAnyPublisher(),
            lunarHeroTapped: lunarHeroTappedSubject.eraseToAnyPublisher(),
            dayTapped: dayTappedSubject.eraseToAnyPublisher(),
            photosTapped: photosTappedSubject.eraseToAnyPublisher(),
            bellTapped: bellTappedSubject.eraseToAnyPublisher(),
            eventsTapped: eventsTappedSubject.eraseToAnyPublisher(),
            articleTapped: articleTappedSubject.eraseToAnyPublisher(),
            articlesViewAllTapped: articlesViewAllTappedSubject.eraseToAnyPublisher(),
            templeTapped: templeTappedSubject.eraseToAnyPublisher(),
            deityTapped: deityTappedSubject.eraseToAnyPublisher(),
            deitiesViewAllTapped: deitiesViewAllTappedSubject.eraseToAnyPublisher(),
            suggestedSessionTapped: suggestedSessionTappedSubject.eraseToAnyPublisher()
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

        weekCalendarView.weekdayLabels = model.weekdayLabels
        weekCalendarView.calendarLinkText = model.weekCalendarLinkText
        weekCalendarView.legend = model.weekLegend
        weekCalendarView.pages = model.weekPages

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

        photosHeader.title = model.photosTitle
        photosHeader.trailingText = model.photosViewAllText
        photosGrid.photosMoreText = model.photosMoreText
        photosGrid.photosMoreLabel = model.photosMoreLabel

        templesHeader.title = model.templesTitle
        templesHeader.trailingText = model.templesFindText
        templesCarousel.temples = model.temples

        deitiesHeader.title = model.deitiesTitle
        deitiesHeader.trailingText = model.deitiesViewAllText
        deitiesCarousel.deities = model.deities

        bellCard.title = model.bellTitle
        bellCard.subtitle = model.bellSubtitle

        articlesHeader.title = model.articlesTitle
        articlesHeader.trailingText = model.articlesViewAllText
        articlesList.articles = model.articles
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
        lunarHeroTappedSubject.send(())
    }

    /// Nút "Tất cả" ở mục "Sự kiện Phật giáo" — mở màn Lịch lễ Phật giáo (`festivals`).
    private func handleEventsViewAllTapped() {
        eventsTappedSubject.send(())
    }

    /// Chạm 1 sự kiện trong carousel "Sự kiện Phật giáo" — mở màn Lịch lễ Phật giáo (`festivals`).
    private func handleEventTapped(_ event: ILHomeEventItemModel) {
        eventsTappedSubject.send(())
    }

    private func handleMalaFullscreenTapped() {
        malaFullscreenTappedSubject.send(())
    }

    /// 1 hàng "Thời khóa gợi ý" — ViewModel quyết định màn đích theo loại mục (thiền → Chuẩn bị
    /// thiền).
    private func handleSuggestedSessionTapped(_ session: ILHomeSuggestedSessionModel) {
        suggestedSessionTappedSubject.send(session.id)
    }

    /// Khối "Ảnh chùa đẹp" — mở màn gallery ảnh chùa (`photos`).
    private func handlePhotosViewAllTapped() {
        photosTappedSubject.send(())
    }

    private func handlePhotoTapped() {
        photosTappedSubject.send(())
    }

    /// Link "Tìm chùa" ở carousel "Chùa Việt Nam" — màn danh sách/tìm chùa chưa build.
    private func handleTemplesFindTapped() {
        // TODO: điều hướng sang màn tìm chùa (Đạo tràng) khi có coordinator tương ứng.
    }

    /// Chi tiết 1 chùa trong carousel "Chùa Việt Nam" — mở màn Trang chùa (`temple`) theo
    /// `temple.id`.
    private func handleTempleTapped(_ temple: ILHomeTempleModel) {
        templeTappedSubject.send(temple.id)
    }

    /// Chi tiết 1 vị Phật / Bồ Tát trong carousel "Thư viện Phật & Bồ Tát" — mở màn chi tiết
    /// (`deity`) theo `deity.id`.
    private func handleDeityTapped(_ deity: ILHomeDeityModel) {
        deityTappedSubject.send(deity.id)
    }

    /// Link "Xem tất cả" ở carousel "Thư viện Phật & Bồ Tát" — mở màn danh sách "Chư Phật & Bồ Tát".
    private func handleDeitiesViewAllTapped() {
        deitiesViewAllTappedSubject.send(())
    }

    /// Thẻ "Chuông mõ" — mở màn Chuông mõ.
    private func handleBellTapped() {
        bellTappedSubject.send(())
    }

    /// Link "Xem tất cả" ở mục "Bài viết Phật pháp hay" — mở màn Tất cả bài viết (`articles`).
    private func handleArticlesViewAllTapped() {
        articlesViewAllTappedSubject.send(())
    }

    /// Chi tiết 1 bài viết — mở màn Bài viết Phật pháp (`article`) theo `article.id`.
    private func handleArticleTapped(_ article: ILHomeArticleModel) {
        articleTappedSubject.send(article.id)
    }
}
