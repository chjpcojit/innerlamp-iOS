//
//  ILSanghaViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILSanghaViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: ILSanghaViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let findSanghaTappedSubject = PassthroughSubject<Void, Never>()
    private let sitTogetherTappedSubject = PassthroughSubject<Void, Never>()
    private let composeTappedSubject = PassthroughSubject<Void, Never>()
    private let eventsTappedSubject = PassthroughSubject<Void, Never>()
    private let communityTappedSubject = PassthroughSubject<Void, Never>()
    private let postTappedSubject = PassthroughSubject<String, Never>()

    // MARK: - UI Elements
    private lazy var headerView = ILTabHeaderView(
        title: "sangha.title".localized,
        trailingText: "sangha.header.find".localized
    )

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

    private lazy var liveSessionCard = ILSanghaLiveSessionCardView()

    private lazy var composeChip = ILChip(label: "sangha.action.compose".localized)
    private lazy var eventsChip = ILChip(label: "sangha.action.events".localized)

    private lazy var quickActionsRow: UIStackView = {
        let row = UIStackView(arrangedSubviews: [composeChip, eventsChip, UIView()])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = ILMetrics.spaceSmall
        return row
    }()

    private lazy var communityHeader = ILSectionHeaderView(title: "sangha.section.community".localized)
    private lazy var communityCard = ILSanghaCommunityCardView()
    private lazy var postListView = ILSanghaPostListView()

    // MARK: - Initializer
    init(viewModel: ILSanghaViewModel) {
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

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.canvas

        [scrollView, headerView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        [liveSessionCard, quickActionsRow, communityHeader, communityCard, postListView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentStack.addArrangedSubview($0)
        }
        contentStack.setCustomSpacing(ILMetrics.spaceMedium + 2, after: liveSessionCard)
        contentStack.setCustomSpacing(ILMetrics.groupSpacing + 2, after: quickActionsRow)
        contentStack.setCustomSpacing(ILMetrics.spaceMedium - 2, after: communityHeader)
        contentStack.setCustomSpacing(ILMetrics.groupSpacing, after: communityCard)

        headerView.onTrailingTap = { [weak self] in self?.findSanghaTappedSubject.send(()) }
        liveSessionCard.onSitTogetherTapped = { [weak self] in self?.sitTogetherTappedSubject.send(()) }
        composeChip.onTap = { [weak self] in self?.composeTappedSubject.send(()) }
        eventsChip.onTap = { [weak self] in self?.eventsTappedSubject.send(()) }
        communityCard.onTap = { [weak self] in self?.communityTappedSubject.send(()) }
        postListView.onPostTapped = { [weak self] id in self?.postTappedSubject.send(id) }
    }

    override func setupConstraints() {
        super.setupConstraints()

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: ILMetrics.spaceMedium + 2),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: ILMetrics.screenHorizontal),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -(ILMetrics.bottomNavHeight + ILMetrics.groupSpacing)),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -ILMetrics.screenHorizontal * 2)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILSanghaViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            findSanghaTapped: findSanghaTappedSubject.eraseToAnyPublisher(),
            sitTogetherTapped: sitTogetherTappedSubject.eraseToAnyPublisher(),
            composeTapped: composeTappedSubject.eraseToAnyPublisher(),
            eventsTapped: eventsTappedSubject.eraseToAnyPublisher(),
            communityTapped: communityTappedSubject.eraseToAnyPublisher(),
            postTapped: postTappedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        // Gửi sau khi đã subscribe ở trên, trong cùng 1 call đồng bộ — PassthroughSubject không
        // phát lại giá trị đã gửi trước khi có subscriber.
        viewDidLoadSubject.send(())
    }

    // MARK: - Render
    private func render(state: ViewState<ILSanghaStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure:
            // TODO: hiển thị ILStateView(.error / .offline) khi có API đạo tràng thật.
            break
        }
    }

    private func updateUI(with model: ILSanghaStateModel) {
        if let live = model.liveSession {
            liveSessionCard.configure(with: live)
        }
        liveSessionCard.isHidden = model.liveSession == nil

        if let community = model.community {
            communityCard.configure(with: community)
        }
        communityHeader.isHidden = model.community == nil
        communityCard.isHidden = model.community == nil

        postListView.configure(posts: model.posts)
        postListView.isHidden = !model.hasPosts
    }
}
