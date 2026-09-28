//
//  ILMeditationSessionViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILMeditationSessionViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: ILMeditationSessionViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let playPauseTappedSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let endTappedSubject = PassthroughSubject<Void, Never>()

    /// Last breath direction/play state the ring was animated for — the state arrives every
    /// second, but the ring only needs a new animation when one of these changes.
    private var animatedBreathPhase: ILBreathPhase?
    private var animatedIsPlaying: Bool?

    // MARK: - UI Elements
    private lazy var backgroundView = ILImmersiveBackgroundView()

    private lazy var headerView = ILNavBar()

    private lazy var breathingRingView = ILBreathingRingView()

    private lazy var cueLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.scriptureBodyLarge
        label.textColor = ILColors.medInk
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var cueTranslationLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.hintItalic
        label.textColor = ILColors.medInkTertiary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var cueStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [cueLabel, cueTranslationLabel])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = ILMetrics.spaceSmall
        return stack
    }()

    private lazy var controlsView = ILImmersiveTransportControlsView()

    private lazy var endEarlyButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = ILColors.medInkSecondary
        config.contentInsets = NSDirectionalEdgeInsets(
            top: ILMetrics.spaceSmall, leading: ILMetrics.spaceSmall,
            bottom: ILMetrics.spaceSmall, trailing: ILMetrics.spaceSmall
        )
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = ILTypography.subhead
            return outgoing
        }
        return UIButton(configuration: config)
    }()

    // MARK: - Initializer
    init(viewModel: ILMeditationSessionViewModel) {
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
        // Keep the screen awake for the whole sit.
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.medBackgroundEdge

        view.addSubview(backgroundView)

        headerView.onBack = { [weak self] in self?.backTappedSubject.send(()) }
        view.addSubview(headerView)

        view.addSubview(breathingRingView)
        view.addSubview(cueStack)

        controlsView.onLeadingTap = { [weak self] in self?.backTappedSubject.send(()) }
        controlsView.onPrimaryTap = { [weak self] in self?.playPauseTappedSubject.send(()) }
        controlsView.onTrailingTap = { [weak self] in self?.endTappedSubject.send(()) }
        view.addSubview(controlsView)

        endEarlyButton.addTarget(self, action: #selector(handleEndEarlyTap), for: .touchUpInside)
        view.addSubview(endEarlyButton)
    }

    override func setupConstraints() {
        super.setupConstraints()
        [backgroundView, headerView, breathingRingView, cueStack, controlsView, endEarlyButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        let horizontal = ILMetrics.immersiveHorizontal

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontal),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontal),

            breathingRingView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: ILMetrics.spaceLarge),
            breathingRingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            cueStack.topAnchor.constraint(equalTo: breathingRingView.bottomAnchor, constant: ILMetrics.immersiveCueSpacing),
            cueStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontal),
            cueStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontal),
            cueStack.bottomAnchor.constraint(lessThanOrEqualTo: controlsView.topAnchor, constant: -ILMetrics.spaceStandard),

            controlsView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            controlsView.bottomAnchor.constraint(equalTo: endEarlyButton.topAnchor, constant: -(ILMetrics.groupSpacing - ILMetrics.spaceSmall)),

            endEarlyButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            endEarlyButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -ILMetrics.spaceSmall)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILMeditationSessionViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            playPauseTapped: playPauseTappedSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            endTapped: endTappedSubject.eraseToAnyPublisher()
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
    private func render(state: ViewState<ILMeditationSessionStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILMeditationSessionStateModel) {
        headerView.title = model.headerTitle
        headerView.subtitle = model.headerSubtitle

        breathingRingView.timerText = model.timerText
        breathingRingView.captionText = model.timerCaption

        cueLabel.text = model.cueText
        cueTranslationLabel.text = model.cueTranslation
        cueStack.isHidden = model.cueText.isEmpty

        controlsView.isPlaying = model.isPlaying
        controlsView.pauseAccessibilityLabel = model.pauseAccessibilityLabel
        controlsView.playAccessibilityLabel = model.resumeAccessibilityLabel
        controlsView.leadingAccessibilityLabel = model.exitAccessibilityLabel
        controlsView.trailingAccessibilityLabel = model.endAccessibilityLabel

        endEarlyButton.configuration?.title = model.endEarlyTitle

        updateBreathing(with: model)
    }

    private func updateBreathing(with model: ILMeditationSessionStateModel) {
        guard model.breathPhase != animatedBreathPhase || model.isPlaying != animatedIsPlaying else { return }
        animatedBreathPhase = model.breathPhase
        animatedIsPlaying = model.isPlaying

        if model.isPlaying {
            breathingRingView.animateBreath(
                expanded: model.breathPhase == .inhale,
                duration: TimeInterval(model.secondsLeftInBreathPhase)
            )
        } else {
            breathingRingView.pauseBreath()
        }
    }

    // MARK: - Actions
    @objc private func handleEndEarlyTap() {
        endTappedSubject.send(())
    }
}
