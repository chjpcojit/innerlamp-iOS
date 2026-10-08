//
//  ILFamilyTreeAddMemberViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILFamilyTreeAddMemberViewController: BaseViewController {

    private typealias Tree = ILColors.FamilyTree

    private enum Layout {
        static let contentTop: CGFloat = 18
        static let contentBottom: CGFloat = 40
        static let sectionGap: CGFloat = 18
        static let relationGap: CGFloat = 10
        static let fieldGap: CGFloat = 14
        static let labelGap: CGFloat = 6
        static let deathColumnGap: CGFloat = 10
        static let anniversaryWidthRatio: CGFloat = 1.4
        static let navBarBottomGap: CGFloat = 12
        static let lockedAlpha: CGFloat = 0.6
    }

    // MARK: - Properties
    private let viewModel: ILFamilyTreeAddMemberViewModel
    private var cancellables = Set<AnyCancellable>()

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let closeTappedSubject = PassthroughSubject<Void, Never>()
    private let relationSelectedSubject = PassthroughSubject<ILFamilyAddRelation, Never>()
    private let pickerToggledSubject = PassthroughSubject<Void, Never>()
    private let relativePickedSubject = PassthroughSubject<String, Never>()
    private let nameChangedSubject = PassthroughSubject<String, Never>()
    private let genderSelectedSubject = PassthroughSubject<ILFamilyGender, Never>()
    private let birthYearChangedSubject = PassthroughSubject<String, Never>()
    private let livingSelectedSubject = PassthroughSubject<Bool, Never>()
    private let deathYearChangedSubject = PassthroughSubject<String, Never>()
    private let anniversaryChangedSubject = PassthroughSubject<String, Never>()
    private let residenceChangedSubject = PassthroughSubject<String, Never>()
    private let burialPlaceChangedSubject = PassthroughSubject<String, Never>()
    private let noteChangedSubject = PassthroughSubject<String, Never>()
    private let saveTappedSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    private lazy var headerView = ILNavBar(
        title: "familyTreeAddMember.title".localized,
        rightActionTitle: "familyTreeAddMember.save".localized,
        showBack: false,
        showClose: true
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

    private lazy var relationToggle = ILSegmentedToggleView(titles: [
        "familyTreeAddMember.relation.child".localized,
        "familyTreeAddMember.relation.spouse".localized
    ])
    private lazy var relativeCard = ILFamilyTreeAddMemberRelativeCardView()
    private lazy var pickerView: ILFamilyTreeAddMemberPickerView = {
        let picker = ILFamilyTreeAddMemberPickerView()
        picker.isHidden = true
        return picker
    }()
    private lazy var previewLabel = makeLabel(font: ILTypography.treeNote, color: Tree.selected)
    private lazy var relationErrorLabel = makeLabel(font: ILTypography.subheadMedium, color: ILColors.danger)

    private lazy var nameCard = makeCard("name")
    private lazy var genderLabel = makeLabel(font: ILTypography.subhead, color: ILColors.inkSecondary,
                                             text: "familyTreeAddMember.field.gender".localized)
    private lazy var genderToggle = ILSegmentedToggleView(titles: [
        "familyTreeAddMember.gender.male".localized,
        "familyTreeAddMember.gender.female".localized
    ])
    private lazy var genderLockedLabel = makeLabel(font: ILTypography.caption, color: Tree.inkMuted,
                                                   text: "familyTreeAddMember.gender.locked".localized)
    private lazy var birthYearCard = makeCard("birthYear", keyboard: .numberPad)
    private lazy var statusLabel = makeLabel(font: ILTypography.subhead, color: ILColors.inkSecondary,
                                             text: "familyTreeAddMember.field.status".localized)
    private lazy var statusToggle = ILSegmentedToggleView(titles: [
        "familyTreeAddMember.status.living".localized,
        "familyTreeAddMember.status.deceased".localized
    ])
    private lazy var residenceCard = makeCard("residence")
    private lazy var deathYearCard = makeCard("deathYear", keyboard: .numberPad)
    private lazy var anniversaryCard = makeCard("anniversary")
    private lazy var burialCard = makeCard("burialPlace")
    private lazy var noteCard: ILInputCardView = {
        let card = ILInputCardView(
            label: "familyTreeAddMember.field.note".localized,
            placeholder: "familyTreeAddMember.field.note.placeholder".localized,
            style: .multiLine
        )
        return card
    }()

    private lazy var deathRow: UIStackView = {
        let row = UIStackView(arrangedSubviews: [deathYearCard, anniversaryCard])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = Layout.deathColumnGap
        return row
    }()

    private lazy var submitButton: ILButton = {
        let button = ILButton(title: "familyTreeAddMember.submit".localized, variant: .primary)
        button.loadingTitle = "familyTreeAddMember.submit.loading".localized
        return button
    }()

    // MARK: - Initializer
    init(viewModel: ILFamilyTreeAddMemberViewModel) {
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

        let relationSection = UIStackView(arrangedSubviews: [
            ILSectionEyebrowView(title: "familyTreeAddMember.section.relation".localized),
            relationToggle, relativeCard, pickerView, previewLabel, relationErrorLabel
        ])
        relationSection.axis = .vertical
        relationSection.spacing = Layout.relationGap

        let genderBlock = UIStackView(arrangedSubviews: [genderLabel, genderToggle, genderLockedLabel])
        genderBlock.axis = .vertical
        genderBlock.spacing = Layout.labelGap
        let statusBlock = UIStackView(arrangedSubviews: [statusLabel, statusToggle])
        statusBlock.axis = .vertical
        statusBlock.spacing = Layout.labelGap

        let infoSection = UIStackView(arrangedSubviews: [
            ILSectionEyebrowView(title: "familyTreeAddMember.section.info".localized),
            nameCard, genderBlock, birthYearCard, statusBlock, residenceCard, deathRow, burialCard, noteCard
        ])
        infoSection.axis = .vertical
        infoSection.spacing = Layout.fieldGap

        [relationSection, infoSection, submitButton].forEach { contentStack.addArrangedSubview($0) }

        headerView.onClose = { [weak self] in self?.closeTappedSubject.send(()) }
        headerView.onAction = { [weak self] in self?.save() }
        submitButton.onTap = { [weak self] in self?.save() }

        // Index 0 = "Con của", 1 = "Vợ / chồng của".
        relationToggle.onSelect = { [weak self] index in self?.relationSelectedSubject.send(index == 0 ? .child : .spouse) }
        relativeCard.onToggle = { [weak self] in self?.pickerToggledSubject.send(()) }
        pickerView.onPick = { [weak self] id in self?.relativePickedSubject.send(id) }
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

        let input = ILFamilyTreeAddMemberViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            closeTapped: closeTappedSubject.eraseToAnyPublisher(),
            relationSelected: relationSelectedSubject.eraseToAnyPublisher(),
            pickerToggled: pickerToggledSubject.eraseToAnyPublisher(),
            relativePicked: relativePickedSubject.eraseToAnyPublisher(),
            nameChanged: nameChangedSubject.eraseToAnyPublisher(),
            genderSelected: genderSelectedSubject.eraseToAnyPublisher(),
            birthYearChanged: birthYearChangedSubject.eraseToAnyPublisher(),
            livingSelected: livingSelectedSubject.eraseToAnyPublisher(),
            deathYearChanged: deathYearChangedSubject.eraseToAnyPublisher(),
            anniversaryChanged: anniversaryChangedSubject.eraseToAnyPublisher(),
            residenceChanged: residenceChangedSubject.eraseToAnyPublisher(),
            burialPlaceChanged: burialPlaceChangedSubject.eraseToAnyPublisher(),
            noteChanged: noteChangedSubject.eraseToAnyPublisher(),
            saveTapped: saveTappedSubject.eraseToAnyPublisher()
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
    private func render(state: ViewState<ILFamilyTreeAddMemberStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILFamilyTreeAddMemberStateModel) {
        let draft = model.draft

        relationToggle.selectedIndex = draft.relation == .child ? 0 : 1
        relativeCard.configure(name: model.relativeName, meta: model.relativeMeta, isPickerOpen: model.isPickerOpen)
        pickerView.isHidden = !model.isPickerOpen
        pickerView.configure(rows: model.people)
        previewLabel.text = model.preview
        relationErrorLabel.text = model.error(for: .relation)
        relationErrorLabel.isHidden = model.error(for: .relation) == nil

        apply(draft.name, error: model.error(for: .name), to: nameCard)
        genderToggle.selectedIndex = model.shownGender == .male ? 0 : 1
        genderToggle.isUserInteractionEnabled = !model.isGenderLocked
        genderToggle.alpha = model.isGenderLocked ? Layout.lockedAlpha : 1
        genderLockedLabel.isHidden = !model.isGenderLocked
        apply(draft.birthYear, error: model.error(for: .birthYear), to: birthYearCard)

        statusToggle.selectedIndex = draft.isLiving ? 0 : 1
        residenceCard.isHidden = !draft.isLiving
        deathRow.isHidden = draft.isLiving
        burialCard.isHidden = draft.isLiving
        apply(draft.residence, error: model.error(for: .residence), to: residenceCard)
        apply(draft.deathYear, error: model.error(for: .deathYear), to: deathYearCard)
        apply(draft.anniversary, error: model.error(for: .anniversary), to: anniversaryCard)
        burialCard.text = draft.burialPlace
        noteCard.text = draft.note

        submitButton.buttonState = model.isSubmitting ? .loading : .normal

        if let field = model.errorField {
            focus(field)
        }
    }

    private func apply(_ text: String, error: String?, to card: ILInputCardView) {
        card.text = text
        card.errorText = error
    }

    /// Scrolls to the invalid field and puts the caret in it.
    private func focus(_ field: ILFamilyTreeAddMemberField) {
        let target: UIView
        switch field {
        case .relation: target = relativeCard
        case .name: target = nameCard
        case .birthYear: target = birthYearCard
        case .deathYear: target = deathYearCard
        case .anniversary: target = anniversaryCard
        case .residence: target = residenceCard
        }
        scrollView.layoutIfNeeded()
        scrollView.scrollRectToVisible(target.convert(target.bounds, to: scrollView), animated: true)
        (target as? ILInputCardView)?.focus()
    }

    // MARK: - Actions
    private func save() {
        view.endEditing(true)
        saveTappedSubject.send(())
    }

    // MARK: - Factories
    /// `key` is the `familyTreeAddMember.field.<key>` / `.placeholder` localization pair.
    private func makeCard(_ key: String, keyboard: UIKeyboardType = .default) -> ILInputCardView {
        let card = ILInputCardView(label: "familyTreeAddMember.field.\(key)".localized)
        card.placeholder = "familyTreeAddMember.field.\(key).placeholder".localized
        card.keyboardType = keyboard
        return card
    }

    private func makeLabel(font: UIFont, color: UIColor, text: String? = nil) -> UILabel {
        let label = UILabel()
        label.font = font
        label.textColor = color
        label.numberOfLines = 0
        label.text = text
        return label
    }
}
