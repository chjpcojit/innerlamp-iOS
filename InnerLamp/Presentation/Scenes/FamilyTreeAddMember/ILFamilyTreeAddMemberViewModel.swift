//
//  ILFamilyTreeAddMemberViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILFamilyTreeAddMemberNavEvent: Equatable {
    case close
    /// The member was validated and saved; the owning coordinator hands the new tree back.
    case saved(tree: ILFamilyTreeEntity, memberID: String)
}

protocol ILFamilyTreeAddMemberViewModelProtocol: ViewModelType {
    /// Independent of `transform(input:)` — the owning `ILFamilyTreeAddMemberCoordinator`
    /// subscribes to this directly in `start()`, before the ViewController exists.
    var navigationEventPublisher: AnyPublisher<ILFamilyTreeAddMemberNavEvent, Never> { get }
}

final class ILFamilyTreeAddMemberViewModel: ILFamilyTreeAddMemberViewModelProtocol {

    private static let yearDigits = 4

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let closeTapped: AnyPublisher<Void, Never>
        let relationSelected: AnyPublisher<ILFamilyAddRelation, Never>
        let pickerToggled: AnyPublisher<Void, Never>
        let relativePicked: AnyPublisher<String, Never>
        let nameChanged: AnyPublisher<String, Never>
        let genderSelected: AnyPublisher<ILFamilyGender, Never>
        let birthYearChanged: AnyPublisher<String, Never>
        /// true = "Còn sống", false = "Đã mất".
        let livingSelected: AnyPublisher<Bool, Never>
        let deathYearChanged: AnyPublisher<String, Never>
        let anniversaryChanged: AnyPublisher<String, Never>
        let residenceChanged: AnyPublisher<String, Never>
        let burialPlaceChanged: AnyPublisher<String, Never>
        let noteChanged: AnyPublisher<String, Never>
        let saveTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILFamilyTreeAddMemberStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILFamilyTreeAddMemberNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILFamilyTreeAddMemberNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILFamilyTreeAddMemberStateModel>, Never>
    private var currentState = ILFamilyTreeAddMemberStateModel()
    private let useCase: ILFamilyTreeAddMemberUseCase
    private let tree: ILFamilyTreeEntity
    private let graph: ILFamilyTreeGraph
    private let now: () -> Date
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    /// `relativeID` is the person the new member is attached to (the selected one in the tree).
    init(
        useCase: ILFamilyTreeAddMemberUseCase,
        tree: ILFamilyTreeEntity,
        relativeID: String,
        relation: ILFamilyAddRelation = .child,
        now: @escaping () -> Date = Date.init
    ) {
        self.useCase = useCase
        self.tree = tree
        self.graph = ILFamilyTreeGraph(members: tree.members)
        self.now = now
        var initial = ILFamilyTreeAddMemberStateModel()
        initial.draft.relativeID = relativeID
        initial.draft.relation = relation
        currentState = initial
        stateSubject = CurrentValueSubject(.success(initial))
        refresh()
        publish()
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.publish() }
            .store(in: &cancellables)

