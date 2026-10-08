//
//  ILFamilyTreeMemberViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILFamilyTreeMemberNavEvent: Equatable {
    case back
    /// The edit was validated and saved; the profile stays open, the owning coordinator hands the
    /// updated tree back to the family tree.
    case saved(tree: ILFamilyTreeEntity, memberID: String)
    /// A relation row: show that person on the tree.
    case openMember(String)
    /// TƯỞNG NIỆM tiles and the temple link act on this member (destinations unconfirmed —
    /// TD-FamilyTreeMember-003).
    case remind(String)
    case lightLamp(String)
    case chant(String)
    case openTemple(String)
}

protocol ILFamilyTreeMemberViewModelProtocol: ViewModelType {
    /// Independent of `transform(input:)` — the owning `ILFamilyTreeMemberCoordinator` subscribes to
    /// this directly in `start()`, before the ViewController exists.
    var navigationEventPublisher: AnyPublisher<ILFamilyTreeMemberNavEvent, Never> { get }
}

final class ILFamilyTreeMemberViewModel: ILFamilyTreeMemberViewModelProtocol {

    private static let yearDigits = 4

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        /// Back chip: leaves the screen in view mode, discards the edit in edit mode.
        let backTapped: AnyPublisher<Void, Never>
        let editTapped: AnyPublisher<Void, Never>
        let nameChanged: AnyPublisher<String, Never>
        let genderSelected: AnyPublisher<ILFamilyGender, Never>
        let birthYearChanged: AnyPublisher<String, Never>
        /// true = "Còn sống", false = "Đã mất".
        let livingSelected: AnyPublisher<Bool, Never>
        let residenceChanged: AnyPublisher<String, Never>
        let deathYearChanged: AnyPublisher<String, Never>
        let anniversaryChanged: AnyPublisher<String, Never>
        let burialPlaceChanged: AnyPublisher<String, Never>
        let dharmaNameChanged: AnyPublisher<String, Never>
        let tabletTempleChanged: AnyPublisher<String, Never>
        let noteChanged: AnyPublisher<String, Never>
        let saveTapped: AnyPublisher<Void, Never>
        /// A row of the QUAN HỆ list.
        let relationTapped: AnyPublisher<String, Never>
        let remindTapped: AnyPublisher<Void, Never>
        let lightLampTapped: AnyPublisher<Void, Never>
        let chantTapped: AnyPublisher<Void, Never>
        let templeTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILFamilyTreeMemberStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILFamilyTreeMemberNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILFamilyTreeMemberNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILFamilyTreeMemberStateModel>, Never>
    private var currentState = ILFamilyTreeMemberStateModel()
    private let useCase: ILFamilyTreeMemberUseCase
    /// Working copy: replaced by the updated tree after every successful save.
    private var tree: ILFamilyTreeEntity
    private let memberID: String
    private let kinship: String?
    private let now: () -> Date
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(
        useCase: ILFamilyTreeMemberUseCase,
        tree: ILFamilyTreeEntity,
        memberID: String,
        kinship: String?,
        now: @escaping () -> Date = Date.init
    ) {
        self.useCase = useCase
        self.tree = tree
        self.memberID = memberID
        self.kinship = kinship
        self.now = now
        stateSubject = CurrentValueSubject(.success(ILFamilyTreeMemberStateModel()))
        refreshDisplay()
        publish()
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.publish() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.handleBackTapped() }
            .store(in: &cancellables)

        input.editTapped
            .sink { [weak self] _ in self?.handleEditTapped() }
            .store(in: &cancellables)

        input.nameChanged
            .sink { [weak self] text in self?.edit { $0.draft.name = text } }
            .store(in: &cancellables)

        input.genderSelected
            .sink { [weak self] gender in self?.edit { $0.draft.gender = gender } }
            .store(in: &cancellables)

        input.birthYearChanged
            .sink { [weak self] text in self?.edit { $0.draft.birthYear = Self.yearText(text) } }
            .store(in: &cancellables)

        input.livingSelected
            .sink { [weak self] isLiving in self?.edit { $0.draft.isLiving = isLiving } }
            .store(in: &cancellables)

        input.residenceChanged
            .sink { [weak self] text in self?.edit { $0.draft.residence = text } }
            .store(in: &cancellables)

        input.deathYearChanged
            .sink { [weak self] text in self?.edit { $0.draft.deathYear = Self.yearText(text) } }
            .store(in: &cancellables)

        input.anniversaryChanged
            .sink { [weak self] text in self?.edit { $0.draft.anniversary = text } }
            .store(in: &cancellables)

        input.burialPlaceChanged
            .sink { [weak self] text in self?.edit { $0.draft.burialPlace = text } }
            .store(in: &cancellables)

        input.dharmaNameChanged
            .sink { [weak self] text in self?.edit { $0.draft.dharmaName = text } }
            .store(in: &cancellables)

        input.tabletTempleChanged
            .sink { [weak self] text in self?.edit { $0.draft.tabletTemple = text } }
            .store(in: &cancellables)

        input.noteChanged
            .sink { [weak self] text in self?.edit { $0.draft.note = text } }
            .store(in: &cancellables)

        input.saveTapped
            .sink { [weak self] _ in self?.handleSaveTapped() }
            .store(in: &cancellables)

        input.relationTapped
            .sink { [weak self] id in self?.navigationEventSubject.send(.openMember(id)) }
            .store(in: &cancellables)

        input.remindTapped
            .sink { [weak self] _ in self?.sendForMember { .remind($0) } }
            .store(in: &cancellables)

