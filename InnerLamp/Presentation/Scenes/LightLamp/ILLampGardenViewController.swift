//
//  ILLampGardenViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILLampGardenViewController: BaseViewController {

    // MARK: - Types
    private nonisolated enum Section: Hashable, Sendable { case main }

    // MARK: - Properties
    private let viewModel: ILLampGardenViewModel
    private var cancellables = Set<AnyCancellable>()
    private var dataSource: UICollectionViewDiffableDataSource<Section, String>?
    private var cardsByID: [String: ILLampGardenStateModel.Card] = [:]
    private var chipKinds: [ILLampKind?] = []
    private var showsMoreButton = false

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let lightTappedSubject = PassthroughSubject<Void, Never>()
    private let filterSelectedSubject = PassthroughSubject<ILLampKind?, Never>()
    private let loadMoreTappedSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    private lazy var headerBand: ILStickyHeaderBand = {
        let band = ILStickyHeaderBand()
        return band
    }()

    private lazy var headerView: ILNavBar = {
        let navBar = ILNavBar(
            title: "lightLamp.garden.title".localized,
            rightActionTitle: "lightLamp.garden.lightAction".localized
        )
        return navBar
    }()

    private lazy var chipScrollView: ILChipScrollView = {
        let scrollView = ILChipScrollView()
        return scrollView
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewCompositionalLayout { [weak self] _, environment in
            self?.makeSection(width: environment.container.effectiveContentSize.width)
        }
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.showsVerticalScrollIndicator = false
        collection.contentInsetAdjustmentBehavior = .never
        collection.register(ILLampCardView.self, forCellWithReuseIdentifier: ILLampCardView.reuseIdentifier)
        collection.register(
            ILLampGardenFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: ILLampGardenFooterView.reuseIdentifier
        )
        return collection
    }()

    private lazy var emptyStateView: ILStateView = {
        let view = ILStateView(
            kind: .empty,
            title: "lightLamp.garden.empty.title".localized,
            message: "lightLamp.garden.empty.message".localized
        )
        view.isHidden = true
        return view
    }()

    // MARK: - Initializer
    init(viewModel: ILLampGardenViewModel) {
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
        guard isMovingFromParent else { return }
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
        headerView.onAction = { [weak self] in self?.lightTappedSubject.send(()) }
        chipScrollView.onSelect = { [weak self] index in
            guard let self, self.chipKinds.indices.contains(index) else { return }
            self.filterSelectedSubject.send(self.chipKinds[index])
        }

        headerBand.addSubview(headerView)
        headerBand.addSubview(chipScrollView)
        headerBand.bind(to: collectionView)
        [collectionView, emptyStateView, headerBand].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        [headerView, chipScrollView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        configureDataSource()
    }

    override func setupConstraints() {
        super.setupConstraints()
        NSLayoutConstraint.activate([
            headerBand.topAnchor.constraint(equalTo: view.topAnchor),
            headerBand.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBand.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall / 2),
            headerView.leadingAnchor.constraint(equalTo: headerBand.leadingAnchor, constant: ILMetrics.screenHorizontal),
            headerView.trailingAnchor.constraint(equalTo: headerBand.trailingAnchor, constant: -ILMetrics.screenHorizontal),

            chipScrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: ILMetrics.rowSpacing),
            chipScrollView.leadingAnchor.constraint(equalTo: headerBand.leadingAnchor),
            chipScrollView.trailingAnchor.constraint(equalTo: headerBand.trailingAnchor),
            chipScrollView.bottomAnchor.constraint(equalTo: headerBand.bottomAnchor, constant: -ILMetrics.rowSpacing),

            // Grid runs under the glass header; its height is applied as top content inset in
            // `applyHeaderInset`.
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateView.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ILMetrics.screenHorizontal),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ILMetrics.screenHorizontal)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILLampGardenViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            lightTapped: lightTappedSubject.eraseToAnyPublisher(),
            filterSelected: filterSelectedSubject.eraseToAnyPublisher(),
            loadMoreTapped: loadMoreTappedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.state
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
    }

    /// Pushes the grid below the header; on the first layout the offset is set to the content top.
    private func applyHeaderInset() {
        let top = headerBand.bounds.height
        guard top > 0, collectionView.contentInset.top != top else { return }
        let wasAtTop = collectionView.contentOffset.y <= -collectionView.contentInset.top
        collectionView.contentInset.top = top
        collectionView.verticalScrollIndicatorInsets.top = top
        if wasAtTop { collectionView.contentOffset.y = -top }
    }

    // MARK: - Collection
    private func makeSection(width: CGFloat) -> NSCollectionLayoutSection {
        let spacing = ILMetrics.Lamp.gridSpacing
        let inset = ILMetrics.screenHorizontal
        let available = width - inset * 2
        // auto-fill like the design: as many columns as fit `cardMinWidth`.
        let columns = max(1, Int((available + spacing) / (ILMetrics.Lamp.cardMinWidth + spacing)))

        let item = NSCollectionLayoutItem(layoutSize: .init(
            widthDimension: .fractionalWidth(1.0 / CGFloat(columns)),
            heightDimension: .absolute(ILMetrics.Lamp.cardHeight)
        ))
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(ILMetrics.Lamp.cardHeight)),
            repeatingSubitem: item,
            count: columns
        )
        group.interItemSpacing = .fixed(spacing)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = spacing
        section.contentInsets = NSDirectionalEdgeInsets(
            top: ILMetrics.spaceStandard, leading: inset, bottom: ILMetrics.groupSpacing, trailing: inset
        )
        let footer = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(1)),
            elementKind: UICollectionView.elementKindSectionFooter,
            alignment: .bottom
        )
        section.boundarySupplementaryItems = [footer]
        return section
    }

    private func configureDataSource() {
        let source = UICollectionViewDiffableDataSource<Section, String>(collectionView: collectionView) {
            [weak self] collectionView, indexPath, id in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ILLampCardView.reuseIdentifier, for: indexPath
            ) as? ILLampCardView else { return UICollectionViewCell() }
            if let card = self?.cardsByID[id] {
                cell.configure(with: card)
            }
            return cell
        }
        source.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let footer = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind, withReuseIdentifier: ILLampGardenFooterView.reuseIdentifier, for: indexPath
            ) as? ILLampGardenFooterView else { return nil }
            footer.setVisible(self?.showsMoreButton ?? false)
            footer.onTap = { [weak self] in self?.loadMoreTappedSubject.send(()) }
            return footer
        }
        dataSource = source
    }

    // MARK: - Render
    private func render(state: ViewState<ILLampGardenStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILLampGardenStateModel) {
        headerView.subtitle = model.subtitle

        chipKinds = model.chips.map(\.kind)
        chipScrollView.configure(
            titles: model.chips.map { "\($0.title) · \($0.count)" },
            selectedIndex: model.chips.firstIndex(where: \.isSelected) ?? 0
        )

        emptyStateView.isHidden = !model.isEmpty
        collectionView.isHidden = model.isEmpty

        // Cards are keyed by id; only the ids that changed are inserted/removed (diffable data
        // source), so a "load more" appends rows without re-creating the visible ones.
        let previousIDs = dataSource?.snapshot().itemIdentifiers ?? []
        cardsByID = Dictionary(uniqueKeysWithValues: model.cards.map { ($0.id, $0) })
        let ids = model.cards.map(\.id)
        showsMoreButton = model.hasMore
        guard ids != previousIDs else {
            refreshFooter()
            return
        }
        var snapshot = NSDiffableDataSourceSnapshot<Section, String>()
        snapshot.appendSections([.main])
        snapshot.appendItems(ids)
        dataSource?.apply(snapshot, animatingDifferences: false) { [weak self] in
            self?.refreshFooter()
        }
    }

    private func refreshFooter() {
        let footers = collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionFooter)
        for case let footer as ILLampGardenFooterView in footers {
            footer.setVisible(showsMoreButton)
        }
    }
}

/// Footer of the garden grid holding "Xem thêm đèn"; collapses to zero height when there are no
/// more lamps.
private final class ILLampGardenFooterView: UICollectionReusableView {

    static let reuseIdentifier = "ILLampGardenFooterView"

    var onTap: (() -> Void)?

    private lazy var button: ILButton = {
        let button = ILButton(title: "lightLamp.garden.more".localized, variant: .ghost)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private var topConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        button.onTap = { [weak self] in self?.onTap?() }
        addSubview(button)
        let top = button.topAnchor.constraint(equalTo: topAnchor, constant: ILMetrics.spaceSmall)
        let height = button.heightAnchor.constraint(equalToConstant: ILMetrics.buttonHeight - 4)
        topConstraint = top
        heightConstraint = height
        NSLayoutConstraint.activate([
            top, height,
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setVisible(_ visible: Bool) {
        button.isHidden = !visible
        topConstraint?.constant = visible ? ILMetrics.spaceSmall : 0
        heightConstraint?.constant = visible ? ILMetrics.buttonHeight - 4 : 0
    }
}
