//
//  ILFamilyTreeViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILFamilyTreeViewModelTests: XCTestCase {

    private typealias Factory = ILFamilyTreeTestFactory

    private var mockUseCase: MockILFamilyTreeUseCase!
    private var mockResolver: MockILFamilyTreeViewerResolver!
    private var sut: ILFamilyTreeViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var searchToggledSubject: PassthroughSubject<Void, Never>!
    private var searchTextChangedSubject: PassthroughSubject<String, Never>!
    private var searchSubmittedSubject: PassthroughSubject<Void, Never>!
    private var generationSelectedSubject: PassthroughSubject<Int, Never>!
    private var memberTappedSubject: PassthroughSubject<String, Never>!
    private var sheetMemberTappedSubject: PassthroughSubject<String, Never>!
    private var sheetToggledSubject: PassthroughSubject<Void, Never>!
    private var sheetDismissedSubject: PassthroughSubject<Void, Never>!
    private var rootTappedSubject: PassthroughSubject<Void, Never>!
    private var meTappedSubject: PassthroughSubject<Void, Never>!
    private var createTappedSubject: PassthroughSubject<Void, Never>!
    private var joinTappedSubject: PassthroughSubject<Void, Never>!
    private var addTappedSubject: PassthroughSubject<Void, Never>!
    private var fullProfileTappedSubject: PassthroughSubject<Void, Never>!
    private var reminderTappedSubject: PassthroughSubject<Void, Never>!
    private var contextualActionTappedSubject: PassthroughSubject<Void, Never>!
    private var offeringTappedSubject: PassthroughSubject<Void, Never>!
    private var chantTappedSubject: PassthroughSubject<Void, Never>!
    private var templeTappedSubject: PassthroughSubject<Void, Never>!
    private var titleTappedSubject: PassthroughSubject<Void, Never>!
    private var switcherDismissedSubject: PassthroughSubject<Void, Never>!
    private var viewSelectedSubject: PassthroughSubject<ILFamilyTreeViewKind, Never>!
    private var chronicleTappedSubject: PassthroughSubject<Void, Never>!

    private var latest: ILFamilyTreeStateModel?

    override func setUp() {
        super.setUp()
        mockUseCase = MockILFamilyTreeUseCase()
        mockResolver = MockILFamilyTreeViewerResolver()
        sut = ILFamilyTreeViewModel(useCase: mockUseCase, viewerResolver: mockResolver, now: { Factory.date(2026, 10, 3) })
        cancellables = []
        viewDidLoadSubject = .init()
        backTappedSubject = .init()
        searchToggledSubject = .init()
        searchTextChangedSubject = .init()
        searchSubmittedSubject = .init()
        generationSelectedSubject = .init()
        memberTappedSubject = .init()
        sheetMemberTappedSubject = .init()
        sheetToggledSubject = .init()
        sheetDismissedSubject = .init()
        rootTappedSubject = .init()
        meTappedSubject = .init()
        createTappedSubject = .init()
        joinTappedSubject = .init()
        addTappedSubject = .init()
        fullProfileTappedSubject = .init()
        reminderTappedSubject = .init()
        contextualActionTappedSubject = .init()
        offeringTappedSubject = .init()
        chantTappedSubject = .init()
        templeTappedSubject = .init()
        titleTappedSubject = .init()
        switcherDismissedSubject = .init()
        viewSelectedSubject = .init()
        chronicleTappedSubject = .init()
        latest = nil
    }

    override func tearDown() {
        cancellables = nil
        latest = nil
        sut = nil
        mockUseCase = nil
        mockResolver = nil
        super.tearDown()
    }

    private func makeInput() -> ILFamilyTreeViewModel.Input {
        ILFamilyTreeViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            searchToggled: searchToggledSubject.eraseToAnyPublisher(),
            searchTextChanged: searchTextChangedSubject.eraseToAnyPublisher(),
            searchSubmitted: searchSubmittedSubject.eraseToAnyPublisher(),
            generationSelected: generationSelectedSubject.eraseToAnyPublisher(),
            memberTapped: memberTappedSubject.eraseToAnyPublisher(),
            sheetMemberTapped: sheetMemberTappedSubject.eraseToAnyPublisher(),
            sheetToggled: sheetToggledSubject.eraseToAnyPublisher(),
            sheetDismissed: sheetDismissedSubject.eraseToAnyPublisher(),
            rootTapped: rootTappedSubject.eraseToAnyPublisher(),
            meTapped: meTappedSubject.eraseToAnyPublisher(),
            createTapped: createTappedSubject.eraseToAnyPublisher(),
            joinTapped: joinTappedSubject.eraseToAnyPublisher(),
            addTapped: addTappedSubject.eraseToAnyPublisher(),
            fullProfileTapped: fullProfileTappedSubject.eraseToAnyPublisher(),
            reminderTapped: reminderTappedSubject.eraseToAnyPublisher(),
            contextualActionTapped: contextualActionTappedSubject.eraseToAnyPublisher(),
            offeringTapped: offeringTappedSubject.eraseToAnyPublisher(),
            chantTapped: chantTappedSubject.eraseToAnyPublisher(),
            templeTapped: templeTappedSubject.eraseToAnyPublisher(),
            titleTapped: titleTappedSubject.eraseToAnyPublisher(),
            switcherDismissed: switcherDismissedSubject.eraseToAnyPublisher(),
            viewSelected: viewSelectedSubject.eraseToAnyPublisher(),
            chronicleTapped: chronicleTappedSubject.eraseToAnyPublisher()
        )
    }

    /// Subscribes to the output, sends `viewDidLoad` and waits for the first loaded (non-initial) state.
    @discardableResult
    private func load(file: StaticString = #filePath, line: UInt = #line) -> ILFamilyTreeStateModel? {
        let output = sut.transform(input: makeInput())
        let loaded = expectation(description: "tree loaded")
        loaded.assertForOverFulfill = false
        output.state
            .sink { [weak self] state in
                guard case .success(let model) = state else { return }
                self?.latest = model
                if model != .initial { loaded.fulfill() }
            }
            .store(in: &cancellables)
        viewDidLoadSubject.send(())
        wait(for: [loaded], timeout: 1)
        return latest
    }

    // MARK: - Loading
    func test_viewDidLoad_buildsCanvasHeaderChipsAndOpensOnTheClanHead() {
        let state = load()

        XCTAssertEqual(state?.title, "Họ Nguyễn Hữu")
        XCTAssertEqual(state?.isEmpty, false)
        XCTAssertEqual(state?.nodes.count, 24)
        XCTAssertEqual(state?.generationChips.count, 7)
        XCTAssertEqual(state?.generationChips.first?.isSelected, true)
        XCTAssertEqual(state?.selectedID, "p13")
        XCTAssertEqual(state?.detail?.name, "Nguyễn Hữu Minh")
        XCTAssertEqual(state?.focus?.memberID, "p13")
        XCTAssertEqual(state?.subtitle, String(format: "familyTree.subtitle.format".localized, "Hành Thiện", 6, 24))
    }

    func test_viewDidLoad_emptyTree_showsEmptyStateWithDefaultTitle() {
        mockUseCase.tree = .empty
        let state = load()

        XCTAssertEqual(state?.isEmpty, true)
        XCTAssertEqual(state?.title, "familyTree.title.default".localized)
        XCTAssertEqual(state?.subtitle, "familyTree.empty.subtitle".localized)
        XCTAssertTrue(state?.nodes.isEmpty ?? false)
        XCTAssertNil(state?.selectedID)
        XCTAssertNil(state?.detail)
    }

    func test_viewDidLoad_failure_emitsFailureState() {
        mockUseCase.error = NSError(domain: "test", code: 1)
        let output = sut.transform(input: makeInput())
        let failed = expectation(description: "failure state")
        output.state
            .sink { if case .failure = $0 { failed.fulfill() } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        wait(for: [failed], timeout: 1)
    }

    func test_nodes_carryLookAndMeta() {
        let state = load()

        let founder = state?.nodes.first { $0.id == "p1" }
        XCTAssertEqual(founder?.look.isFounder, true)
        XCTAssertEqual(founder?.name, "Nguyễn Hữu Phúc")
        XCTAssertEqual(founder?.meta, String(format: "familyTree.node.founder".localized, 1))

        let head = state?.nodes.first { $0.id == "p13" }
        XCTAssertEqual(head?.look.isClanHead, true)
        XCTAssertEqual(head?.name, "Hữu Minh")

        let spouse = state?.nodes.first { $0.id == "s2" }
        XCTAssertEqual(spouse?.meta, String(format: "familyTree.node.daughterInLaw".localized, 5))
    }

    // MARK: - Viewer ("BẠN")
    func test_withoutViewer_hidesEveryBanElement() {
        let state = load()

        XCTAssertNil(state?.meID)
        XCTAssertEqual(state?.nodes.contains { $0.isMe }, false)
        XCTAssertNil(state?.detail?.kinship)
    }

    func test_withViewer_marksOnlyThatNode_andShowsKinshipInTheSheet() {
        mockResolver.meID = "p18"
        let state = load()

        XCTAssertEqual(state?.meID, "p18")
        XCTAssertEqual(state?.nodes.filter(\.isMe).map(\.id), ["p18"])
        // Opens on the clan head p13, who is the viewer's father.
        XCTAssertEqual(state?.detail?.kinship, "familyTree.relation.father".localized)
    }

    func test_withViewerNotInTheTree_hidesEveryBanElement() {
        mockResolver.meID = "nobody"
        let state = load()

        XCTAssertNil(state?.meID)
        XCTAssertEqual(state?.nodes.contains { $0.isMe }, false)
    }

    func test_detail_kinshipHiddenWhenNotDerivable() {
        mockResolver.meID = "p18"
        load()

        // p14 is a cousin-line relative: not covered by the simple kinship rules.
        memberTappedSubject.send("p14")

        XCTAssertNil(latest?.detail?.kinship)
    }

    func test_meTapped_selectsAndCentresTheViewer_andClearsFilters() {
        mockResolver.meID = "p18"
        load()
        generationSelectedSubject.send(3)
        let token = latest?.focus?.token

        meTappedSubject.send(())

        XCTAssertEqual(latest?.selectedID, "p18")
        XCTAssertEqual(latest?.focus?.memberID, "p18")
        XCTAssertNotEqual(latest?.focus?.token, token)
        XCTAssertEqual(latest?.generationChips.first?.isSelected, true)
        XCTAssertEqual(latest?.detail?.kinship, "familyTree.kin.me".localized)
    }

    func test_meTapped_withoutViewer_changesNothing() {
        load()
        let before = latest

        meTappedSubject.send(())

        XCTAssertEqual(latest, before)
    }

    func test_placeholderResolver_picksTheClanHead() {
        XCTAssertEqual(ILPlaceholderFamilyTreeViewerResolver().viewerMemberID(in: ILFamilyTreeTestFactory.tree), "p13")
        XCTAssertNil(ILPlaceholderFamilyTreeViewerResolver().viewerMemberID(in: .empty))
    }

    // MARK: - Selection
    func test_memberTapped_selectsAndRefocuses_withoutTouchingTheSheet() {
        load()
        let firstToken = latest?.focus?.token

        memberTappedSubject.send("p6")

        XCTAssertEqual(latest?.selectedID, "p6")
        XCTAssertEqual(latest?.lineageIDs, ["p1", "p3", "p6"])
        XCTAssertEqual(latest?.detail?.name, "Nguyễn Hữu Nghĩa")
        XCTAssertNotEqual(latest?.focus?.token, firstToken)
        XCTAssertEqual(latest?.isSheetExpanded, false)
    }

    func test_memberTapped_unknownID_changesNothing() {
        load()
        let before = latest

        memberTappedSubject.send("nobody")

        XCTAssertEqual(latest, before)
    }

    func test_sheetMemberTapped_selectsAndCollapsesTheSheet() {
        load()
        sheetToggledSubject.send(())
        XCTAssertEqual(latest?.isSheetExpanded, true)

        sheetMemberTappedSubject.send("p8")

        XCTAssertEqual(latest?.selectedID, "p8")
        XCTAssertEqual(latest?.isSheetExpanded, false)
    }

    func test_sheetToggled_thenDismissed() {
        load()

        sheetToggledSubject.send(())
        XCTAssertEqual(latest?.isSheetExpanded, true)

        sheetDismissedSubject.send(())
        XCTAssertEqual(latest?.isSheetExpanded, false)
    }

    func test_detail_forLivingClanHead_hasRoleYearsBranchAndRelations() {
        load()
        let detail = latest?.detail

        XCTAssertEqual(detail?.role, "familyTree.role.head".localized)
        XCTAssertEqual(detail?.status, "familyTree.status.living".localized)
        XCTAssertEqual(detail?.years, String(format: "familyTree.years.living".localized, 1946, 80))
        XCTAssertEqual(detail?.branch, String(format: "familyTree.branch.eldest".localized, "Lộc"))
        XCTAssertNil(detail?.anniversary)
        XCTAssertEqual(detail?.relations.map(\.memberID), ["p8", "s2", "p18", "p19"])
        XCTAssertEqual(detail?.lineage.map(\.memberID), ["p1", "p2", "p4", "p8", "p13"])
        XCTAssertEqual(detail?.lineage.last?.isSelected, true)
        XCTAssertEqual(detail?.lineage.last?.hasNext, false)
        XCTAssertEqual(detail?.lineage.first?.hasNext, true)
    }

    func test_detail_forDeceasedFounder_hasAnniversaryAndLifespan() {
        load()

        memberTappedSubject.send("p1")
        let detail = latest?.detail

        XCTAssertEqual(detail?.role, "familyTree.role.founder".localized)
        XCTAssertEqual(detail?.years, String(format: "familyTree.years.deceased".localized, 1812, 1879, 68))
        XCTAssertEqual(
            detail?.anniversary,
            String(format: "familyTree.anniversary.format".localized, 15, "lunarCalendar.month.12".localized)
        )
        XCTAssertEqual(detail?.branch, "familyTree.branch.founder".localized)
        XCTAssertEqual(detail?.note, "Lập ấp Hành Thiện.")
    }

    // MARK: - Generation filter
    func test_generationSelected_dimsOtherGenerations() {
        load()

        generationSelectedSubject.send(3)

        XCTAssertEqual(latest?.generationChips.first { $0.isSelected }?.generation, 3)
        // Generation 3 stays fully visible; p1 (generation 1) and the spouse of a generation-5 member dim.
        XCTAssertNil(latest?.nodeAlphas["p4"])
        XCTAssertEqual(latest?.nodeAlphas["p1"], ILMetrics.FamilyTree.dimmedAlpha)
        XCTAssertEqual(latest?.nodeAlphas["s2"], ILMetrics.FamilyTree.dimmedAlpha)
    }

    func test_generationSelected_all_clearsDimming() {
        load()
        generationSelectedSubject.send(3)

        generationSelectedSubject.send(0)

        XCTAssertTrue(latest?.nodeAlphas.isEmpty ?? false)
    }

    // MARK: - Search
    func test_searchToggled_opensAndClosesAndClearsText() {
        load()

        searchToggledSubject.send(())
        XCTAssertEqual(latest?.isSearchOpen, true)

        searchTextChangedSubject.send("duc")
        searchToggledSubject.send(())
        XCTAssertEqual(latest?.isSearchOpen, false)
        XCTAssertEqual(latest?.searchText, "")
        XCTAssertTrue(latest?.nodeAlphas.isEmpty ?? false)
    }

    func test_searchTextChanged_dimsNonMatches_andShowsCount() {
        load()
        searchToggledSubject.send(())

        searchTextChangedSubject.send("duc")

        XCTAssertNil(latest?.nodeAlphas["p5"])
        XCTAssertEqual(latest?.nodeAlphas["p1"], ILMetrics.FamilyTree.searchDimmedAlpha)
        XCTAssertEqual(latest?.searchCountText, String(format: "familyTree.search.count".localized, 1))
    }

    func test_searchTextChanged_noMatch_dimsEveryoneAndCountsZero() {
        load()
        searchToggledSubject.send(())

        searchTextChangedSubject.send("zzz")

        XCTAssertEqual(latest?.nodeAlphas.count, 24)
        XCTAssertEqual(latest?.searchCountText, String(format: "familyTree.search.count".localized, 0))
    }

    func test_searchTextChanged_whileSearchClosed_doesNotFilter() {
        load()

        searchTextChangedSubject.send("duc")

        XCTAssertTrue(latest?.nodeAlphas.isEmpty ?? false)
    }

    func test_searchSubmitted_selectsFirstHit_andCollapsesSheet() {
        load()
        searchToggledSubject.send(())
        sheetToggledSubject.send(())
        searchTextChangedSubject.send("duc")

        searchSubmittedSubject.send(())

        XCTAssertEqual(latest?.selectedID, "p5")
        XCTAssertEqual(latest?.isSheetExpanded, false)
        XCTAssertEqual(latest?.focus?.memberID, "p5")
    }

    func test_searchSubmitted_withoutHits_changesNothingSelected() {
        load()
        searchToggledSubject.send(())
        searchTextChangedSubject.send("zzz")

        searchSubmittedSubject.send(())

        XCTAssertEqual(latest?.selectedID, "p13")
    }

    // MARK: - Root
    func test_rootTapped_selectsFounder_andClearsFilterAndSearch() {
        load()
        generationSelectedSubject.send(3)
        searchToggledSubject.send(())
        searchTextChangedSubject.send("duc")
        sheetToggledSubject.send(())

        rootTappedSubject.send(())

        XCTAssertEqual(latest?.selectedID, "p1")
        XCTAssertEqual(latest?.generationChips.first { $0.isSelected }?.generation, 0)
        XCTAssertEqual(latest?.searchText, "")
        XCTAssertEqual(latest?.isSheetExpanded, false)
        XCTAssertTrue(latest?.nodeAlphas.isEmpty ?? false)
    }

    // MARK: - Branch end (DỨT NHÁNH)
    func test_nodes_isBranchEnd_onlyForDeceasedChildlessBloodDescendantsBeyondTheFounder() {
        let state = load()
        func isEnd(_ id: String) -> Bool? { state?.nodes.first { $0.id == id }?.isBranchEnd }

        XCTAssertEqual(isEnd("p7"), true)   // deceased, no children
        XCTAssertEqual(isEnd("p12"), true)
        XCTAssertEqual(isEnd("p15"), true)
        XCTAssertEqual(isEnd("p5"), false)  // deceased but has a child
        XCTAssertEqual(isEnd("p1"), false)  // founder (generation 1)
        XCTAssertEqual(isEnd("s1"), false)  // married-in spouse
        XCTAssertEqual(isEnd("p20"), false) // living
    }

    func test_detail_forBranchEnd_branchTextReadsDutNhanh() {
        load()

        memberTappedSubject.send("p7")

        XCTAssertEqual(latest?.detail?.isBranchEnd, true)
        XCTAssertEqual(latest?.detail?.branch, "familyTree.branch.ended".localized)
    }

    func test_detail_forNonBranchEnd_keepsChiText() {
        load()

        memberTappedSubject.send("p5")

        XCTAssertEqual(latest?.detail?.isBranchEnd, false)
        XCTAssertEqual(latest?.detail?.branch, String(format: "familyTree.branch.eldest".localized, "Lộc"))
    }

    // MARK: - Detail extras
    func test_detail_extraFacts_areEmptyUntilThereIsADataSource() {
        load()

        let detail = latest?.detail

        XCTAssertNil(detail?.residence)
        XCTAssertNil(detail?.burialPlace)
        XCTAssertNil(detail?.dharmaName)
        XCTAssertNil(detail?.tabletTemple)
    }

    func test_detail_livingMember_hasNoMemorialAndOffersAddDescendant() {
        load()

        XCTAssertNil(latest?.detail?.memorial)
        XCTAssertEqual(latest?.detail?.contextualActionTitle, "familyTree.cta.addDescendant".localized)
    }

    func test_detail_deceasedWithAnniversary_hasFilledReminderAndRemindAction() {
        load()

        memberTappedSubject.send("p1")
        let memorial = latest?.detail?.memorial

        XCTAssertEqual(
            memorial?.title,
            String(format: "familyTree.memorial.titleFormat".localized, 15, "lunarCalendar.month.12".localized)
        )
        XCTAssertEqual(memorial?.buttonTitle, "familyTree.memorial.remind".localized)
        XCTAssertEqual(memorial?.isButtonFilled, true)
        XCTAssertEqual(latest?.detail?.contextualActionTitle, "familyTree.cta.remindAnniversary".localized)
    }

    func test_detail_deceasedWithoutAnniversary_offersToAddTheDate() {
        load()

        memberTappedSubject.send("p2")
        let memorial = latest?.detail?.memorial

        XCTAssertEqual(memorial?.title, "familyTree.memorial.unknownTitle".localized)
        XCTAssertEqual(memorial?.buttonTitle, "familyTree.memorial.addDate".localized)
        XCTAssertEqual(memorial?.isButtonFilled, false)
    }

    // MARK: - Stub navigation events
    func test_addTapped_firesAddMember() {
        _ = sut.transform(input: makeInput())
        var event: ILFamilyTreeNavEvent?
        sut.navigationEventPublisher.sink { event = $0 }.store(in: &cancellables)

        addTappedSubject.send(())

        XCTAssertEqual(event, .addMember)
    }

    func test_sheetActions_fireEventsForTheSelectedMember() {
        load()   // opens on the clan head p13 (living)
        var events: [ILFamilyTreeNavEvent] = []
        sut.navigationEventPublisher.sink { events.append($0) }.store(in: &cancellables)

        fullProfileTappedSubject.send(())
        reminderTappedSubject.send(())
        offeringTappedSubject.send(())
        chantTappedSubject.send(())
        templeTappedSubject.send(())
        contextualActionTappedSubject.send(())   // living -> add descendant

        XCTAssertEqual(events, [
            .openProfile(memberID: "p13"), .remindAnniversary(memberID: "p13"),
            .lightLamp(memberID: "p13"), .chant(memberID: "p13"),
            .openTemple(memberID: "p13"), .addDescendant(memberID: "p13")
        ])
    }

    func test_contextualActionTapped_forDeceased_firesRemindAnniversary() {
        load()
        memberTappedSubject.send("p1")
        var event: ILFamilyTreeNavEvent?
        sut.navigationEventPublisher.sink { event = $0 }.store(in: &cancellables)

        contextualActionTappedSubject.send(())

        XCTAssertEqual(event, .remindAnniversary(memberID: "p1"))
    }

    func test_sheetActions_withoutLoadedTree_doNothing() {
        _ = sut.transform(input: makeInput())
        var events: [ILFamilyTreeNavEvent] = []
        sut.navigationEventPublisher.sink { events.append($0) }.store(in: &cancellables)

        fullProfileTappedSubject.send(())
        contextualActionTappedSubject.send(())

        XCTAssertTrue(events.isEmpty)
    }

    // MARK: - Navigation
    func test_backTapped_firesBack() {
        _ = sut.transform(input: makeInput())
        var event: ILFamilyTreeNavEvent?
        sut.navigationEventPublisher.sink { event = $0 }.store(in: &cancellables)

        backTappedSubject.send(())

        XCTAssertEqual(event, .back)
    }

    func test_createTapped_firesCreateTree() {
        _ = sut.transform(input: makeInput())
        var event: ILFamilyTreeNavEvent?
        sut.navigationEventPublisher.sink { event = $0 }.store(in: &cancellables)

        createTappedSubject.send(())

        XCTAssertEqual(event, .createTree)
    }

    func test_showCreatedTree_replacesEmptyStateWithTheNewTree() {
        mockUseCase.tree = .empty
        load()
        let created = ILFamilyTreeEntity(
            clanName: "Họ Trần Văn", hometown: "Hành Thiện",
            members: [ILFamilyMemberEntity(
                id: "p1", name: "Trần Văn Khải", gender: .male, birthYear: 1820, deathYear: 1890,
                anniversary: nil, note: nil, parentID: nil, spouseID: nil, isClanHead: false
            )]
        )

        sut.showCreatedTree(created)

        XCTAssertEqual(latest?.isEmpty, false)
        XCTAssertEqual(latest?.title, "Họ Trần Văn")
        XCTAssertEqual(latest?.nodes.count, 1)
        XCTAssertEqual(latest?.selectedID, "p1")
    }

    // MARK: - Books, switcher and merged view
    /// A maternal book whose "Trần Thị Hạnh" is the mother (`s2`) of the viewer `p18` in the sample clan.
    private var maternalBook: ILFamilyTreeEntity {
        ILFamilyTreeEntity(
            clanName: "Họ Trần", hometown: "Giao Thủy",
            members: [
                ILFamilyMemberEntity(
                    id: "p1", name: "Trần Văn Bảo", gender: .male, birthYear: 1920, deathYear: 1990,
                    anniversary: nil, note: nil, parentID: nil, spouseID: nil, isClanHead: false
                ),
                ILFamilyMemberEntity(
                    id: "p2", name: "Trần Thị Hạnh", gender: .female, birthYear: 1950, deathYear: nil,
                    anniversary: nil, note: nil, parentID: "p1", spouseID: nil, isClanHead: false
                )
            ],
            side: .maternal
        )
    }

    func test_viewDidLoad_enablesTheSwitcherWithOneBookRow() {
        let state = load()

        XCTAssertEqual(state?.canSwitch, true)
        XCTAssertEqual(state?.isSwitcherOpen, false)
        XCTAssertEqual(state?.switcherRows.count, 1)
        XCTAssertEqual(state?.switcherRows.first?.isSelected, true)
        XCTAssertEqual(state?.canCreateBook, true)
        XCTAssertEqual(state?.isMerged, false)
    }

    func test_titleTapped_opensThenClosesTheSwitcher() {
        load()

        titleTappedSubject.send(())
        XCTAssertEqual(latest?.isSwitcherOpen, true)

        titleTappedSubject.send(())
        XCTAssertEqual(latest?.isSwitcherOpen, false)
    }

    func test_switcherDismissed_closesTheSwitcher() {
        load()
        titleTappedSubject.send(())

        switcherDismissedSubject.send(())

        XCTAssertEqual(latest?.isSwitcherOpen, false)
    }

    func test_emptyState_hasNoSwitcher() {
        mockUseCase.tree = .empty

        let state = load()

        XCTAssertEqual(state?.isEmpty, true)
        XCTAssertEqual(state?.canSwitch, false)
        XCTAssertEqual(state?.switcherRows.isEmpty, true)
    }

    func test_showCreatedTree_secondBookBecomesMaternalAndOffersTheMergedRow() {
        mockResolver.meID = "p18"
        load()

        sut.showCreatedTree(maternalBook)

        XCTAssertEqual(latest?.title, "Họ Trần")
        // Two books + the merged "Nội – ngoại" row; no room for a third book.
        XCTAssertEqual(latest?.switcherRows.map(\.kind).count, 3)
        XCTAssertEqual(latest?.switcherRows.last?.kind, .merged)
        XCTAssertEqual(latest?.canCreateBook, false)
        // The viewer is not in the maternal book, so no "BẠN" there.
        XCTAssertNil(latest?.meID)
    }

    func test_viewSelected_merged_buildsThePedigreeAroundTheViewer() {
        mockResolver.meID = "p18"
        load()
        sut.showCreatedTree(maternalBook)

        viewSelectedSubject.send(.merged)

        XCTAssertEqual(latest?.isMerged, true)
        XCTAssertEqual(latest?.meID, "n:p18")
        XCTAssertEqual(latest?.selectedID, "n:p18")
        // viewer, father line p13…p1, grandmother s1, mother Hạnh and her father Bảo
        XCTAssertEqual(latest?.nodes.count, 9)
        XCTAssertEqual(latest?.generationChips.first?.title, "familyTree.generation.all".localized)
        XCTAssertEqual(latest?.detail?.role, "familyTree.merged.role.me".localized)
    }

    func test_viewSelected_backToABook_leavesTheMergedView() {
        mockResolver.meID = "p18"
        load()
        sut.showCreatedTree(maternalBook)
        viewSelectedSubject.send(.merged)
        guard let paternalID = latest?.switcherRows.first?.kind else { return XCTFail("no book row") }

        viewSelectedSubject.send(paternalID)

        XCTAssertEqual(latest?.isMerged, false)
        XCTAssertEqual(latest?.nodes.count, 24)
    }

    func test_viewSelected_sameView_justClosesTheSwitcher() {
        load()
        titleTappedSubject.send(())
        guard let current = latest?.switcherRows.first?.kind else { return XCTFail("no book row") }

        viewSelectedSubject.send(current)

        XCTAssertEqual(latest?.isSwitcherOpen, false)
        XCTAssertEqual(latest?.nodes.count, 24)
    }

    func test_chronicleTapped_firesOpenChronicle() {
        load()
        var event: ILFamilyTreeNavEvent?
        sut.navigationEventPublisher.sink { event = $0 }.store(in: &cancellables)

        chronicleTappedSubject.send(())

        XCTAssertEqual(event, .openChronicle)
    }

    func test_addTapped_inTheMergedView_firesNothing() {
        mockResolver.meID = "p18"
        load()
        sut.showCreatedTree(maternalBook)
        viewSelectedSubject.send(.merged)
        var event: ILFamilyTreeNavEvent?
        sut.navigationEventPublisher.sink { event = $0 }.store(in: &cancellables)

        addTappedSubject.send(())

        XCTAssertNil(event)
    }

    func test_showUpdatedBook_replacesTheBookAndKeepsThePersonSelected() {
        load()
        guard let member = Factory.tree.members.first(where: { $0.id == "p13" }) else { return XCTFail("no p13") }
        var renamed = member
        renamed.name = "Nguyễn Hữu Thành"
        var updated = Factory.tree
        updated.members = updated.members.map { $0.id == "p13" ? renamed : $0 }

        sut.showUpdatedBook(updated, memberID: "p13")

        XCTAssertEqual(latest?.selectedID, "p13")
        XCTAssertEqual(latest?.detail?.name, "Nguyễn Hữu Thành")
    }

    func test_showUpdatedBooks_appliesAChangedHometown() {
        load()
        var updated = Factory.tree
        updated.hometown = "Nam Định"

        sut.showUpdatedBooks([updated])

        XCTAssertEqual(latest?.subtitle, String(format: "familyTree.subtitle.format".localized, "Nam Định", 6, 24))
    }

    func test_profileContext_inTheMergedViewPointsAtTheOriginalBook() {
        mockResolver.meID = "p18"
        load()
        sut.showCreatedTree(maternalBook)
        viewSelectedSubject.send(.merged)

        let context = sut.profileContext(memberID: "g:p2")

        XCTAssertEqual(context?.memberID, "p2")
        XCTAssertEqual(context?.tree.clanName, "Họ Trần")
    }

    func test_openMember_inAnotherBook_switchesToThatBook() {
        mockResolver.meID = "p18"
        load()
        let maternal = maternalBook
        sut.showCreatedTree(maternal)
        sut.showTree(Factory.tree, selecting: "p13")

        sut.openMember(treeID: maternal.id, memberID: "p2")

        XCTAssertEqual(latest?.title, "Họ Trần")
        XCTAssertEqual(latest?.selectedID, "p2")
    }
}

