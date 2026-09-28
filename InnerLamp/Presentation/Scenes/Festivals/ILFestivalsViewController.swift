//
//  ILFestivalsViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILFestivalsViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: ILFestivalsViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let tabSelectedSubject = PassthroughSubject<ILFestivalsTab, Never>()
    private let hostTappedSubject = PassthroughSubject<String, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    private lazy var headerContainer: UIView = {
        let container = UIView()
        container.backgroundColor = ILColors.canvas
        return container
    }()

    private lazy var headerView = ILNavBar(title: "festivals.header.title".localized)

    private lazy var headerDivider: UIView = {
        let divider = UIView()
        divider.backgroundColor = ILColors.borderSoft
        return divider
    }()

    private lazy var allChip = ILChip(label: "festivals.tab.all".localized)
    private lazy var festivalsChip = ILChip(label: "festivals.tab.major".localized)
    private lazy var observancesChip = ILChip(label: "festivals.tab.observance".localized)

    private lazy var chipsRow: UIStackView = {
        let row = UIStackView(arrangedSubviews: [allChip, festivalsChip, observancesChip, UIView()])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = ILMetrics.spaceSmall
        return row
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
        stack.spacing = ILMetrics.groupSpacing + 2
        return stack
    }()

    private lazy var introLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Initializer
    init(viewModel: ILFestivalsViewModel) {
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
        (tabBarController as? ILMainTabBarController)?.setBottomNavHidden(false, animated: animated)
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.canvas

        headerView.onBack = { [weak self] in self?.backTappedSubject.send(()) }
        headerContainer.addSubview(headerView)
        headerContainer.addSubview(chipsRow)
        headerContainer.addSubview(headerDivider)

        [scrollView, headerContainer].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        introLabel.translatesAutoresizingMaskIntoConstraints = false
        introLabel.attributedText = ILTypography.makeParagraph(
            text: "festivals.intro".localized,
            font: ILTypography.note,
            color: ILColors.inkTertiary,
            cssLineHeight: 1.6
        )
        contentStack.addArrangedSubview(introLabel)

        allChip.onTap = { [weak self] in self?.tabSelectedSubject.send(.all) }
        festivalsChip.onTap = { [weak self] in self?.tabSelectedSubject.send(.festivals) }
        observancesChip.onTap = { [weak self] in self?.tabSelectedSubject.send(.observances) }
    }

    override func setupConstraints() {
        super.setupConstraints()
        [headerView, chipsRow, headerDivider].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            headerContainer.topAnchor.constraint(equalTo: view.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall / 2),
            headerView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: ILMetrics.screenHorizontal),
            headerView.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -ILMetrics.screenHorizontal),

            chipsRow.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 12),
            chipsRow.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: ILMetrics.screenHorizontal),
            chipsRow.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -ILMetrics.screenHorizontal),

            headerDivider.topAnchor.constraint(equalTo: chipsRow.bottomAnchor, constant: 12),
            headerDivider.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            headerDivider.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            headerDivider.heightAnchor.constraint(equalToConstant: 1),
            headerDivider.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 14),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: ILMetrics.screenHorizontal),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -ILMetrics.screenPadding.bottom),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -ILMetrics.screenHorizontal * 2)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILFestivalsViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            tabSelected: tabSelectedSubject.eraseToAnyPublisher(),
            hostTapped: hostTappedSubject.eraseToAnyPublisher(),
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
    private func render(state: ViewState<ILFestivalsStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILFestivalsStateModel) {
        headerView.subtitle = model.subtitle
        updateSelectedChip(model.selectedTab)
        rebuildMonths(model.months)
    }

    private func updateSelectedChip(_ tab: ILFestivalsTab) {
        allChip.chipState = tab == .all ? .selected : .normal
        festivalsChip.chipState = tab == .festivals ? .selected : .normal
        observancesChip.chipState = tab == .observances ? .selected : .normal
    }

    /// Dựng lại danh sách tháng (tiêu đề tháng + các thẻ ngày lễ). `introLabel` giữ nguyên ở đầu
    /// stack; các mục tháng được thêm sau nó và xoá khi render lại.
    private func rebuildMonths(_ months: [ILFestivalMonthModel]) {
        for subview in contentStack.arrangedSubviews where subview !== introLabel {
            contentStack.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }

        for month in months {
            contentStack.addArrangedSubview(makeMonthSection(month))
        }
    }

    /// 1 tháng = stack dọc (tiêu đề tháng + các thẻ ngày lễ).
    private func makeMonthSection(_ month: ILFestivalMonthModel) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = ILMetrics.spaceSmall

        let header = UILabel()
        header.font = ILTypography.scriptureBody
        header.textColor = ILColors.ink
        header.text = month.label
        stack.addArrangedSubview(header)
        stack.setCustomSpacing(ILMetrics.rowSpacing, after: header)

        for day in month.days {
            let item = ILFestivalsItemView()
            item.configure(with: day)
            item.onHostTap = { [weak self] id in self?.hostTappedSubject.send(id) }
            stack.addArrangedSubview(item)
        }
        return stack
    }
}
