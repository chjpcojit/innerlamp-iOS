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
    private let doneTappedSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()

    private var lastRenderedCount: Int?

    // MARK: - UI Elements
    private lazy var backgroundView = ILImmersiveBackgroundView()

    private lazy var headerView = ILNavBar()

    private lazy var countDisplayView = ILMalaCountDisplayView()

    private lazy var strandView = ILMalaStrandView()

    private lazy var mantraLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.scriptureTitle
        label.textColor = ILColors.medInk
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var hintLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.hintItalic
        label.textColor = ILColors.medInkTertiary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var actionBarView = ILImmersiveActionBarView()

    private lazy var footnoteLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.label
        label.textColor = ILColors.medInkMuted
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var lowerStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [mantraLabel, hintLabel, actionBarView, footnoteLabel])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = ILMetrics.spaceSmall
        stack.setCustomSpacing(ILMetrics.groupSpacing, after: hintLabel)
        stack.setCustomSpacing(ILMetrics.spaceStandard, after: actionBarView)
        return stack
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

        headerView.onBack = { [weak self] in self?.backTappedSubject.send(()) }
        view.addSubview(headerView)

        view.addSubview(countDisplayView)

        strandView.onAdvance = { [weak self] in self?.beadAdvancedSubject.send(()) }
        view.addSubview(strandView)

        actionBarView.onSecondaryTap = { [weak self] in self?.resetTappedSubject.send(()) }
        actionBarView.onPrimaryTap = { [weak self] in self?.doneTappedSubject.send(()) }
        view.addSubview(lowerStack)
    }

    override func setupConstraints() {
        super.setupConstraints()
        [backgroundView, headerView, countDisplayView, strandView, lowerStack].forEach {
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

            countDisplayView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: ILMetrics.spaceLarge),
            countDisplayView.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            strandView.topAnchor.constraint(equalTo: countDisplayView.bottomAnchor, constant: ILMetrics.spaceMedium),
            strandView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontal),
            strandView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontal),
            strandView.bottomAnchor.constraint(equalTo: lowerStack.topAnchor, constant: -ILMetrics.spaceStandard),

            lowerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontal),
            lowerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontal),
            lowerStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -ILMetrics.spaceMedium)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILMalaViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            beadAdvanced: beadAdvancedSubject.eraseToAnyPublisher(),
            resetTapped: resetTappedSubject.eraseToAnyPublisher(),
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

        countDisplayView.goal = model.goal
        countDisplayView.goalText = model.goalText
        countDisplayView.count = model.count

        strandView.accessibilityLabel = model.strandAccessibilityLabel
        strandView.accessibilityValue = "\(model.count)"
        strandView.count = model.count

        mantraLabel.text = model.mantraText
        hintLabel.text = model.hintText
        actionBarView.secondaryTitle = model.resetTitle
        actionBarView.primaryTitle = model.doneTitle
        footnoteLabel.text = model.footnoteText

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
}
