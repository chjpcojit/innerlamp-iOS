//
//  ILFestivalDetailViewController.swift
//  InnerLamp
//

import UIKit
import Combine

/// EN: Festival detail screen (`festDetail` in the design handoff): sticky header
///     (`ILStickyHeaderBand` + `ILNavBar`), hero image, kind + title + lunar date, about block,
///     solar date card with countdown, "what Buddhists usually do", "sutras to recite" and
///     "hosting temples". Sections without data show an "empty" caption instead of being hidden.
/// VI: Màn "Chi tiết ngày lễ" (`festDetail` trong design handoff): header dán cố định
///     (`ILStickyHeaderBand` + `ILNavBar`), ảnh đại diện, nhãn loại + tên lễ + ngày âm, phần giới
///     thiệu, thẻ ngày dương + đếm ngược, "Phật tử thường làm gì", "Kinh nên tụng", "Chùa tổ chức".
///     Mục chưa có dữ liệu hiện câu "chưa có" thay vì bị ẩn.
final class ILFestivalDetailViewController: BaseViewController {

    private enum Layout {
        static let heroHeight: CGFloat = 220
        static let sectionSpacing: CGFloat = 26
        static let headerBottomInset: CGFloat = 10
        static let contentTopInset: CGFloat = 4
        static let contentBottomInset: CGFloat = 34
    }

    // MARK: - Properties
    private let viewModel: ILFestivalDetailViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let retryTappedSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var headerBand = ILStickyHeaderBand()

    private lazy var navBar: ILNavBar = {
        let bar = ILNavBar(showBack: true)
        bar.onBack = { [weak self] in self?.backTappedSubject.send(()) }
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }()

