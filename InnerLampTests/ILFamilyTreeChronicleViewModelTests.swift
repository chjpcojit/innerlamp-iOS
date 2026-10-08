//
//  ILFamilyTreeChronicleViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

private final class MockILFamilyTreeChronicleUseCase: ILFamilyTreeChronicleUseCase {
    var draft = ILFamilyTreeChronicleDraft(hometown: "Hành Thiện")
    /// `nil` = succeed with the tree that was passed in, hometown taken from the draft.
    var applyResult: Result<ILFamilyTreeEntity, ILFamilyTreeChronicleIssue>?
    var candidates: [ILFamilyMemberEntity] = []
    var saveError: Error?
    private(set) var appliedDrafts: [ILFamilyTreeChronicleDraft] = []
    private(set) var changedHeadIDs: [String] = []
    private(set) var savedTrees: [[ILFamilyTreeEntity]] = []

    func makeDraft(from tree: ILFamilyTreeEntity) -> ILFamilyTreeChronicleDraft { draft }

    func apply(
        _ draft: ILFamilyTreeChronicleDraft, to tree: ILFamilyTreeEntity, currentYear: Int
    ) -> Result<ILFamilyTreeEntity, ILFamilyTreeChronicleIssue> {
        appliedDrafts.append(draft)
        if let applyResult { return applyResult }
        var updated = tree
        updated.hometown = draft.hometown
        updated.chronicle.origin = draft.origin
        return .success(updated)
    }

    func clanHeadCandidates(in tree: ILFamilyTreeEntity) -> [ILFamilyMemberEntity] { candidates }

    func changeClanHead(to memberID: String, in tree: ILFamilyTreeEntity) -> ILFamilyTreeEntity {
        changedHeadIDs.append(memberID)
        var updated = tree
        updated.members = tree.members.map {
            var copy = $0
            copy.isClanHead = $0.id == memberID
            return copy
        }
        return updated
    }

    func save(_ trees: [ILFamilyTreeEntity]) async throws {
        savedTrees.append(trees)
        if let saveError { throw saveError }
    }
}

final class ILFamilyTreeChronicleViewModelTests: XCTestCase {

    private struct TestError: Error {}

    private let paternal = ILFamilyTreeTestFactory.tree
    private var maternal: ILFamilyTreeEntity {
        var tree = ILFamilyTreeEntity(clanName: "Họ Trần", hometown: "Giao Thủy", members: [])
        tree.side = .maternal
        return tree
    }

    private var mockUseCase: MockILFamilyTreeChronicleUseCase!
    private var sut: ILFamilyTreeChronicleViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var backTapped: PassthroughSubject<Void, Never>!
    private var editToggled: PassthroughSubject<Void, Never>!
    private var tabSelected: PassthroughSubject<String, Never>!
    private var fieldEdited: PassthroughSubject<ILFamilyTreeChronicleFieldEdit, Never>!
    private var milestoneAdded: PassthroughSubject<Void, Never>!
    private var milestoneDeleted: PassthroughSubject<String, Never>!
    private var headChangeTapped: PassthroughSubject<Void, Never>!
    private var headPickerDismissed: PassthroughSubject<Void, Never>!
    private var headCandidatePicked: PassthroughSubject<String, Never>!
    private var headChangeConfirmed: PassthroughSubject<Void, Never>!
    private var headChangeCancelled: PassthroughSubject<Void, Never>!
    private var founderTapped: PassthroughSubject<Void, Never>!
    private var keeperTapped: PassthroughSubject<Void, Never>!
    private var personTapped: PassthroughSubject<String, Never>!
    private var remindFounderTapped: PassthroughSubject<Void, Never>!

    private var latest: ILFamilyTreeChronicleStateModel?
    private var failure: Error?
    private var events: [ILFamilyTreeChronicleNavEvent] = []

    override func setUp() {
        super.setUp()
        mockUseCase = MockILFamilyTreeChronicleUseCase()
        mockUseCase.candidates = ILFamilyTreeTestFactory.members.filter { ["p13", "p18"].contains($0.id) }
        bind(trees: [paternal], initialTreeID: paternal.id)
    }

