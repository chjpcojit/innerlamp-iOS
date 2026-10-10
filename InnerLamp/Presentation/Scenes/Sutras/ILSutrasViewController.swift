//
//  ILSutrasViewController.swift
//  InnerLamp
//

import UIKit
import Combine

/// Màn "Kinh sách" (`sutras` trong design handoff): header dán cố định gồm `ILNavBar`, ô tìm kiếm
/// gõ trực tiếp, 2 hàng chip lọc (mục đích/tông phái, độ dài), bên dưới là danh sách thẻ bộ kinh —
/// chạm 1 thẻ mở màn Chi tiết bài kinh.
final class ILSutrasViewController: BaseViewController {

    // MARK: - Layout
    private static let chipRowHeight: CGFloat = 36

    // MARK: - Properties
    private let viewModel: ILSutrasViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let categorySelectedSubject = PassthroughSubject<ILSutraCategory, Never>()
    private let lengthSelectedSubject = PassthroughSubject<ILSutraLengthFilter, Never>()
    private let queryChangedSubject = PassthroughSubject<String, Never>()
    private let sutraTappedSubject = PassthroughSubject<String, Never>()
    private let loadMoreTriggeredSubject = PassthroughSubject<Void, Never>()
    private var currentCategories: [ILSutrasFilterModel<ILSutraCategory>] = []
    private var currentLengths: [ILSutrasFilterModel<ILSutraLengthFilter>] = []

    // MARK: - UI Elements
    private let headerBand = ILStickyHeaderBand()
    private lazy var headerView = ILNavBar(showBack: true)
    private lazy var searchInput = ILSearchInputView(placeholder: "sutras.search.placeholder".localized)
    private let categoryChips = ILChipScrollView()
    private let lengthChips = ILChipScrollView()
    private let listView = ILSutrasListView()
    private let emptyStateView = ILStateView(kind: .empty)
    private let loadingView = ILSutrasSkeletonView()

    // MARK: - Initializer
    init(viewModel: ILSutrasViewModel) {
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
        headerBand.bind(to: listView.scrollView)

        headerView.title = "sutras.header.title".localized
        headerView.onBack = { [weak self] in self?.backTappedSubject.send(()) }

        searchInput.showsClearButton = true
        searchInput.onTextChanged = { [weak self] text in self?.queryChangedSubject.send(text) }

        categoryChips.onSelect = { [weak self] index in
            guard let self, self.currentCategories.indices.contains(index) else { return }
            self.categorySelectedSubject.send(self.currentCategories[index].value)
        }
        lengthChips.onSelect = { [weak self] index in
            guard let self, self.currentLengths.indices.contains(index) else { return }
            self.lengthSelectedSubject.send(self.currentLengths[index].value)
        }

        listView.onItemTap = { [weak self] item in self?.sutraTappedSubject.send(item.id) }
        listView.onLoadMore = { [weak self] in self?.loadMoreTriggeredSubject.send(()) }
        emptyStateView.isHidden = true
        loadingView.isHidden = true

        [headerView, searchInput, categoryChips, lengthChips].forEach(headerBand.addSubview)
        view.addSubview(listView)
        view.addSubview(emptyStateView)
        view.addSubview(loadingView)
        view.addSubview(headerBand)
    }

