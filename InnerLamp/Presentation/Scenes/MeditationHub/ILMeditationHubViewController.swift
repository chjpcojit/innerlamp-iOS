//
//  ILMeditationHubViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILMeditationHubViewController: BaseViewController {

    // MARK: - Constants
    private enum Layout {
        /// Khoảng cách từ dải header dán xuống nội dung (design `margin-top:16px`).
        static let contentTopSpacing: CGFloat = 16
        /// Khoảng cách giữa nav bar và segmented control (`margin-top:12px`).
        static let tabsTopSpacing: CGFloat = 12
        /// Khoảng cách từ segmented control xuống hairline đáy dải header (`padding-bottom:12px`).
        static let headerBottomSpacing: CGFloat = 12
        /// Khoảng cách giữa thẻ tổng quan và khối danh sách bên dưới (`margin-top:22px`).
        static let sectionTopSpacing: CGFloat = 22
    }

    // MARK: - Properties
    private let viewModel: ILMeditationHubViewModel
    private var cancellables = Set<AnyCancellable>()

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let tabSelectedSubject = PassthroughSubject<ILMeditationHubTabKind, Never>()
    private let presetTappedSubject = PassthroughSubject<String, Never>()
    private let customTimerTappedSubject = PassthroughSubject<Void, Never>()
    private let guidedTappedSubject = PassthroughSubject<String, Never>()
    private let downloadTappedSubject = PassthroughSubject<String, Never>()
    private let summaryTappedSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    private lazy var headerBand: UIView = {
        let view = UIView()
        view.backgroundColor = ILColors.canvas
        return view
    }()

    private lazy var navBar = ILNavBar()

    private lazy var tabSelector = ILMeditationHubTabSelectorView()

    private lazy var headerSeparator: UIView = {
        let view = UIView()
        view.backgroundColor = ILColors.borderSoft
        return view
    }()

    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        return scroll
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [summaryCard, timerSection, guidedSection])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = ILMetrics.groupSpacing
        stack.setCustomSpacing(Layout.sectionTopSpacing, after: summaryCard)
        return stack
    }()

    private lazy var summaryCard = ILHeatmapSummaryCardView(columns: 12)
    private lazy var timerSection = ILMeditationHubTimerSectionView()
    private lazy var guidedSection = ILMeditationHubGuidedSectionView()

    // MARK: - Initializer
    init(viewModel: ILMeditationHubViewModel) {
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
        // Màn con ẩn bottom nav theo design handoff (giống Stats/Settings/…).
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

        // Scroll view trước để dải header dán luôn nằm trên nội dung cuộn.
        [scrollView, headerBand].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        navBar.translatesAutoresizingMaskIntoConstraints = false
        headerBand.addSubview(navBar)

        tabSelector.translatesAutoresizingMaskIntoConstraints = false
        headerBand.addSubview(tabSelector)

        headerSeparator.translatesAutoresizingMaskIntoConstraints = false
        headerBand.addSubview(headerSeparator)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        navBar.onBack = { [weak self] in self?.backTappedSubject.send(()) }
        tabSelector.onSelect = { [weak self] kind in self?.tabSelectedSubject.send(kind) }
        timerSection.onPresetTapped = { [weak self] id in self?.presetTappedSubject.send(id) }
        timerSection.onCustomTimerTapped = { [weak self] in self?.customTimerTappedSubject.send(()) }
        guidedSection.onSessionTapped = { [weak self] id in self?.guidedTappedSubject.send(id) }
        guidedSection.onDownloadTapped = { [weak self] id in self?.downloadTappedSubject.send(id) }
        summaryCard.onTap = { [weak self] in self?.summaryTappedSubject.send(()) }
    }

    override func setupConstraints() {
        super.setupConstraints()
        let horizontal = ILMetrics.screenHorizontal

        NSLayoutConstraint.activate([
            headerBand.topAnchor.constraint(equalTo: view.topAnchor),
            headerBand.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBand.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall),
            navBar.leadingAnchor.constraint(equalTo: headerBand.leadingAnchor, constant: horizontal),
            navBar.trailingAnchor.constraint(equalTo: headerBand.trailingAnchor, constant: -horizontal),

            tabSelector.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: Layout.tabsTopSpacing),
            tabSelector.leadingAnchor.constraint(equalTo: headerBand.leadingAnchor, constant: horizontal),
            tabSelector.trailingAnchor.constraint(equalTo: headerBand.trailingAnchor, constant: -horizontal),

            headerSeparator.topAnchor.constraint(equalTo: tabSelector.bottomAnchor, constant: Layout.headerBottomSpacing),
            headerSeparator.leadingAnchor.constraint(equalTo: headerBand.leadingAnchor),
            headerSeparator.trailingAnchor.constraint(equalTo: headerBand.trailingAnchor),
            headerSeparator.heightAnchor.constraint(equalToConstant: 1),
            headerSeparator.bottomAnchor.constraint(equalTo: headerBand.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: headerBand.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: Layout.contentTopSpacing),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: horizontal),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -horizontal),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -ILMetrics.screenPadding.bottom),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -horizontal * 2)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILMeditationHubViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            tabSelected: tabSelectedSubject.eraseToAnyPublisher(),
            presetTapped: presetTappedSubject.eraseToAnyPublisher(),
            customTimerTapped: customTimerTappedSubject.eraseToAnyPublisher(),
            guidedTapped: guidedTappedSubject.eraseToAnyPublisher(),
            downloadTapped: downloadTappedSubject.eraseToAnyPublisher(),
            summaryTapped: summaryTappedSubject.eraseToAnyPublisher()
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
    private func render(state: ViewState<ILMeditationHubStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILMeditationHubStateModel) {
        navBar.title = model.headerTitle
        navBar.subtitle = model.headerSubtitle

        tabSelector.configure(tabs: model.tabs)

        if let summary = model.summary {
            summaryCard.valueText = summary.valueText
            summaryCard.unitText = summary.unitText
            summaryCard.noteText = summary.noteText
            summaryCard.startLabelText = summary.startLabel
            summaryCard.endLabelText = summary.endLabel
            summaryCard.accessibilityLabel = summary.accessibilityLabel
            summaryCard.configure(intensities: summary.intensities)
        }
        summaryCard.isHidden = model.summary == nil

        timerSection.configure(
            sectionTitle: model.timerSectionTitle,
            presets: model.presets,
            customTitle: model.customTimerTitle
        )
        timerSection.isHidden = !model.showsTimerSection

        guidedSection.configure(sectionTitle: model.guidedSectionTitle, sessions: model.guidedSessions)
        guidedSection.isHidden = !model.showsGuidedSection
    }
}
