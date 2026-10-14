//
//  ILTalksViewController.swift
//  InnerLamp
//

import UIKit
import Combine

/// Màn "Pháp thoại" (danh sách): header dán cố định (`ILNavBar` + số bài + chip lọc Tất cả/Nghe/Xem/Đọc)
/// trên danh sách thẻ bài giảng — chạm 1 thẻ mở màn Pháp thoại.
final class ILTalksViewController: BaseViewController {

    // MARK: - Layout
    private static let chipRowHeight: CGFloat = 36

    // MARK: - Properties
    private let viewModel: ILTalksViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let filterSelectedSubject = PassthroughSubject<ILTalkFilter, Never>()
    private var currentFilters: [ILTalksFilterModel] = []
    private let talkTappedSubject = PassthroughSubject<String, Never>()

    // MARK: - UI Elements
    private lazy var headerBand: ILStickyHeaderBand = {
        let v = ILStickyHeaderBand()
        return v
    }()
    private lazy var headerView: ILNavBar = {
        let v = ILNavBar(showBack: true)
        return v
    }()
    private lazy var filterChips: ILChipScrollView = {
        let v = ILChipScrollView()
        return v
    }()
    private lazy var listView: ILTalksListView = {
        let v = ILTalksListView()
        return v
    }()
    private lazy var emptyStateView: ILStateView = {
        let v = ILStateView(kind: .empty)
        v.isHidden = true
        return v
    }()

    // MARK: - Initializer
    init(viewModel: ILTalksViewModel) {
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

        headerView.onBack = { [weak self] in self?.backTappedSubject.send(()) }
        filterChips.onSelect = { [weak self] index in
            guard let self, self.currentFilters.indices.contains(index) else { return }
            self.filterSelectedSubject.send(self.currentFilters[index].value)
        }
        listView.onItemTap = { [weak self] item in self?.talkTappedSubject.send(item.id) }

        [headerView, filterChips].forEach(headerBand.addSubview)
        view.addSubview(listView)
        view.addSubview(emptyStateView)
        view.addSubview(headerBand)
    }

    override func setupConstraints() {
        super.setupConstraints()
        [headerBand, headerView, filterChips, listView, emptyStateView]
            .forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let horizontal = ILMetrics.screenHorizontal

        NSLayoutConstraint.activate([
            headerBand.topAnchor.constraint(equalTo: view.topAnchor),
            headerBand.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBand.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall / 2),
            headerView.leadingAnchor.constraint(equalTo: headerBand.leadingAnchor, constant: horizontal),
            headerView.trailingAnchor.constraint(equalTo: headerBand.trailingAnchor, constant: -horizontal),

            filterChips.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: ILMetrics.rowSpacing),
            filterChips.leadingAnchor.constraint(equalTo: headerBand.leadingAnchor),
            filterChips.trailingAnchor.constraint(equalTo: headerBand.trailingAnchor),
            filterChips.heightAnchor.constraint(equalToConstant: Self.chipRowHeight),
            filterChips.bottomAnchor.constraint(equalTo: headerBand.bottomAnchor, constant: -ILMetrics.rowSpacing),

            // Danh sách chạy dưới header để nội dung mờ xuyên qua kính; chiều cao header được áp
            // thành top content inset trong `viewDidLayoutSubviews`.
            listView.topAnchor.constraint(equalTo: view.topAnchor),
            listView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            listView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            listView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateView.topAnchor.constraint(equalTo: headerBand.bottomAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: listView.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: listView.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: listView.bottomAnchor)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILTalksViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            filterSelected: filterSelectedSubject.eraseToAnyPublisher(),
            talkTapped: talkTappedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.state
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
    }

    // MARK: - Render
    private func render(state: ViewState<ILTalksStateModel>) {
        guard case .success(let model) = state else { return }
        headerView.title = model.headerTitle
        headerView.subtitle = model.subtitle

        currentFilters = model.filters
        filterChips.configure(
            titles: model.filters.map(\.label),
            selectedIndex: model.filters.firstIndex(where: \.isSelected) ?? 0
        )

        listView.items = model.items
        emptyStateView.title = model.emptyTitle
        emptyStateView.message = model.emptyMessage
        emptyStateView.isHidden = !model.items.isEmpty
        listView.isHidden = model.items.isEmpty
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
