//
//  ILMalaViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILMalaViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: ILMalaViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let beadAdvancedSubject = PassthroughSubject<Void, Never>()
    private let resetTappedSubject = PassthroughSubject<Void, Never>()
    private let goalSelectedSubject = PassthroughSubject<Int, Never>()
    private let continueTappedSubject = PassthroughSubject<Void, Never>()
    private let doneTappedSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()

    private var lastRenderedCount: Int?
    private var goalChips: [ILBellChipView] = []

    // MARK: - UI Elements
    private lazy var backgroundView = ILImmersiveBackgroundView()

    private lazy var particleView = ILMalaParticleView()

    private lazy var headerView = ILNavBar()

    private lazy var goalChipStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = ILMetrics.spaceSmall - 2
        return stack
    }()

    private lazy var progressBarView = ILMalaProgressBarView()

    private lazy var strandView = ILMalaStrandView()

    private lazy var mantraLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.scriptureTitle
        label.textColor = ILColors.medInk
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var actionBarView = ILImmersiveActionBarView()

    private lazy var lowerStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [mantraLabel, actionBarView])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = ILMetrics.spaceStandard
        stack.setCustomSpacing(ILMetrics.groupSpacing - 2, after: mantraLabel)
        return stack
    }()

    /// Popup "Tròn N biến" — phủ kín màn, ẩn cho tới khi đủ mục tiêu.
    private lazy var completionView: ILMalaCompletionView = {
        let view = ILMalaCompletionView()
        view.alpha = 0
        view.isHidden = true
        return view
    }()

    // MARK: - Initializer
    init(viewModel: ILMalaViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ilDebugLog("MALA viewWillAppear")
        navigationController?.setNavigationBarHidden(true, animated: animated)
        // Màn immersive phủ kín — thanh điều hướng đáy của tab bar chỉ che nút "Xong".
        (tabBarController as? ILMainTabBarController)?.setBottomNavHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ilDebugLog("MALA viewWillDisappear")
        (tabBarController as? ILMainTabBarController)?.setBottomNavHidden(false, animated: animated)
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.medBackgroundEdge

        view.addSubview(backgroundView)
        view.addSubview(particleView)

        headerView.onBack = { [weak self] in self?.backTappedSubject.send(()) }
        headerView.onAction = { [weak self] in self?.doneTappedSubject.send(()) }
        view.addSubview(headerView)

        view.addSubview(goalChipStack)
        view.addSubview(progressBarView)

        strandView.onAdvance = { [weak self] in self?.beadAdvancedSubject.send(()) }
        view.addSubview(strandView)

        actionBarView.onSecondaryTap = { [weak self] in self?.resetTappedSubject.send(()) }
        view.addSubview(lowerStack)

        completionView.onContinue = { [weak self] in self?.continueTappedSubject.send(()) }
        completionView.onDone = { [weak self] in self?.doneTappedSubject.send(()) }
        view.addSubview(completionView)
    }

    override func setupConstraints() {
        super.setupConstraints()
        [backgroundView, particleView, headerView, goalChipStack, progressBarView, strandView, lowerStack, completionView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        let horizontal = ILMetrics.immersiveHorizontal

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            particleView.topAnchor.constraint(equalTo: view.topAnchor),
            particleView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            particleView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            particleView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontal),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontal),

            goalChipStack.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: ILMetrics.spaceStandard + 2),
            goalChipStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            progressBarView.topAnchor.constraint(equalTo: goalChipStack.bottomAnchor, constant: ILMetrics.spaceMedium),
            progressBarView.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            strandView.topAnchor.constraint(equalTo: progressBarView.bottomAnchor, constant: ILMetrics.spaceMedium),
            strandView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontal),
            strandView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontal),
            strandView.bottomAnchor.constraint(equalTo: lowerStack.topAnchor, constant: -ILMetrics.spaceStandard),

            lowerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontal),
            lowerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontal),
            lowerStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -ILMetrics.spaceMedium),

            completionView.topAnchor.constraint(equalTo: view.topAnchor),
            completionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            completionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            completionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILMalaViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            beadAdvanced: beadAdvancedSubject.eraseToAnyPublisher(),
            resetTapped: resetTappedSubject.eraseToAnyPublisher(),
            goalSelected: goalSelectedSubject.eraseToAnyPublisher(),
            continueTapped: continueTappedSubject.eraseToAnyPublisher(),
            doneTapped: doneTappedSubject.eraseToAnyPublisher(),
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
    private func render(state: ViewState<ILMalaStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILMalaStateModel) {
        headerView.title = model.headerTitle
        headerView.subtitle = model.headerSubtitle
        headerView.rightActionTitle = model.doneTitle

        updateGoalChips(with: model.goalOptions)
        progressBarView.progress = model.goal > 0 ? Double(model.count) / Double(model.goal) : 0

        strandView.accessibilityLabel = model.strandAccessibilityLabel
        strandView.accessibilityValue = "\(model.count)"
        strandView.count = model.count

        mantraLabel.text = model.mantraText
        actionBarView.secondaryTitle = model.resetTitle

        completionView.title = model.completionTitle
        completionView.message = model.completionMessage
        completionView.continueTitle = model.continueTitle
        completionView.doneTitle = model.doneTitle
        setCompletionVisible(model.isRoundComplete)

        // A bead was counted (not a reset / new round): scatter sparks from the strand center —
        // a bigger burst on every mother bead (multiples of the strand's `motherInterval`).
        if let previous = lastRenderedCount, model.count == previous + 1 {
            burstParticles(big: model.count % strandView.motherInterval == 0)
        }

        if model.count != lastRenderedCount, let milestone = model.milestone {
            playFeedback(for: milestone)
        }
        lastRenderedCount = model.count
    }

    /// Haptic feedback per milestone: light on each quarter, "success" on a full round. The bead
    /// "click" and the completion bell are played by `ILMalaViewModel` via its audio service.
    private func playFeedback(for milestone: ILMalaMilestone) {
        switch milestone {
        case .quarter:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .roundComplete:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func burstParticles(big: Bool) {
        let strandCenter = strandView.convert(CGPoint(x: strandView.bounds.midX, y: strandView.bounds.midY), to: particleView)
        particleView.burst(at: strandCenter, big: big)
    }

    private func updateGoalChips(with options: [ILMalaStateModel.GoalOption]) {
        if goalChips.count != options.count {
            goalChips.forEach { $0.removeFromSuperview() }
            goalChips = options.map { option in
                let chip = ILBellChipView(font: ILTypography.captionMedium, horizontalPadding: ILMetrics.rowSpacing + 2)
                chip.onTap = { [weak self] in self?.goalSelectedSubject.send(option.value) }
                goalChipStack.addArrangedSubview(chip)
                return chip
            }
        }
        for (chip, option) in zip(goalChips, options) {
            chip.label = option.title
            chip.isOn = option.isSelected
        }
    }

    private func setCompletionVisible(_ isVisible: Bool) {
        guard completionView.isHidden == isVisible else { return }
        if isVisible {
            completionView.isHidden = false
            UIView.animate(withDuration: 0.25) { self.completionView.alpha = 1 }
            UIAccessibility.post(notification: .screenChanged, argument: completionView)
        } else {
            UIView.animate(withDuration: 0.2, animations: { self.completionView.alpha = 0 }) { _ in
                // A new round may have completed while fading out — only hide if still not visible.
                if self.completionView.alpha == 0 { self.completionView.isHidden = true }
            }
        }
    }
}