        input.lightLampTapped
            .sink { [weak self] _ in self?.sendForMember { .lightLamp($0) } }
            .store(in: &cancellables)

        input.chantTapped
            .sink { [weak self] _ in self?.sendForMember { .chant($0) } }
            .store(in: &cancellables)

        input.templeTapped
            .sink { [weak self] _ in self?.sendForMember { .openTemple($0) } }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    /// Emits an event for the member this screen shows.
    private func sendForMember(_ makeEvent: (String) -> ILFamilyTreeMemberNavEvent) {
        navigationEventSubject.send(makeEvent(memberID))
    }

    private func handleBackTapped() {
        guard currentState.mode == .edit else {
            navigationEventSubject.send(.back)
            return
        }
        guard !currentState.isSubmitting else { return }
        currentState.mode = .view
        clearError()
        publish()
    }

    private func handleEditTapped() {
        guard currentState.mode == .view, let member = member else { return }
        currentState.draft = useCase.makeDraft(from: member)
        clearError()
        currentState.mode = .edit
        publish()
    }

    private func handleSaveTapped() {
        guard currentState.mode == .edit, !currentState.isSubmitting else { return }
        let year = Calendar.current.component(.year, from: now())

        switch useCase.updateMember(currentState.draft, memberID: memberID, in: tree, currentYear: year) {
        case .failure(let issue):
            currentState.errorField = issue.field
            currentState.errorMessage = issue.message
            publish()
        case .success(let result):
            clearError()
            currentState.isSubmitting = true
            publish()
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await self.useCase.save(result.tree)
                    self.tree = result.tree
                    self.currentState.isSubmitting = false
                    self.currentState.mode = .view
                    self.refreshDisplay()
                    self.publish()
                    self.navigationEventSubject.send(.saved(tree: result.tree, memberID: result.memberID))
                } catch {
                    self.currentState.isSubmitting = false
                    self.publish() // release the buttons before the error is shown
                    self.stateSubject.send(.failure(error))
                }
            }
        }
    }

    // MARK: - State helpers
    private var member: ILFamilyMemberEntity? {
        tree.members.first { $0.id == memberID }
    }

    /// Applies one field edit and clears any shown error (it may no longer apply).
    private func edit(_ change: (inout ILFamilyTreeMemberStateModel) -> Void) {
        guard currentState.mode == .edit else { return }
        change(&currentState)
        clearError()
        publish()
    }

    private func clearError() {
        currentState.errorField = nil
        currentState.errorMessage = nil
    }

    /// Re-derives every view-mode text from the working tree.
    private func refreshDisplay() {
        guard let member else { return }
        let graph = ILFamilyTreeGraph(members: tree.members)
        let isFounder = member.id == graph.founder?.id
        let isMarriedIn = graph.isMarriedIn(member)
        let generation = graph.generation(of: member)
        let currentYear = Calendar.current.component(.year, from: now())
        let notUpdated = "familyTree.detail.notUpdated".localized

        currentState.look = ILFamilyTreeMedallionLook(
            gender: member.gender, isLiving: member.isLiving, isFounder: isFounder, isClanHead: member.isClanHead
        )
        currentState.name = member.name
        currentState.meta = ILFamilyTreeFormatter.detailMeta(member, generation: generation, isMarriedIn: isMarriedIn)
        currentState.status = ILFamilyTreeFormatter.status(member)
        currentState.role = ILFamilyTreeFormatter.role(member, isFounder: isFounder)
        currentState.kinship = kinship
        currentState.note = member.note
        currentState.showsMemorial = !member.isLiving

        var facts = [ILFamilyTreeMemberFactModel]()
        func add(_ key: String, _ value: String, isLink: Bool = false) {
            facts.append(ILFamilyTreeMemberFactModel(key: key.localized, value: value, isLink: isLink, isEmphasized: false))
        }
        add("familyTree.detail.years", ILFamilyTreeFormatter.years(member, currentYear: currentYear))
        if let anniversary = ILFamilyTreeFormatter.anniversary(member) { add("familyTree.detail.anniversary", anniversary) }
        if member.isLiving {
            add("familyTree.detail.residence", member.residence ?? notUpdated)
        } else {
            add("familyTree.detail.burial", member.burialPlace ?? notUpdated)
        }
        if let dharmaName = member.dharmaName { add("familyTree.detail.dharmaName", dharmaName) }
        if let temple = member.tabletTemple { add("familyTree.detail.tablet", temple, isLink: true) }
        add("familyTree.detail.branch", ILFamilyTreeFormatter.branch(graph.branch(of: member), isBranchEnd: isBranchEnd(member, graph: graph)))
        currentState.facts = facts

        currentState.relations = graph.relations(of: member).map { relation in
            ILFamilyTreeRelationModel(
                memberID: relation.member.id,
                kind: ILFamilyTreeFormatter.relation(relation.kind),
                name: relation.member.name,
                generation: ILFamilyTreeFormatter.generationLabel(graph.generation(of: relation.member))
            )
        }
    }

    /// A deceased blood descendant (not a married-in spouse, not the founder) with no children.
    private func isBranchEnd(_ member: ILFamilyMemberEntity, graph: ILFamilyTreeGraph) -> Bool {
        !member.isLiving
            && !graph.isMarriedIn(member)
            && graph.generation(of: member) > 1
            && graph.children(of: member.id).isEmpty
    }

    /// Years take digits only, at most four.
    private static func yearText(_ text: String) -> String {
        String(text.filter(\.isNumber).prefix(yearDigits))
    }

    private func publish() {
        stateSubject.send(.success(currentState))
    }
}
