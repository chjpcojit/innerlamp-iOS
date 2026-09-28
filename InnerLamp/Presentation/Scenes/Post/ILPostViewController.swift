//
//  ILPostViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILPostViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: ILPostViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let likeTappedSubject = PassthroughSubject<Void, Never>()
    private let shareTappedSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    private let headerContainer = UIView()

    private lazy var headerView = ILNavBar(showBack: true)

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private lazy var postCard = ILPostCardView()
    private lazy var commentList = ILPostCommentListView()
    private lazy var composerBar = ILPostComposerBarView()

    // MARK: - Initializer
    init(viewModel: ILPostViewModel) {
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

        headerContainer.backgroundColor = ILColors.canvas
        headerContainer.addSubview(headerView)

        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true

        postCard.onLikeTap = { [weak self] in self?.likeTappedSubject.send(()) }
        postCard.onShareTap = { [weak self] in self?.shareTappedSubject.send(()) }

        scrollView.addSubview(contentView)
        [postCard, commentList].forEach { contentView.addSubview($0) }

        view.addSubview(headerContainer)
        view.addSubview(scrollView)
        view.addSubview(composerBar)
    }

    override func setupConstraints() {
        super.setupConstraints()
        [
            headerContainer, headerView, scrollView, contentView,
            postCard, commentList, composerBar
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let horizontal = ILMetrics.screenHorizontal

        NSLayoutConstraint.activate([
            headerContainer.topAnchor.constraint(equalTo: view.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall / 2),
            headerView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: horizontal),
            headerView.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -horizontal),
            headerView.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -ILMetrics.spaceSmall),

            scrollView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: composerBar.topAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: horizontal),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -horizontal),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -horizontal * 2),

            postCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: ILMetrics.spaceStandard),
            postCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            postCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            commentList.topAnchor.constraint(equalTo: postCard.bottomAnchor, constant: ILMetrics.groupSpacing + 2),
            commentList.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            commentList.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            commentList.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -ILMetrics.spaceLarge),

            composerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontal),
            composerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontal),
            composerBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILPostViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            likeTapped: likeTappedSubject.eraseToAnyPublisher(),
            shareTapped: shareTappedSubject.eraseToAnyPublisher()
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
    private func render(state: ViewState<ILPostStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure:
            // TODO: hiển thị ILStateView(.error / .offline) khi có API bài đăng thật.
            break
        }
    }

    private func updateUI(with model: ILPostStateModel) {
        headerView.title = model.communityName
        headerView.subtitle = model.memberCountText

        postCard.configure(with: model)

        commentList.headerTitle = model.commentsHeaderText
        commentList.comments = model.comments
    }
}