    override func setupConstraints() {
        super.setupConstraints()
        [
            headerBand, headerView, searchInput, categoryChips, lengthChips,
            listView, emptyStateView, loadingView
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let horizontal = ILMetrics.screenHorizontal

        NSLayoutConstraint.activate([
            headerBand.topAnchor.constraint(equalTo: view.topAnchor),
            headerBand.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBand.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall / 2),
            headerView.leadingAnchor.constraint(equalTo: headerBand.leadingAnchor, constant: horizontal),
            headerView.trailingAnchor.constraint(equalTo: headerBand.trailingAnchor, constant: -horizontal),

            searchInput.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: ILMetrics.rowSpacing),
            searchInput.leadingAnchor.constraint(equalTo: headerBand.leadingAnchor, constant: horizontal),
            searchInput.trailingAnchor.constraint(equalTo: headerBand.trailingAnchor, constant: -horizontal),

            categoryChips.topAnchor.constraint(equalTo: searchInput.bottomAnchor, constant: ILMetrics.rowSpacing),
            categoryChips.leadingAnchor.constraint(equalTo: headerBand.leadingAnchor),
            categoryChips.trailingAnchor.constraint(equalTo: headerBand.trailingAnchor),
            categoryChips.heightAnchor.constraint(equalToConstant: Self.chipRowHeight),

            lengthChips.topAnchor.constraint(equalTo: categoryChips.bottomAnchor, constant: ILMetrics.spaceSmall),
            lengthChips.leadingAnchor.constraint(equalTo: headerBand.leadingAnchor),
            lengthChips.trailingAnchor.constraint(equalTo: headerBand.trailingAnchor),
            lengthChips.heightAnchor.constraint(equalToConstant: Self.chipRowHeight),
            lengthChips.bottomAnchor.constraint(equalTo: headerBand.bottomAnchor, constant: -ILMetrics.rowSpacing),

            // Danh sách chạy dưới header để nội dung mờ xuyên qua kính; chiều cao header được áp
            // thành top content inset trong `viewDidLayoutSubviews`.
            listView.topAnchor.constraint(equalTo: view.topAnchor),
            listView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            listView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            listView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateView.topAnchor.constraint(equalTo: headerBand.bottomAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: listView.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: listView.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: listView.bottomAnchor),

            loadingView.topAnchor.constraint(equalTo: headerBand.bottomAnchor),
            loadingView.leadingAnchor.constraint(equalTo: listView.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: listView.trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: listView.bottomAnchor)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILSutrasViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            categorySelected: categorySelectedSubject.eraseToAnyPublisher(),
            lengthSelected: lengthSelectedSubject.eraseToAnyPublisher(),
            queryChanged: queryChangedSubject.eraseToAnyPublisher(),
            sutraTapped: sutraTappedSubject.eraseToAnyPublisher(),
            loadMoreTriggered: loadMoreTriggeredSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.state
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
    }

    // MARK: - Render
    private func render(state: ViewState<ILSutrasStateModel>) {
        let model: ILSutrasStateModel
        switch state {
        case .idle, .loading:
            return
        case .failure(let error):
            showError(error.localizedDescription)
            return
        case .success(let value):
            model = value
        }
        headerView.subtitle = model.subtitle

        currentCategories = model.categories
        categoryChips.configure(
            titles: model.categories.map(\.label),
            selectedIndex: model.categories.firstIndex(where: \.isSelected) ?? 0
        )
        currentLengths = model.lengths
        lengthChips.configure(
            titles: model.lengths.map(\.label),
            selectedIndex: model.lengths.firstIndex(where: \.isSelected) ?? 0
        )

        listView.countText = model.countText
        listView.items = model.items
        listView.footerState = Self.footerState(for: model)
        emptyStateView.title = model.emptyTitle
        emptyStateView.message = model.emptyMessage
        // While the first page is loading there are no rows yet: show the card skeleton instead of
        // flashing the empty state. The skeleton bars start pulsing once the view is in a window.
        let showsSkeleton = model.items.isEmpty && model.isLoadingMore
        let showsEmptyState = model.items.isEmpty && !model.isLoadingMore
        loadingView.isHidden = !showsSkeleton
        emptyStateView.isHidden = !showsEmptyState
        listView.isHidden = showsEmptyState || showsSkeleton
    }

    private static func footerState(for model: ILSutrasStateModel) -> ILLoadMoreFooterView.State {
        if model.isLoadingMore { return .loading }
        if !model.hasMore { return .end }
        return .hidden
    }

    /// Đẩy danh sách xuống dưới header; lần layout đầu thì đặt offset ở đỉnh nội dung thay vì dưới header.
    private func applyHeaderInset() {
        let scrollView = listView.scrollView
        let top = headerBand.bounds.height
        guard top > 0, scrollView.contentInset.top != top else { return }
        let wasAtTop = scrollView.contentOffset.y <= -scrollView.contentInset.top
        scrollView.contentInset.top = top
        scrollView.verticalScrollIndicatorInsets.top = top
        if wasAtTop { scrollView.contentOffset.y = -top }
    }
}
