//
//  ILMemorialEditViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILMemorialEditViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: ILMemorialEditViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let saveTappedSubject = PassthroughSubject<Void, Never>()
    private let deleteTappedSubject = PassthroughSubject<Void, Never>()
    private let nameChangedSubject = PassthroughSubject<String, Never>()
    private let relationshipSelectedSubject = PassthroughSubject<ILMemorialRelationship, Never>()
    private let calendarSelectedSubject = PassthroughSubject<ILMemorialCalendarKind, Never>()
    private let daySelectedSubject = PassthroughSubject<Int, Never>()
    private let monthSelectedSubject = PassthroughSubject<Int, Never>()
    private let yearSelectedSubject = PassthroughSubject<Int, Never>()
    private let noteChangedSubject = PassthroughSubject<String, Never>()
    private let reminderToggledSubject = PassthroughSubject<Bool, Never>()
    private let leadSelectedSubject = PassthroughSubject<Int, Never>()
    private let timeSelectedSubject = PassthroughSubject<Int, Never>()
    private let syncToggledSubject = PassthroughSubject<Bool, Never>()

    // MARK: - UI Elements
    private lazy var headerContainer: UIView = {
        let container = UIView()
        container.backgroundColor = ILColors.canvas
        return container
    }()

    private lazy var headerView = ILNavBar(rightActionTitle: "memorial.edit.save".localized)

    private lazy var headerDivider: UIView = {
        let divider = UIView()
        divider.backgroundColor = ILColors.borderSoft
        return divider
    }()

    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.keyboardDismissMode = .interactive
        return scroll
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = ILMetrics.groupSpacing
        return stack
    }()

    /// Portrait placeholder — picking a photo is not built yet (see `Docs/Specs/Memorial/`).
    private lazy var portraitView: ILAvatarView = {
        let avatar = ILAvatarView(initials: "", tone: .gold, size: 104)
        avatar.isUserInteractionEnabled = false
        return avatar
    }()

    private lazy var nameField = ILInputCardView(
        label: "memorial.edit.name.label".localized,
        placeholder: "memorial.edit.name.placeholder".localized
    )

    private lazy var relationshipGroup = ILMemorialChipGroupView()

    private lazy var calendarToggle = ILSegmentedToggleView(titles: [
        "memorial.edit.calendar.lunar".localized,
        "memorial.edit.calendar.solar".localized
    ])

    private lazy var dayField = ILMenuFieldView(caption: "memorial.edit.day".localized)
    private lazy var monthField = ILMenuFieldView(caption: "memorial.edit.month".localized)
    private lazy var yearField = ILMenuFieldView(caption: "memorial.edit.year".localized)

    private lazy var previewCard = ILMemorialPreviewCardView()

    private lazy var noteField = ILInputCardView(
        label: "memorial.edit.note.label".localized,
        placeholder: "memorial.edit.note.placeholder".localized,
        style: .multiLine
    )

    private lazy var reminderCard = ILMemorialReminderCardView()

    private lazy var saveButton = ILButton(title: "", loadingTitle: "memorial.edit.saving".localized)

    /// Fixed bar that keeps the save button on screen while the form scrolls.
    private lazy var bottomBar: UIView = {
        let bar = UIView()
        bar.backgroundColor = ILColors.canvas
        return bar
    }()

    private lazy var bottomBarDivider: UIView = {
        let divider = UIView()
        divider.backgroundColor = ILColors.borderSoft
        return divider
    }()

    private lazy var deleteButton = ILButton(title: "memorial.edit.delete".localized, variant: .danger)

    // MARK: - Initializer
    init(viewModel: ILMemorialEditViewModel) {
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

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.canvas

        headerView.onBack = { [weak self] in self?.backTappedSubject.send(()) }
        headerView.onAction = { [weak self] in self?.saveTappedSubject.send(()) }
        headerContainer.addSubview(headerView)
        headerContainer.addSubview(headerDivider)

        bottomBar.addSubview(bottomBarDivider)
        bottomBar.addSubview(saveButton)

        [scrollView, headerContainer, bottomBar].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        nameField.onTextChanged = { [weak self] text in self?.nameChangedSubject.send(text) }
        noteField.onTextChanged = { [weak self] text in self?.noteChangedSubject.send(text) }
        relationshipGroup.onSelect = { [weak self] id in
            guard let self, ILMemorialRelationship.allCases.indices.contains(id) else { return }
            self.relationshipSelectedSubject.send(ILMemorialRelationship.allCases[id])
        }
        calendarToggle.onSelect = { [weak self] index in
            self?.calendarSelectedSubject.send(index == 0 ? .lunar : .solar)
        }
        dayField.onSelect = { [weak self] id in self?.daySelectedSubject.send(id) }
        monthField.onSelect = { [weak self] id in self?.monthSelectedSubject.send(id) }
        yearField.onSelect = { [weak self] id in self?.yearSelectedSubject.send(id) }
        reminderCard.onReminderToggled = { [weak self] isOn in self?.reminderToggledSubject.send(isOn) }
        reminderCard.onLeadSelected = { [weak self] id in self?.leadSelectedSubject.send(id) }
        reminderCard.onTimeSelected = { [weak self] id in self?.timeSelectedSubject.send(id) }
        reminderCard.onSyncToggled = { [weak self] isOn in self?.syncToggledSubject.send(isOn) }
        saveButton.onTap = { [weak self] in self?.saveTappedSubject.send(()) }
        deleteButton.onTap = { [weak self] in self?.deleteTappedSubject.send(()) }

        let portraitRow = UIStackView(arrangedSubviews: [portraitView])
        portraitRow.alignment = .center
        portraitRow.axis = .vertical

        let dateRow = UIStackView(arrangedSubviews: [dayField, monthField, yearField])
        dateRow.axis = .horizontal
        dateRow.distribution = .fill
        dateRow.spacing = ILMetrics.spaceSmall
        dayField.widthAnchor.constraint(equalTo: yearField.widthAnchor, multiplier: 0.9).isActive = true
        monthField.widthAnchor.constraint(equalTo: yearField.widthAnchor, multiplier: 1.1).isActive = true

        let deathDateSection = makeSection(
            title: "memorial.edit.deathDate".localized,
            content: [calendarToggle, dateRow, previewCard]
        )

        [
            portraitRow,
            nameField,
            makeSection(title: "memorial.edit.relationship".localized, content: [relationshipGroup]),
            deathDateSection,
            noteField,
            makeSection(title: "memorial.edit.reminder".localized, content: [reminderCard]),
            deleteButton
        ].forEach { contentStack.addArrangedSubview($0) }
    }

    override func setupConstraints() {
        super.setupConstraints()
        [headerView, headerDivider, bottomBarDivider, saveButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            headerContainer.topAnchor.constraint(equalTo: view.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall / 2),
            headerView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: ILMetrics.screenHorizontal),
            headerView.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -ILMetrics.screenHorizontal),

            headerDivider.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 12),
            headerDivider.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            headerDivider.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            headerDivider.heightAnchor.constraint(equalToConstant: 1),
            headerDivider.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            // Pinned to the keyboard (equals the safe-area bottom when hidden) so the save bar
            // rides above it and the focused field can scroll into view.
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            bottomBarDivider.topAnchor.constraint(equalTo: bottomBar.topAnchor),
            bottomBarDivider.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            bottomBarDivider.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),
            bottomBarDivider.heightAnchor.constraint(equalToConstant: 1),

            saveButton.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: ILMetrics.spaceMedium),
            saveButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: ILMetrics.screenHorizontal),
            saveButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            saveButton.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor, constant: -ILMetrics.spaceMedium),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: ILMetrics.groupSpacing),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: ILMetrics.screenHorizontal),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -ILMetrics.screenPadding.bottom),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -ILMetrics.screenHorizontal * 2)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILMemorialEditViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            saveTapped: saveTappedSubject.eraseToAnyPublisher(),
            deleteTapped: deleteTappedSubject.eraseToAnyPublisher(),
            nameChanged: nameChangedSubject.eraseToAnyPublisher(),
            relationshipSelected: relationshipSelectedSubject.eraseToAnyPublisher(),
            calendarSelected: calendarSelectedSubject.eraseToAnyPublisher(),
            daySelected: daySelectedSubject.eraseToAnyPublisher(),
            monthSelected: monthSelectedSubject.eraseToAnyPublisher(),
            yearSelected: yearSelectedSubject.eraseToAnyPublisher(),
            noteChanged: noteChangedSubject.eraseToAnyPublisher(),
            reminderToggled: reminderToggledSubject.eraseToAnyPublisher(),
            leadSelected: leadSelectedSubject.eraseToAnyPublisher(),
            timeSelected: timeSelectedSubject.eraseToAnyPublisher(),
            syncToggled: syncToggledSubject.eraseToAnyPublisher()
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
    private func render(state: ViewState<ILMemorialEditStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILMemorialEditStateModel) {
        headerView.title = model.title
        saveButton.title = model.saveTitle
        saveButton.buttonState = model.isSaving ? .loading : .normal
        deleteButton.isHidden = !model.canDelete
        deleteButton.buttonState = model.isSaving ? .disabled : .normal

        portraitView.initials = model.name.first.map { String($0).uppercased() } ?? ""
        nameField.text = model.name
        nameField.errorText = model.nameError
        noteField.text = model.note

        relationshipGroup.configure(options: model.relationships)

        calendarToggle.selectedIndex = model.calendarKind == .lunar ? 0 : 1
        configure(field: dayField, options: model.dayOptions, selectedID: model.selectedDay)
        configure(field: monthField, options: model.monthOptions, selectedID: model.selectedMonth)
        configure(field: yearField, options: model.yearOptions, selectedID: model.selectedYear)
        previewCard.configure(next: model.previewNext, detail: model.previewDetail)

        reminderCard.configure(with: model)
    }

    private func configure(field: ILMenuFieldView, options: [ILMemorialOptionModel], selectedID: Int) {
        field.options = options.map { ILMenuFieldView.Option(id: $0.id, title: $0.title) }
        field.selectedID = selectedID
    }

    // MARK: - Layout helpers
    /// Caps section title above its content, spaced like the design handoff.
    private func makeSection(title: String, content: [UIView]) -> UIStackView {
        let label = UILabel()
        label.attributedText = ILTypography.makeEyebrow(text: title.uppercased(), color: ILColors.inkMuted)

        let stack = UIStackView(arrangedSubviews: [label] + content)
        stack.axis = .vertical
        stack.spacing = ILMetrics.spaceMedium - 4
        return stack
    }
}
