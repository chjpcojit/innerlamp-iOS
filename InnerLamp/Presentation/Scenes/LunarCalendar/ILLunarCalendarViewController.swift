//
//  ILLunarCalendarViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILLunarCalendarViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: ILLunarCalendarViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let previousMonthTappedSubject = PassthroughSubject<Void, Never>()
    private let nextMonthTappedSubject = PassthroughSubject<Void, Never>()
    private let pageChangedSubject = PassthroughSubject<Int, Never>()
    private let dayTappedSubject = PassthroughSubject<String, Never>()
    private let closeTappedSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    private lazy var headerContainer: UIView = {
        let container = UIView()
        container.backgroundColor = ILColors.canvas
        return container
    }()

    private lazy var headerView = ILHeaderView(isCloseButton: true, isBackButtonHidden: false)

    private lazy var headerDivider: UIView = {
        let divider = UIView()
        divider.backgroundColor = ILColors.border
        return divider
    }()

    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.alwaysBounceVertical = true
        scroll.showsVerticalScrollIndicator = false
        return scroll
    }()

    private lazy var contentView = UIView()

    private lazy var pagerBarView = ILLunarCalendarPagerBarView()

    private lazy var carouselView = ILLunarCalendarMonthCarouselView()

    private lazy var dayInfoCardView = ILLunarCalendarDayInfoCardView()

    private lazy var upcomingStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = ILMetrics.rowSpacing
        return stack
    }()

    // MARK: - Initializer
    init(viewModel: ILLunarCalendarViewModel) {
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
        // Màn phủ kín có nút ✕ ở header — thanh điều hướng đáy của tab bar không cần thiết.
        (tabBarController as? ILMainTabBarController)?.setBottomNavHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        (tabBarController as? ILMainTabBarController)?.setBottomNavHidden(false, animated: animated)
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.canvas

        headerView.onBack = { [weak self] in self?.closeTappedSubject.send(()) }
        headerView.accessibilityLabel = "lunarCalendar.close".localized
        headerContainer.addSubview(headerView)
        headerContainer.addSubview(headerDivider)

        pagerBarView.previousAccessibilityLabel = "lunarCalendar.pager.previous".localized
        pagerBarView.nextAccessibilityLabel = "lunarCalendar.pager.next".localized
        pagerBarView.onPrevious = { [weak self] in self?.previousMonthTappedSubject.send(()) }
        pagerBarView.onNext = { [weak self] in self?.nextMonthTappedSubject.send(()) }

        carouselView.onPageChanged = { [weak self] page in self?.pageChangedSubject.send(page) }
        carouselView.onDayTap = { [weak self] id in self?.dayTappedSubject.send(id) }

        [pagerBarView, carouselView, dayInfoCardView, upcomingStack].forEach(contentView.addSubview)
        scrollView.addSubview(contentView)

        view.addSubview(scrollView)
        view.addSubview(headerContainer)
    }

    override func setupConstraints() {
        super.setupConstraints()
        [headerContainer, headerView, headerDivider, scrollView, contentView,
         pagerBarView, carouselView, dayInfoCardView, upcomingStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

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
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            pagerBarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: ILMetrics.groupSpacing - 2),
            pagerBarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontal),
            pagerBarView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontal),

            // Full-bleed: các thẻ tháng tự chừa lề 20pt bên trong carousel.
            carouselView.topAnchor.constraint(equalTo: pagerBarView.bottomAnchor, constant: ILMetrics.spaceMedium),
            carouselView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            carouselView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            dayInfoCardView.topAnchor.constraint(equalTo: carouselView.bottomAnchor, constant: ILMetrics.groupSpacing),
            dayInfoCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontal),
            dayInfoCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontal),

            upcomingStack.topAnchor.constraint(equalTo: dayInfoCardView.bottomAnchor, constant: ILMetrics.groupSpacing - 2),
            upcomingStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontal),
            upcomingStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontal),
            upcomingStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -ILMetrics.screenPadding.bottom)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILLunarCalendarViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            previousMonthTapped: previousMonthTappedSubject.eraseToAnyPublisher(),
            nextMonthTapped: nextMonthTappedSubject.eraseToAnyPublisher(),
            pageChanged: pageChangedSubject.eraseToAnyPublisher(),
            dayTapped: dayTappedSubject.eraseToAnyPublisher(),
            closeTapped: closeTappedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
    }

    // MARK: - Render
    private func render(state: ViewState<ILLunarCalendarStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILLunarCalendarStateModel) {
        headerView.title = model.headerTitle
        headerView.subtitle = model.headerSubtitle
        pagerBarView.hintText = model.pagerHintText

        carouselView.weekdayLabels = model.weekdayLabels
        carouselView.months = model.months
        carouselView.scroll(toPage: model.currentPage, animated: true)

        dayInfoCardView.eyebrowText = model.heroEyebrowText
        dayInfoCardView.titleText = model.heroTitle
        dayInfoCardView.bodyText = model.heroBody

        rebuildUpcoming(model.upcoming)
    }

    private func rebuildUpcoming(_ items: [ILLunarCalendarUpcomingModel]) {
        upcomingStack.arrangedSubviews.forEach {
            upcomingStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        for item in items {
            let row = ILRow(
                title: item.title,
                subtitle: item.subtitle,
                tone: mapTone(item.category),
                glyph: mapGlyph(item.category)
            )
            // Chưa có màn đích (đạo tràng/nhắc lịch) — hàng chỉ hiển thị, không phản hồi chạm.
            row.isUserInteractionEnabled = false
            upcomingStack.addArrangedSubview(row)
        }
    }

    private func mapTone(_ category: ILLunarCalendarDayCategory) -> ILColors.Tone {
        switch category {
        case .newMoon, .fullMoon: return .gold
        case .fastDay, .ordinary: return .green
        }
    }

    private func mapGlyph(_ category: ILLunarCalendarDayCategory) -> ILRow.Glyph {
        switch category {
        case .newMoon, .fullMoon: return .circle
        case .fastDay, .ordinary: return .leaf
        }
    }
}