    private lazy var heroView = ILFestivalDetailHeroView()
    private lazy var kindRow = ILFestivalDetailKindRowView()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.displayLarge
        label.textColor = ILColors.ink
        label.numberOfLines = 0
        return label
    }()

    private lazy var lunarLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.bodyMedium
        label.textColor = ILColors.link
        label.numberOfLines = 0
        return label
    }()

    private lazy var aboutView = ILFestivalDetailAboutView()
    private lazy var dateCard = ILFestivalDetailDateCardView()

    private lazy var practicesEyebrow = ILSectionEyebrowView()
    private lazy var practicesCard = ILFestivalDetailListCardView()
    private lazy var sutraEyebrow = ILSectionEyebrowView()
    private lazy var sutraCard = ILFestivalDetailListCardView()
    private lazy var hostsEyebrow = ILSectionEyebrowView()
    private lazy var hostsCard = ILFestivalDetailListCardView()

    /// EN: Full-screen states — shown instead of `scrollView` while there is no content.
    /// VI: Trạng thái toàn màn hình — hiện thay `scrollView` khi chưa có nội dung.
    private lazy var loadingView: ILLoadingDotsView = {
        let view = ILLoadingDotsView()
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var errorView: ILFestivalDetailErrorView = {
        let view = ILFestivalDetailErrorView()
        view.onRetry = { [weak self] in self?.retryTappedSubject.send(()) }
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var lastHeaderHeight: CGFloat = 0

    // MARK: - Initializer
    init(viewModel: ILFestivalDetailViewModel) {
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyHeaderInset()
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.canvas

        headerBand.addSubview(navBar)
        scrollView.addSubview(contentStack)
        headerBand.bind(to: scrollView)

        [
            heroView, kindRow, titleLabel, lunarLabel, aboutView, dateCard,
            practicesEyebrow, practicesCard, sutraEyebrow, sutraCard, hostsEyebrow, hostsCard
        ].forEach { contentStack.addArrangedSubview($0) }

        contentStack.setCustomSpacing(ILMetrics.groupSpacing, after: heroView)
        contentStack.setCustomSpacing(ILMetrics.rowSpacing, after: kindRow)
        contentStack.setCustomSpacing(ILMetrics.rowSpacing, after: titleLabel)
        contentStack.setCustomSpacing(ILMetrics.groupSpacing, after: lunarLabel)
        contentStack.setCustomSpacing(Layout.sectionSpacing, after: aboutView)
        [practicesEyebrow, sutraEyebrow, hostsEyebrow].forEach {
            contentStack.setCustomSpacing(ILMetrics.spaceCompact, after: $0)
        }
        contentStack.setCustomSpacing(Layout.sectionSpacing, after: dateCard)
        contentStack.setCustomSpacing(Layout.sectionSpacing, after: practicesCard)
        contentStack.setCustomSpacing(Layout.sectionSpacing, after: sutraCard)

        // Scroll view first so the sticky header band stays on top of scrolled content.
        [scrollView, loadingView, errorView, headerBand].forEach { view.addSubview($0) }
    }

    override func setupConstraints() {
        super.setupConstraints()
        let horizontal = ILMetrics.screenHorizontal

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            headerBand.topAnchor.constraint(equalTo: view.topAnchor),
            headerBand.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBand.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceTiny),
            navBar.leadingAnchor.constraint(equalTo: headerBand.leadingAnchor, constant: horizontal),
            navBar.trailingAnchor.constraint(equalTo: headerBand.trailingAnchor, constant: -horizontal),
            navBar.bottomAnchor.constraint(equalTo: headerBand.bottomAnchor, constant: -Layout.headerBottomInset),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: Layout.contentTopInset),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: horizontal),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -horizontal),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -Layout.contentBottomInset),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -horizontal * 2),

            heroView.heightAnchor.constraint(equalToConstant: Layout.heroHeight),

            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            errorView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontal),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontal)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILFestivalDetailViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            retryTapped: retryTappedSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        // No `.receive(on: DispatchQueue.main)`: state is already sent on main (MainActor default),
        // and deferring it renders the first state only after the appear transition has run.
        output.state
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
    }

    // MARK: - Pinned header
    /// EN: Content starts below the header: the header height is `contentInset.top`.
    /// VI: Nội dung bắt đầu dưới header: chiều cao header là `contentInset.top`.
    private func applyHeaderInset() {
        let top = headerBand.bounds.height
        guard top > 0, top != lastHeaderHeight else { return }
        let wasAtTop = lastHeaderHeight == 0 || scrollView.contentOffset.y <= -lastHeaderHeight + 0.5
        lastHeaderHeight = top
        scrollView.contentInset.top = top
        scrollView.verticalScrollIndicatorInsets.top = top
        if wasAtTop { scrollView.contentOffset.y = -top }
    }

    // MARK: - Render
    private enum ScreenState {
        case loading
        case content
        case error
    }

    private func render(state: ViewState<ILFestivalDetailStateModel>) {
        switch state {
        case .idle:
            break
        case .loading:
            showScreenState(.loading)
        case .success(let model):
            updateUI(with: model)
            showScreenState(.content)
        case .failure(let error):
            errorView.configure(for: error)
            showScreenState(.error)
        }
    }

    private func showScreenState(_ screenState: ScreenState) {
        scrollView.isHidden = screenState != .content
        errorView.isHidden = screenState != .error
        let isLoading = screenState == .loading
        if isLoading, loadingView.isHidden {
            loadingView.isHidden = false
            // Pulsing needs a window; on the first `.loading` (sent from `viewDidLoad`) the view is
            // not in one yet, so start it on the next run-loop turn.
            DispatchQueue.main.async { [weak self] in self?.loadingView.startPulsingAnimation() }
        } else if !isLoading {
            loadingView.isHidden = true
        }
    }

    private func updateUI(with model: ILFestivalDetailStateModel) {
        heroView.configure(imageURL: model.imageURL, emptyText: model.imageEmptyText)
        kindRow.configure(kindText: model.kindText)
        titleLabel.text = model.title
        lunarLabel.text = model.lunarText
        aboutView.configure(paragraphs: model.aboutParagraphs, emptyText: model.aboutEmptyText)

        dateCard.configure(
            day: model.dayText,
            date: model.dateText,
            caption: model.dateCaption,
            countdown: model.countdownText
        )

        practicesEyebrow.title = model.practicesTitle
        practicesCard.configure(items: model.practices, emptyText: model.practicesEmptyText)
        sutraEyebrow.title = model.sutraTitle
        sutraCard.configure(items: [], emptyText: model.sutraEmptyText)
        hostsEyebrow.title = model.hostsTitle
        hostsCard.configure(items: [], emptyText: model.hostsEmptyText)
    }
}
