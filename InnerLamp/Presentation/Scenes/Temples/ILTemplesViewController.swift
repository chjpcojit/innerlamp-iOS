//
//  ILTemplesViewController.swift
//  InnerLamp
//

import UIKit
import Combine

/// Màn "Tất cả chùa" (`temples` trong design handoff): header dán cố định gồm `ILNavBar` (phụ đề
/// "N ngôi chùa"), ô tìm kiếm và chip miền; bên dưới là danh sách thẻ chùa — chạm 1 thẻ mở Trang
/// chùa. Nút "Đề xuất" của prototype chưa có (xem TD-Temples-001).
final class ILTemplesViewController: BaseViewController {

    // MARK: - Layout
    private static let chipRowHeight: CGFloat = 36

    private enum ScreenState {
        case loading
        case list
        case empty
        case error
    }

    // MARK: - Properties
    private let viewModel: ILTemplesViewModel
    private var cancellables = Set<AnyCancellable>()
    private var rows: [ILTemplesRowModel] = []
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let queryChangedSubject = PassthroughSubject<String, Never>()
    private let regionSelectedSubject = PassthroughSubject<ILTempleFinderRegionFilter, Never>()
    private let templeTappedSubject = PassthroughSubject<String, Never>()
    private let retryTappedSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    private lazy var headerBand = ILStickyHeaderBand()
    private lazy var headerView = ILNavBar(title: "temples.header.title".localized, showBack: true)
    private lazy var searchInput = ILSearchInputView(placeholder: "temples.search.placeholder".localized)

