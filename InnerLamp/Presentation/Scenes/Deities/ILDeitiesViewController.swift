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

    private let gridView = ILDeitiesGridView()

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

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.canvas

        headerView.title = "deities.header.title".localized
        headerView.onBack = { [weak self] in self?.backTappedSubject.send(()) }

        headerContainer.addSubview(headerView)
        headerContainer.addSubview(chipsScrollView)
        headerContainer.addSubview(headerDivider)

        chipsScrollView.addSubview(chipsStack)

        gridView.onItemTap = { [weak self] item in self?.deityTappedSubject.send(item.id) }

        view.addSubview(headerContainer)
        view.addSubview(gridView)
    }

    override func setupConstraints() {
        super.setupConstraints()
        [headerContainer, headerView, chipsScrollView, chipsStack, headerDivider, gridView].forEach {
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

            gridView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILDeitiesViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            filterSelected: filterSelectedSubject.eraseToAnyPublisher(),
            deityTapped: deityTappedSubject.eraseToAnyPublisher()
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
    private func render(state: ViewState<ILDeitiesStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILDeitiesStateModel) {
        headerView.subtitle = model.subtitle
        rebuildChips(model.filters)
        gridView.items = model.items
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
}
