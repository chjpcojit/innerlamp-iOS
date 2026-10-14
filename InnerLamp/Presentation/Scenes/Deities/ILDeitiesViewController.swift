//
//  ILDeitiesViewController.swift
//  InnerLamp
//

import UIKit
import Combine

/// Màn danh sách "Chư Phật & Bồ Tát" (`buddhas` trong design handoff): header dán cố định gồm
/// `ILNavBar` + 3 chip lọc (Tất cả / Chư Phật / Bồ Tát), bên dưới là lưới 2 cột các thẻ
/// `ILDeitiesCardView` — chạm 1 thẻ mở màn chi tiết `Deity`.
final class ILDeitiesViewController: BaseViewController {

    // MARK: - Layout
    /// Chiều cao dải chip lọc (34px chip + 2px đệm dưới theo design handoff).
    private static let chipRowHeight: CGFloat = 36

    // MARK: - Properties
    private let viewModel: ILDeitiesViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let filterSelectedSubject = PassthroughSubject<ILDeityKind?, Never>()
    private let deityTappedSubject = PassthroughSubject<String, Never>()
    private let retryTappedSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    private lazy var headerBand: ILStickyHeaderBand = {
        let v = ILStickyHeaderBand()
        return v
    }()

    private lazy var headerView: ILNavBar = {
        let v = ILNavBar(showBack: true)
        v.title = "deities.header.title".localized
        return v
    }()

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

    private lazy var gridView: ILDeitiesGridView = {
        let v = ILDeitiesGridView()
        return v
    }()

    /// Full-area states under the header: loading skeleton, "Đang cập nhật" (no data) and load
    /// error (+ "Thử lại").
    private lazy var loadingView: ILDeitiesSkeletonView = {
        let v = ILDeitiesSkeletonView()
        v.isHidden = true
        return v
    }()
    private lazy var emptyStateView: ILStateView = {
        let v = ILStateView(kind: .empty)
        v.isHidden = true
        return v
    }()
    private lazy var errorStateView: ILStateView = {
        let v = ILStateView(kind: .error)
        return v
    }()
    private lazy var retryButton: ILButton = {
        let v = ILButton(title: "common.retry".localized, variant: .primary)
        return v
    }()
    private lazy var errorStack: UIStackView = {
        let v = UIStackView()
        v.axis = .vertical
        v.alignment = .fill
        v.spacing = ILMetrics.groupSpacing
        v.isHidden = true
        return v
    }()

    // MARK: - Initializer
    init(viewModel: ILDeitiesViewModel) {
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

        headerBand.bind(to: gridView.scrollView)
        headerBand.addSubview(headerView)
        headerBand.addSubview(chipsScrollView)

        chipsScrollView.addSubview(chipsStack)

        gridView.onItemTap = { [weak self] item in self?.deityTappedSubject.send(item.id) }

        retryButton.onTap = { [weak self] in self?.retryTappedSubject.send(()) }
        errorStack.addArrangedSubview(errorStateView)
        errorStack.addArrangedSubview(retryButton)

        view.addSubview(gridView)
        view.addSubview(loadingView)
        view.addSubview(emptyStateView)
        view.addSubview(errorStack)
        view.addSubview(headerBand)
    }