    private lazy var chipsScrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.alwaysBounceHorizontal = false
        return scroll
    }()

    private lazy var chipsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = ILMetrics.spaceSmall
        stack.alignment = .center
        return stack
    }()

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = false
        table.keyboardDismissMode = .onDrag
        table.contentInsetAdjustmentBehavior = .never
        table.estimatedRowHeight = 108
        table.rowHeight = UITableView.automaticDimension
        table.dataSource = self
        table.delegate = self
        table.register(ILTemplesRowCell.self, forCellReuseIdentifier: ILTemplesRowCell.reuseIdentifier)
        return table
    }()

    private lazy var skeletonView: ILTempleFinderSkeletonView = {
        let v = ILTempleFinderSkeletonView()
        v.isHidden = true
        return v
    }()
    private lazy var emptyStateView: ILStateView = {
        let v = ILStateView(kind: .empty)
        v.isHidden = true
        return v
    }()
    private lazy var errorStateView = ILStateView(kind: .error)
    private lazy var retryButton = ILButton(title: "common.retry".localized, variant: .primary)
    private lazy var errorStack: UIStackView = {
        let v = UIStackView()
        v.axis = .vertical
        v.alignment = .fill
        v.spacing = ILMetrics.groupSpacing
        v.isHidden = true
        return v
    }()

    // MARK: - Initializer
    init(viewModel: ILTemplesViewModel) {
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

        headerView.onBack = { [weak self] in self?.backTappedSubject.send(()) }
        searchInput.onTextChanged = { [weak self] text in self?.queryChangedSubject.send(text) }

        headerBand.bind(to: tableView)
        [headerView, searchInput, chipsScrollView].forEach { headerBand.addSubview($0) }
        chipsScrollView.addSubview(chipsStack)


        retryButton.onTap = { [weak self] in self?.retryTappedSubject.send(()) }
        errorStack.addArrangedSubview(errorStateView)
        errorStack.addArrangedSubview(retryButton)

        view.addSubview(tableView)
        view.addSubview(skeletonView)
        view.addSubview(emptyStateView)
        view.addSubview(errorStack)
        view.addSubview(headerBand)
    }

    override func setupConstraints() {
        super.setupConstraints()
        [
            headerBand, headerView, searchInput, chipsScrollView, chipsStack,
            tableView, skeletonView, emptyStateView, errorStack
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let horizontal = ILMetrics.screenHorizontal

        NSLayoutConstraint.activate([
            headerBand.topAnchor.constraint(equalTo: view.topAnchor),
            headerBand.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBand.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall / 2),
            headerView.leadingAnchor.constraint(equalTo: headerBand.leadingAnchor, constant: horizontal),
            headerView.trailingAnchor.constraint(equalTo: headerBand.trailingAnchor, constant: -horizontal),

            searchInput.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: ILMetrics.spaceMedium),
            searchInput.leadingAnchor.constraint(equalTo: headerBand.leadingAnchor, constant: horizontal),
            searchInput.trailingAnchor.constraint(equalTo: headerBand.trailingAnchor, constant: -horizontal),
            searchInput.heightAnchor.constraint(equalToConstant: ILMetrics.inputHeight),

            chipsScrollView.topAnchor.constraint(equalTo: searchInput.bottomAnchor, constant: ILMetrics.spaceMedium),
            chipsScrollView.leadingAnchor.constraint(equalTo: headerBand.leadingAnchor),
            chipsScrollView.trailingAnchor.constraint(equalTo: headerBand.trailingAnchor),
            chipsScrollView.heightAnchor.constraint(equalToConstant: Self.chipRowHeight),
            chipsScrollView.bottomAnchor.constraint(equalTo: headerBand.bottomAnchor, constant: -ILMetrics.rowSpacing),

            chipsStack.topAnchor.constraint(equalTo: chipsScrollView.contentLayoutGuide.topAnchor),
            chipsStack.leadingAnchor.constraint(equalTo: chipsScrollView.contentLayoutGuide.leadingAnchor, constant: horizontal),
            chipsStack.trailingAnchor.constraint(equalTo: chipsScrollView.contentLayoutGuide.trailingAnchor, constant: -horizontal),
            chipsStack.bottomAnchor.constraint(equalTo: chipsScrollView.contentLayoutGuide.bottomAnchor),

            // Danh sách chạy dưới header; chiều cao header được áp thành top inset trong
            // `viewDidLayoutSubviews`.
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            skeletonView.topAnchor.constraint(equalTo: headerBand.bottomAnchor),
            skeletonView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            skeletonView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            skeletonView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateView.topAnchor.constraint(equalTo: headerBand.bottomAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            errorStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontal),
            errorStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontal)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILTemplesViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            queryChanged: queryChangedSubject.eraseToAnyPublisher(),
            regionSelected: regionSelectedSubject.eraseToAnyPublisher(),
            templeTapped: templeTappedSubject.eraseToAnyPublisher(),
            retryTapped: retryTappedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        // `emptyText` is bound first: `render` reads `emptyStateView` copy it has already set.
        output.emptyText
            .sink { [weak self] text in
                self?.emptyStateView.title = text?.title ?? ""
                self?.emptyStateView.message = text?.message ?? ""
            }
            .store(in: &cancellables)

        // No `.receive(on: DispatchQueue.main)`: state is already sent on main (MainActor default).
        output.state
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        output.filters
            .sink { [weak self] chips in self?.rebuildChips(chips) }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
    }

    // MARK: - Render
    private func render(state: ViewState<ILTemplesStateModel>) {
        switch state {
        case .idle:
            break
        case .loading:
            showScreenState(.loading)
        case .success(let model):
            headerView.subtitle = model.subtitle
            if model.rows != rows {
                rows = model.rows
                tableView.reloadData()
            }
            showScreenState(rows.isEmpty ? .empty : .list)
        case .failure(let error):
            configureErrorState(for: error)
            showScreenState(.error)
        }
    }

    private func showScreenState(_ screenState: ScreenState) {
        tableView.isHidden = screenState != .list
        emptyStateView.isHidden = screenState != .empty
        errorStack.isHidden = screenState != .error
        skeletonView.isHidden = screenState != .loading
    }

    /// Offline gets its own glyph/title; every other failure reads as a generic load error.
    private func configureErrorState(for error: Error) {
        if case ILCatalogError.offline = error {
            errorStateView.kind = .offline
            errorStateView.title = "temples.error.offlineTitle".localized
        } else {
            errorStateView.kind = .error
            errorStateView.title = "temples.error.title".localized
        }
        errorStateView.message = error.localizedDescription
    }

    private func rebuildChips(_ chips: [ILTempleFinderRegionChipModel]) {
        chipsStack.arrangedSubviews.forEach {
            chipsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for chip in chips {
            let view = ILChip(label: chip.label, state: chip.isSelected ? .selected : .normal)
            view.onTap = { [weak self] in self?.regionSelectedSubject.send(chip.filter) }
            chipsStack.addArrangedSubview(view)
        }
    }

    /// Đẩy danh sách xuống dưới header; lần layout đầu thì đặt offset ở đỉnh nội dung.
    private func applyHeaderInset() {
        let top = headerBand.bounds.height
        let bottom = ILMetrics.groupSpacing + ILMetrics.spaceStandard
        guard top > 0, tableView.contentInset.top != top else { return }
        let wasAtTop = tableView.contentOffset.y <= -tableView.contentInset.top
        tableView.contentInset = UIEdgeInsets(top: top + ILMetrics.spaceSmall, left: 0, bottom: bottom, right: 0)
        tableView.verticalScrollIndicatorInsets.top = top
        if wasAtTop { tableView.contentOffset.y = -tableView.contentInset.top }
    }
}

// MARK: - UITableViewDataSource
extension ILTemplesViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ILTemplesRowCell.reuseIdentifier, for: indexPath)
        (cell as? ILTemplesRowCell)?.configure(with: rows[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ILTemplesViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        templeTappedSubject.send(rows[indexPath.row].id)
    }
}
