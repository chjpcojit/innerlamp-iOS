//
//  ILLightLampViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILLightLampViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: ILLightLampViewModel
    private var cancellables = Set<AnyCancellable>()
    private var appliedPhase: ILLightLampStateModel.Phase = .form

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let gardenTappedSubject = PassthroughSubject<Void, Never>()
    private let kindSelectedSubject = PassthroughSubject<ILLampKind, Never>()
    private let intentionSelectedSubject = PassthroughSubject<ILLampIntention, Never>()
    private let durationSelectedSubject = PassthroughSubject<Int, Never>()
    private let targetChangedSubject = PassthroughSubject<String, Never>()
    private let vowChangedSubject = PassthroughSubject<String, Never>()
    private let lightTappedSubject = PassthroughSubject<Void, Never>()
    private let againTappedSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    private lazy var headerBand: ILStickyHeaderBand = {
        let band = ILStickyHeaderBand()
        return band
    }()

    private lazy var headerView: ILNavBar = {
        let navBar = ILNavBar(
            title: "lightLamp.light.title".localized,
            rightActionTitle: "lightLamp.light.gardenAction".localized
        )
        navBar.usesCloseGlyphOnLeft = true
        return navBar
    }()

    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.keyboardDismissMode = .interactive
        scroll.contentInsetAdjustmentBehavior = .never
        return scroll
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = ILMetrics.groupSpacing
        return stack
    }()

    private lazy var stageView: ILLampStageView = {
        let view = ILLampStageView(kind: .oil)
        return view
    }()

    private lazy var kindPicker: ILLampKindPickerView = {
        let picker = ILLampKindPickerView()
        return picker
    }()

    private lazy var intentionChips: [ILLampIntention: ILChip] = {
        var chips: [ILLampIntention: ILChip] = [:]
        for intention in ILLampIntention.allCases {
            let chip = ILChip(label: ILLightLampViewModel.title(of: intention))
            chip.onTap = { [weak self] in self?.intentionSelectedSubject.send(intention) }
            chips[intention] = chip
        }
        return chips
    }()

    private lazy var intentionFlow: ILChipFlowView = {
        let flow = ILChipFlowView(rowSpacing: ILMetrics.spaceSmall, itemSpacing: ILMetrics.spaceSmall)
        return flow
    }()

    private lazy var targetField: ILInputCardView = {
        let field = ILInputCardView(
            label: "",
            placeholder: "lightLamp.target.placeholder".localized
        )
        return field
    }()

    private lazy var vowField: ILInputCardView = {
        let field = ILInputCardView(
            label: "",
            placeholder: "lightLamp.vow.placeholder".localized,
            style: .multiLine
        )
        return field
    }()

    private lazy var durationToggle: ILSegmentedToggleView = {
        let toggle = ILSegmentedToggleView()
        toggle.titles = ILLampEntity.durationOptions.map {
            String(format: "lightLamp.duration.format".localized, $0)
        }
        return toggle
    }()

    private lazy var formStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = ILMetrics.groupSpacing
        return stack
    }()

    private lazy var dedicationLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.cormorant(size: 20, weight: .medium, italic: true)
        label.textColor = ILColors.ink
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var vowQuoteLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.taglineItalic
        label.textColor = ILColors.inkDim
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var doneCard: UIView = {
        let card = UIView()
        card.backgroundColor = ILColors.surface
        card.layer.cornerRadius = ILMetrics.radiusCardMedium
        card.layer.borderWidth = 1
        card.layer.borderColor = ILColors.border.cgColor
        return card
    }()

    private lazy var againButton: ILButton = {
        let button = ILButton(title: "lightLamp.done.again".localized, variant: .ghost)
        button.isHidden = true
        return button
    }()

    private lazy var gardenButton: ILButton = {
        let button = ILButton(title: "lightLamp.done.garden".localized, variant: .primary)
        button.isHidden = true
        return button
    }()

    private lazy var doneStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = ILMetrics.spaceMedium
        stack.isHidden = true
        stack.alpha = 0
        return stack
    }()

    /// Sticky bottom bar: the primary "Thắp đèn" button, swapped for the completion actions once the lamp is lit.
    private lazy var bottomBar: UIView = {
        let bar = UIView()
        bar.backgroundColor = ILColors.canvas
        return bar
    }()

    private lazy var bottomDivider: UIView = {
        let divider = UIView()
        divider.backgroundColor = ILColors.borderSoft
        return divider
    }()

    private lazy var lightButton: ILButton = {
        let button = ILButton(title: "lightLamp.button.light".localized, variant: .primary)
        return button
    }()

    /// Holds the form action ("Thắp đèn") or, once lit, the completion actions stacked vertically.
    private lazy var bottomStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = ILMetrics.spaceMedium
        return stack
    }()

    // MARK: - Initializer
    init(viewModel: ILLightLampViewModel) {
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
        // Pushing the garden keeps the bar hidden; only restore it when this screen is popped.
        guard isMovingFromParent else { return }
        (tabBarController as? ILMainTabBarController)?.setBottomNavHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyHeaderInset()
        // Keep the last content clear of the sticky bar.
        let barInset = bottomBar.bounds.height
        if scrollView.contentInset.bottom != barInset {
            scrollView.contentInset.bottom = barInset
            scrollView.verticalScrollIndicatorInsets.bottom = barInset
        }
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.canvas

        headerView.onBack = { [weak self] in self?.backTappedSubject.send(()) }
        headerView.onAction = { [weak self] in self?.gardenTappedSubject.send(()) }
        headerBand.addSubview(headerView)
        headerBand.bind(to: scrollView)

        kindPicker.onSelect = { [weak self] kind in self?.kindSelectedSubject.send(kind) }
        intentionFlow.setItems(ILLampIntention.allCases.compactMap { intentionChips[$0] })
        targetField.onTextChanged = { [weak self] text in self?.targetChangedSubject.send(text) }
        vowField.onTextChanged = { [weak self] text in self?.vowChangedSubject.send(text) }
        durationToggle.onSelect = { [weak self] index in
            guard ILLampEntity.durationOptions.indices.contains(index) else { return }
            self?.durationSelectedSubject.send(ILLampEntity.durationOptions[index])
        }
        lightButton.onTap = { [weak self] in self?.lightTappedSubject.send(()) }
        againButton.onTap = { [weak self] in self?.againTappedSubject.send(()) }
        gardenButton.onTap = { [weak self] in self?.gardenTappedSubject.send(()) }

        formStack.addArrangedSubview(makeSection(title: "lightLamp.section.kind".localized, content: kindPicker))
        formStack.addArrangedSubview(makeSection(title: "lightLamp.section.intention".localized, content: intentionFlow))
        formStack.addArrangedSubview(makeSection(title: "lightLamp.section.target".localized, content: targetField))
        formStack.addArrangedSubview(
            makeSection(
                title: "lightLamp.section.vow".localized,
                trailingTitle: "lightLamp.vow.optional".localized,
                content: vowField
            )
        )
        formStack.addArrangedSubview(makeSection(title: "lightLamp.section.duration".localized, content: durationToggle))

        let textStack = UIStackView(arrangedSubviews: [dedicationLabel, vowQuoteLabel])
        textStack.axis = .vertical
        textStack.spacing = 10
        textStack.translatesAutoresizingMaskIntoConstraints = false
        doneCard.addSubview(textStack)
        NSLayoutConstraint.activate([
            textStack.topAnchor.constraint(equalTo: doneCard.topAnchor, constant: 20),
            textStack.bottomAnchor.constraint(equalTo: doneCard.bottomAnchor, constant: -20),
            textStack.leadingAnchor.constraint(equalTo: doneCard.leadingAnchor, constant: 20),
            textStack.trailingAnchor.constraint(equalTo: doneCard.trailingAnchor, constant: -20)
        ])
        doneStack.addArrangedSubview(doneCard)
        [lightButton, gardenButton, againButton].forEach { bottomStack.addArrangedSubview($0) }

        [stageView, formStack, doneStack].forEach { contentStack.addArrangedSubview($0) }
        contentStack.setCustomSpacing(ILMetrics.spaceStandard, after: stageView)

        [headerView, headerBand, scrollView, bottomBar, bottomDivider, bottomStack, contentStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        bottomBar.addSubview(bottomDivider)
        bottomBar.addSubview(bottomStack)
        [scrollView, headerBand, bottomBar].forEach { view.addSubview($0) }
        scrollView.addSubview(contentStack)
    }

    override func setupConstraints() {
        super.setupConstraints()
        NSLayoutConstraint.activate([
            headerBand.topAnchor.constraint(equalTo: view.topAnchor),
            headerBand.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBand.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall / 2),
            headerView.leadingAnchor.constraint(equalTo: headerBand.leadingAnchor, constant: ILMetrics.screenHorizontal),
            headerView.trailingAnchor.constraint(equalTo: headerBand.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            headerView.bottomAnchor.constraint(equalTo: headerBand.bottomAnchor, constant: -ILMetrics.spaceSmall),

            // Scroll view runs under the glass header; its height is applied as top content inset
            // in `applyHeaderInset`.
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            bottomDivider.topAnchor.constraint(equalTo: bottomBar.topAnchor),
            bottomDivider.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            bottomDivider.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),
            bottomDivider.heightAnchor.constraint(equalToConstant: 1),

            bottomStack.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: ILMetrics.spaceMedium - 2),
            bottomStack.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: ILMetrics.screenHorizontal),
            bottomStack.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            bottomStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -ILMetrics.spaceSmall),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: ILMetrics.spaceMedium),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: ILMetrics.screenHorizontal),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -ILMetrics.screenPadding.bottom),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -ILMetrics.screenHorizontal * 2)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILLightLampViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            gardenTapped: gardenTappedSubject.eraseToAnyPublisher(),
            kindSelected: kindSelectedSubject.eraseToAnyPublisher(),
            intentionSelected: intentionSelectedSubject.eraseToAnyPublisher(),
            durationSelected: durationSelectedSubject.eraseToAnyPublisher(),
            targetChanged: targetChangedSubject.eraseToAnyPublisher(),
            vowChanged: vowChangedSubject.eraseToAnyPublisher(),
            lightTapped: lightTappedSubject.eraseToAnyPublisher(),
            againTapped: againTappedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.state
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
    }

    // MARK: - Render
    private func render(state: ViewState<ILLightLampStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILLightLampStateModel) {
        stageView.configure(kind: model.selectedKind, kicker: model.kicker, countLine: model.countLine)
        kindPicker.configure(options: model.kinds)
        for option in model.intentions {
            intentionChips[option.intention]?.chipState = option.isSelected ? .selected : .normal
        }
        durationToggle.selectedIndex = model.selectedDurationIndex
        targetField.text = model.target
        vowField.text = model.vow

        lightButton.title = model.buttonTitle
        lightButton.buttonState = model.phase == .form ? .normal : .disabled

        if let completion = model.completion {
            dedicationLabel.text = completion.dedication
            vowQuoteLabel.text = completion.vowQuote
            vowQuoteLabel.isHidden = completion.vowQuote.isEmpty
        }

        guard model.phase != appliedPhase else { return }
        let previous = appliedPhase
        appliedPhase = model.phase
        applyPhase(model.phase, from: previous, caption: model.completion?.caption)
    }

    /// Animates between the three phases (design `lpPhase`): form → lighting ignites the lamp,
    /// lighting → done grows the stage and swaps the form for the completion content, done → form
    /// (light another) reverses it.
    private func applyPhase(
        _ phase: ILLightLampStateModel.Phase,
        from previous: ILLightLampStateModel.Phase,
        caption: String?
    ) {
        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        switch phase {
        case .lighting:
            view.endEditing(true)
            stageView.setIgnited(true, animated: !reduceMotion)
        case .done:
            let showDone = {
                self.stageView.setLit(true, caption: caption)
                self.formStack.alpha = 0
                self.doneStack.isHidden = false
                self.doneStack.alpha = 1
                self.view.layoutIfNeeded()
            }
            formStack.isHidden = true
            lightButton.isHidden = true
            gardenButton.isHidden = false
            againButton.isHidden = false
            UIView.animate(
                withDuration: reduceMotion ? 0 : ILMetrics.Lamp.stageResizeDuration,
                delay: 0,
                options: [.curveEaseInOut],
                animations: showDone
            )
            scrollView.setContentOffset(.zero, animated: true)
        case .form:
            stageView.setIgnited(false, animated: !reduceMotion)
            formStack.isHidden = false
            lightButton.isHidden = false
            gardenButton.isHidden = true
            againButton.isHidden = true
            doneStack.isHidden = true
            UIView.animate(
                withDuration: reduceMotion ? 0 : ILMetrics.Lamp.stageResizeDuration,
                delay: 0,
                options: [.curveEaseInOut]
            ) {
                self.stageView.setLit(false, caption: nil)
                self.formStack.alpha = 1
                self.doneStack.alpha = 0
                self.view.layoutIfNeeded()
            }
        }
    }

    // MARK: - Helpers
    /// Pushes the content below the header; on the first layout the offset is set to the content top.
    private func applyHeaderInset() {
        let top = headerBand.bounds.height
        guard top > 0, scrollView.contentInset.top != top else { return }
        let wasAtTop = scrollView.contentOffset.y <= -scrollView.contentInset.top
        scrollView.contentInset.top = top
        scrollView.verticalScrollIndicatorInsets.top = top
        if wasAtTop { scrollView.contentOffset.y = -top }
    }

    private func makeSection(title: String, trailingTitle: String? = nil, content: UIView) -> UIView {
        let titleLabel = UILabel()
        titleLabel.font = ILTypography.sectionTitle
        titleLabel.textColor = ILColors.ink
        titleLabel.text = title

        let header = UIStackView(arrangedSubviews: [titleLabel])
        header.axis = .horizontal
        header.alignment = .firstBaseline
        if let trailingTitle {
            let trailing = UILabel()
            trailing.font = ILTypography.bodySmall
            trailing.textColor = ILColors.inkMuted
            trailing.text = trailingTitle
            header.addArrangedSubview(UIView())
            header.addArrangedSubview(trailing)
        }

        let stack = UIStackView(arrangedSubviews: [header, content])
        stack.axis = .vertical
        stack.spacing = 10
        return stack
    }
}