    override func tearDown() {
        cancellables = nil
        latest = nil
        failure = nil
        events = []
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func bind(trees: [ILFamilyTreeEntity], initialTreeID: String) {
        sut = ILFamilyTreeChronicleViewModel(
            useCase: mockUseCase, trees: trees, initialTreeID: initialTreeID, makeID: { "m-new" },
            now: { DateComponents(calendar: .current, year: 2026, month: 10, day: 3).date ?? Date() }
        )
        cancellables = []
        backTapped = .init(); editToggled = .init(); tabSelected = .init(); fieldEdited = .init()
        milestoneAdded = .init(); milestoneDeleted = .init(); headChangeTapped = .init()
        headPickerDismissed = .init(); headCandidatePicked = .init(); headChangeConfirmed = .init()
        headChangeCancelled = .init(); founderTapped = .init(); keeperTapped = .init()
        personTapped = .init(); remindFounderTapped = .init()
        latest = nil
        failure = nil
        events = []

        let output = sut.transform(input: .init(
            viewDidLoad: Just(()).eraseToAnyPublisher(),
            backTapped: backTapped.eraseToAnyPublisher(),
            editToggled: editToggled.eraseToAnyPublisher(),
            tabSelected: tabSelected.eraseToAnyPublisher(),
            fieldEdited: fieldEdited.eraseToAnyPublisher(),
            milestoneAdded: milestoneAdded.eraseToAnyPublisher(),
            milestoneDeleted: milestoneDeleted.eraseToAnyPublisher(),
            headChangeTapped: headChangeTapped.eraseToAnyPublisher(),
            headPickerDismissed: headPickerDismissed.eraseToAnyPublisher(),
            headCandidatePicked: headCandidatePicked.eraseToAnyPublisher(),
            headChangeConfirmed: headChangeConfirmed.eraseToAnyPublisher(),
            headChangeCancelled: headChangeCancelled.eraseToAnyPublisher(),
            founderTapped: founderTapped.eraseToAnyPublisher(),
            keeperTapped: keeperTapped.eraseToAnyPublisher(),
            personTapped: personTapped.eraseToAnyPublisher(),
            remindFounderTapped: remindFounderTapped.eraseToAnyPublisher()
        ))
        output.state
            .sink { [weak self] state in
                switch state {
                case .success(let model): self?.latest = model
                case .failure(let error): self?.failure = error
                case .idle, .loading: break
                }
            }
            .store(in: &cancellables)
        sut.navigationEventPublisher
            .sink { [weak self] in self?.events.append($0) }
            .store(in: &cancellables)
    }

    // MARK: - Initial state
    func test_initialState_describesTheActiveBookInViewMode() {
        XCTAssertEqual(latest?.title, "Họ Nguyễn Hữu")
        XCTAssertEqual(latest?.home, "Hành Thiện")
        XCTAssertEqual(latest?.isEditing, false)
        XCTAssertEqual(latest?.founderMemberID, "p1")
        XCTAssertEqual(latest?.founderName, "Nguyễn Hữu Phúc")
        XCTAssertEqual(latest?.keeperMemberID, "p13")
        XCTAssertEqual(latest?.canRemindFounder, true)
        XCTAssertEqual(latest?.tabs.count, 0)
        XCTAssertLessThanOrEqual(latest?.people.count ?? 99, 4)
    }

    func test_back_sendsBack() {
        backTapped.send(())
        XCTAssertEqual(events, [.back])
    }

    // MARK: - Edit mode
    func test_editToggled_whenViewing_entersEditWithDraft() {
        editToggled.send(())
        XCTAssertEqual(latest?.isEditing, true)
        XCTAssertEqual(latest?.draft.hometown, "Hành Thiện")
    }

    func test_editToggled_whenEditing_validDraft_savesAndReturnsToView() async throws {
        editToggled.send(())
        fieldEdited.send(.origin("Gốc tích"))
        editToggled.send(())
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(mockUseCase.appliedDrafts.last?.origin, "Gốc tích")
        XCTAssertEqual(mockUseCase.savedTrees.count, 1)
        XCTAssertEqual(latest?.isEditing, false)
        XCTAssertEqual(latest?.origin, "Gốc tích")
        XCTAssertEqual(latest?.isSaving, false)
        XCTAssertNotNil(latest?.toastMessage)
        if case .updated(let trees)? = events.first { XCTAssertEqual(trees.first?.chronicle.origin, "Gốc tích") } else { XCTFail("expected .updated") }
    }

    func test_editToggled_whenEditing_invalidDraft_showsIssueAndStaysEditing() {
        mockUseCase.applyResult = .failure(.init(field: .milestoneYear("m1"), message: "Năm chưa hợp lệ."))
        editToggled.send(())
        editToggled.send(())
        XCTAssertEqual(latest?.isEditing, true)
        XCTAssertEqual(latest?.error(for: .milestoneYear("m1")), "Năm chưa hợp lệ.")
        XCTAssertTrue(events.isEmpty)
    }

    func test_editToggled_saveFails_staysEditingAndSendsFailure() async throws {
        mockUseCase.saveError = TestError()
        editToggled.send(())
        editToggled.send(())
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertNotNil(failure)
        XCTAssertEqual(latest?.isEditing, true)
        XCTAssertEqual(latest?.isSaving, false)
        XCTAssertTrue(events.isEmpty)
    }

    func test_fieldEdited_updatesDraftAndClearsError() {
        mockUseCase.applyResult = .failure(.init(field: .milestoneYear("m1"), message: "x"))
        editToggled.send(())
        editToggled.send(())
        fieldEdited.send(.shrineName("Nhà thờ tổ"))
        XCTAssertEqual(latest?.draft.shrineName, "Nhà thờ tổ")
        XCTAssertNil(latest?.errorField)
    }

    func test_fieldEdited_ignoredInViewMode() {
        fieldEdited.send(.origin("x"))
        XCTAssertEqual(latest?.draft.origin, "")
    }

    func test_milestoneYear_keepsFourDigitsOnly() {
        mockUseCase.draft.milestones = [.init(id: "a", year: "", text: "")]
        editToggled.send(())
        fieldEdited.send(.milestoneYear(id: "a", text: "19a12x7"))
        XCTAssertEqual(latest?.draft.milestones.first?.year, "1912")
    }

    func test_milestoneAdded_appendsEmptyRowWithNewId() {
        editToggled.send(())
        milestoneAdded.send(())
        XCTAssertEqual(latest?.draft.milestones, [.init(id: "m-new", year: "", text: "")])
    }

    func test_milestoneDeleted_removesThatRow() {
        mockUseCase.draft.milestones = [.init(id: "a", year: "1", text: ""), .init(id: "b", year: "2", text: "")]
        editToggled.send(())
        milestoneDeleted.send("a")
        XCTAssertEqual(latest?.draft.milestones.map(\.id), ["b"])
    }

    // MARK: - Tabs
    func test_tabs_shownOnlyWithSeveralBooks_andSelectionSwitchesBook() {
        let maternalTree = maternal
        bind(trees: [paternal, maternalTree], initialTreeID: paternal.id)
        XCTAssertEqual(latest?.tabs.map(\.treeID), [paternal.id, maternalTree.id])
        XCTAssertEqual(latest?.tabs.map(\.isSelected), [true, false])

        editToggled.send(())
        tabSelected.send(maternalTree.id)
        XCTAssertEqual(latest?.title, "Họ Trần")
        XCTAssertEqual(latest?.isEditing, false)
        XCTAssertEqual(latest?.tabs.map(\.isSelected), [false, true])
    }

    // MARK: - Clan head
    func test_headChangeTapped_opensPickerWithCandidates_andDismissCloses() {
        headChangeTapped.send(())
        XCTAssertEqual(latest?.isHeadPickerOpen, true)
        XCTAssertEqual(latest?.candidates.map(\.memberID), ["p13", "p18"])
        XCTAssertEqual(latest?.candidates.map(\.isCurrent), [true, false])
        headPickerDismissed.send(())
        XCTAssertEqual(latest?.isHeadPickerOpen, false)
    }

    func test_headCandidatePicked_asksForConfirmation() {
        headChangeTapped.send(())
        headCandidatePicked.send("p18")
        XCTAssertEqual(latest?.pendingHead?.memberID, "p18")
        XCTAssertEqual(latest?.isHeadPickerOpen, false)
        XCTAssertTrue(mockUseCase.changedHeadIDs.isEmpty)
    }

    func test_headCandidatePicked_currentHead_isIgnored() {
        headChangeTapped.send(())
        headCandidatePicked.send("p13")
        XCTAssertNil(latest?.pendingHead)
    }

    func test_headChangeCancelled_dropsThePendingChange() {
        headChangeTapped.send(())
        headCandidatePicked.send("p18")
        headChangeCancelled.send(())
        XCTAssertNil(latest?.pendingHead)
        XCTAssertTrue(mockUseCase.changedHeadIDs.isEmpty)
    }

    func test_headChangeConfirmed_changesHeadSavesAndSendsUpdated() async throws {
        headChangeTapped.send(())
        headCandidatePicked.send("p18")
        headChangeConfirmed.send(())
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(mockUseCase.changedHeadIDs, ["p18"])
        XCTAssertEqual(mockUseCase.savedTrees.count, 1)
        XCTAssertEqual(latest?.keeperMemberID, "p18")
        XCTAssertNil(latest?.pendingHead)
        if case .updated(let trees)? = events.first {
            XCTAssertEqual(trees.first?.members.filter(\.isClanHead).map(\.id), ["p18"])
        } else {
            XCTFail("expected .updated")
        }
    }

    // MARK: - Hand-offs
    func test_founderTapped_opensTheFounder() {
        founderTapped.send(())
        XCTAssertEqual(events, [.openMember(treeID: paternal.id, memberID: "p1")])
    }

    func test_keeperTapped_opensTheClanHead() {
        keeperTapped.send(())
        XCTAssertEqual(events, [.openMember(treeID: paternal.id, memberID: "p13")])
    }

    func test_personTapped_opensThatPerson() {
        personTapped.send("p13")
        XCTAssertEqual(events, [.openMember(treeID: paternal.id, memberID: "p13")])
    }

    func test_remindFounderTapped_sendsReminderEvent() {
        remindFounderTapped.send(())
        XCTAssertEqual(events, [.remindFounderAnniversary(treeID: paternal.id, memberID: "p1")])
    }
}
