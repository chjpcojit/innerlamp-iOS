//
//  ILBellViewController.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import UIKit
import Combine

final class ILBellViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: ILBellViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let presetSelectedSubject = PassthroughSubject<Int, Never>()
    private let modeSelectedSubject = PassthroughSubject<ILBellMode, Never>()
    private let everySelectedSubject = PassthroughSubject<Int, Never>()
    private let rateAdjustTappedSubject = PassthroughSubject<Int, Never>()
    private let padTappedSubject = PassthroughSubject<Void, Never>()
    private let toggleTappedSubject = PassthroughSubject<Void, Never>()
    private let leftButtonTappedSubject = PassthroughSubject<Void, Never>()
    private let ringBellTappedSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()

    private var lastMoCount: Int?
    private var lastBellCount: Int?
    /// Whether the static controls (preset chips, mode labels, every options) have been built —
    /// they don't change per strike, so they're only laid out once.
    private var hasBuiltStaticControls = false

    // MARK: - UI Elements
    private lazy var backgroundView = ILImmersiveBackgroundView()

    private lazy var headerView = ILNavBar()

    private let presetScrollView = UIScrollView()
    private let presetStack = UIStackView()
    private var presetChips: [ILBellChipView] = []

    private let modeSegmentedView = ILBellModeSegmentedView()

    private lazy var padView = ILBellPadView()

    private lazy var moCountLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.note
        label.textColor = ILColors.medInkSecondary
        label.textAlignment = .center
        return label
    }()

    private lazy var bellCountLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.note
        label.textColor = ILColors.medInkSecondary
        label.textAlignment = .center
        return label
    }()

    private lazy var countersStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [moCountLabel, bellCountLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 18
        return stack
    }()

    private lazy var middleStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [padView, countersStack])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = ILMetrics.spaceMedium
        return stack
    }()

    private lazy var rateCardView = ILBellRateCardView()
    private lazy var actionBarView = ILBellActionBarView()

    // MARK: - Initializer
    init(viewModel: ILBellViewModel) {
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
        // Immersive full-screen screen — hide the tab bar's bottom nav while shown.
        (tabBarController as? ILMainTabBarController)?.setBottomNavHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        (tabBarController as? ILMainTabBarController)?.setBottomNavHidden(false, animated: animated)
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.medBackgroundEdge

        view.addSubview(backgroundView)

        headerView.onBack = { [weak self] in self?.backTappedSubject.send(()) }
        view.addSubview(headerView)

        presetScrollView.showsHorizontalScrollIndicator = false
        presetScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(presetScrollView)

        presetStack.axis = .horizontal
        presetStack.alignment = .center
        presetStack.spacing = 8
        presetStack.translatesAutoresizingMaskIntoConstraints = false
        presetScrollView.addSubview(presetStack)

        modeSegmentedView.onSelect = { [weak self] index in
            self?.modeSelectedSubject.send(ILBellMode(rawValue: index) ?? .moAndBell)
        }
        view.addSubview(modeSegmentedView)

        padView.onTap = { [weak self] in self?.padTappedSubject.send(()) }
        view.addSubview(middleStack)

        rateCardView.onSlower = { [weak self] in self?.rateAdjustTappedSubject.send(-1) }
        rateCardView.onFaster = { [weak self] in self?.rateAdjustTappedSubject.send(1) }
        rateCardView.onEverySelected = { [weak self] index in self?.everySelectedSubject.send(index) }
        view.addSubview(rateCardView)

        actionBarView.onLeftTap = { [weak self] in self?.leftButtonTappedSubject.send(()) }
        actionBarView.onToggleTap = { [weak self] in self?.toggleTappedSubject.send(()) }
        actionBarView.onRingBellTap = { [weak self] in self?.ringBellTappedSubject.send(()) }
        view.addSubview(actionBarView)
    }

    override func setupConstraints() {
        super.setupConstraints()
        let horizontal = ILMetrics.immersiveHorizontal

        [backgroundView, headerView, modeSegmentedView, middleStack, rateCardView, actionBarView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        // Center the pad in the flexible middle region, but yield to the minimum-spacing constraints
        // on shorter screens so the layout never conflicts.
        let centerYConstraint = middleStack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: ILMetrics.spaceSmall)
        centerYConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            centerYConstraint,
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontal),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontal),

            presetScrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 18),
            presetScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            presetScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            presetStack.topAnchor.constraint(equalTo: presetScrollView.topAnchor),
            presetStack.leadingAnchor.constraint(equalTo: presetScrollView.leadingAnchor, constant: horizontal),
            presetStack.trailingAnchor.constraint(greaterThanOrEqualTo: presetScrollView.trailingAnchor, constant: -horizontal),
            presetStack.heightAnchor.constraint(equalTo: presetScrollView.heightAnchor),

            modeSegmentedView.topAnchor.constraint(equalTo: presetScrollView.bottomAnchor, constant: ILMetrics.spaceMedium),
            modeSegmentedView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontal),
            modeSegmentedView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontal),

            middleStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            middleStack.topAnchor.constraint(greaterThanOrEqualTo: modeSegmentedView.bottomAnchor, constant: ILMetrics.spaceMedium),

            rateCardView.topAnchor.constraint(greaterThanOrEqualTo: middleStack.bottomAnchor, constant: ILMetrics.spaceStandard),
            rateCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontal),
            rateCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontal),

            actionBarView.topAnchor.constraint(equalTo: rateCardView.bottomAnchor, constant: ILMetrics.spaceStandard),
            actionBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontal),
            actionBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontal),
            actionBarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -ILMetrics.spaceMedium)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILBellViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            presetSelected: presetSelectedSubject.eraseToAnyPublisher(),
            modeSelected: modeSelectedSubject.eraseToAnyPublisher(),
            everySelected: everySelectedSubject.eraseToAnyPublisher(),
            rateAdjustTapped: rateAdjustTappedSubject.eraseToAnyPublisher(),
            padTapped: padTappedSubject.eraseToAnyPublisher(),
            toggleTapped: toggleTappedSubject.eraseToAnyPublisher(),
            leftButtonTapped: leftButtonTappedSubject.eraseToAnyPublisher(),
            ringBellTapped: ringBellTappedSubject.eraseToAnyPublisher(),
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
    private func render(state: ViewState<ILBellStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILBellStateModel) {
        headerView.title = model.headerTitle
        headerView.subtitle = model.headerSubtitle

        if !hasBuiltStaticControls {
            buildStaticControls(with: model)
        }
        updateStaticSelection(with: model)

        rateCardView.rateLabelText = model.rateLabel
        rateCardView.rateValueText = model.rateValue

        padView.tagText = model.padTag
        padView.numberText = "\(model.padNumber)"
        padView.hintText = model.padHint
        padView.accessibilityLabel = "bell.pad.accessibility".localized
        padView.accessibilityValue = "\(model.padNumber)"

        moCountLabel.text = model.moCountText
        bellCountLabel.text = model.bellCountText

        actionBarView.leftTitle = model.leftButtonTitle
        actionBarView.ringBellTitle = model.ringBellTitle
        actionBarView.isRunning = model.isRunning

        replayStrikeFeedback(model)
    }

    /// Build the controls whose content never changes across state updates (they are only rebuilt
    /// once, so a strike doesn't reset the preset scroll position or flicker the segments).
    private func buildStaticControls(with model: ILBellStateModel) {
        presetChips = model.presetLabels.enumerated().map { index, label in
            let chip = ILBellChipView(label: label)
            chip.onTap = { [weak self] in self?.presetSelectedSubject.send(index) }
            return chip
        }
        presetChips.forEach { presetStack.addArrangedSubview($0) }

        modeSegmentedView.labels = model.modeLabels
        rateCardView.everyPromptText = "bell.every.label".localized
        rateCardView.everyLabels = model.everyOptionLabels

        hasBuiltStaticControls = true
    }

    private func updateStaticSelection(with model: ILBellStateModel) {
        for (index, chip) in presetChips.enumerated() {
            chip.isOn = index == model.selectedPresetIndex
        }
        modeSegmentedView.selectedIndex = model.selectedMode.rawValue
        rateCardView.selectedEveryIndex = model.selectedEveryIndex
        rateCardView.showEveryRow = model.showEveryRow
    }

    /// The state carries raw counters (not a transient event), so a strike is detected by a counter
    /// increase — mirroring how `ILMalaViewController` reacts to count changes.
    private func replayStrikeFeedback(_ model: ILBellStateModel) {
        if let lastMoCount, model.moCount > lastMoCount {
            padView.flashMo()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        if let lastBellCount, model.bellCount > lastBellCount {
            padView.flashBell()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        lastMoCount = model.moCount
        lastBellCount = model.bellCount
    }
}
