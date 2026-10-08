//
//  ILLibraryViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILLibraryViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: ILLibraryViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let quickAccessTappedSubject = PassthroughSubject<ILLibraryQuickAccessKind, Never>()
    private let searchTappedSubject = PassthroughSubject<Void, Never>()
    private let featuredTappedSubject = PassthroughSubject<Void, Never>()
    private let deityTappedSubject = PassthroughSubject<String, Never>()
    private let deitiesViewAllTappedSubject = PassthroughSubject<Void, Never>()
    private let sutrasViewAllTappedSubject = PassthroughSubject<Void, Never>()
    private let itemTappedSubject = PassthroughSubject<String, Never>()

    // MARK: - UI Elements
    private let headerBand = ILStickyHeaderBand()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.displayMedium
        label.textColor = ILColors.ink
        label.text = "library.title".localized
        label.accessibilityTraits = .header
        return label
    }()

    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        return scroll
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        return stack
    }()

    private lazy var searchBar = ILSearchBarView(placeholder: "library.search.placeholder".localized)
    private lazy var quickAccessGrid = ILLibraryQuickAccessGridView()
    private lazy var featureCard = ILFeatureCardView()
    private lazy var deitiesHeader = ILSectionHeaderView(title: "")
    /// Dùng chung view carousel với Trang chủ (`ILHomeDeityCarouselView`) — cùng dữ liệu
    /// "Chư Phật & Bồ Tát", chỉ khác tiêu đề section (xem `ILLibraryStateModel.deitiesTitle`).
    private lazy var deitiesCarousel = ILHomeDeityCarouselView()
    private lazy var listView = ILLibraryListView()
    private lazy var skeletonView = ILSkeletonLoadingView()

    // MARK: - Initializer
    init(viewModel: ILLibraryViewModel) {
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyHeaderInset()
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.canvas

        // Band last so it sits above the scroll view and the skeleton.
        [scrollView, skeletonView, headerBand].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerBand.addSubview(titleLabel)
        scrollView.contentInsetAdjustmentBehavior = .never
        headerBand.bind(to: scrollView)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        [searchBar, quickAccessGrid, featureCard, deitiesHeader, deitiesCarousel, listView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentStack.addArrangedSubview($0)
        }
        contentStack.setCustomSpacing(ILMetrics.spaceMedium, after: searchBar)
        contentStack.setCustomSpacing(ILMetrics.groupSpacing, after: quickAccessGrid)
        contentStack.setCustomSpacing(ILMetrics.groupSpacing + 2, after: featureCard)
        contentStack.setCustomSpacing(ILMetrics.rowSpacing, after: deitiesHeader)
        contentStack.setCustomSpacing(ILMetrics.groupSpacing + 2, after: deitiesCarousel)

        searchBar.onTap = { [weak self] in self?.searchTappedSubject.send(()) }
        quickAccessGrid.onTileTapped = { [weak self] kind in self?.quickAccessTappedSubject.send(kind) }
        featureCard.onTap = { [weak self] in self?.featuredTappedSubject.send(()) }
        deitiesHeader.onTrailingTap = { [weak self] in self?.deitiesViewAllTappedSubject.send(()) }
        deitiesCarousel.onDeityTap = { [weak self] deity in self?.deityTappedSubject.send(deity.id) }
        listView.onItemTapped = { [weak self] id in self?.itemTappedSubject.send(id) }
        listView.onViewAllTapped = { [weak self] in self?.sutrasViewAllTappedSubject.send(()) }
    }

    override func setupConstraints() {
        super.setupConstraints()

        NSLayoutConstraint.activate([
            headerBand.topAnchor.constraint(equalTo: view.topAnchor),
            headerBand.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBand.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceMedium),
            titleLabel.leadingAnchor.constraint(equalTo: headerBand.leadingAnchor, constant: ILMetrics.screenHorizontal),
            titleLabel.trailingAnchor.constraint(equalTo: headerBand.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            titleLabel.bottomAnchor.constraint(equalTo: headerBand.bottomAnchor, constant: -ILMetrics.spaceMedium + 2),

            // Scroll view chạy dưới header để nội dung mờ xuyên qua kính; chiều cao header được áp
            // thành top content inset trong `viewDidLayoutSubviews`.
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            skeletonView.topAnchor.constraint(equalTo: headerBand.bottomAnchor),
            skeletonView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            skeletonView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            skeletonView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: ILMetrics.spaceMedium),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: ILMetrics.screenHorizontal),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -(ILMetrics.bottomNavHeight + ILMetrics.groupSpacing)),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -ILMetrics.screenHorizontal * 2)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILLibraryViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            quickAccessTapped: quickAccessTappedSubject.eraseToAnyPublisher(),
            searchTapped: searchTappedSubject.eraseToAnyPublisher(),
            featuredTapped: featuredTappedSubject.eraseToAnyPublisher(),
            deityTapped: deityTappedSubject.eraseToAnyPublisher(),
            deitiesViewAllTapped: deitiesViewAllTappedSubject.eraseToAnyPublisher(),
            sutrasViewAllTapped: sutrasViewAllTappedSubject.eraseToAnyPublisher(),
            itemTapped: itemTappedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        // No `.receive(on: DispatchQueue.main)`: state is already sent on main (MainActor default),
        // and deferring it renders the first state only after the appear transition has run.
        output.state
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        // Gửi sau khi đã subscribe ở trên, trong cùng 1 call đồng bộ — PassthroughSubject không
        // phát lại giá trị đã gửi trước khi có subscriber.
        viewDidLoadSubject.send(())
    }

    // MARK: - Render
    private func render(state: ViewState<ILLibraryStateModel>) {
        switch state {
        case .idle:
            break
        case .loading:
            skeletonView.setLoading(true)
        case .success(let model):
            skeletonView.setLoading(false)
            updateUI(with: model)
        case .failure:
            skeletonView.setLoading(false)
            // TODO: hiển thị ILStateView(.error) khi có API danh mục thật (Phase 3 của tasks.md).
            break
        }
    }

    private func updateUI(with model: ILLibraryStateModel) {
        quickAccessGrid.configure(tiles: model.quickAccess)

        if let featured = model.featured {
            featureCard.eyebrow = featured.eyebrow
            featureCard.title = featured.title
            featureCard.ctaTitle = featured.ctaTitle
            featureCard.isHidden = false
        } else {
            featureCard.isHidden = true
        }

        deitiesHeader.title = model.deitiesTitle
        deitiesHeader.trailingText = model.deitiesViewAllText
        deitiesCarousel.deities = model.deities
        deitiesCarousel.emptyText = model.deitiesEmptyText
        deitiesCarousel.isLoading = model.deitiesLoading

        listView.configure(with: model)
    }

    /// Đẩy nội dung xuống dưới header; lần layout đầu thì đặt offset ở đỉnh nội dung thay vì dưới header.
    private func applyHeaderInset() {
        let top = headerBand.bounds.height
        guard top > 0, scrollView.contentInset.top != top else { return }
        let wasAtTop = scrollView.contentOffset.y <= -scrollView.contentInset.top
        scrollView.contentInset.top = top
        scrollView.verticalScrollIndicatorInsets.top = top
        if wasAtTop { scrollView.contentOffset.y = -top }
    }
}
