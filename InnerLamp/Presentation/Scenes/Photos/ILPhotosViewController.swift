//
//  ILPhotosViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILPhotosViewController: BaseViewController {

    // MARK: - Layout
    /// Chiều cao dải chip lọc (34px chip + 2px padding dưới theo design handoff).
    private static let chipRowHeight: CGFloat = 36

    // MARK: - Properties
    private let viewModel: ILPhotosViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let categorySelectedSubject = PassthroughSubject<ILPhotosCategory?, Never>()
    private let loadMoreTriggeredSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let photoSelectedSubject = PassthroughSubject<String, Never>()
    /// Chips currently built — they are rebuilt only when the selection changes, not on every paging update.
    private var renderedCategories: [ILPhotosCategoryModel] = []

    // MARK: - UI Elements
    private lazy var headerContainer: UIView = {
        let container = UIView()
        container.backgroundColor = ILColors.canvas
        return container
    }()

    private lazy var headerView = ILNavBar(showBack: true)

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

    private lazy var headerDivider: UIView = {
        let divider = UIView()
        divider.backgroundColor = ILColors.border
        return divider
    }()

    private lazy var masonryGrid = ILPhotosMasonryGridView()

    /// Shown over the grid during the first load (nothing to display yet) instead of the footer spinner.
    private lazy var skeletonView = ILPhotosSkeletonView()

    // MARK: - Initializer
    init(viewModel: ILPhotosViewModel) {
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
        // Pushing the photo viewer keeps the bottom nav hidden; only popping this screen restores it.
        guard isMovingFromParent else { return }
        (tabBarController as? ILMainTabBarController)?.setBottomNavHidden(false, animated: animated)
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.canvas

        headerView.title = "photos.header.title".localized
        headerView.onBack = { [weak self] in self?.backTappedSubject.send(()) }

        masonryGrid.onLoadMore = { [weak self] in self?.loadMoreTriggeredSubject.send(()) }
        masonryGrid.onPhotoTap = { [weak self] id in self?.photoSelectedSubject.send(id) }

        headerContainer.addSubview(headerView)
        headerContainer.addSubview(chipsScrollView)
        headerContainer.addSubview(headerDivider)

        chipsScrollView.addSubview(chipsStack)

        view.addSubview(headerContainer)
        view.addSubview(masonryGrid)
        view.addSubview(skeletonView)
        skeletonView.isHidden = true
    }

    override func setupConstraints() {
        super.setupConstraints()
        [headerContainer, headerView, chipsScrollView, chipsStack, headerDivider, masonryGrid, skeletonView].forEach {
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

            chipsScrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: ILMetrics.spaceMedium),
            chipsScrollView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            chipsScrollView.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            chipsScrollView.heightAnchor.constraint(equalToConstant: Self.chipRowHeight),

            chipsStack.topAnchor.constraint(equalTo: chipsScrollView.contentLayoutGuide.topAnchor),
            chipsStack.leadingAnchor.constraint(equalTo: chipsScrollView.contentLayoutGuide.leadingAnchor, constant: horizontal),
            chipsStack.trailingAnchor.constraint(equalTo: chipsScrollView.contentLayoutGuide.trailingAnchor, constant: -horizontal),
            chipsStack.bottomAnchor.constraint(equalTo: chipsScrollView.contentLayoutGuide.bottomAnchor),

            headerDivider.topAnchor.constraint(equalTo: chipsScrollView.bottomAnchor, constant: ILMetrics.rowSpacing),
            headerDivider.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            headerDivider.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            headerDivider.heightAnchor.constraint(equalToConstant: 1),
            headerDivider.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),

            masonryGrid.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            masonryGrid.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            masonryGrid.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            masonryGrid.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            skeletonView.topAnchor.constraint(equalTo: masonryGrid.topAnchor),
            skeletonView.leadingAnchor.constraint(equalTo: masonryGrid.leadingAnchor),
            skeletonView.trailingAnchor.constraint(equalTo: masonryGrid.trailingAnchor),
            skeletonView.bottomAnchor.constraint(equalTo: masonryGrid.bottomAnchor)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILPhotosViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            categorySelected: categorySelectedSubject.eraseToAnyPublisher(),
            loadMoreTriggered: loadMoreTriggeredSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            photoSelected: photoSelectedSubject.eraseToAnyPublisher()
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
    private func render(state: ViewState<ILPhotosStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILPhotosStateModel) {
        headerView.subtitle = model.subtitle
        if model.categories != renderedCategories {
            renderedCategories = model.categories
            rebuildChips(model.categories)
        }
        masonryGrid.photos = model.photos
        // First load (empty grid + request in flight): skeleton instead of the footer spinner.
        skeletonView.isHidden = !(model.photos.isEmpty && model.isLoadingMore)
        masonryGrid.footerState = skeletonView.isHidden ? footerState(for: model) : .hidden
    }

    private func footerState(for model: ILPhotosStateModel) -> ILLoadMoreFooterView.State {
        if model.isLoadingMore { return .loading }
        // Nothing to show an "end" for until at least one page arrived (or after a failed load).
        if !model.hasMore && !model.photos.isEmpty { return .end }
        return .hidden
    }

    private func rebuildChips(_ categories: [ILPhotosCategoryModel]) {
        chipsStack.arrangedSubviews.forEach {
            chipsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        for category in categories {
            let chip = ILChip(
                label: category.label,
                state: category.isSelected ? .selected : .normal
            )
            chip.onTap = { [weak self] in self?.categorySelectedSubject.send(category.category) }
            chipsStack.addArrangedSubview(chip)
        }
    }
}
