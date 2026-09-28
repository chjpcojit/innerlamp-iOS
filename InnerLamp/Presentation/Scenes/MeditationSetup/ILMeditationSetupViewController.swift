//
//  ILMeditationSetupViewController.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import UIKit
import Combine

final class ILMeditationSetupViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: ILMeditationSetupViewModel
    private var cancellables = Set<AnyCancellable>()

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let durationSelectedSubject = PassthroughSubject<Int, Never>()
    private let startTappedSubject = PassthroughSubject<Void, Never>()
    private let silentTappedSubject = PassthroughSubject<Void, Never>()
    private let closeTappedSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    private let backgroundGradientLayer = CAGradientLayer()

    private lazy var headerView: ILNavBar = {
        let view = ILNavBar(title: "meditationSetup.header.title".localized, showBack: false, showClose: true)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let scrollView = UIScrollView()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            titleLabel, subtitleLabel,
            durationEyebrow, durationView, durationHintLabel,
            bellEyebrow, bellCardView, tipView
        ])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = ILMetrics.rowSpacing
        stack.setCustomSpacing(ILMetrics.spaceSmall, after: titleLabel)
        stack.setCustomSpacing(24, after: subtitleLabel)
        stack.setCustomSpacing(ILMetrics.spaceSmall, after: durationView)
        stack.setCustomSpacing(22, after: durationHintLabel)
        stack.setCustomSpacing(ILMetrics.spaceStandard, after: bellCardView)
        return stack
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.displayLarge
        label.textColor = ILColors.ink
        label.numberOfLines = 0
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.bodyCompact
        label.textColor = ILColors.inkTertiary
        label.numberOfLines = 0
        return label
    }()

    private lazy var durationEyebrow = ILSectionEyebrowView(title: "meditationSetup.duration.section".localized)
    private lazy var durationView = ILMeditationSetupDurationView()

    private lazy var durationHintLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.label
        label.textColor = ILColors.inkMuted
        label.numberOfLines = 0
        return label
    }()

    private lazy var bellEyebrow = ILSectionEyebrowView(title: "meditationSetup.bell.section".localized)
    private lazy var bellCardView = ILMeditationSetupBellCardView()
    private lazy var tipView = ILMeditationSetupTipView()

    private lazy var startButton = ILButton(title: "", variant: .primary)

    private lazy var silentButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = ILTypography.bodySmall
        button.setTitleColor(ILColors.inkSubtle, for: .normal)
        button.addTarget(self, action: #selector(handleSilentTap), for: .touchUpInside)
        return button
    }()

    // MARK: - Initializer
    init(viewModel: ILMeditationSetupViewModel) {
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
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradientLayer.frame = view.bounds
    }

    // `layer.colors` là CGColor tĩnh, không tự đảo theo trait — refresh thủ công khi hệ
    // thống đổi light/dark (giống Login/Onboarding/Splash).
    private func applyColorAppearanceChange() {
        backgroundGradientLayer.colors = [
            ILColors.canvasWarm.cgColor,
            ILColors.canvasWarmEnd1.cgColor
        ]
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()

        // Nền gradient dọc `card2 → sunk` khớp design handoff (`setup`), cùng cặp token với
        // Login/Onboarding (canvasWarm/canvasWarmEnd1).
        backgroundGradientLayer.colors = [
            ILColors.canvasWarm.cgColor,
            ILColors.canvasWarmEnd1.cgColor
        ]
        backgroundGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        backgroundGradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        view.layer.insertSublayer(backgroundGradientLayer, at: 0)

        headerView.onClose = { [weak self] in self?.closeTappedSubject.send(()) }
        view.addSubview(headerView)

        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        durationView.onSelect = { [weak self] minutes in self?.durationSelectedSubject.send(minutes) }
        startButton.onTap = { [weak self] in self?.startTappedSubject.send(()) }

        startButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(startButton)

        silentButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(silentButton)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILMeditationSetupViewController, _) in
            view.applyColorAppearanceChange()
        }
    }

    override func setupConstraints() {
        super.setupConstraints()

        let horizontal = ILMetrics.screenHorizontal

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontal),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontal),

            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 4),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: startButton.topAnchor, constant: -ILMetrics.spaceStandard),

            // Pin nội dung vào contentLayoutGuide để nó nằm sát trên (nội dung ngắn) và cuộn được
            // khi màn thấp; width theo frameLayoutGuide để không cuộn ngang.
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 22),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: horizontal),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -horizontal),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -ILMetrics.spaceMedium),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -horizontal * 2),

            startButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontal),
            startButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontal),
            startButton.bottomAnchor.constraint(equalTo: silentButton.topAnchor, constant: -ILMetrics.spaceMedium),

            silentButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            silentButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -ILMetrics.spaceSmall)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILMeditationSetupViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            durationSelected: durationSelectedSubject.eraseToAnyPublisher(),
            startTapped: startTappedSubject.eraseToAnyPublisher(),
            silentTapped: silentTappedSubject.eraseToAnyPublisher(),
            closeTapped: closeTappedSubject.eraseToAnyPublisher()
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
    private func render(state: ViewState<ILMeditationSetupStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILMeditationSetupStateModel) {
        headerView.title = model.headerTitle
        titleLabel.text = model.title
        subtitleLabel.text = model.subtitle

        durationView.options = model.durationOptions
        durationView.selectedIndex = model.selectedDurationIndex
        durationHintLabel.text = model.durationHint

        bellCardView.configure(
            openingValue: model.openingBellValue,
            intervalValue: model.intervalBellValue,
            soundValue: model.backgroundSoundValue
        )

        tipView.text = model.tipText
        startButton.title = model.startButtonTitle
        silentButton.setTitle(model.silentButtonTitle, for: .normal)
    }

    // MARK: - Actions
    @objc private func handleSilentTap() {
        silentTappedSubject.send(())
    }
}
