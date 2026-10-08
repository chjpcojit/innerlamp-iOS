//
//  ILFamilyTreeChronicleViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILFamilyTreeChronicleViewController: BaseViewController {

    private typealias Tree = ILColors.FamilyTree

    private enum Layout {
        static let contentTop: CGFloat = 16
        static let contentBottom: CGFloat = 40
        static let sectionGap: CGFloat = 24
        static let blockGap: CGFloat = 10
        static let fieldGap: CGFloat = 12
        static let mastheadGap: CGFloat = 16
        static let navBarBottomGap: CGFloat = 12
        static let plaqueColumnGap: CGFloat = 8
        static let plaqueMeaningRatio: CGFloat = 1.6
        static let noticePadding: CGFloat = 12
        static let noticeRadius: CGFloat = 6
    }

    // MARK: - Properties
    private let viewModel: ILFamilyTreeChronicleViewModel
    private var cancellables = Set<AnyCancellable>()

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let editToggledSubject = PassthroughSubject<Void, Never>()
    private let tabSelectedSubject = PassthroughSubject<String, Never>()
    private let fieldEditedSubject = PassthroughSubject<ILFamilyTreeChronicleFieldEdit, Never>()
    private let milestoneAddedSubject = PassthroughSubject<Void, Never>()
    private let milestoneDeletedSubject = PassthroughSubject<String, Never>()
    private let headChangeTappedSubject = PassthroughSubject<Void, Never>()
    private let headPickerDismissedSubject = PassthroughSubject<Void, Never>()
    private let headCandidatePickedSubject = PassthroughSubject<String, Never>()
    private let headChangeConfirmedSubject = PassthroughSubject<Void, Never>()
    private let headChangeCancelledSubject = PassthroughSubject<Void, Never>()
    private let founderTappedSubject = PassthroughSubject<Void, Never>()
    private let keeperTappedSubject = PassthroughSubject<Void, Never>()
    private let personTappedSubject = PassthroughSubject<String, Never>()
    private let remindFounderTappedSubject = PassthroughSubject<Void, Never>()

    private var tabTreeIDs: [String] = []
    private var renderedTimeline: [ILFamilyTreeChronicleTimelineRow]?
    private var renderedPeople: [ILFamilyTreeChroniclePersonRow]?
    private var shownErrorField: ILFamilyTreeChronicleField?
    private var shownToastToken = 0
    private var isConfirmPresented = false

    // MARK: - UI Elements
    private lazy var headerView = ILNavBar(
        title: "familyTreeChronicle.title".localized,
        rightActionTitle: "familyTreeChronicle.edit".localized
    )

    private lazy var headerDivider: UIView = {
        let divider = UIView()
        divider.backgroundColor = Tree.borderSoft
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
        stack.spacing = Layout.sectionGap
        return stack
    }()

    private lazy var tabToggle = ILSegmentedToggleView()
    private lazy var mastheadView = ILFamilyTreeChronicleHeaderView()
    private lazy var homeCard = makeCard("hometown")
    private lazy var editNoticeView: UIView = {
        let notice = UIView()
        notice.backgroundColor = Tree.livingTint
        notice.layer.cornerRadius = Layout.noticeRadius
        let label = UILabel()
        label.text = "familyTreeChronicle.editNotice".localized
        label.font = ILTypography.subhead
        label.textColor = Tree.forest
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        notice.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: notice.topAnchor, constant: Layout.noticePadding),
            label.bottomAnchor.constraint(equalTo: notice.bottomAnchor, constant: -Layout.noticePadding),
            label.leadingAnchor.constraint(equalTo: notice.leadingAnchor, constant: Layout.noticePadding),
            label.trailingAnchor.constraint(equalTo: notice.trailingAnchor, constant: -Layout.noticePadding)
        ])
        notice.isHidden = true
        return notice
    }()

    // Nguồn gốc
    private lazy var founderCard = ILFamilyTreeChronicleFounderCardView()
    private lazy var originViewCard = ILFamilyTreeChronicleTextCardView()
    private lazy var originEditCard = makeCard("origin", style: .multiLine)

    // Mốc lịch sử
    private lazy var timelineView = ILFamilyTreeChronicleTimelineView()
    private lazy var timelineEmptyCard = ILFamilyTreeChronicleTextCardView()
    private lazy var milestoneEditor = ILFamilyTreeChronicleMilestoneEditorView()

    // Nhà thờ họ
    private lazy var shrineCard = ILFamilyTreeChronicleShrineCardView()
    private lazy var shrineEmptyCard = ILFamilyTreeChronicleTextCardView()
    private lazy var shrineNameCard = makeCard("shrineName")
    private lazy var shrineAddressCard = makeCard("shrineAddress")
    private lazy var annualGatheringCard = makeCard("annualGathering")
    private lazy var shrineEditStack = makeStack([shrineNameCard, shrineAddressCard, annualGatheringCard], spacing: Layout.fieldGap)

    // Gia huấn
    private lazy var plaqueView = ILFamilyTreeChroniclePlaqueView()
    private lazy var teachingsViewCard = ILFamilyTreeChronicleTextCardView()
    private lazy var plaqueHanCard = makeCard("plaqueHan")
    private lazy var plaqueMeaningCard = makeCard("plaqueMeaning")
    private lazy var coupletUpperCard = makeCard("coupletUpper")
    private lazy var coupletLowerCard = makeCard("coupletLower")
    private lazy var teachingsEditCard = makeCard("teachings", style: .multiLine)
    private lazy var plaqueRow: UIStackView = {
        let row = UIStackView(arrangedSubviews: [plaqueHanCard, plaqueMeaningCard])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = Layout.plaqueColumnGap
        return row
    }()
    private lazy var teachingsEditStack = makeStack(
        [plaqueRow, coupletUpperCard, coupletLowerCard, teachingsEditCard], spacing: Layout.fieldGap
    )

    // Người tiêu biểu
    private lazy var peopleView = ILFamilyTreeChroniclePeopleView()

    private lazy var footnoteLabel: UILabel = {
        let label = UILabel()
        label.text = "familyTreeChronicle.footnote".localized
        label.font = ILTypography.caption
        label.textColor = Tree.inkMuted
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var headPickerView: ILFamilyTreeChronicleHeadPickerView = {
        let picker = ILFamilyTreeChronicleHeadPickerView()
        picker.onPick = { [weak self] id in self?.headCandidatePickedSubject.send(id) }
        picker.onDismiss = { [weak self] in self?.headPickerDismissedSubject.send(()) }
        return picker
    }()

    // Section containers (hidden as a whole)
    private lazy var originSection = makeSection(
        "familyTreeChronicle.section.origin", [founderCard, originViewCard, originEditCard]
    )
    private lazy var timelineSection = makeSection(
        "familyTreeChronicle.section.milestones", [timelineView, timelineEmptyCard, milestoneEditor]
    )
    private lazy var shrineSection = makeSection(
        "familyTreeChronicle.section.shrine", [shrineCard, shrineEmptyCard, shrineEditStack]
    )
    private lazy var teachingsSection = makeSection(
        "familyTreeChronicle.section.teachings", [plaqueView, teachingsViewCard, teachingsEditStack]
    )
    private lazy var peopleSection = makeSection("familyTreeChronicle.section.people", [peopleView])

    // MARK: - Initializer
    init(viewModel: ILFamilyTreeChronicleViewModel) {
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
        // Child screen without the bottom nav (per design handoff).
        (tabBarController as? ILMainTabBarController)?.setBottomNavHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        (tabBarController as? ILMainTabBarController)?.setBottomNavHidden(false, animated: animated)
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = Tree.paper

        [headerView, headerDivider, scrollView, headPickerView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        let masthead = makeStack([mastheadView, homeCard, editNoticeView], spacing: Layout.mastheadGap)
        [tabToggle, masthead, originSection, timelineSection, shrineSection, teachingsSection, peopleSection, footnoteLabel]
            .forEach { contentStack.addArrangedSubview($0) }

        headerView.onBack = { [weak self] in self?.backTappedSubject.send(()) }
        headerView.onAction = { [weak self] in self?.toggleEdit() }

        tabToggle.onSelect = { [weak self] index in
            guard let self, self.tabTreeIDs.indices.contains(index) else { return }
            self.view.endEditing(true)
            self.tabSelectedSubject.send(self.tabTreeIDs[index])
        }

        founderCard.onTap = { [weak self] in self?.founderTappedSubject.send(()) }
        let startEditing: () -> Void = { [weak self] in self?.toggleEdit() }
        originViewCard.onPlaceholderTap = startEditing
        timelineEmptyCard.onPlaceholderTap = startEditing
        shrineEmptyCard.onPlaceholderTap = startEditing
        teachingsViewCard.onPlaceholderTap = startEditing
        originViewCard.configure(text: "", placeholder: "familyTreeChronicle.origin.empty".localized)
        timelineEmptyCard.configure(text: "", placeholder: "familyTreeChronicle.milestones.empty".localized)
        shrineEmptyCard.configure(text: "", placeholder: "familyTreeChronicle.shrine.empty".localized)

        shrineCard.onKeeperTap = { [weak self] in self?.keeperTappedSubject.send(()) }
        shrineCard.onChangeTap = { [weak self] in self?.headChangeTappedSubject.send(()) }
        shrineCard.onRemindTap = { [weak self] in self?.remindFounderTappedSubject.send(()) }
        peopleView.onPick = { [weak self] id in self?.personTappedSubject.send(id) }

        milestoneEditor.onAdd = { [weak self] in self?.milestoneAddedSubject.send(()) }
        milestoneEditor.onDelete = { [weak self] id in self?.milestoneDeletedSubject.send(id) }
        milestoneEditor.onYearChanged = { [weak self] id, text in
            self?.fieldEditedSubject.send(.milestoneYear(id: id, text: text))
        }
        milestoneEditor.onTextChanged = { [weak self] id, text in
            self?.fieldEditedSubject.send(.milestoneText(id: id, text: text))
        }

        bindField(homeCard) { .hometown($0) }
        bindField(originEditCard) { .origin($0) }
        bindField(shrineNameCard) { .shrineName($0) }
        bindField(shrineAddressCard) { .shrineAddress($0) }
        bindField(annualGatheringCard) { .annualGathering($0) }
        bindField(plaqueHanCard) { .plaqueHan($0) }
        bindField(plaqueMeaningCard) { .plaqueMeaning($0) }
        bindField(coupletUpperCard) { .coupletUpper($0) }
        bindField(coupletLowerCard) { .coupletLower($0) }
        bindField(teachingsEditCard) { .teachings($0) }
    }

    override func setupConstraints() {
        super.setupConstraints()

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ILMetrics.screenHorizontal),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ILMetrics.screenHorizontal),

            headerDivider.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: Layout.navBarBottomGap),
            headerDivider.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerDivider.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerDivider.heightAnchor.constraint(equalToConstant: 1),

            scrollView.topAnchor.constraint(equalTo: headerDivider.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // Pinned to the keyboard so lower fields can scroll above it (BaseViewController
            // scrolls the focused field into view).
            scrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: Layout.contentTop),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: ILMetrics.screenHorizontal),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -Layout.contentBottom),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -ILMetrics.screenHorizontal * 2),

            headPickerView.topAnchor.constraint(equalTo: view.topAnchor),
            headPickerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            headPickerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headPickerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // Hoành phi (Han) : phiên âm · nghĩa = 1 : 1.6 (design handoff)
            plaqueMeaningCard.widthAnchor.constraint(equalTo: plaqueHanCard.widthAnchor, multiplier: Layout.plaqueMeaningRatio)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILFamilyTreeChronicleViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            editToggled: editToggledSubject.eraseToAnyPublisher(),
            tabSelected: tabSelectedSubject.eraseToAnyPublisher(),
            fieldEdited: fieldEditedSubject.eraseToAnyPublisher(),
            milestoneAdded: milestoneAddedSubject.eraseToAnyPublisher(),
            milestoneDeleted: milestoneDeletedSubject.eraseToAnyPublisher(),
            headChangeTapped: headChangeTappedSubject.eraseToAnyPublisher(),
            headPickerDismissed: headPickerDismissedSubject.eraseToAnyPublisher(),
            headCandidatePicked: headCandidatePickedSubject.eraseToAnyPublisher(),
            headChangeConfirmed: headChangeConfirmedSubject.eraseToAnyPublisher(),
            headChangeCancelled: headChangeCancelledSubject.eraseToAnyPublisher(),
            founderTapped: founderTappedSubject.eraseToAnyPublisher(),
            keeperTapped: keeperTappedSubject.eraseToAnyPublisher(),
            personTapped: personTappedSubject.eraseToAnyPublisher(),
            remindFounderTapped: remindFounderTappedSubject.eraseToAnyPublisher()
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
    private func render(state: ViewState<ILFamilyTreeChronicleStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILFamilyTreeChronicleStateModel) {
        let isEditing = model.isEditing
        let draft = model.draft

        headerView.rightActionTitle = (isEditing ? "familyTreeChronicle.done" : "familyTreeChronicle.edit").localized
        updateTabs(model.tabs)
        mastheadView.configure(title: model.title, home: model.home, meta: model.meta, showsHome: !isEditing)
        homeCard.isHidden = !isEditing
        homeCard.text = draft.hometown
        editNoticeView.isHidden = !isEditing

        // Nguồn gốc
        founderCard.configure(name: model.founderName, years: model.founderYears,
                              isTappable: !isEditing && model.founderMemberID != nil)
        originViewCard.isHidden = isEditing
        originViewCard.configure(text: model.origin, placeholder: "familyTreeChronicle.origin.empty".localized)
        originEditCard.isHidden = !isEditing
        originEditCard.text = draft.origin

        // Mốc lịch sử
        if renderedTimeline != model.timeline {
            renderedTimeline = model.timeline
            timelineView.configure(rows: model.timeline)
        }
        timelineView.isHidden = isEditing || model.timeline.isEmpty
        timelineEmptyCard.isHidden = isEditing || !model.timeline.isEmpty
        milestoneEditor.isHidden = !isEditing
        milestoneEditor.configure(milestones: draft.milestones) { model.error(for: .milestoneYear($0)) }

        // Nhà thờ họ
        shrineCard.configure(with: model)
        shrineCard.isHidden = isEditing || model.shrineName.isEmpty
        shrineEmptyCard.isHidden = isEditing || !model.shrineName.isEmpty
        shrineEditStack.isHidden = !isEditing
        shrineNameCard.text = draft.shrineName
        shrineAddressCard.text = draft.shrineAddress
        annualGatheringCard.text = draft.annualGathering

        // Gia huấn
        plaqueView.configure(han: model.plaqueHan, meaning: model.plaqueMeaning, couplets: model.couplets)
        plaqueView.isHidden = isEditing || (model.plaqueHan.isEmpty && model.couplets.isEmpty)
        teachingsViewCard.isHidden = isEditing
        teachingsViewCard.configure(text: model.teachings, placeholder: "familyTreeChronicle.teachings.empty".localized)
        teachingsEditStack.isHidden = !isEditing
        plaqueHanCard.text = draft.plaqueHan
        plaqueMeaningCard.text = draft.plaqueMeaning
        coupletUpperCard.text = draft.coupletUpper
        coupletLowerCard.text = draft.coupletLower
        teachingsEditCard.text = draft.teachings

        // Người tiêu biểu
        if renderedPeople != model.people {
            renderedPeople = model.people
            peopleView.configure(rows: model.people)
        }
        peopleSection.isHidden = isEditing || model.people.isEmpty

        headPickerView.setOpen(model.isHeadPickerOpen, rows: model.candidates)
        presentConfirmIfNeeded(model.pendingHead)
        showToastIfNeeded(model)
        focusErrorIfNeeded(model)
    }

    private func updateTabs(_ tabs: [ILFamilyTreeChronicleTabModel]) {
        tabToggle.isHidden = tabs.isEmpty
        tabTreeIDs = tabs.map(\.treeID)
        let titles = tabs.map(\.title)
        if tabToggle.titles != titles { tabToggle.titles = titles }
        tabToggle.selectedIndex = tabs.firstIndex(where: \.isSelected) ?? 0
    }

    /// The "Chuyển tộc trưởng?" dialog, shown once per pending change.
    private func presentConfirmIfNeeded(_ pending: ILFamilyTreeChroniclePendingHead?) {
        guard let pending else {
            isConfirmPresented = false
            return
        }
        guard !isConfirmPresented else { return }
        isConfirmPresented = true
        ILAlertPresenter.shared.show(
            .dialog(
                title: "familyTreeChronicle.head.confirm.title".localized,
                message: pending.message,
                primary: ILAlertAction(title: "familyTreeChronicle.head.confirm.ok".localized) { [weak self] in
                    self?.headChangeConfirmedSubject.send(())
                },
                secondary: ILAlertAction(title: "common.cancel".localized) { [weak self] in
                    self?.headChangeCancelledSubject.send(())
                }
            ),
            from: self
        )
    }

    private func showToastIfNeeded(_ model: ILFamilyTreeChronicleStateModel) {
        guard model.toastToken != shownToastToken else { return }
        shownToastToken = model.toastToken
        guard let message = model.toastMessage else { return }
        ILAlertPresenter.shared.show(.success(title: message, message: nil), from: self)
    }

    /// Scrolls to the invalid year and puts the caret in it — once per new error.
    private func focusErrorIfNeeded(_ model: ILFamilyTreeChronicleStateModel) {
        defer { shownErrorField = model.errorField }
        guard let field = model.errorField, field != shownErrorField else { return }
        switch field {
        case .milestoneYear(let id):
            guard let card = milestoneEditor.yearCard(of: id) else { return }
            scrollView.layoutIfNeeded()
            scrollView.scrollRectToVisible(card.convert(card.bounds, to: scrollView), animated: true)
            card.focus()
        }
    }

    // MARK: - Actions
    private func toggleEdit() {
        view.endEditing(true)
        editToggledSubject.send(())
    }

    private func bindField(_ card: ILInputCardView, _ makeEdit: @escaping (String) -> ILFamilyTreeChronicleFieldEdit) {
        card.onTextChanged = { [weak self] text in self?.fieldEditedSubject.send(makeEdit(text)) }
    }

    // MARK: - Factories
    /// `key` is the `familyTreeChronicle.field.<key>` / `.placeholder` localization pair.
    private func makeCard(_ key: String, style: ILInputCardView.Style = .singleLine) -> ILInputCardView {
        let card = ILInputCardView(label: "familyTreeChronicle.field.\(key)".localized, style: style)
        card.placeholder = "familyTreeChronicle.field.\(key).placeholder".localized
        return card
    }

    private func makeStack(_ views: [UIView], spacing: CGFloat) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = spacing
        return stack
    }

    private func makeSection(_ titleKey: String, _ views: [UIView]) -> UIStackView {
        makeStack([ILSectionEyebrowView(title: titleKey.localized)] + views, spacing: Layout.blockGap)
    }
}