    override func setupConstraints() {
        super.setupConstraints()
        [
            headerBand, headerView, chipsScrollView, chipsStack, gridView,
            loadingView, emptyStateView, errorStack
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        let horizontal = ILMetrics.screenHorizontal

        NSLayoutConstraint.activate([
            headerBand.topAnchor.constraint(equalTo: view.topAnchor),
            headerBand.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBand.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall / 2),
            headerView.leadingAnchor.constraint(equalTo: headerBand.leadingAnchor, constant: horizontal),
            headerView.trailingAnchor.constraint(equalTo: headerBand.trailingAnchor, constant: -horizontal),

            chipsScrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: ILMetrics.spaceMedium),
            chipsScrollView.leadingAnchor.constraint(equalTo: headerBand.leadingAnchor),
            chipsScrollView.trailingAnchor.constraint(equalTo: headerBand.trailingAnchor),
            chipsScrollView.heightAnchor.constraint(equalToConstant: Self.chipRowHeight),

            chipsStack.topAnchor.constraint(equalTo: chipsScrollView.contentLayoutGuide.topAnchor),
            chipsStack.leadingAnchor.constraint(equalTo: chipsScrollView.contentLayoutGuide.leadingAnchor, constant: horizontal),
            chipsStack.trailingAnchor.constraint(equalTo: chipsScrollView.contentLayoutGuide.trailingAnchor, constant: -horizontal),
            chipsStack.bottomAnchor.constraint(equalTo: chipsScrollView.contentLayoutGuide.bottomAnchor),

            chipsScrollView.bottomAnchor.constraint(equalTo: headerBand.bottomAnchor, constant: -ILMetrics.rowSpacing),

            // Lưới chạy dưới header để nội dung mờ xuyên qua kính; chiều cao header được áp thành
            // top content inset trong `viewDidLayoutSubviews`.
            gridView.topAnchor.constraint(equalTo: view.topAnchor),
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingView.topAnchor.constraint(equalTo: headerBand.bottomAnchor),
            loadingView.leadingAnchor.constraint(equalTo: gridView.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: gridView.trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: gridView.bottomAnchor),

            emptyStateView.topAnchor.constraint(equalTo: headerBand.bottomAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: gridView.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: gridView.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: gridView.bottomAnchor),

            errorStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontal),
            errorStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontal)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILDeitiesViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            filterSelected: filterSelectedSubject.eraseToAnyPublisher(),
            deityTapped: deityTappedSubject.eraseToAnyPublisher(),
            retryTapped: retryTappedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        // No `.receive(on: DispatchQueue.main)`: state is already sent on main (MainActor default),
        // and deferring it renders the first state only after the appear transition has run.
        output.state
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        output.filters
            .sink { [weak self] filters in self?.rebuildChips(filters) }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
    }

    // MARK: - Render
    private enum ScreenState {
        case loading
        case content
        case empty
        case error
    }

    private func render(state: ViewState<ILDeitiesStateModel>) {
        switch state {
        case .idle:
            break
        case .loading:
            showScreenState(.loading)
        case .success(let model):
            updateUI(with: model)
            showScreenState(model.items.isEmpty ? .empty : .content)
        case .failure(let error):
            configureErrorState(for: error)
            showScreenState(.error)
        }
    }

    private func showScreenState(_ screenState: ScreenState) {
        gridView.isHidden = screenState != .content
        emptyStateView.isHidden = screenState != .empty
        errorStack.isHidden = screenState != .error
        // The skeleton bars start pulsing on their own once the view is in a window.
        loadingView.isHidden = screenState != .loading
    }

    /// Offline gets its own glyph/title; every other failure reads as a generic load error.
    private func configureErrorState(for error: Error) {
        if case ILCatalogError.offline = error {
            errorStateView.kind = .offline
            errorStateView.title = "deities.error.offlineTitle".localized
        } else {
            errorStateView.kind = .error
            errorStateView.title = "deities.error.title".localized
        }
        errorStateView.message = error.localizedDescription
    }

    private func updateUI(with model: ILDeitiesStateModel) {
        headerView.subtitle = model.subtitle
        gridView.items = model.items
        emptyStateView.title = model.emptyTitle
        emptyStateView.message = model.emptyMessage
    }

    private func rebuildChips(_ filters: [ILDeitiesFilterModel]) {
        chipsStack.arrangedSubviews.forEach {
            chipsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        for filter in filters {
            let chip = ILChip(
                label: filter.label,
                state: filter.isSelected ? .selected : .normal
            )
            chip.onTap = { [weak self] in self?.filterSelectedSubject.send(filter.kind) }
            chipsStack.addArrangedSubview(chip)
        }
    }

    /// Đẩy lưới xuống dưới header; lần layout đầu thì đặt offset ở đỉnh nội dung thay vì dưới header.
    private func applyHeaderInset() {
        let scrollView = gridView.scrollView
        let top = headerBand.bounds.height
        guard top > 0, scrollView.contentInset.top != top else { return }
        let wasAtTop = scrollView.contentOffset.y <= -scrollView.contentInset.top
        scrollView.contentInset.top = top
        scrollView.verticalScrollIndicatorInsets.top = top
        if wasAtTop { scrollView.contentOffset.y = -top }
    }
}
