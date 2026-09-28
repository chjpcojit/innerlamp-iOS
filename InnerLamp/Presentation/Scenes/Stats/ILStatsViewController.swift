//
//  ILStatsViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILStatsViewController: BaseViewController {

    // MARK: - Constants
    private enum Layout {
        /// Gap between the sticky nav band and the first card (handoff `margin-top:18px`).
        static let contentTopSpacing: CGFloat = 18
        /// Gap between the nav bar and the bottom of its sticky band (handoff `padding-bottom:10px`).
        static let headerBottomSpacing: CGFloat = 10
    }

    // MARK: - Properties
    private let viewModel: ILStatsViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let reminderTappedSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    private lazy var headerBand: UIView = {
        let view = UIView()
        view.backgroundColor = ILColors.canvas
        return view
    }()

    private lazy var navBar = ILNavBar(
        title: "stats.header.title".localized,
        subtitle: "stats.header.subtitle".localized
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
        stack.spacing = ILMetrics.spaceMedium
        return stack
    }()

    private lazy var streakCard: ILStatHeroCardView = {
        let card = ILStatHeroCardView()
        card.eyebrow = "stats.streak.eyebrow".localized
        return card
    }()

    private lazy var tilesRow: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = ILMetrics.spaceSmall + 4
        return stack
    }()

    private lazy var weeklyChartCard = ILStatBarChartCardView()

    private lazy var mixCard: ILStatBreakdownCardView = {
        let card = ILStatBreakdownCardView()
        card.title = "stats.mix.title".localized
        return card
    }()

    private lazy var reminderCard: ILStatsReminderCardView = {
        let card = ILStatsReminderCardView()
        card.title = "stats.reminder.title".localized
        return card
    }()

    // MARK: - Initializer
    init(viewModel: ILStatsViewModel) {
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
        // Child screens hide the bottom navigation (per design handoff).
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

        // Scroll view first so the sticky header band stays on top of scrolled content.
        [scrollView, headerBand].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        navBar.translatesAutoresizingMaskIntoConstraints = false
        headerBand.addSubview(navBar)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        [streakCard, tilesRow, weeklyChartCard, mixCard, reminderCard].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentStack.addArrangedSubview($0)
        }

        navBar.onBack = { [weak self] in self?.backTappedSubject.send(()) }
        reminderCard.onTap = { [weak self] in self?.reminderTappedSubject.send(()) }
    }

    override func setupConstraints() {
        super.setupConstraints()

        NSLayoutConstraint.activate([
            headerBand.topAnchor.constraint(equalTo: view.topAnchor),
            headerBand.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBand.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall),
            navBar.leadingAnchor.constraint(equalTo: headerBand.leadingAnchor, constant: ILMetrics.screenHorizontal),
            navBar.trailingAnchor.constraint(equalTo: headerBand.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            navBar.bottomAnchor.constraint(equalTo: headerBand.bottomAnchor, constant: -Layout.headerBottomSpacing),

            scrollView.topAnchor.constraint(equalTo: headerBand.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: Layout.contentTopSpacing),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: ILMetrics.screenHorizontal),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -ILMetrics.screenPadding.bottom),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -ILMetrics.screenHorizontal * 2)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILStatsViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            reminderTapped: reminderTappedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        // No `.receive(on: DispatchQueue.main)`: state is already sent on main (MainActor default),
        // and deferring it renders the first state only after the appear transition has run.
        output.state
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        // Sent after subscribing above, in the same synchronous call — PassthroughSubject does not
        // replay values sent before a subscriber exists.
        viewDidLoadSubject.send(())
    }

    // MARK: - Render
    private func render(state: ViewState<ILStatsStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure:
            // TODO: show ILStateView(.error / .offline) once stats come from a real Repository.
            break
        }
    }

    private func updateUI(with model: ILStatsStateModel) {
        streakCard.valueText = model.streak.valueText
        streakCard.unitText = model.streak.unitText
        streakCard.note = model.streak.milestoneText ?? ""
        streakCard.progress = model.streak.milestoneText == nil ? nil : model.streak.milestoneProgress

        tilesRow.arrangedSubviews.forEach {
            tilesRow.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for tile in model.tiles {
            tilesRow.addArrangedSubview(makeTileView(tile))
        }
        tilesRow.isHidden = model.tiles.isEmpty

        if let chart = model.weeklyChart {
            weeklyChartCard.title = chart.title
            weeklyChartCard.trailingText = chart.averageText
            weeklyChartCard.startLabelText = chart.startLabel
            weeklyChartCard.endLabelText = chart.endLabel
            weeklyChartCard.bars = chart.bars.map { .init(heightRatio: $0.heightRatio, opacity: $0.opacity) }
        }
        weeklyChartCard.isHidden = model.weeklyChart == nil

        mixCard.items = model.mix.map {
            .init(name: $0.name, fraction: $0.fraction, valueText: $0.percentText, color: color(for: $0.kind))
        }
        mixCard.isHidden = !model.hasMix

        reminderCard.subtitle = model.reminderSubtitle
    }

    private func makeTileView(_ tile: ILStatsTileModel) -> ILStatTileView {
        let view = ILStatTileView()
        view.title = tile.title
        view.valueText = tile.valueText
        view.unitText = tile.unitText
        view.footnote = tile.footnote
        view.footnoteColor = tile.footnoteTone == .positive ? ILColors.greenText : ILColors.inkSubtle
        return view
    }

    /// Practice kind → accent color (handoff `mix` palette).
    private func color(for kind: ILStatsPracticeKind) -> UIColor {
        switch kind {
        case .breathMeditation: return ILColors.green
        case .chanting: return ILColors.gold
        case .recitation: return ILColors.rose
        case .dharmaTalk: return ILColors.inkFaint
        }
    }
}
