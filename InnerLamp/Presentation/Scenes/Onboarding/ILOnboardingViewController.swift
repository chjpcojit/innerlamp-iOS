//
//  ILOnboardingViewController.swift
//  InnerLamp
//
//  Created by ChjpCoj on 12/9/26.
//

import UIKit
import Combine

final class ILOnboardingViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: ILOnboardingViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let nextTriggerSubject = PassthroughSubject<Void, Never>()
    private let backTriggerSubject = PassthroughSubject<Void, Never>()
    private let skipTriggerSubject = PassthroughSubject<Void, Never>()
    private let toggleItemSubject = PassthroughSubject<(stepIndex: Int, itemIndex: Int), Never>()

    /// Set right before sending `nextTrigger`/`backTrigger` from a completed interactive swipe —
    /// the swipe already animated the crossfade by hand (`UIViewPropertyAnimator`), so the
    /// `output.state` sink must render that particular update without re-animating it.
    private var suppressNextRenderAnimation = false

    // MARK: - UI Elements
    private let backgroundGradientLayer = CAGradientLayer()
    private let topGlowGradientLayer = CAGradientLayer()

    private lazy var topGlowCircle: UIView = {
        // radial-gradient(circle, rgba(217,150,60,.20), transparent 62%)
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        topGlowGradientLayer.type = .radial
        topGlowGradientLayer.colors = [
            ILColors.goldGlow.cgColor,
            ILColors.goldGlowClear.cgColor
        ]
        topGlowGradientLayer.locations = [0.0, 0.62]
        topGlowGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        topGlowGradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        view.layer.addSublayer(topGlowGradientLayer)
        return view
    }()

    private lazy var topBar: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// `IL-Logo` 32px ở thanh trên (design `isOnb`), kèm wordmark bên cạnh.
    private let logoIcon = ILLogoView(size: 32)

    private lazy var logoLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.logoMark
        label.textColor = ILColors.ink
        label.attributedText = ILTypography.makeAttributedString(
            text: "onboarding.wordmark".localized,
            font: ILTypography.logoMark,
            color: ILColors.ink,
            letterSpacingEm: 0.2
        )
        return label
    }()

    private lazy var logoStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [logoIcon, logoLabel])
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var skipButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("onboarding.skip".localized, for: .normal)
        button.titleLabel?.font = ILTypography.bodySmall
        button.setTitleColor(ILColors.inkSubtle, for: .normal)
        return button
    }()

    private lazy var progressBar: ILStepProgressBar = {
        let bar = ILStepProgressBar(numberOfSteps: viewModel.state.totalSteps)
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }()

    private lazy var stepContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// Built once from `viewModel.state.steps` — số lượng/loại step hoàn toàn động,
    /// thêm step mới không đòi hỏi sửa property hay constraint nào ở đây.
    private lazy var stepViews: [UIView] = viewModel.state.steps.enumerated().map { index, content in
        let stepView = makeStepView(for: content, stepIndex: index)
        stepView.translatesAutoresizingMaskIntoConstraints = false
        return stepView
    }

    private lazy var bottomArea: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var nextButton: ILButton = {
        let button = ILButton(title: "onboarding.cta.start".localized, variant: .primary)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("onboarding.back.toLogin".localized, for: .normal)
        button.titleLabel?.font = ILTypography.bodySmall
        button.setTitleColor(ILColors.inkMuted, for: .normal)
        return button
    }()

    private lazy var bottomStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [nextButton, backButton])
        stack.axis = .vertical
        stack.spacing = 14
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Swipe Transition State
    private let stepPanGesture = UIPanGestureRecognizer()
    private var stepTransitionAnimator: UIViewPropertyAnimator?
    private var interactiveDirection: Int? // +1 = forward (next), -1 = back, 0 = out-of-range (ignored)
    private var interactiveFromStep = 0
    private var interactiveToStep = 0
    private var currentStep = 0

    // MARK: - Initializer
    init(viewModel: ILOnboardingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradientLayer.frame = view.bounds
        topGlowGradientLayer.frame = topGlowCircle.bounds
    }

    private func applyColorAppearanceChange() {
        // Giống Splash: CAGradientLayer.colors không tự đảo theo trait, canvasWarm/
        // canvasWarmEnd2 giờ có biến thể dark nên phải set lại thủ công. topGlow (vàng)
        // bất biến theo theme, không cần refresh.
        backgroundGradientLayer.colors = [
            ILColors.canvasWarm.cgColor,
            ILColors.canvasWarmEnd2.cgColor
        ]
    }

    override func setupViews() {
        super.setupViews()
        navigationController?.setNavigationBarHidden(true, animated: false)

        // Background Gradient
        backgroundGradientLayer.colors = [
            ILColors.canvasWarm.cgColor,
            ILColors.canvasWarmEnd2.cgColor
        ]
        backgroundGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        backgroundGradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        view.layer.insertSublayer(backgroundGradientLayer, at: 0)

        view.addSubview(topGlowCircle)

        topBar.addSubview(logoStack)
        topBar.addSubview(skipButton)
        skipButton.addTarget(self, action: #selector(handleSkipTapped), for: .touchUpInside)
        view.addSubview(topBar)

        view.addSubview(progressBar)

        stepViews.forEach { stepContainerView.addSubview($0) }
        view.addSubview(stepContainerView)

        stepPanGesture.addTarget(self, action: #selector(handleStepPan(_:)))
        stepPanGesture.delegate = self
        stepContainerView.addGestureRecognizer(stepPanGesture)

        nextButton.onTap = { [weak self] in
            self?.handleNextTapped()
        }
        backButton.addTarget(self, action: #selector(handleBackTapped), for: .touchUpInside)

        bottomArea.addSubview(bottomStack)
        view.addSubview(bottomArea)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILOnboardingViewController, _) in
            view.applyColorAppearanceChange()
        }
    }

    /// Tạo view cho 1 step theo nội dung của nó và móc callback toggle (nếu có) về
    /// `toggleItemSubject` — không cần biết step này là step mấy hay onboarding có tổng cộng
    /// bao nhiêu step.
    private func makeStepView(for content: ILOnboardingStepContent, stepIndex: Int) -> UIView {
        switch content {
        case .intro:
            return ILOnboardingIntroStepView()

        case .chipChoice:
            let view = ILOnboardingChoiceStepView()
            view.onToggleItem = { [weak self] itemIndex in
                self?.toggleItemSubject.send((stepIndex: stepIndex, itemIndex: itemIndex))
            }
            return view

        case .toggleList:
            let view = ILOnboardingToggleListStepView()
            view.onToggleItem = { [weak self] itemIndex in
                self?.toggleItemSubject.send((stepIndex: stepIndex, itemIndex: itemIndex))
            }
            return view
        }
    }

    override func setupConstraints() {
        super.setupConstraints()

        NSLayoutConstraint.activate([
            // Top Glow
            topGlowCircle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            topGlowCircle.topAnchor.constraint(equalTo: view.topAnchor, constant: -120),
            topGlowCircle.widthAnchor.constraint(equalToConstant: 420),
            topGlowCircle.heightAnchor.constraint(equalToConstant: 420),

            // Top Bar
            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 26),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -26),
            topBar.heightAnchor.constraint(equalToConstant: 32),

            logoIcon.leadingAnchor.constraint(equalTo: topBar.leadingAnchor),
            logoIcon.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),

            skipButton.trailingAnchor.constraint(equalTo: topBar.trailingAnchor),
            skipButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),

            // Progress Bar
            progressBar.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 22),
            progressBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 26),
            progressBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -26),

            // Step Container
            stepContainerView.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 16),
            stepContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 26),
            stepContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -26),
            stepContainerView.bottomAnchor.constraint(equalTo: bottomArea.topAnchor, constant: -16),

            // Bottom Area
            bottomArea.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 26),
            bottomArea.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -26),
            bottomArea.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
            // nextButton height is owned by ILButton (ILMetrics.buttonHeight) — don't re-pin here.
        ])

        // Step Views Pinning — 1 view mới trong `stepViews` tự động được pin, không cần sửa gì ở đây.
        NSLayoutConstraint.activate(stepViews.flatMap { stepView in
            [
                stepView.leadingAnchor.constraint(equalTo: stepContainerView.leadingAnchor),
                stepView.trailingAnchor.constraint(equalTo: stepContainerView.trailingAnchor),
                stepView.topAnchor.constraint(equalTo: stepContainerView.topAnchor),
                stepView.bottomAnchor.constraint(equalTo: stepContainerView.bottomAnchor)
            ]
        })

        NSLayoutConstraint.activate([
            bottomStack.leadingAnchor.constraint(equalTo: bottomArea.leadingAnchor),
            bottomStack.trailingAnchor.constraint(equalTo: bottomArea.trailingAnchor),
            bottomStack.topAnchor.constraint(equalTo: bottomArea.topAnchor),
            bottomStack.bottomAnchor.constraint(equalTo: bottomArea.bottomAnchor)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILOnboardingViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            nextTrigger: nextTriggerSubject.eraseToAnyPublisher(),
            backTrigger: backTriggerSubject.eraseToAnyPublisher(),
            skipTrigger: skipTriggerSubject.eraseToAnyPublisher(),
            toggleItem: toggleItemSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        // No `.receive(on: DispatchQueue.main)`: state is already sent on main (MainActor default),
        // and deferring it renders the first state only after the appear transition has run.
        output.state
            .sink { [weak self] state in
                guard let self else { return }
                let shouldAnimate = !self.suppressNextRenderAnimation
                self.suppressNextRenderAnimation = false
                self.render(state: state, animateStepChange: shouldAnimate)
            }
            .store(in: &cancellables)

        // Send after subscribing above, in the same synchronous call — PassthroughSubject
        // doesn't replay values sent before a subscriber attaches.
        viewDidLoadSubject.send(())
    }

    // MARK: - Render
    private func render(state: ViewState<ILOnboardingStateModel>, animateStepChange: Bool = true) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model, animateStepChange: animateStepChange)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILOnboardingStateModel, animateStepChange: Bool = true) {
        currentStep = model.currentStep
        progressBar.currentStep = model.currentStep
        nextButton.title = model.ctaTitle
        backButton.setTitle(model.backTitle, for: .normal)

        for (index, content) in model.steps.enumerated() {
            configureStepView(stepViews[index], with: content)
        }

        if animateStepChange {
            crossFadeToStep(model.currentStep)
        }
    }

    private func configureStepView(_ view: UIView, with content: ILOnboardingStepContent) {
        switch content {
        case .intro:
            break

        case .chipChoice(let title, let subtitle, let items):
            (view as? ILOnboardingChoiceStepView)?.configure(
                title: title,
                subtitle: subtitle,
                items: items.map { (label: $0.label, isSelected: $0.isSelected) }
            )

        case .toggleList(let title, let subtitle, let items):
            (view as? ILOnboardingToggleListStepView)?.configure(
                title: title,
                subtitle: subtitle,
                items: items.map { (title: $0.label, sub: $0.sub, isOn: $0.isEnabled) }
            )
        }
    }

    private func crossFadeToStep(_ step: Int) {
        let views = stepViews

        // Unhide the incoming view up front so it's actually in the hierarchy to fade in —
        // `isHidden` isn't animatable, so flipping it inside the animation block just snaps.
        views[step].isHidden = false

        UIView.animate(
            withDuration: 0.28,
            delay: 0,
            options: .curveEaseInOut,
            animations: {
                for (index, view) in views.enumerated() {
                    view.alpha = index == step ? 1 : 0
                    view.isHidden = index != 0
                }
            },
            completion: { _ in
                self.finalizeStepVisibility(step)
            }
        )
    }

    private func finalizeStepVisibility(_ step: Int) {
        for (index, view) in stepViews.enumerated() {
            view.isHidden = index != step
            view.isUserInteractionEnabled = index == step
        }
    }

    // MARK: - Actions
    private func handleNextTapped() {
        cancelActiveSwipeIfNeeded()
        nextTriggerSubject.send(())
    }

    @objc private func handleBackTapped() {
        cancelActiveSwipeIfNeeded()
        backTriggerSubject.send(())
    }

    @objc private func handleSkipTapped() {
        cancelActiveSwipeIfNeeded()
        skipTriggerSubject.send(())
    }

    private func cancelActiveSwipeIfNeeded() {
        guard let animator = stepTransitionAnimator else { return }
        animator.stopAnimation(true)
        stepTransitionAnimator = nil
        interactiveDirection = nil
        finalizeStepVisibility(interactiveFromStep)
    }

    // MARK: - Swipe-to-change-step

    @objc private func handleStepPan(_ gesture: UIPanGestureRecognizer) {
        let width = max(stepContainerView.bounds.width, 1)
        let translation = gesture.translation(in: stepContainerView)

        switch gesture.state {
        case .began:
            beginInteractiveStepTransition()
            updateInteractiveStepTransition(translation: translation, width: width)

        case .changed:
            if stepTransitionAnimator == nil {
                beginInteractiveStepTransition()
            }
            updateInteractiveStepTransition(translation: translation, width: width)

        case .ended, .cancelled, .failed:
            let velocity = gesture.velocity(in: stepContainerView).x
            endInteractiveStepTransition(translation: translation, velocity: velocity, width: width)

        default:
            break
        }
    }

    private func beginInteractiveStepTransition() {
        interactiveFromStep = currentStep
        interactiveDirection = nil
    }

    /// Lazily locks in a swipe direction once the finger has moved enough to show intent,
    /// then drives a paused `UIViewPropertyAnimator` by hand so the crossfade tracks the
    /// finger 1:1 (fractionComplete) instead of playing a fixed-duration animation.
    private func updateInteractiveStepTransition(translation: CGPoint, width: CGFloat) {
        if interactiveDirection == nil {
            guard abs(translation.x) > 8 else { return }

            let direction = translation.x < 0 ? 1 : -1
            let targetStep = interactiveFromStep + direction
            guard stepViews.indices.contains(targetStep) else {
                interactiveDirection = 0 // swiping past the first/last step — ignore this gesture
                return
            }

            interactiveDirection = direction
            interactiveToStep = targetStep
            prepareInteractiveAnimator(from: interactiveFromStep, to: interactiveToStep)
        }

        guard let animator = stepTransitionAnimator, let direction = interactiveDirection, direction != 0 else { return }

        let rawPercent = translation.x / width
        let percent = direction == 1 ? -rawPercent : rawPercent
        animator.fractionComplete = max(0, min(1, percent))
    }

    private func prepareInteractiveAnimator(from: Int, to: Int) {
        let views = stepViews
        views[to].isHidden = false
        views[to].alpha = 0
        views[to].isUserInteractionEnabled = false
        views[from].isUserInteractionEnabled = false

        let animator = UIViewPropertyAnimator(duration: 0.28, curve: .easeOut) {
            views[to].alpha = 1
            views[from].alpha = 0
        }
        animator.pauseAnimation()
        stepTransitionAnimator = animator
    }

    private func endInteractiveStepTransition(translation: CGPoint, velocity: CGFloat, width: CGFloat) {
        guard let animator = stepTransitionAnimator, let direction = interactiveDirection, direction != 0 else {
            stepTransitionAnimator = nil
            interactiveDirection = nil
            return
        }

        let rawPercent = translation.x / width
        let percent = direction == 1 ? -rawPercent : rawPercent
        let normalizedVelocity = direction == 1 ? -velocity : velocity

        let shouldComplete = percent > 0.35 || normalizedVelocity > 300
        let toStep = interactiveToStep
        let fromStep = interactiveFromStep

        animator.isReversed = !shouldComplete
        animator.addCompletion { [weak self] _ in
            guard let self = self else { return }
            self.finalizeStepVisibility(shouldComplete ? toStep : fromStep)
            self.stepTransitionAnimator = nil
            self.interactiveDirection = nil

            guard shouldComplete else { return }
            // The swipe itself already crossfaded the views by hand — suppress the sink's own
            // crossfade so `render(state:)` only updates labels/progress for this one update.
            self.suppressNextRenderAnimation = true
            if direction == 1 {
                self.nextTriggerSubject.send(())
            } else {
                self.backTriggerSubject.send(())
            }
        }
        animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension ILOnboardingViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Let chips / bell switches / bell cards handle their own taps —
        // only start the page-swipe from the surrounding blank areas.
        var view = touch.view
        while let candidate = view {
            if candidate is UIControl { return false }
            view = candidate.superview
            if candidate === stepContainerView { break }
        }
        return true
    }
}
