//
//  ILEventsViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILEventsViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: ILEventsViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let tabSelectedSubject = PassthroughSubject<ILEventsTab, Never>()
    private let registerTappedSubject = PassthroughSubject<String, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()

    /// id sự kiện nổi bật đang hiển thị — dùng khi bấm "Ghi danh" ở thẻ hero.
    private var featuredEventId: String?

    // MARK: - UI Elements
    private lazy var headerContainer: UIView = {
        let container = UIView()
        container.backgroundColor = ILColors.canvas
        return container
    }()

    private lazy var headerView = ILNavBar(
        title: "events.header.title".localized,
        subtitle: "events.header.subtitle".localized
    )

    private lazy var headerDivider: UIView = {
        let divider = UIView()
        divider.backgroundColor = ILColors.border
        return divider
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

    private lazy var upcomingChip = ILChip(label: "events.tab.upcoming".localized)
    private lazy var coursesChip = ILChip(label: "events.tab.courses".localized)
    private lazy var registeredChip = ILChip(label: "events.tab.registered".localized)

    private lazy var chipsRow: UIStackView = {
        let row = UIStackView(arrangedSubviews: [upcomingChip, coursesChip, registeredChip, UIView()])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = ILMetrics.spaceSmall
        return row
    }()

    private lazy var heroCard = ILEventsHeroCardView()

    private lazy var sectionHeader = ILSectionHeaderView(title: "")

    private lazy var listStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = ILMetrics.rowSpacing
        return stack
    }()

    // MARK: - Initializer
    init(viewModel: ILEventsViewModel) {
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
        // Màn con không hiện thanh điều hướng đáy (theo design handoff) — che bar của tab.
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

        [scrollView, headerContainer].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        [chipsRow, heroCard, sectionHeader, listStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentStack.addArrangedSubview($0)
        }
        contentStack.setCustomSpacing(ILMetrics.groupSpacing - 2, after: chipsRow)
        contentStack.setCustomSpacing(ILMetrics.groupSpacing + 4, after: heroCard)
        contentStack.setCustomSpacing(ILMetrics.spaceMedium - 2, after: sectionHeader)

        upcomingChip.onTap = { [weak self] in self?.tabSelectedSubject.send(.upcoming) }
        coursesChip.onTap = { [weak self] in self?.tabSelectedSubject.send(.courses) }
        registeredChip.onTap = { [weak self] in self?.tabSelectedSubject.send(.registered) }
        heroCard.onRegister = { [weak self] in
            guard let id = self?.featuredEventId else { return }
            self?.registerTappedSubject.send(id)
        }
    }

    override func setupConstraints() {
        super.setupConstraints()
        [headerView, headerDivider].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            headerContainer.topAnchor.constraint(equalTo: view.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall / 2),
            headerView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: ILMetrics.screenHorizontal),
            headerView.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -ILMetrics.screenHorizontal),

            headerDivider.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: ILMetrics.rowSpacing),
            headerDivider.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            headerDivider.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            headerDivider.heightAnchor.constraint(equalToConstant: 1),
            headerDivider.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: ILMetrics.groupSpacing - 2),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: ILMetrics.screenHorizontal),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -ILMetrics.screenPadding.bottom),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -ILMetrics.screenHorizontal * 2)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILEventsViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            tabSelected: tabSelectedSubject.eraseToAnyPublisher(),
            registerTapped: registerTappedSubject.eraseToAnyPublisher(),
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

    // MARK: - Render
    private func render(state: ViewState<ILEventsStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILEventsStateModel) {
        updateSelectedChip(model.selectedTab)

        if let featured = model.featured {
            heroCard.configure(with: featured)
            featuredEventId = featured.id
            heroCard.isHidden = false
        } else {
            featuredEventId = nil
            heroCard.isHidden = true
        }

        sectionHeader.title = model.listTitle

        rebuildList(model.items)
    }

    private func updateSelectedChip(_ tab: ILEventsTab) {
        upcomingChip.chipState = tab == .upcoming ? .selected : .normal
        coursesChip.chipState = tab == .courses ? .selected : .normal
        registeredChip.chipState = tab == .registered ? .selected : .normal
    }

    private func rebuildList(_ items: [ILEventsListItemModel]) {
        listStack.arrangedSubviews.forEach {
            listStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        for item in items {
            let row = ILEventsListItemView()
            row.configure(with: item)
            row.onTap = { [weak self] in self?.registerTappedSubject.send(item.id) }
            listStack.addArrangedSubview(row)
        }
    }
}
