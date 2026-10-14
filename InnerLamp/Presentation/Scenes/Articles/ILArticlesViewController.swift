//
//  ILArticlesViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILArticlesViewController: BaseViewController {

    // MARK: - Layout
    /// Distance from the bottom of the scroll content at which a load-more is triggered (design
    /// handoff: <120px).
    private static let loadMoreThreshold: CGFloat = 120

    // MARK: - Properties
    private let viewModel: ILArticlesViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let articleTappedSubject = PassthroughSubject<String, Never>()
    private let loadMoreTriggeredSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    private lazy var headerContainer: UIView = {
        let container = UIView()
        container.backgroundColor = ILColors.canvas
        return container
    }()

    private lazy var headerView: ILNavBar = {
        let navBar = ILNavBar(showBack: true)
        navBar.title = "articles.header.title".localized
        return navBar
    }()

    private lazy var headerDivider: UIView = {
        let divider = UIView()
        divider.backgroundColor = ILColors.border
        return divider
    }()

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var listView: ILArticlesListView = {
        let view = ILArticlesListView()
        return view
    }()

    // MARK: - Initializer
    init(viewModel: ILArticlesViewModel) {
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

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.canvas

        headerView.onBack = { [weak self] in self?.backTappedSubject.send(()) }

        headerContainer.addSubview(headerView)
        headerContainer.addSubview(headerDivider)

        scrollView.delegate = self
        view.addSubview(scrollView)

        scrollView.addSubview(contentView)

        listView.onArticleTap = { [weak self] article in
            self?.articleTappedSubject.send(article.id)
        }
        contentView.addSubview(listView)

        view.addSubview(headerContainer)
    }

    override func setupConstraints() {
        super.setupConstraints()
        [headerContainer, headerView, headerDivider, listView].forEach {
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

            headerDivider.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: ILMetrics.spaceMedium),
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

            listView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: ILMetrics.spaceStandard),
            listView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontal),
            listView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontal),
            listView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -ILMetrics.spaceLarge)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILArticlesViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            articleTapped: articleTappedSubject.eraseToAnyPublisher(),
            loadMoreTriggered: loadMoreTriggeredSubject.eraseToAnyPublisher()
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
    private func render(state: ViewState<ILArticlesStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILArticlesStateModel) {
        headerView.subtitle = model.subtitle
        listView.articles = model.articles
        listView.footerState = footerState(for: model)
    }

    private func footerState(for model: ILArticlesStateModel) -> ILLoadMoreFooterView.State {
        if model.isLoadingMore { return .loading }
        if !model.hasMore { return .end }
        return .hidden
    }
}

// MARK: - UIScrollViewDelegate
extension ILArticlesViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let distanceToBottom = scrollView.contentSize.height - (offsetY + scrollView.bounds.height)
        if distanceToBottom < Self.loadMoreThreshold {
            loadMoreTriggeredSubject.send(())
        }
    }
}