// MARK: - Mock ILFamilyTreeUseCase
final class MockILFamilyTreeViewerResolver: ILFamilyTreeViewerResolving {
    var meID: String?

    func viewerMemberID(in tree: ILFamilyTreeEntity) -> String? { meID }
}

final class MockILFamilyTreeUseCase: ILFamilyTreeUseCase {
    var trees = [ILFamilyTreeTestFactory.tree]
    /// The first (paternal) book; assigning an empty tree means "the user has no book yet".
    var tree: ILFamilyTreeEntity {
        get { trees.first ?? .empty }
        set { trees = newValue.members.isEmpty ? [] : [newValue] }
    }
    var error: Error?
    var loadCalled = false

    func loadTrees() async throws -> [ILFamilyTreeEntity] {
        loadCalled = true
        if let error { throw error }
        return trees
    }

    func makePedigree(
        viewerID: String, paternal: ILFamilyTreeEntity, maternal: ILFamilyTreeEntity?
    ) -> ILFamilyTreePedigree? {
        ILFamilyTreePedigree.build(viewerID: viewerID, paternal: paternal, maternal: maternal)
    }

    func makeGraph(for tree: ILFamilyTreeEntity) -> ILFamilyTreeGraph {
        ILFamilyTreeGraph(members: tree.members)
    }
}
