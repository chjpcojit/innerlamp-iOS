//
//  ILFamilyTreeChronicleViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILFamilyTreeChronicleNavEvent: Equatable {
    case back
    /// An edit or a clan-head change was saved; the screen stays open. Carries every book.
    case updated([ILFamilyTreeEntity])
    /// A person row (founder, keeper, notable person) was tapped — the tree should select them.
    case openMember(treeID: String, memberID: String)
    /// "Nhắc giỗ tổ hằng năm" (no Sổ giỗ hand-off yet — TD-FamilyTreeChronicle-003).
    case remindFounderAnniversary(treeID: String, memberID: String)
}

/// One edit of a form field, carrying the raw text.
enum ILFamilyTreeChronicleFieldEdit: Equatable {
    case hometown(String)
    case origin(String)
    case milestoneYear(id: String, text: String)
    case milestoneText(id: String, text: String)
    case shrineName(String)
    case shrineAddress(String)
    case annualGathering(String)
    case plaqueHan(String)
    case plaqueMeaning(String)
    case coupletUpper(String)
    case coupletLower(String)
    case teachings(String)
}

protocol ILFamilyTreeChronicleViewModelProtocol: ViewModelType {
    /// Independent of `transform(input:)` — the owning `ILFamilyTreeChronicleCoordinator`
    /// subscribes to this directly in `start()`, before the ViewController exists.
    var navigationEventPublisher: AnyPublisher<ILFamilyTreeChronicleNavEvent, Never> { get }
}

final class ILFamilyTreeChronicleViewModel: ILFamilyTreeChronicleViewModelProtocol {