        input.closeTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.close) }
            .store(in: &cancellables)

        input.relationSelected
            .sink { [weak self] relation in self?.edit { $0.draft.relation = relation } }
            .store(in: &cancellables)

        input.pickerToggled
            .sink { [weak self] _ in
                self?.currentState.isPickerOpen.toggle()
                self?.refresh()
                self?.publish()
            }
            .store(in: &cancellables)

        input.relativePicked
            .sink { [weak self] id in
                self?.currentState.isPickerOpen = false
                self?.edit { $0.draft.relativeID = id }
            }
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

        input.deathYearChanged
            .sink { [weak self] text in self?.edit { $0.draft.deathYear = Self.yearText(text) } }
            .store(in: &cancellables)

        input.anniversaryChanged
            .sink { [weak self] text in self?.edit { $0.draft.anniversary = text } }
            .store(in: &cancellables)

        input.residenceChanged
            .sink { [weak self] text in self?.edit { $0.draft.residence = text } }
            .store(in: &cancellables)

        input.burialPlaceChanged
            .sink { [weak self] text in self?.edit { $0.draft.burialPlace = text } }
            .store(in: &cancellables)

        input.noteChanged
            .sink { [weak self] text in self?.edit { $0.draft.note = text } }
            .store(in: &cancellables)

        input.saveTapped
            .sink { [weak self] _ in self?.handleSaveTapped() }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleSaveTapped() {
        guard !currentState.isSubmitting else { return }
        let year = Calendar.current.component(.year, from: now())

        switch useCase.addMember(currentState.draft, to: tree, currentYear: year) {
        case .failure(let issue):
            currentState.errorField = issue.field
            currentState.errorMessage = issue.message
            publish()
        case .success(let result):
            currentState.errorField = nil
            currentState.errorMessage = nil
            currentState.isSubmitting = true
            publish()
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await self.useCase.save(result.tree)
                    self.currentState.isSubmitting = false
                    self.publish()
                    self.navigationEventSubject.send(.saved(tree: result.tree, memberID: result.memberID))
                } catch {
                    self.currentState.isSubmitting = false
                    self.publish() // release the button before the error is shown
                    self.stateSubject.send(.failure(error))
                }
            }
        }
    }

    // MARK: - State helpers
    /// Applies one field edit, clears any shown error (it may no longer apply) and re-derives the
    /// relative card / preview / gender.
    private func edit(_ change: (inout ILFamilyTreeAddMemberStateModel) -> Void) {
        change(&currentState)
        currentState.errorField = nil
        currentState.errorMessage = nil
        refresh()
        publish()
    }

    private func refresh() {
        let draft = currentState.draft
        guard let relative = graph.member(id: draft.relativeID) else { return }

        currentState.relativeName = relative.name
        currentState.relativeMeta = [
            personMeta(relative),
            (relative.isLiving ? "familyTreeAddMember.relative.meta.living" : "familyTreeAddMember.relative.meta.deceased").localized
        ].joined(separator: " · ")
        currentState.people = tree.members.map {
            ILFamilyTreeAddMemberPersonRow(id: $0.id, name: $0.name, meta: personMeta($0), isSelected: $0.id == relative.id)
        }
        currentState.preview = preview(for: draft.relation, relative: relative)
        currentState.isGenderLocked = draft.relation == .spouse
        currentState.shownGender = draft.relation == .spouse
            ? (relative.gender == .male ? .female : .male)
            : draft.gender
    }

    /// "Đời N", or "Đời N · dâu/rể" for a married-in person.
    private func personMeta(_ member: ILFamilyMemberEntity) -> String {
        let generation = graph.generation(of: member)
        let key: String
        if graph.isMarriedIn(member) {
            key = member.gender == .female
                ? "familyTreeAddMember.person.meta.daughterInLaw"
                : "familyTreeAddMember.person.meta.sonInLaw"
        } else {
            key = "familyTreeAddMember.person.meta.generation"
        }
        return String(format: key.localized, generation)
    }

    private func preview(for relation: ILFamilyAddRelation, relative: ILFamilyMemberEntity) -> String {
        switch relation {
        case .child:
            let parent = graph.isMarriedIn(relative)
                ? (relative.spouseID.flatMap { graph.member(id: $0) } ?? relative)
                : relative
            let generation = graph.generation(of: parent) + 1
            if let partner = graph.spouse(of: parent.id) {
                return String(format: "familyTreeAddMember.preview.childBoth".localized, generation, parent.name, partner.name)
            }
            return String(format: "familyTreeAddMember.preview.child".localized, generation, parent.name)
        case .spouse:
            let key = relative.gender == .male ? "familyTreeAddMember.preview.wife" : "familyTreeAddMember.preview.husband"
            return String(format: key.localized, graph.generation(of: relative), relative.name)
        }
    }

    /// Years take digits only, at most four.
    private static func yearText(_ text: String) -> String {
        String(text.filter(\.isNumber).prefix(yearDigits))
    }

    private func publish() {
        stateSubject.send(.success(currentState))
    }
}
