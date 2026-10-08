//
//  ILFamilyTreeMemberViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILFamilyTreeMemberViewController: BaseViewController {

    private typealias Tree = ILColors.FamilyTree

    private enum Layout {
        static let contentTop: CGFloat = 0
        static let contentBottom: CGFloat = 40
        static let sectionGap: CGFloat = 22
        static let sectionTitleGap: CGFloat = 10
        static let editTop: CGFloat = 20
        static let editSectionGap: CGFloat = 20
        static let fieldGap: CGFloat = 14
        static let labelGap: CGFloat = 6
        static let deathColumnGap: CGFloat = 10
        static let anniversaryWidthRatio: CGFloat = 1.4
        static let navBarBottomGap: CGFloat = 12
    }

    // MARK: - Properties
    private let viewModel: ILFamilyTreeMemberViewModel
    private var cancellables = Set<AnyCancellable>()
    private var mode: ILFamilyTreeMemberMode = .view
    private var renderedRelations: [ILFamilyTreeRelationModel]?

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let editTappedSubject = PassthroughSubject<Void, Never>()
    private let nameChangedSubject = PassthroughSubject<String, Never>()
    private let genderSelectedSubject = PassthroughSubject<ILFamilyGender, Never>()
    private let birthYearChangedSubject = PassthroughSubject<String, Never>()
    private let livingSelectedSubject = PassthroughSubject<Bool, Never>()
    private let residenceChangedSubject = PassthroughSubject<String, Never>()
    private let deathYearChangedSubject = PassthroughSubject<String, Never>()
    private let anniversaryChangedSubject = PassthroughSubject<String, Never>()
    private let burialPlaceChangedSubject = PassthroughSubject<String, Never>()
    private let dharmaNameChangedSubject = PassthroughSubject<String, Never>()
    private let tabletTempleChangedSubject = PassthroughSubject<String, Never>()
    private let noteChangedSubject = PassthroughSubject<String, Never>()
    private let saveTappedSubject = PassthroughSubject<Void, Never>()
    private let relationTappedSubject = PassthroughSubject<String, Never>()
    private let remindTappedSubject = PassthroughSubject<Void, Never>()
    private let lightLampTappedSubject = PassthroughSubject<Void, Never>()
    private let chantTappedSubject = PassthroughSubject<Void, Never>()
    private let templeTappedSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    /// In edit mode the back chip is the "Hủy" action (discards the edit).
    private lazy var headerView = ILNavBar(
        title: "familyTreeMember.title.view".localized,
        rightActionTitle: "familyTreeMember.action.edit".localized
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
        let stack = UIStackView(arrangedSubviews: [viewStack, editStack])
        stack.axis = .vertical
        stack.alignment = .fill
        return stack
    }()

    // View mode
    private lazy var heroView = ILFamilyTreeMemberHeroView()
    private lazy var infoCard = ILFamilyTreeMemberInfoCardView()
    private lazy var noteView = ILFamilyTreeMemberNoteView()
    private lazy var memorialTiles = ILFamilyTreeMemberMemorialTilesView()
    private lazy var relationsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        return stack
    }()
    private lazy var memorialSection = makeSection(
        title: "familyTree.detail.memorial".localized, content: memorialTiles
    )
    private lazy var relationsSection = makeSection(
        title: "familyTree.detail.relations".localized, content: relationsStack, titleGap: 4
    )

    private lazy var viewStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            heroView,
            makeSection(title: "familyTreeMember.section.info".localized, content: infoCard),
            makeSection(title: "familyTreeMember.section.note".localized, content: noteView),
            memorialSection,
            relationsSection
        ])
        stack.axis = .vertical
        stack.spacing = Layout.sectionGap
        return stack
    }()

    // Edit mode
    private lazy var nameCard = makeCard("name")
    private lazy var genderToggle = ILSegmentedToggleView(titles: [
        "familyTreeAddMember.gender.male".localized,
        "familyTreeAddMember.gender.female".localized
    ])
    private lazy var birthYearCard = makeCard("birthYear", keyboard: .numberPad)
    private lazy var statusToggle = ILSegmentedToggleView(titles: [
        "familyTreeAddMember.status.living".localized,
        "familyTreeAddMember.status.deceased".localized
    ])
    private lazy var residenceCard = makeCard("residence")
    private lazy var deathYearCard = makeCard("deathYear", keyboard: .numberPad)
    private lazy var anniversaryCard = makeCard("anniversary")
    private lazy var burialCard = makeCard("burialPlace")
    private lazy var dharmaNameCard = makeCard("dharmaName", prefix: "familyTreeMember")
    private lazy var tabletTempleCard = makeCard("tabletTemple", prefix: "familyTreeMember")
    private lazy var noteCard = ILInputCardView(
        label: "familyTreeMember.field.note".localized,
        placeholder: "familyTreeMember.field.note.placeholder".localized,
        style: .multiLine
    )

    private lazy var deathRow: UIStackView = {
        let row = UIStackView(arrangedSubviews: [deathYearCard, anniversaryCard])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = Layout.deathColumnGap
        return row
    }()

    /// "TƯỞNG NIỆM" block of the form (death year, anniversary, burial) — deceased only.
    private lazy var memorialFormSection: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            makeEyebrow("familyTree.detail.memorial".localized), deathRow, burialCard
        ])
        stack.axis = .vertical
        stack.spacing = Layout.fieldGap
        return stack
    }()

    private lazy var submitButton: ILButton = {
        let button = ILButton(title: "familyTreeMember.submit".localized, variant: .primary)
        button.loadingTitle = "familyTreeMember.submit.loading".localized
        return button
    }()

    private lazy var editStack: UIStackView = {
        let genderBlock = makeLabeledBlock("familyTreeAddMember.field.gender", genderToggle)
        let statusBlock = makeLabeledBlock("familyTreeAddMember.field.status", statusToggle)
        let basics = UIStackView(arrangedSubviews: [
            makeEyebrow("familyTreeMember.section.basic".localized),
            nameCard, genderBlock, birthYearCard, statusBlock, residenceCard
        ])
        basics.axis = .vertical
        basics.spacing = Layout.fieldGap

        let spiritual = UIStackView(arrangedSubviews: [
            makeEyebrow("familyTreeMember.section.spiritual".localized), dharmaNameCard, tabletTempleCard
        ])
        spiritual.axis = .vertical
        spiritual.spacing = Layout.fieldGap

        let note = UIStackView(arrangedSubviews: [makeEyebrow("familyTreeMember.section.note".localized), noteCard])
        note.axis = .vertical
        note.spacing = Layout.fieldGap

        let stack = UIStackView(arrangedSubviews: [basics, memorialFormSection, spiritual, note, submitButton])
        stack.axis = .vertical
        stack.spacing = Layout.editSectionGap
        stack.layoutMargins = UIEdgeInsets(top: Layout.editTop, left: 0, bottom: 0, right: 0)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.isHidden = true
        return stack
    }()

    // MARK: - Initializer
    init(viewModel: ILFamilyTreeMemberViewModel) {
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

        [headerView, headerDivider, scrollView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        headerView.onBack = { [weak self] in
            self?.view.endEditing(true)
            self?.backTappedSubject.send(())
        }
        headerView.onAction = { [weak self] in self?.handleHeaderAction() }
        submitButton.onTap = { [weak self] in self?.save() }

        infoCard.onLinkTap = { [weak self] in self?.templeTappedSubject.send(()) }
        noteView.onEmptyTap = { [weak self] in self?.editTappedSubject.send(()) }
        memorialTiles.onRemind = { [weak self] in self?.remindTappedSubject.send(()) }
        memorialTiles.onLightLamp = { [weak self] in self?.lightLampTappedSubject.send(()) }
        memorialTiles.onChant = { [weak self] in self?.chantTappedSubject.send(()) }

        // Index 0 = "Nam", 1 = "Nữ".
        genderToggle.onSelect = { [weak self] index in self?.genderSelectedSubject.send(index == 0 ? .male : .female) }
        // Index 0 = "Còn sống", 1 = "Đã mất".
        statusToggle.onSelect = { [weak self] index in self?.livingSelectedSubject.send(index == 0) }

        nameCard.onTextChanged = { [weak self] text in self?.nameChangedSubject.send(text) }
        birthYearCard.onTextChanged = { [weak self] text in self?.birthYearChangedSubject.send(text) }
        residenceCard.onTextChanged = { [weak self] text in self?.residenceChangedSubject.send(text) }
        deathYearCard.onTextChanged = { [weak self] text in self?.deathYearChangedSubject.send(text) }
        anniversaryCard.onTextChanged = { [weak self] text in self?.anniversaryChangedSubject.send(text) }
        burialCard.onTextChanged = { [weak self] text in self?.burialPlaceChangedSubject.send(text) }
        dharmaNameCard.onTextChanged = { [weak self] text in self?.dharmaNameChangedSubject.send(text) }
        tabletTempleCard.onTextChanged = { [weak self] text in self?.tabletTempleChangedSubject.send(text) }
        noteCard.onTextChanged = { [weak self] text in self?.noteChangedSubject.send(text) }
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

            // "Năm mất" : "Ngày giỗ" = 1 : 1.4 (design handoff)
            anniversaryCard.widthAnchor.constraint(equalTo: deathYearCard.widthAnchor, multiplier: Layout.anniversaryWidthRatio)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILFamilyTreeMemberViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            editTapped: editTappedSubject.eraseToAnyPublisher(),
            nameChanged: nameChangedSubject.eraseToAnyPublisher(),
            genderSelected: genderSelectedSubject.eraseToAnyPublisher(),
            birthYearChanged: birthYearChangedSubject.eraseToAnyPublisher(),
            livingSelected: livingSelectedSubject.eraseToAnyPublisher(),
            residenceChanged: residenceChangedSubject.eraseToAnyPublisher(),
            deathYearChanged: deathYearChangedSubject.eraseToAnyPublisher(),
            anniversaryChanged: anniversaryChangedSubject.eraseToAnyPublisher(),
            burialPlaceChanged: burialPlaceChangedSubject.eraseToAnyPublisher(),
            dharmaNameChanged: dharmaNameChangedSubject.eraseToAnyPublisher(),
            tabletTempleChanged: tabletTempleChangedSubject.eraseToAnyPublisher(),
            noteChanged: noteChangedSubject.eraseToAnyPublisher(),
            saveTapped: saveTappedSubject.eraseToAnyPublisher(),
            relationTapped: relationTappedSubject.eraseToAnyPublisher(),
            remindTapped: remindTappedSubject.eraseToAnyPublisher(),
            lightLampTapped: lightLampTappedSubject.eraseToAnyPublisher(),
            chantTapped: chantTappedSubject.eraseToAnyPublisher(),
            templeTapped: templeTappedSubject.eraseToAnyPublisher()
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
    private func render(state: ViewState<ILFamilyTreeMemberStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILFamilyTreeMemberStateModel) {
        applyMode(model.mode)
        updateViewMode(with: model)
        updateEditMode(with: model)
    }

    private func applyMode(_ newMode: ILFamilyTreeMemberMode) {
        guard newMode != mode else { return }
        mode = newMode
        let isEditing = newMode == .edit
        viewStack.isHidden = isEditing
        editStack.isHidden = !isEditing
        headerView.title = (isEditing ? "familyTreeMember.title.edit" : "familyTreeMember.title.view").localized
        headerView.rightActionTitle = (isEditing ? "familyTreeMember.action.save" : "familyTreeMember.action.edit").localized
        scrollView.setContentOffset(.zero, animated: false)
    }

    private func updateViewMode(with model: ILFamilyTreeMemberStateModel) {
        heroView.configure(with: model)
        infoCard.configure(facts: model.facts)
        noteView.configure(note: model.note)
        memorialSection.isHidden = !model.showsMemorial
        relationsSection.isHidden = model.relations.isEmpty
        if renderedRelations != model.relations {
            renderedRelations = model.relations
            relationsStack.arrangedSubviews.forEach {
                relationsStack.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
            model.relations.forEach { relation in
                let row = ILFamilyTreeMemberRelationRowView(relation: relation)
                row.onTap = { [weak self] id in self?.relationTappedSubject.send(id) }
                relationsStack.addArrangedSubview(row)
            }
        }
    }

    private func updateEditMode(with model: ILFamilyTreeMemberStateModel) {
        let draft = model.draft
        apply(draft.name, error: model.error(for: .name), to: nameCard)
        genderToggle.selectedIndex = draft.gender == .male ? 0 : 1
        apply(draft.birthYear, error: model.error(for: .birthYear), to: birthYearCard)

        statusToggle.selectedIndex = draft.isLiving ? 0 : 1
        residenceCard.isHidden = !draft.isLiving
        memorialFormSection.isHidden = draft.isLiving
        residenceCard.text = draft.residence
        apply(draft.deathYear, error: model.error(for: .deathYear), to: deathYearCard)
        apply(draft.anniversary, error: model.error(for: .anniversary), to: anniversaryCard)
        burialCard.text = draft.burialPlace
        dharmaNameCard.text = draft.dharmaName
        tabletTempleCard.text = draft.tabletTemple
        noteCard.text = draft.note

        submitButton.buttonState = model.isSubmitting ? .loading : .normal

        if model.mode == .edit, let field = model.errorField {
            focus(field)
        }
    }

    private func apply(_ text: String, error: String?, to card: ILInputCardView) {
        card.text = text
        card.errorText = error
    }

    /// Scrolls to the invalid field and puts the caret in it.
    private func focus(_ field: ILFamilyTreeMemberField) {
        let target: ILInputCardView
        switch field {
        case .member: return
        case .name: target = nameCard
        case .birthYear: target = birthYearCard
        case .deathYear: target = deathYearCard
        case .anniversary: target = anniversaryCard
        }
        scrollView.layoutIfNeeded()
        scrollView.scrollRectToVisible(target.convert(target.bounds, to: scrollView), animated: true)
        target.focus()
    }

    // MARK: - Actions
    private func handleHeaderAction() {
        switch mode {
        case .view: editTappedSubject.send(())
        case .edit: save()
        }
    }

    private func save() {
        view.endEditing(true)
        saveTappedSubject.send(())
    }

    // MARK: - Factories
    /// `prefix.field.<key>` / `.placeholder` is the localization pair of the card.
    private func makeCard(_ key: String, keyboard: UIKeyboardType = .default, prefix: String = "familyTreeAddMember") -> ILInputCardView {
        let card = ILInputCardView(label: "\(prefix).field.\(key)".localized)
        card.placeholder = "\(prefix).field.\(key).placeholder".localized
        card.keyboardType = keyboard
        return card
    }

    private func makeEyebrow(_ title: String) -> UILabel {
        let label = UILabel()
        label.attributedText = ILTypography.makeEyebrow(text: title, color: Tree.eyebrow)
        return label
    }

    private func makeSection(title: String, content: UIView, titleGap: CGFloat = Layout.sectionTitleGap) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [makeEyebrow(title), content])
        stack.axis = .vertical
        stack.spacing = titleGap
        return stack
    }

    private func makeLabeledBlock(_ labelKey: String, _ control: UIView) -> UIStackView {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.inkSecondary
        label.text = labelKey.localized
        let stack = UIStackView(arrangedSubviews: [label, control])
        stack.axis = .vertical
        stack.spacing = Layout.labelGap
        return stack
    }
}