    private static let yearDigits = 4
    private static let maxPeople = 4

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        /// Nav-bar "Sửa" / "Xong" and the "Chưa có … bấm để …" placeholders.
        let editToggled: AnyPublisher<Void, Never>
        /// Book tab, by tree id.
        let tabSelected: AnyPublisher<String, Never>
        let fieldEdited: AnyPublisher<ILFamilyTreeChronicleFieldEdit, Never>
        let milestoneAdded: AnyPublisher<Void, Never>
        let milestoneDeleted: AnyPublisher<String, Never>
        /// "Đổi" next to the keeper, and the sheet that follows it.
        let headChangeTapped: AnyPublisher<Void, Never>
        let headPickerDismissed: AnyPublisher<Void, Never>
        let headCandidatePicked: AnyPublisher<String, Never>
        let headChangeConfirmed: AnyPublisher<Void, Never>
        let headChangeCancelled: AnyPublisher<Void, Never>
        let founderTapped: AnyPublisher<Void, Never>
        let keeperTapped: AnyPublisher<Void, Never>
        let personTapped: AnyPublisher<String, Never>
        let remindFounderTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILFamilyTreeChronicleStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILFamilyTreeChronicleNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILFamilyTreeChronicleNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILFamilyTreeChronicleStateModel>, Never>
    private var currentState = ILFamilyTreeChronicleStateModel()
    private let useCase: ILFamilyTreeChronicleUseCase
    private var trees: [ILFamilyTreeEntity]
    private var activeIndex: Int
    private let makeID: () -> String
    private let now: () -> Date
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(
        useCase: ILFamilyTreeChronicleUseCase,
        trees: [ILFamilyTreeEntity],
        initialTreeID: String,
        makeID: @escaping () -> String = { "m" + UUID().uuidString },
        now: @escaping () -> Date = Date.init
    ) {
        self.useCase = useCase
        self.trees = trees
        self.activeIndex = trees.firstIndex(where: { $0.id == initialTreeID }) ?? 0
        self.makeID = makeID
        self.now = now
        stateSubject = CurrentValueSubject(.success(ILFamilyTreeChronicleStateModel()))
        refresh()
        publish()
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.publish() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.back) }
            .store(in: &cancellables)

        input.editToggled
            .sink { [weak self] _ in self?.handleEditToggled() }
            .store(in: &cancellables)

        input.tabSelected
            .sink { [weak self] id in self?.handleTabSelected(id) }
            .store(in: &cancellables)

        input.fieldEdited
            .sink { [weak self] edit in self?.handleFieldEdited(edit) }
            .store(in: &cancellables)

        input.milestoneAdded
            .sink { [weak self] _ in self?.handleMilestoneAdded() }
            .store(in: &cancellables)

        input.milestoneDeleted
            .sink { [weak self] id in self?.handleMilestoneDeleted(id) }
            .store(in: &cancellables)

        input.headChangeTapped
            .sink { [weak self] _ in self?.handleHeadChangeTapped() }
            .store(in: &cancellables)

        input.headPickerDismissed
            .sink { [weak self] _ in
                self?.currentState.isHeadPickerOpen = false
                self?.publish()
            }
            .store(in: &cancellables)

        input.headCandidatePicked
            .sink { [weak self] id in self?.handleHeadCandidatePicked(id) }
            .store(in: &cancellables)

        input.headChangeConfirmed
            .sink { [weak self] _ in self?.handleHeadChangeConfirmed() }
            .store(in: &cancellables)

        input.headChangeCancelled
            .sink { [weak self] _ in
                self?.currentState.pendingHead = nil
                self?.publish()
            }
            .store(in: &cancellables)

        input.founderTapped
            .sink { [weak self] _ in self?.openMember(self?.currentState.founderMemberID) }
            .store(in: &cancellables)

        input.keeperTapped
            .sink { [weak self] _ in self?.openMember(self?.currentState.keeperMemberID) }
            .store(in: &cancellables)

        input.personTapped
            .sink { [weak self] id in self?.openMember(id) }
            .store(in: &cancellables)

        input.remindFounderTapped
            .sink { [weak self] _ in
                guard let self, let id = self.currentState.founderMemberID else { return }
                self.navigationEventSubject.send(.remindFounderAnniversary(treeID: self.activeTree.id, memberID: id))
            }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleEditToggled() {
        guard !currentState.isSaving else { return }
        if currentState.isEditing {
            handleDone()
        } else {
            currentState.draft = useCase.makeDraft(from: activeTree)
            currentState.errorField = nil
            currentState.errorMessage = nil
            currentState.toastMessage = nil
            currentState.isEditing = true
            publish()
        }
    }

    /// "Xong": validate, apply to the active book, save, then back to view mode.
    private func handleDone() {
        let year = Calendar.current.component(.year, from: now())
        switch useCase.apply(currentState.draft, to: activeTree, currentYear: year) {
        case .failure(let issue):
            currentState.errorField = issue.field
            currentState.errorMessage = issue.message
            publish()
        case .success(let updated):
            currentState.errorField = nil
            currentState.errorMessage = nil
            currentState.isSaving = true
            publish()
            persist(replacing: updated, successToast: String(format: "familyTreeChronicle.toast.saved".localized, displayTitle(of: updated))) {
                $0.currentState.isEditing = false
            }
        }
    }

    private func handleTabSelected(_ id: String) {
        guard !currentState.isSaving, let index = trees.firstIndex(where: { $0.id == id }), index != activeIndex else { return }
        activeIndex = index
        currentState.isEditing = false
        currentState.isHeadPickerOpen = false
        currentState.pendingHead = nil
        currentState.errorField = nil
        currentState.errorMessage = nil
        currentState.toastMessage = nil
        refresh()
        publish()
    }

    private func handleFieldEdited(_ edit: ILFamilyTreeChronicleFieldEdit) {
        guard currentState.isEditing else { return }
        switch edit {
        case .hometown(let text): currentState.draft.hometown = text
        case .origin(let text): currentState.draft.origin = text
        case .milestoneYear(let id, let text):
            updateMilestone(id) { $0.year = Self.yearText(text) }
        case .milestoneText(let id, let text):
            updateMilestone(id) { $0.text = text }
        case .shrineName(let text): currentState.draft.shrineName = text
        case .shrineAddress(let text): currentState.draft.shrineAddress = text
        case .annualGathering(let text): currentState.draft.annualGathering = text
        case .plaqueHan(let text): currentState.draft.plaqueHan = text
        case .plaqueMeaning(let text): currentState.draft.plaqueMeaning = text
        case .coupletUpper(let text): currentState.draft.coupletUpper = text
        case .coupletLower(let text): currentState.draft.coupletLower = text
        case .teachings(let text): currentState.draft.teachings = text
        }
        // The shown error may no longer apply.
        currentState.errorField = nil
        currentState.errorMessage = nil
        publish()
    }

    private func updateMilestone(_ id: String, _ change: (inout ILFamilyTreeChronicleMilestoneDraft) -> Void) {
        guard let index = currentState.draft.milestones.firstIndex(where: { $0.id == id }) else { return }
        change(&currentState.draft.milestones[index])
    }

    private func handleMilestoneAdded() {
        guard currentState.isEditing else { return }
        currentState.draft.milestones.append(ILFamilyTreeChronicleMilestoneDraft(id: makeID(), year: "", text: ""))
        publish()
    }

    private func handleMilestoneDeleted(_ id: String) {
        guard currentState.isEditing else { return }
        currentState.draft.milestones.removeAll { $0.id == id }
        currentState.errorField = nil
        currentState.errorMessage = nil
        publish()
    }

    private func handleHeadChangeTapped() {
        guard !currentState.isEditing else { return }
        currentState.isHeadPickerOpen = true
        refresh()
        publish()
    }

    private func handleHeadCandidatePicked(_ id: String) {
        guard let candidate = candidates.first(where: { $0.id == id }), !candidate.isClanHead else { return }
        let graph = ILFamilyTreeGraph(members: activeTree.members)
        var message = ""
        if let current = activeTree.members.first(where: { $0.isClanHead && !graph.isMarriedIn($0) }) {
            message += String(format: "familyTreeChronicle.head.confirm.replace".localized, current.name)
        }
        message += String(
            format: "familyTreeChronicle.head.confirm.message".localized,
            candidate.name, graph.generation(of: candidate), displayTitle(of: activeTree)
        )
        currentState.isHeadPickerOpen = false
        currentState.pendingHead = ILFamilyTreeChroniclePendingHead(memberID: id, message: message)
        publish()
    }

    private func handleHeadChangeConfirmed() {
        guard let pending = currentState.pendingHead, !currentState.isSaving else { return }
        let updated = useCase.changeClanHead(to: pending.memberID, in: activeTree)
        let name = updated.members.first(where: { $0.id == pending.memberID })?.name ?? ""
        currentState.pendingHead = nil
        currentState.isSaving = true
        publish()
        persist(replacing: updated, successToast: String(format: "familyTreeChronicle.toast.headChanged".localized, name)) { _ in }
    }

    private func openMember(_ id: String?) {
        guard let id else { return }
        navigationEventSubject.send(.openMember(treeID: activeTree.id, memberID: id))
    }

    /// Saves the books with `updated` in place of the active one; on success refreshes the screen,
    /// shows `successToast` and tells the coordinator. On failure the old book stays.
    private func persist(
        replacing updated: ILFamilyTreeEntity,
        successToast: String,
        onSuccess: @escaping (ILFamilyTreeChronicleViewModel) -> Void
    ) {
        var newTrees = trees
        newTrees[activeIndex] = updated
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.useCase.save(newTrees)
                self.trees = newTrees
                onSuccess(self)
                self.currentState.isSaving = false
                self.refresh()
                self.currentState.toastMessage = successToast
                self.currentState.toastToken += 1
                self.publish()
                self.navigationEventSubject.send(.updated(newTrees))
            } catch {
                self.currentState.isSaving = false
                self.publish() // release the button before the error is shown
                self.stateSubject.send(.failure(error))
            }
        }
    }

    // MARK: - Tree -> StateModel mapping
    private var activeTree: ILFamilyTreeEntity { trees[activeIndex] }

    private var candidates: [ILFamilyMemberEntity] { useCase.clanHeadCandidates(in: activeTree) }

    private func displayTitle(of tree: ILFamilyTreeEntity) -> String {
        tree.clanName.isEmpty ? "familyTree.title.default".localized : tree.clanName
    }

    /// Re-derives every view-mode text from the active book (and the tabs / candidate rows).
    private func refresh() {
        guard trees.indices.contains(activeIndex) else { return }
        let tree = activeTree
        let chronicle = tree.chronicle
        let graph = ILFamilyTreeGraph(members: tree.members)
        let founder = graph.founder
        let keeper = tree.members.first { $0.isClanHead && !graph.isMarriedIn($0) }
        let sortedMilestones = chronicle.milestones.sorted { ($0.year ?? 0) < ($1.year ?? 0) }

        currentState.tabs = trees.count > 1
            ? trees.map { ILFamilyTreeChronicleTabModel(treeID: $0.id, title: tabTitle(of: $0), isSelected: $0.id == tree.id) }
            : []

        currentState.title = displayTitle(of: tree)
        currentState.home = tree.hometown
        currentState.meta = metaText(graph: graph, founder: founder, firstYear: sortedMilestones.compactMap(\.year).first)

        currentState.founderMemberID = founder?.id
        currentState.founderName = founder?.name ?? "familyTreeChronicle.founder.unknown".localized
        currentState.founderYears = founder.map(founderYears) ?? ""
        currentState.origin = chronicle.origin

        currentState.timeline = sortedMilestones.enumerated().map { index, milestone in
            ILFamilyTreeChronicleTimelineRow(
                id: milestone.id, year: milestone.year.map(String.init) ?? "", text: milestone.text,
                hasNext: index < sortedMilestones.count - 1
            )
        }

        currentState.shrineName = chronicle.shrineName
        currentState.shrineAddress = chronicle.shrineAddress
        currentState.keeperMemberID = keeper?.id
        currentState.keeperName = keeper?.name ?? "familyTreeChronicle.keeper.none".localized
        let founderAnniversary = founder.flatMap { ILFamilyTreeFormatter.anniversary($0) }
        currentState.founderAnniversary = founderAnniversary ?? "familyTreeChronicle.anniversary.unknown".localized
        currentState.annualGathering = chronicle.annualGathering
        currentState.canRemindFounder = founderAnniversary != nil

        currentState.plaqueHan = chronicle.plaqueHan
        currentState.plaqueMeaning = chronicle.plaqueMeaning
        currentState.couplets = [chronicle.coupletUpper, chronicle.coupletLower].filter { !$0.isEmpty }
        currentState.teachings = chronicle.teachings

        currentState.people = tree.members
            // The founder always counts as a notable person, so the section never disappears just
            // because nobody has a biography or the clan-head role yet.
            .filter { !graph.isMarriedIn($0) && ($0.id == founder?.id || (($0.note ?? "").isEmpty == false) || $0.isClanHead) }
            .prefix(Self.maxPeople)
            .map { member in
                let prefix: String
                if member.id == founder?.id {
                    prefix = "familyTreeChronicle.people.founder".localized
                } else if member.isClanHead {
                    prefix = "familyTreeChronicle.people.head".localized
                } else {
                    prefix = ""
                }
                return ILFamilyTreeChroniclePersonRow(
                    memberID: member.id, name: member.name, subtitle: prefix + (member.note ?? ""),
                    generation: ILFamilyTreeFormatter.generationLabel(graph.generation(of: member))
                )
            }

        if currentState.isHeadPickerOpen {
            currentState.candidates = candidates.map { member in
                ILFamilyTreeChronicleCandidateRow(
                    memberID: member.id, name: member.name, subtitle: candidateSubtitle(member, graph: graph),
                    isCurrent: member.id == keeper?.id
                )
            }
        } else {
            currentState.candidates = []
        }
    }

    private func tabTitle(of tree: ILFamilyTreeEntity) -> String {
        let key = tree.side == .paternal ? "familyTreeChronicle.tab.paternal" : "familyTreeChronicle.tab.maternal"
        return String(format: key.localized, displayTitle(of: tree))
    }

    /// "5 đời · 24 người · từ năm 1812".
    private func metaText(graph: ILFamilyTreeGraph, founder: ILFamilyMemberEntity?, firstYear: Int?) -> String {
        var text = String(format: "familyTreeChronicle.meta.format".localized, graph.maxGeneration, graph.members.count)
        if let year = firstYear ?? founder?.birthYear {
            text += String(format: "familyTreeChronicle.meta.since".localized, year)
        }
        return text
    }

    /// "1812 – 1879 · giỗ 15 tháng Chạp âm lịch".
    private func founderYears(_ founder: ILFamilyMemberEntity) -> String {
        var parts: [String] = []
        switch (founder.birthYear, founder.deathYear) {
        case let (birth?, death?): parts.append("\(birth) – \(death)")
        case let (birth?, nil): parts.append("\(birth)")
        case let (nil, death?): parts.append("– \(death)")
        case (nil, nil): break
        }
        if let anniversary = ILFamilyTreeFormatter.anniversary(founder) {
            parts.append(String(format: "familyTreeChronicle.founder.anniversary".localized, anniversary))
        }
        return parts.joined(separator: " · ")
    }

    /// "Đời 5 · sinh 1946 · <nơi ở>".
    private func candidateSubtitle(_ member: ILFamilyMemberEntity, graph: ILFamilyTreeGraph) -> String {
        var parts = [ILFamilyTreeFormatter.generationLabel(graph.generation(of: member))]
        if let birth = member.birthYear {
            parts.append(String(format: "familyTreeChronicle.candidate.born".localized, birth))
        }
        if let residence = member.residence, !residence.isEmpty { parts.append(residence) }
        return parts.joined(separator: " · ")
    }

    /// Years take digits only, at most four.
    private static func yearText(_ text: String) -> String {
        String(text.filter(\.isNumber).prefix(yearDigits))
    }

    private func publish() {
        stateSubject.send(.success(currentState))
    }
}
