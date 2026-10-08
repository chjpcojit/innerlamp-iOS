//
//  ILFamilyTreeViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILFamilyTreeNavEvent: Equatable {
    case back
    /// Empty state: open the "Tạo gia phả" form.
    case createTree
    /// Header "+": add a member (no form yet — TD-FamilyTree-004).
    case addMember
    /// Sheet "Hồ sơ đầy đủ" — the member profile (view + edit).
    case openProfile(memberID: String)
    /// TƯỞNG NIỆM pill / contextual "Nhắc ngày giỗ" (no Sổ giỗ hand-off yet — TD-FamilyTree-005).
    case remindAnniversary(memberID: String)
    /// Contextual "Thêm con cháu" for a living member (TD-FamilyTree-005).
    case addDescendant(memberID: String)
    /// TƯỞNG NIỆM "Thắp đèn" / "Tụng kinh" tiles (TD-FamilyTree-006).
    case lightLamp(memberID: String)
    case chant(memberID: String)
    /// "Bài vị thờ tại" link (TD-FamilyTree-008).
    case openTemple(memberID: String)
    /// Red 譜 seal, or the "Phả ký dòng họ" row of the switcher menu.
    case openChronicle
}

protocol ILFamilyTreeViewModelProtocol: ViewModelType {
    /// Independent of `transform(input:)` — the owning `ILFamilyTreeCoordinator` subscribes to
    /// this directly in `start()`, before the ViewController exists.
    var navigationEventPublisher: AnyPublisher<ILFamilyTreeNavEvent, Never> { get }
}

