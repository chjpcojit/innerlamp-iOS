//
//  ILFamilyTreeCreateViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILFamilyTreeCreateViewController: BaseViewController {

    private typealias Tree = ILColors.FamilyTree

    private enum Layout {
        static let contentTop: CGFloat = 20
        static let contentBottom: CGFloat = 40
        static let sectionGap: CGFloat = 20
        static let fieldGap: CGFloat = 14
        static let eyebrowGap: CGFloat = 14
        static let statusLabelGap: CGFloat = 6
        static let buttonFootnoteGap: CGFloat = 10
        static let deathColumnGap: CGFloat = 10
        static let anniversaryWidthRatio: CGFloat = 1.4
        static let navBarBottomGap: CGFloat = 12
    }

    // MARK: - Properties
    private let viewModel: ILFamilyTreeCreateViewModel
    private var cancellables = Set<AnyCancellable>()

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let clanNameChangedSubject = PassthroughSubject<String, Never>()
    private let hometownChangedSubject = PassthroughSubject<String, Never>()
    private let founderNameChangedSubject = PassthroughSubject<String, Never>()
    private let birthYearChangedSubject = PassthroughSubject<String, Never>()
    private let livingSelectedSubject = PassthroughSubject<Bool, Never>()
    private let deathYearChangedSubject = PassthroughSubject<String, Never>()
    private let anniversaryChangedSubject = PassthroughSubject<String, Never>()
    private let spouseNameChangedSubject = PassthroughSubject<String, Never>()
    private let createTappedSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    private lazy var headerView = ILNavBar(title: "familyTreeCreate.title".localized)

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

    private lazy var headerCard = ILFamilyTreeCreateHeaderCardView()

    private lazy var clanNameCard = makeCard("clanName")
    private lazy var hometownCard = makeCard("hometown")
    private lazy var founderNameCard = makeCard("founderName")
    private lazy var birthYearCard = makeCard("birthYear", keyboard: .numberPad)
    private lazy var deathYearCard = makeCard("deathYear", keyboard: .numberPad)
    private lazy var anniversaryCard = makeCard("anniversary")
    private lazy var spouseCard = makeCard("spouse")

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.inkSecondary
        label.text = "familyTreeCreate.field.status".localized
        return label
    }()

    private lazy var statusToggle = ILSegmentedToggleView(titles: [
        "familyTreeCreate.status.deceased".localized,
        "familyTreeCreate.status.living".localized
    ])

    private lazy var deathRow: UIStackView = {
        let row = UIStackView(arrangedSubviews: [deathYearCard, anniversaryCard])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = Layout.deathColumnGap
        return row
    }()

    private lazy var submitButton: ILButton = {
        let button = ILButton(title: "familyTreeCreate.submit".localized, variant: .primary)
        button.loadingTitle = "familyTreeCreate.submit.loading".localized
        return button
    }()

    private lazy var footnoteLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = ILTypography.makeParagraph(
            text: "familyTreeCreate.footnote".localized,
            font: ILTypography.subhead,
            color: Tree.inkMuted,
            cssLineHeight: 1.5,
            alignment: .center
        )
        return label
    }()

    // MARK: - Initializer
    init(viewModel: ILFamilyTreeCreateViewModel) {
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

        let clanSection = makeSection(
            titleKey: "familyTreeCreate.section.clan",
            fields: [clanNameCard, hometownCard]
        )
        let statusBlock = UIStackView(arrangedSubviews: [statusLabel, statusToggle])
        statusBlock.axis = .vertical
        statusBlock.spacing = Layout.statusLabelGap
        let founderSection = makeSection(
            titleKey: "familyTreeCreate.section.founder",
            fields: [founderNameCard, birthYearCard, statusBlock, deathRow, spouseCard]
        )
        let submitBlock = UIStackView(arrangedSubviews: [submitButton, footnoteLabel])
        submitBlock.axis = .vertical
        submitBlock.spacing = Layout.buttonFootnoteGap

        [headerCard, clanSection, founderSection, submitBlock].forEach { contentStack.addArrangedSubview($0) }

        headerView.onBack = { [weak self] in self?.backTappedSubject.send(()) }

        clanNameCard.onTextChanged = { [weak self] text in self?.clanNameChangedSubject.send(text) }
        hometownCard.onTextChanged = { [weak self] text in self?.hometownChangedSubject.send(text) }
        founderNameCard.onTextChanged = { [weak self] text in self?.founderNameChangedSubject.send(text) }
        birthYearCard.onTextChanged = { [weak self] text in self?.birthYearChangedSubject.send(text) }
        deathYearCard.onTextChanged = { [weak self] text in self?.deathYearChangedSubject.send(text) }
        anniversaryCard.onTextChanged = { [weak self] text in self?.anniversaryChangedSubject.send(text) }
        spouseCard.onTextChanged = { [weak self] text in self?.spouseNameChangedSubject.send(text) }

        // Index 0 = "Đã mất", 1 = "Còn sống".
        statusToggle.onSelect = { [weak self] index in self?.livingSelectedSubject.send(index == 1) }
        submitButton.onTap = { [weak self] in
            self?.view.endEditing(true)
            self?.createTappedSubject.send(())
        }
    }

    override func setupConstraints() {
        super.setupConstraints()

        // Let the scroll view run to the screen's bottom edge (content scrolls through the home-indicator
        // area instead of being clipped at the safe area); its automatic inset keeps the button clear of it.
        view.keyboardLayoutGuide.usesBottomSafeArea = false

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

        let input = ILFamilyTreeCreateViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            clanNameChanged: clanNameChangedSubject.eraseToAnyPublisher(),
            hometownChanged: hometownChangedSubject.eraseToAnyPublisher(),
            founderNameChanged: founderNameChangedSubject.eraseToAnyPublisher(),
            birthYearChanged: birthYearChangedSubject.eraseToAnyPublisher(),
            livingSelected: livingSelectedSubject.eraseToAnyPublisher(),
            deathYearChanged: deathYearChangedSubject.eraseToAnyPublisher(),
            anniversaryChanged: anniversaryChangedSubject.eraseToAnyPublisher(),
            spouseNameChanged: spouseNameChangedSubject.eraseToAnyPublisher(),
            createTapped: createTappedSubject.eraseToAnyPublisher()
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
    private func render(state: ViewState<ILFamilyTreeCreateStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILFamilyTreeCreateStateModel) {
        headerCard.configure(title: model.headerTitle, subtitle: model.headerSubtitle)

        apply(model.clanName, error: model.error(for: .clanName), to: clanNameCard)
        apply(model.hometown, error: model.error(for: .hometown), to: hometownCard)
        apply(model.founderName, error: model.error(for: .founderName), to: founderNameCard)
        apply(model.birthYear, error: model.error(for: .birthYear), to: birthYearCard)
        apply(model.deathYear, error: model.error(for: .deathYear), to: deathYearCard)
        apply(model.anniversary, error: model.error(for: .anniversary), to: anniversaryCard)
        spouseCard.text = model.spouseName

        statusToggle.selectedIndex = model.isFounderLiving ? 1 : 0
        deathRow.isHidden = model.isFounderLiving

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
    private func focus(_ field: ILFamilyTreeCreateField) {
        let card = card(for: field)
        scrollView.layoutIfNeeded()
        scrollView.scrollRectToVisible(card.convert(card.bounds, to: scrollView), animated: true)
        card.focus()
    }

    private func card(for field: ILFamilyTreeCreateField) -> ILInputCardView {
        switch field {
        case .clanName: return clanNameCard
        case .hometown: return hometownCard
        case .founderName: return founderNameCard
        case .birthYear: return birthYearCard
        case .deathYear: return deathYearCard
        case .anniversary: return anniversaryCard
        }
    }

    // MARK: - Factories
    /// `key` is the `familyTreeCreate.field.<key>` / `.placeholder` localization pair.
    private func makeCard(_ key: String, keyboard: UIKeyboardType = .default) -> ILInputCardView {
        let card = ILInputCardView(label: "familyTreeCreate.field.\(key)".localized)
        card.placeholder = "familyTreeCreate.field.\(key).placeholder".localized
        card.keyboardType = keyboard
        return card
    }

    private func makeSection(titleKey: String, fields: [UIView]) -> UIStackView {
        let section = UIStackView(arrangedSubviews: [ILSectionEyebrowView(title: titleKey.localized)] + fields)
        section.axis = .vertical
        section.spacing = Layout.fieldGap
        section.setCustomSpacing(Layout.eyebrowGap, after: section.arrangedSubviews[0])
        return section
    }
}
