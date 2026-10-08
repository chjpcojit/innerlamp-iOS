//
//  ILMemorialViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILMemorialViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: ILMemorialViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let addTappedSubject = PassthroughSubject<Void, Never>()
    private let itemTappedSubject = PassthroughSubject<String, Never>()
    private let familyTreeTappedSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    private lazy var headerContainer: UIView = {
        let container = UIView()
        container.backgroundColor = ILColors.canvas
        return container
    }()

    private lazy var headerView = ILNavBar(title: "memorial.list.title".localized)

    private lazy var headerDivider: UIView = {
        let divider = UIView()
        divider.backgroundColor = ILColors.borderSoft
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
        stack.spacing = ILMetrics.groupSpacing
        return stack
    }()

    private lazy var highlightCard = ILMemorialHighlightCardView()

    private lazy var sectionLabel: UILabel = {
        let label = UILabel()
        label.attributedText = ILTypography.makeEyebrow(text: "memorial.list.section".localized, color: ILColors.inkMuted)
        return label
    }()

    private lazy var rowsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = ILMetrics.rowSpacing
        return stack
    }()

    private lazy var listSection: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [highlightCard, sectionLabel, rowsStack])
        stack.axis = .vertical
        stack.spacing = ILMetrics.spaceMedium
        stack.setCustomSpacing(ILMetrics.spaceLarge - 4, after: highlightCard)
        stack.isHidden = true
        return stack
    }()

    private lazy var emptyStateView = ILMemorialEmptyView()

    /// Sticky bottom bar with the primary "Thêm người thân" button (design handoff) — always shown once loaded.
    private lazy var bottomBar: UIView = {
        let bar = UIView()
        bar.backgroundColor = ILColors.canvas
        bar.isHidden = true
        return bar
    }()

    private lazy var addButton = ILButton(title: "memorial.list.addPerson".localized, variant: .primary)

    private lazy var familyTreeButton = ILButton(title: "memorial.list.familyTree".localized, variant: .ghost)

    // MARK: - Initializer
    init(viewModel: ILMemorialViewModel) {
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
        // Màn con không hiện thanh điều hướng đáy (theo design handoff).
        (tabBarController as? ILMainTabBarController)?.setBottomNavHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pushing the form keeps the bar hidden; only restore it when this screen is popped.
        guard isMovingFromParent else { return }
        (tabBarController as? ILMainTabBarController)?.setBottomNavHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Keep the last content row clear of the sticky bar.
        let barInset = bottomBar.isHidden ? 0 : bottomBar.bounds.height
        if scrollView.contentInset.bottom != barInset {
            scrollView.contentInset.bottom = barInset
            scrollView.verticalScrollIndicatorInsets.bottom = barInset
        }
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.canvas

        headerView.onBack = { [weak self] in self?.backTappedSubject.send(()) }
        headerContainer.addSubview(headerView)
        headerContainer.addSubview(headerDivider)

        addButton.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(addButton)

        [scrollView, headerContainer, bottomBar].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        emptyStateView.isHidden = true
        addButton.onTap = { [weak self] in self?.addTappedSubject.send(()) }
        familyTreeButton.onTap = { [weak self] in self?.familyTreeTappedSubject.send(()) }
        emptyStateView.onFamilyTreeTap = { [weak self] in self?.familyTreeTappedSubject.send(()) }
        highlightCard.onTap = { [weak self] in
            guard let id = self?.currentHighlightID else { return }
            self?.itemTappedSubject.send(id)
        }

        [listSection, emptyStateView, familyTreeButton].forEach { contentStack.addArrangedSubview($0) }
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

            headerDivider.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 12),
            headerDivider.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            headerDivider.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            headerDivider.heightAnchor.constraint(equalToConstant: 1),
            headerDivider.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            addButton.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: ILMetrics.spaceMedium - 2),
            addButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: ILMetrics.screenHorizontal),
            addButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -ILMetrics.spaceSmall),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: ILMetrics.spaceMedium),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: ILMetrics.screenHorizontal),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -ILMetrics.screenPadding.bottom),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -ILMetrics.screenHorizontal * 2)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILMemorialViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            addTapped: addTappedSubject.eraseToAnyPublisher(),
            itemTapped: itemTappedSubject.eraseToAnyPublisher(),
            familyTreeTapped: familyTreeTappedSubject.eraseToAnyPublisher()
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
    private var currentHighlightID: String?
    private var lastConfirmation = ""

    private func render(state: ViewState<ILMemorialStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILMemorialStateModel) {
        headerView.subtitle = model.subtitle
        showConfirmationIfNeeded(model.bannerText)

        currentHighlightID = model.highlight?.id
        if let highlight = model.highlight {
            highlightCard.configure(with: highlight)
        }
        listSection.isHidden = model.highlight == nil
        emptyStateView.isHidden = !model.isEmpty
        familyTreeButton.isHidden = model.isEmpty
        bottomBar.isHidden = false
        view.setNeedsLayout()
        rebuildRows(model.rows)
    }

    /// Confirmation goes through the shared window-level toast, so it never re-lays out the list.
    /// `message` stays set for a while after being raised, so only show it once per value.
    private func showConfirmationIfNeeded(_ message: String) {
        defer { lastConfirmation = message }
        guard !message.isEmpty, message != lastConfirmation else { return }
        ILAlertPresenter.shared.show(.success(title: message, message: nil), from: self)
    }

    private func rebuildRows(_ rows: [ILMemorialRowModel]) {
        rowsStack.arrangedSubviews.forEach {
            rowsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for row in rows {
            let rowView = ILMemorialRowView(model: row)
            rowView.onTap = { [weak self] in self?.itemTappedSubject.send(row.id) }
            rowsStack.addArrangedSubview(rowView)
        }
    }
}