final class ILFamilyTreeViewModel: ILFamilyTreeViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        let searchToggled: AnyPublisher<Void, Never>
        let searchTextChanged: AnyPublisher<String, Never>
        let searchSubmitted: AnyPublisher<Void, Never>
        /// 0 = all generations.
        let generationSelected: AnyPublisher<Int, Never>
        /// A node on the canvas.
        let memberTapped: AnyPublisher<String, Never>
        /// A relation / lineage row in the detail sheet — also collapses the sheet.
        let sheetMemberTapped: AnyPublisher<String, Never>
        let sheetToggled: AnyPublisher<Void, Never>
        let sheetDismissed: AnyPublisher<Void, Never>
        /// "Về gốc" button: back to the founder with every filter cleared.
        let rootTapped: AnyPublisher<Void, Never>
        /// Gold "BẠN" button: select and centre the viewer's node, filters cleared.
        let meTapped: AnyPublisher<Void, Never>
        /// Empty state: "Tạo gia phả mới".
        let createTapped: AnyPublisher<Void, Never>
        /// Empty state: "Tham gia bằng mã mời".
        let joinTapped: AnyPublisher<Void, Never>
        /// Header "+".
        let addTapped: AnyPublisher<Void, Never>
        /// Sheet actions — all act on the selected member.
        let fullProfileTapped: AnyPublisher<Void, Never>
        let reminderTapped: AnyPublisher<Void, Never>
        let contextualActionTapped: AnyPublisher<Void, Never>
        let offeringTapped: AnyPublisher<Void, Never>
        let chantTapped: AnyPublisher<Void, Never>
        let templeTapped: AnyPublisher<Void, Never>
        /// Clan name in the header: opens / closes the book switcher.
        let titleTapped: AnyPublisher<Void, Never>
        /// Scrim behind the switcher menu.
        let switcherDismissed: AnyPublisher<Void, Never>
        /// A row of the switcher menu.
        let viewSelected: AnyPublisher<ILFamilyTreeViewKind, Never>
        /// Red 譜 seal, or the chronicle row of the switcher menu.
        let chronicleTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILFamilyTreeStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILFamilyTreeNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILFamilyTreeNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILFamilyTreeStateModel>, Never>
    private var currentState: ILFamilyTreeStateModel
    private var graph = ILFamilyTreeGraph(members: [])
    /// The tree being drawn: the active book, or the synthetic pedigree while merged.
    private var tree = ILFamilyTreeEntity.empty
    /// Every clan book of the user, kept in memory — see TD-FamilyTree-011.
    private var books: [ILFamilyTreeEntity] = []
    private var viewKind = ILFamilyTreeViewKind.merged
    private var pedigree: ILFamilyTreePedigree?
    private var selectedGeneration = 0
    private var focusToken = 0
    private let useCase: ILFamilyTreeUseCase
    private let viewerResolver: ILFamilyTreeViewerResolving
    private let now: () -> Date
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(
        useCase: ILFamilyTreeUseCase,
        viewerResolver: ILFamilyTreeViewerResolving,
        now: @escaping () -> Date = Date.init
    ) {
        self.useCase = useCase
        self.viewerResolver = viewerResolver
        self.now = now
        self.currentState = .initial
        self.stateSubject = CurrentValueSubject(.success(.initial))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.back) }
            .store(in: &cancellables)

        input.searchToggled
            .sink { [weak self] _ in self?.handleSearchToggled() }
            .store(in: &cancellables)

        input.searchTextChanged
            .sink { [weak self] text in self?.handleSearchTextChanged(text) }
            .store(in: &cancellables)

        input.searchSubmitted
            .sink { [weak self] _ in self?.handleSearchSubmitted() }
            .store(in: &cancellables)

        input.generationSelected
            .sink { [weak self] generation in self?.handleGenerationSelected(generation) }
            .store(in: &cancellables)

        input.memberTapped
            .sink { [weak self] id in self?.select(id, collapseSheet: false) }
            .store(in: &cancellables)

        input.sheetMemberTapped
            .sink { [weak self] id in self?.select(id, collapseSheet: true) }
            .store(in: &cancellables)

        input.sheetToggled
            .sink { [weak self] _ in self?.setSheetExpanded(!(self?.currentState.isSheetExpanded ?? false)) }
            .store(in: &cancellables)

        input.sheetDismissed
            .sink { [weak self] _ in self?.setSheetExpanded(false) }
            .store(in: &cancellables)

        input.rootTapped
            .sink { [weak self] _ in self?.handleRootTapped() }
            .store(in: &cancellables)

        input.meTapped
            .sink { [weak self] _ in self?.handleMeTapped() }
            .store(in: &cancellables)

        input.createTapped
            .sink { [weak self] _ in self?.handleCreateTapped() }
            .store(in: &cancellables)

        input.joinTapped
            .sink { _ in print("TODO: open the join-by-invite-code flow (no screen/API yet — TD-FamilyTree-002)") }
            .store(in: &cancellables)

        input.addTapped
            .sink { [weak self] _ in self?.handleAddTapped() }
            .store(in: &cancellables)

        input.fullProfileTapped
            .sink { [weak self] _ in self?.sendForSelected(resolvingOrigin: false) { .openProfile(memberID: $0) } }
            .store(in: &cancellables)

        input.reminderTapped
            .sink { [weak self] _ in self?.sendForSelected { .remindAnniversary(memberID: $0) } }
            .store(in: &cancellables)

        input.contextualActionTapped
            .sink { [weak self] _ in self?.handleContextualAction() }
            .store(in: &cancellables)

        input.offeringTapped
            .sink { [weak self] _ in self?.sendForSelected { .lightLamp(memberID: $0) } }
            .store(in: &cancellables)

        input.chantTapped
            .sink { [weak self] _ in self?.sendForSelected { .chant(memberID: $0) } }
            .store(in: &cancellables)

        input.templeTapped
            .sink { [weak self] _ in self?.sendForSelected { .openTemple(memberID: $0) } }
            .store(in: &cancellables)

        input.titleTapped
            .sink { [weak self] _ in self?.handleTitleTapped() }
            .store(in: &cancellables)

        input.switcherDismissed
            .sink { [weak self] _ in self?.setSwitcherOpen(false) }
            .store(in: &cancellables)

        input.viewSelected
            .sink { [weak self] kind in self?.handleViewSelected(kind) }
            .store(in: &cancellables)

        input.chronicleTapped
            .sink { [weak self] _ in self?.handleChronicleTapped() }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Coordinator hand-off
    /// What the add-member form needs: the active book and the person to attach to — the selected
    /// one, else the founder. `nil` while the tree is empty, and in the merged view (no single book
    /// to add to).
    func addMemberContext(relativeID: String? = nil) -> (tree: ILFamilyTreeEntity, relativeID: String)? {
        guard pedigree == nil,
              let id = relativeID ?? currentState.selectedID ?? graph.founder?.id,
              graph.member(id: id) != nil else { return nil }
        return (tree, id)
    }

    /// What the profile screen needs for a person shown on the canvas: the book they belong to,
    /// their id inside that book and the "Với bạn" text.
    func profileContext(memberID: String) -> (tree: ILFamilyTreeEntity, memberID: String, kinship: String?)? {
        let origin = originOf(memberID)
        guard let book = books.first(where: { $0.id == origin.treeID }),
              book.members.contains(where: { $0.id == origin.memberID }),
              let member = graph.member(id: memberID) else { return nil }
        return (book, origin.memberID, kinshipText(for: member))
    }

    /// What the chronicle needs: every book, and the one to open on — the active book, or the
    /// paternal one while the merged view is showing.
    func chronicleContext() -> (trees: [ILFamilyTreeEntity], activeTreeID: String)? {
        guard let first = books.first else { return nil }
        if case .book(let id) = viewKind { return (books, id) }
        return (books, books.first(where: { $0.side == .paternal })?.id ?? first.id)
    }

    /// Called when the add-member form returns the updated book — shows it and selects the new person.
    func showTree(_ tree: ILFamilyTreeEntity, selecting memberID: String) {
        replaceBook(tree)
        showView(.book(tree.id), selecting: memberID)
    }

    /// Called when the profile screen saved an edit: the updated book replaces the old one and the
    /// current view (book or merged) is rebuilt around the same person.
    func showUpdatedBook(_ tree: ILFamilyTreeEntity, memberID: String) {
        replaceBook(tree)
        showView(viewKind, selecting: displayedID(treeID: tree.id, memberID: memberID))
    }

    /// Called when the chronicle screen changed one or more books (hometown, head of the clan...).
    func showUpdatedBooks(_ trees: [ILFamilyTreeEntity]) {
        trees.forEach(replaceBook)
        showView(viewKind, selecting: currentState.selectedID)
    }

    /// A person was opened from the profile / chronicle screen: show them on the tree. They are
    /// selected in place when the merged view already contains them, else their book is shown.
    func openMember(treeID: String, memberID: String) {
        if pedigree != nil, let displayed = displayedID(treeID: treeID, memberID: memberID) {
            select(displayed, collapseSheet: true)
        } else {
            switchToBook(treeID, selecting: memberID)
        }
    }

    /// Called when the create screen returns a new book — it joins the user's books (the first one
    /// is the paternal book, the next the maternal one) and is shown right away.
    func showCreatedTree(_ tree: ILFamilyTreeEntity) {
        var created = tree
        created.side = books.contains(where: { $0.side == .paternal }) ? .maternal : .paternal
        books.append(created)
        showView(.book(created.id), selecting: nil)
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let loaded = try await self.useCase.loadTrees()
                // Books the user created before the (stubbed) load came back must not be wiped.
                if self.books.isEmpty { self.books = loaded }
                self.showView(self.books.first.map { ILFamilyTreeViewKind.book($0.id) } ?? .merged, selecting: nil)
            } catch {
                self.stateSubject.send(.failure(error))
            }
        }
    }

    private func handleSearchToggled() {
        currentState.isSearchOpen.toggle()
        currentState.searchText = ""
        refreshDynamicState()
        publish()
    }

    private func handleSearchTextChanged(_ text: String) {
        currentState.searchText = text
        refreshDynamicState()
        publish()
    }

    private func handleSearchSubmitted() {
        guard let first = searchHits().first else { return }
        select(first, collapseSheet: true)
    }

    private func handleGenerationSelected(_ generation: Int) {
        selectedGeneration = generation
        refreshDynamicState()
        publish()
    }

    private func handleRootTapped() {
        selectedGeneration = 0
        currentState.searchText = ""
        currentState.isSheetExpanded = false
        guard let founder = graph.founder else {
            refreshDynamicState()
            publish()
            return
        }
        select(founder.id, collapseSheet: true)
    }

    private func handleMeTapped() {
        guard let meID = currentState.meID else { return }
        selectedGeneration = 0
        currentState.searchText = ""
        select(meID, collapseSheet: true)
    }

    private func handleCreateTapped() {
        currentState.isSwitcherOpen = false
        publish()
        navigationEventSubject.send(.createTree)
    }

    private func handleAddTapped() {
        // The merged view has no single book to add a person to.
        guard pedigree == nil else { return }
        navigationEventSubject.send(.addMember)
    }

    private func handleTitleTapped() {
        guard currentState.canSwitch else { return }
        setSwitcherOpen(!currentState.isSwitcherOpen)
    }

    private func setSwitcherOpen(_ open: Bool) {
        guard currentState.isSwitcherOpen != open else { return }
        currentState.isSwitcherOpen = open
        publish()
    }

    private func handleViewSelected(_ kind: ILFamilyTreeViewKind) {
        guard kind != viewKind else {
            setSwitcherOpen(false)
            return
        }
        showView(kind, selecting: nil)
    }

    private func handleChronicleTapped() {
        guard !books.isEmpty else { return }
        setSwitcherOpen(false)
        navigationEventSubject.send(.openChronicle)
    }

    /// Emits an event for the selected member; nothing happens without a selection. The member id
    /// is translated back to the id inside its own book unless `resolvingOrigin` is `false`.
    private func sendForSelected(resolvingOrigin: Bool = true, _ makeEvent: (String) -> ILFamilyTreeNavEvent) {
        guard let id = currentState.selectedID else { return }
        navigationEventSubject.send(makeEvent(resolvingOrigin ? originOf(id).memberID : id))
    }

    /// The outlined bottom pill: "Thêm con cháu" for the living, "Nhắc ngày giỗ" for the deceased;
    /// in the merged view "Hồ sơ của bạn" for the viewer, "Mở trong họ …" for everyone else.
    private func handleContextualAction() {
        guard let id = currentState.selectedID, let member = graph.member(id: id) else { return }
        if let pedigree, let origin = pedigree.origins[id] {
            if id == pedigree.viewerID {
                navigationEventSubject.send(.openProfile(memberID: id))
            } else {
                switchToBook(origin.treeID, selecting: origin.memberID)
            }
            return
        }
        navigationEventSubject.send(member.isLiving ? .addDescendant(memberID: id) : .remindAnniversary(memberID: id))
    }

    private func setSheetExpanded(_ expanded: Bool) {
        guard currentState.detail != nil else { return }
        currentState.isSheetExpanded = expanded
        publish()
    }

    private func select(_ id: String, collapseSheet: Bool) {
        guard graph.member(id: id) != nil else { return }
        currentState.selectedID = id
        if collapseSheet { currentState.isSheetExpanded = false }
        focusToken += 1
        currentState.focus = ILFamilyTreeFocusRequest(memberID: id, token: focusToken)
        refreshDynamicState()
        publish()
    }

    // MARK: - Books & views
    private func replaceBook(_ tree: ILFamilyTreeEntity) {
        if let index = books.firstIndex(where: { $0.id == tree.id }) {
            books[index] = tree
        } else {
            books.append(tree)
        }
    }

    private func switchToBook(_ treeID: String, selecting memberID: String?) {
        guard books.contains(where: { $0.id == treeID }) else { return }
        showView(.book(treeID), selecting: memberID)
    }

    /// Draws a book or the merged tree. A merged view that cannot be built (no paternal book,
    /// no viewer) falls back to the first book.
    private func showView(_ kind: ILFamilyTreeViewKind, selecting memberID: String?) {
        if case .merged = kind, let merged = makePedigree() {
            viewKind = .merged
            pedigree = merged
            display(merged.tree, selecting: memberID)
            return
        }
        var wanted: ILFamilyTreeEntity?
        if case .book(let id) = kind { wanted = books.first(where: { $0.id == id }) }
        guard let book = wanted ?? books.first else {
            viewKind = .merged
            pedigree = nil
            display(.empty, selecting: nil)
            return
        }
        viewKind = .book(book.id)
        pedigree = nil
        display(book, selecting: memberID)
    }

    /// The paternal book joined with the maternal one — only when both exist and the viewer is in
    /// the paternal book.
    private func makePedigree() -> ILFamilyTreePedigree? {
        guard let paternal = books.first(where: { $0.side == .paternal }),
              let maternal = books.first(where: { $0.side == .maternal }),
              let viewerID = viewerResolver.viewerMemberID(in: paternal) else { return nil }
        return useCase.makePedigree(viewerID: viewerID, paternal: paternal, maternal: maternal)
    }

    /// Where a displayed person lives: their own book, and their id there.
    private func originOf(_ displayedID: String) -> (treeID: String, memberID: String) {
        if let origin = pedigree?.origins[displayedID] { return (origin.treeID, origin.memberID) }
        return (tree.id, displayedID)
    }

    /// The id a book member has on the canvas right now — `nil` when the canvas does not show them.
    private func displayedID(treeID: String, memberID: String) -> String? {
        if let pedigree {
            return pedigree.origins.first(where: { $0.value.treeID == treeID && $0.value.memberID == memberID })?.key
        }
        return tree.id == treeID && graph.member(id: memberID) != nil ? memberID : nil
    }

    private func makeSwitcherRows() -> [ILFamilyTreeSwitcherRowModel] {
        var rows = books.map { book -> ILFamilyTreeSwitcherRowModel in
            let bookGraph = useCase.makeGraph(for: book)
            return ILFamilyTreeSwitcherRowModel(
                kind: .book(book.id),
                side: book.side,
                glyph: "familyTree.empty.seal".localized,
                title: book.clanName.isEmpty ? "familyTree.title.default".localized : book.clanName,
                subtitle: ILFamilyTreeFormatter.switcherSubtitle(
                    side: book.side, hometown: book.hometown,
                    generations: bookGraph.maxGeneration, people: bookGraph.members.count
                ),
                isSelected: viewKind == .book(book.id)
            )
        }
        if let merged = makePedigree() {
            rows.append(ILFamilyTreeSwitcherRowModel(
                kind: .merged,
                side: nil,
                glyph: "familyTree.merged.seal".localized,
                title: "familyTree.merged.rowTitle".localized,
                subtitle: String(format: "familyTree.merged.rowSubtitle".localized, merged.tree.members.count),
                isSelected: viewKind == .merged
            ))
        }
        return rows
    }

    // MARK: - Entity -> StateModel mapping
    private func display(_ displayed: ILFamilyTreeEntity, selecting requested: String?) {
        tree = displayed
        graph = useCase.makeGraph(for: displayed)
        selectedGeneration = 0
        let isMerged = pedigree != nil

        var state = ILFamilyTreeStateModel.initial
        state.isEmpty = graph.members.isEmpty
        state.isMerged = isMerged
        state.canSwitch = !books.isEmpty
        state.canCreateBook = books.count < 2
        state.switcherRows = makeSwitcherRows()
        if isMerged {
            state.title = "familyTree.merged.title".localized
            state.subtitle = String(
                format: "familyTree.merged.subtitle".localized,
                graph.founder.map { ILFamilyTreeFormatter.nodeName($0, isFounder: false) } ?? "",
                graph.maxGeneration, graph.members.count
            )
        } else {
            state.title = displayed.clanName.isEmpty ? "familyTree.title.default".localized : displayed.clanName
            state.subtitle = graph.members.isEmpty
                ? "familyTree.empty.subtitle".localized
                : ILFamilyTreeFormatter.subtitle(hometown: displayed.hometown, generations: graph.maxGeneration, people: graph.members.count)
        }
        state.layout = ILFamilyTreeLayout.make(graph: graph)
        // The viewer is resolved only against members that actually exist in the graph, and only in
        // the paternal book (or the merged tree): the maternal book is someone else's family.
        if let pedigree {
            state.meID = pedigree.viewerID
        } else if displayed.side == .paternal {
            state.meID = viewerResolver.viewerMemberID(in: displayed).flatMap { graph.member(id: $0) }?.id
        }
        currentState = state
        currentState.nodes = graph.members.compactMap(makeNode)

        // Open on the requested person; else the viewer (merged) or the clan head (the person the
        // book is kept by), else the founder.
        let fallback = isMerged ? graph.founder : (graph.members.first(where: \.isClanHead) ?? graph.founder)
        if let initial = requested.flatMap({ graph.member(id: $0) }) ?? fallback {
            select(initial.id, collapseSheet: true)
        } else {
            refreshDynamicState()
            publish()
        }
    }

    private func makeNode(_ member: ILFamilyMemberEntity) -> ILFamilyTreeNodeModel? {
        guard let center = currentState.layout.centers[member.id] else { return nil }
        let isFounder = member.id == graph.founder?.id
        let isMarriedIn = graph.isMarriedIn(member)
        let generation = graph.generation(of: member)
        let metrics = ILMetrics.FamilyTree.self
        let width: CGFloat
        if isFounder {
            width = metrics.nodeFounderWidth
        } else if member.isClanHead {
            width = metrics.nodeHeadWidth
        } else if isMarriedIn {
            width = metrics.nodeSpouseWidth
        } else if generation == graph.maxGeneration && generation > 1 {
            width = metrics.nodeYoungestWidth
        } else {
            width = metrics.nodeWidth
        }
        let meta = mergedLabel(for: member).map { $0.uppercased() }
            ?? ILFamilyTreeFormatter.nodeMeta(member, generation: generation, isFounder: isFounder, isMarriedIn: isMarriedIn)
        return ILFamilyTreeNodeModel(
            id: member.id,
            center: center,
            width: width,
            name: ILFamilyTreeFormatter.nodeName(member, isFounder: isFounder),
            meta: meta,
            look: look(of: member, isFounder: isFounder),
            isBranchEnd: isBranchEnd(member),
            isMe: member.id == currentState.meID
        )
    }

    /// A deceased blood descendant (not a married-in spouse, not the founder) with no children.
    /// Never in the merged view, where "no children" only means "no known parents".
    private func isBranchEnd(_ member: ILFamilyMemberEntity) -> Bool {
        pedigree == nil
            && !member.isLiving
            && !graph.isMarriedIn(member)
            && graph.generation(of: member) > 1
            && graph.children(of: member.id).isEmpty
    }

    private func look(of member: ILFamilyMemberEntity, isFounder: Bool) -> ILFamilyTreeMedallionLook {
        ILFamilyTreeMedallionLook(
            gender: member.gender, isLiving: member.isLiving, isFounder: isFounder, isClanHead: member.isClanHead
        )
    }

    // MARK: Merged-view labels
    /// "Chính bạn", "Cha", "Mẹ", "Ông nội", "Bà ngoại"... — `nil` outside the merged view.
    private func mergedLabel(for member: ILFamilyMemberEntity) -> String? {
        guard let origin = pedigree?.origins[member.id] else { return nil }
        return ILFamilyTreeFormatter.mergedKin(depth: origin.depth, gender: member.gender, side: origin.side)
    }

    /// Recomputes everything derived from selection / filter / search.
    private func refreshDynamicState() {
        let hits = searchHits()
        let hitSet = Set(hits)
        let isSearching = !hits.isEmpty || !trimmedQuery.isEmpty

        currentState.generationChips = (0...max(graph.maxGeneration, 0)).map { generation in
            ILFamilyTreeGenerationChipModel(
                generation: generation,
                title: pedigree == nil
                    ? ILFamilyTreeFormatter.chipTitle(generation: generation)
                    : ILFamilyTreeFormatter.mergedChipTitle(generation: generation),
                isSelected: generation == selectedGeneration
            )
        }
        currentState.searchCountText = isSearching ? ILFamilyTreeFormatter.searchCount(hits.count) : ""

        var alphas: [String: CGFloat] = [:]
        for member in graph.members {
            if selectedGeneration != 0, graph.generation(of: member) != selectedGeneration {
                alphas[member.id] = ILMetrics.FamilyTree.dimmedAlpha
            }
            if isSearching, !hitSet.contains(member.id) {
                alphas[member.id] = ILMetrics.FamilyTree.searchDimmedAlpha
            }
        }
        currentState.nodeAlphas = alphas

        guard let id = currentState.selectedID, let selected = graph.member(id: id) else {
            currentState.detail = nil
            currentState.lineageIDs = []
            return
        }
        let chain = graph.lineage(of: selected)
        currentState.lineageIDs = Set(chain.map(\.id))
        currentState.detail = makeDetail(for: selected, chain: chain)
    }

    private var trimmedQuery: String {
        currentState.isSearchOpen ? currentState.searchText.trimmingCharacters(in: .whitespacesAndNewlines) : ""
    }

    private func searchHits() -> [String] {
        trimmedQuery.isEmpty ? [] : graph.search(trimmedQuery)
    }

    private func makeDetail(for member: ILFamilyMemberEntity, chain: [ILFamilyMemberEntity]) -> ILFamilyTreeDetailModel {
        if let pedigree, let origin = pedigree.origins[member.id] {
            return makeMergedDetail(for: member, origin: origin, pedigree: pedigree, chain: chain)
        }
        let isFounder = member.id == graph.founder?.id
        let generation = graph.generation(of: member)
        let currentYear = Calendar.current.component(.year, from: now())

        let relations = graph.relations(of: member).map { relation in
            ILFamilyTreeRelationModel(
                memberID: relation.member.id,
                kind: ILFamilyTreeFormatter.relation(relation.kind),
                name: relation.member.name,
                generation: ILFamilyTreeFormatter.generationLabel(graph.generation(of: relation.member))
            )
        }
        let lineage = chain.enumerated().map { index, step in
            ILFamilyTreeLineageStepModel(
                memberID: step.id,
                name: step.name,
                meta: lineageMeta(step),
                isSelected: step.id == member.id,
                hasNext: index < chain.count - 1
            )
        }
        let branchEnd = isBranchEnd(member)
        return ILFamilyTreeDetailModel(
            memberID: member.id,
            look: look(of: member, isFounder: isFounder),
            name: member.name,
            meta: ILFamilyTreeFormatter.detailMeta(member, generation: generation, isMarriedIn: graph.isMarriedIn(member)),
            status: ILFamilyTreeFormatter.status(member),
            role: ILFamilyTreeFormatter.role(member, isFounder: isFounder),
            years: ILFamilyTreeFormatter.years(member, currentYear: currentYear),
            anniversary: ILFamilyTreeFormatter.anniversary(member),
            branch: ILFamilyTreeFormatter.branch(graph.branch(of: member), isBranchEnd: branchEnd),
            isBranchEnd: branchEnd,
            // @ai: assumption — see Docs/Assumptions/FamilyTree/AS-FamilyTree-006-extra-facts-not-recorded.md
            residence: member.residence,
            burialPlace: member.burialPlace,
            dharmaName: member.dharmaName,
            tabletTemple: member.tabletTemple,
            memorial: member.isLiving ? nil : ILFamilyTreeFormatter.memorial(member, now: now()),
            contextualActionTitle: ILFamilyTreeFormatter.contextualAction(member),
            note: member.note,
            kinship: kinshipText(for: member),
            relations: relations,
            lineage: lineage
        )
    }

    /// Detail sheet in the merged view: the "tree" is upside down (a person's father and mother are
    /// their graph children), so relations, labels and the lineage are spelled out from the pedigree.
    private func makeMergedDetail(
        for member: ILFamilyMemberEntity,
        origin: ILFamilyTreePedigree.Origin,
        pedigree: ILFamilyTreePedigree,
        chain: [ILFamilyMemberEntity]
    ) -> ILFamilyTreeDetailModel {
        let isMe = member.id == pedigree.viewerID
        let currentYear = Calendar.current.component(.year, from: now())

        func level(of other: ILFamilyMemberEntity) -> String {
            ILFamilyTreeFormatter.mergedLevel(depth: pedigree.origins[other.id]?.depth ?? 0)
        }
        func label(of other: ILFamilyMemberEntity) -> String {
            mergedLabel(for: other) ?? ""
        }

        var relations = graph.children(of: member.id).map { parent in
            ILFamilyTreeRelationModel(
                memberID: parent.id,
                kind: ILFamilyTreeFormatter.relation(parent.gender == .female ? .mother : .father),
                name: parent.name,
                generation: level(of: parent)
            )
        }
        if let towardViewer = graph.parent(of: member) {
            relations.append(ILFamilyTreeRelationModel(
                memberID: towardViewer.id,
                kind: ILFamilyTreeFormatter.relation(towardViewer.gender == .female ? .daughter : .son),
                name: towardViewer.name,
                generation: level(of: towardViewer)
            ))
        }
        let lineage = chain.enumerated().map { index, step in
            ILFamilyTreeLineageStepModel(
                memberID: step.id, name: step.name, meta: label(of: step),
                isSelected: step.id == member.id, hasNext: index < chain.count - 1
            )
        }
        let bookName = books.first(where: { $0.id == origin.treeID })?.clanName ?? ""
        return ILFamilyTreeDetailModel(
            memberID: member.id,
            look: look(of: member, isFounder: isMe),
            name: member.name,
            meta: ILFamilyTreeFormatter.mergedDetailMeta(depth: origin.depth, gender: member.gender, side: origin.side),
            status: ILFamilyTreeFormatter.status(member),
            role: isMe ? "familyTree.merged.role.me".localized : nil,
            years: ILFamilyTreeFormatter.years(member, currentYear: currentYear),
            anniversary: ILFamilyTreeFormatter.anniversary(member),
            branch: ILFamilyTreeFormatter.mergedBranch(side: origin.side),
            isBranchEnd: false,
            residence: member.residence,
            burialPlace: member.burialPlace,
            dharmaName: member.dharmaName,
            tabletTemple: member.tabletTemple,
            memorial: member.isLiving ? nil : ILFamilyTreeFormatter.memorial(member, now: now()),
            contextualActionTitle: isMe
                ? "familyTree.merged.cta.myProfile".localized
                : String(format: "familyTree.merged.cta.openIn".localized, ILFamilyTreeFormatter.bookReference(bookName)),
            note: member.note,
            kinship: label(of: member),
            relations: relations,
            lineage: lineage,
            lineageTitle: "familyTree.merged.lineage".localized
        )
    }

    private func kinshipText(for member: ILFamilyMemberEntity) -> String? {
        if pedigree != nil { return mergedLabel(for: member) }
        guard let meID = currentState.meID else { return nil }
        return graph.kinship(of: member.id, relativeTo: meID).map { ILFamilyTreeFormatter.kinship($0) }
    }

    private func lineageMeta(_ member: ILFamilyMemberEntity) -> String {
        var meta = ILFamilyTreeFormatter.generationLabel(graph.generation(of: member))
        if member.id == graph.founder?.id {
            meta += " · " + "familyTree.role.founder".localized
        } else if member.isClanHead {
            meta += " · " + "familyTree.role.head".localized
        } else if graph.isMarriedIn(member) {
            meta += " · " + (member.gender == .female ? "familyTree.role.daughterInLaw" : "familyTree.role.sonInLaw").localized
        }
        return meta
    }

    private func publish() {
        stateSubject.send(.success(currentState))
    }
}
