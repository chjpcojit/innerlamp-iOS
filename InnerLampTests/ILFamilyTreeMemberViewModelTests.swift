//
//  ILFamilyTreeMemberViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

private final class MockILFamilyTreeMemberUseCase: ILFamilyTreeMemberUseCase {
    var draft = ILFamilyTreeMemberDraft(name: "Nguyễn Hữu Minh", birthYear: "1946", note: "Giữ nhà thờ tổ.")
    var result: Result<ILFamilyTreeMemberResult, ILFamilyTreeMemberIssue>
    var saveError: Error?
    private(set) var receivedDrafts: [ILFamilyTreeMemberDraft] = []
    private(set) var receivedMemberIDs: [String] = []
    private(set) var savedTrees: [ILFamilyTreeEntity] = []

    init(result: Result<ILFamilyTreeMemberResult, ILFamilyTreeMemberIssue>) {
        self.result = result
    }

    func makeDraft(from member: ILFamilyMemberEntity) -> ILFamilyTreeMemberDraft { draft }

    func updateMember(
        _ draft: ILFamilyTreeMemberDraft, memberID: String, in tree: ILFamilyTreeEntity, currentYear: Int
    ) -> Result<ILFamilyTreeMemberResult, ILFamilyTreeMemberIssue> {
        receivedDrafts.append(draft)
        receivedMemberIDs.append(memberID)
        return result
    }

    func save(_ tree: ILFamilyTreeEntity) async throws {
        savedTrees.append(tree)
        if let saveError { throw saveError }
    }
}

final class ILFamilyTreeMemberViewModelTests: XCTestCase {

    private let tree = ILFamilyTreeTestFactory.tree
    private var renamedTree: ILFamilyTreeEntity!
    private var mockUseCase: MockILFamilyTreeMemberUseCase!
    private var sut: ILFamilyTreeMemberViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var backTapped: PassthroughSubject<Void, Never>!
    private var editTapped: PassthroughSubject<Void, Never>!
    private var nameChanged: PassthroughSubject<String, Never>!
    private var genderSelected: PassthroughSubject<ILFamilyGender, Never>!
    private var birthYearChanged: PassthroughSubject<String, Never>!
    private var livingSelected: PassthroughSubject<Bool, Never>!
    private var residenceChanged: PassthroughSubject<String, Never>!
    private var deathYearChanged: PassthroughSubject<String, Never>!
    private var anniversaryChanged: PassthroughSubject<String, Never>!
    private var burialPlaceChanged: PassthroughSubject<String, Never>!
    private var dharmaNameChanged: PassthroughSubject<String, Never>!
    private var tabletTempleChanged: PassthroughSubject<String, Never>!
    private var noteChanged: PassthroughSubject<String, Never>!
    private var saveTapped: PassthroughSubject<Void, Never>!
    private var relationTapped: PassthroughSubject<String, Never>!
    private var remindTapped: PassthroughSubject<Void, Never>!
    private var lightLampTapped: PassthroughSubject<Void, Never>!
    private var chantTapped: PassthroughSubject<Void, Never>!
    private var templeTapped: PassthroughSubject<Void, Never>!

    private var latest: ILFamilyTreeMemberStateModel?
    private var latestFailure: Error?
    private var events: [ILFamilyTreeMemberNavEvent] = []

    override func setUp() {
        super.setUp()
        var renamed = tree
        if let index = renamed.members.firstIndex(where: { $0.id == "p13" }) {
            renamed.members[index].name = "Nguyễn Hữu Trí"
        }
        renamedTree = renamed
        mockUseCase = MockILFamilyTreeMemberUseCase(result: .success(.init(tree: renamed, memberID: "p13")))
        sut = ILFamilyTreeMemberViewModel(
            useCase: mockUseCase, tree: tree, memberID: "p13", kinship: "Cha",
            now: { DateComponents(calendar: .current, year: 2026, month: 10, day: 3).date ?? Date() }
        )
        cancellables = []
        backTapped = .init(); editTapped = .init(); nameChanged = .init(); genderSelected = .init()
        birthYearChanged = .init(); livingSelected = .init(); residenceChanged = .init()
        deathYearChanged = .init(); anniversaryChanged = .init(); burialPlaceChanged = .init()
        dharmaNameChanged = .init(); tabletTempleChanged = .init(); noteChanged = .init()
        saveTapped = .init(); relationTapped = .init(); remindTapped = .init(); lightLampTapped = .init()
        chantTapped = .init(); templeTapped = .init()
        latest = nil
        latestFailure = nil
        events = []

        let output = sut.transform(input: .init(
            viewDidLoad: Just(()).eraseToAnyPublisher(),
            backTapped: backTapped.eraseToAnyPublisher(),
            editTapped: editTapped.eraseToAnyPublisher(),
            nameChanged: nameChanged.eraseToAnyPublisher(),
            genderSelected: genderSelected.eraseToAnyPublisher(),
            birthYearChanged: birthYearChanged.eraseToAnyPublisher(),
            livingSelected: livingSelected.eraseToAnyPublisher(),
            residenceChanged: residenceChanged.eraseToAnyPublisher(),
            deathYearChanged: deathYearChanged.eraseToAnyPublisher(),
            anniversaryChanged: anniversaryChanged.eraseToAnyPublisher(),
            burialPlaceChanged: burialPlaceChanged.eraseToAnyPublisher(),
            dharmaNameChanged: dharmaNameChanged.eraseToAnyPublisher(),
            tabletTempleChanged: tabletTempleChanged.eraseToAnyPublisher(),
            noteChanged: noteChanged.eraseToAnyPublisher(),
            saveTapped: saveTapped.eraseToAnyPublisher(),
            relationTapped: relationTapped.eraseToAnyPublisher(),
            remindTapped: remindTapped.eraseToAnyPublisher(),
            lightLampTapped: lightLampTapped.eraseToAnyPublisher(),
            chantTapped: chantTapped.eraseToAnyPublisher(),
            templeTapped: templeTapped.eraseToAnyPublisher()
        ))
        output.state
            .sink { [weak self] state in
                switch state {
                case .success(let model): self?.latest = model
                case .failure(let error): self?.latestFailure = error
                case .idle, .loading: break
                }
            }
            .store(in: &cancellables)
        sut.navigationEventPublisher
            .sink { [weak self] in self?.events.append($0) }
            .store(in: &cancellables)
    }

    override func tearDown() {
        cancellables = nil
        latest = nil
        events = []
        sut = nil
        mockUseCase = nil
        renamedTree = nil
        super.tearDown()
    }

    private func enterEdit() {
        editTapped.send(())
    }

    // MARK: - View mode
    func test_initialState_isViewModeWithResolvedTexts() {
        XCTAssertEqual(latest?.mode, .view)
        XCTAssertEqual(latest?.name, "Nguyễn Hữu Minh")
        XCTAssertEqual(latest?.status, "Còn sống")
        XCTAssertEqual(latest?.role, "Tộc trưởng")
        XCTAssertEqual(latest?.kinship, "Cha")
        XCTAssertEqual(latest?.look.isClanHead, true)
        XCTAssertEqual(latest?.showsMemorial, false)
        XCTAssertEqual(latest?.note, "Giữ nhà thờ tổ.")
        XCTAssertFalse(latest?.facts.isEmpty ?? true)
        XCTAssertFalse(latest?.relations.isEmpty ?? true)
    }

    func test_backTapped_inViewMode_sendsBack() {
        backTapped.send(())
        XCTAssertEqual(events, [.back])
    }

    func test_relationTapped_sendsOpenMember() {
        relationTapped.send("p18")
        XCTAssertEqual(events, [.openMember("p18")])
    }

    func test_remindTapped_sendsRemindForThisMember() {
        remindTapped.send(())
        XCTAssertEqual(events, [.remind("p13")])
    }

    func test_lightLampTapped_sendsLightLamp() {
        lightLampTapped.send(())
        XCTAssertEqual(events, [.lightLamp("p13")])
    }

    func test_chantTapped_sendsChant() {
        chantTapped.send(())
        XCTAssertEqual(events, [.chant("p13")])
    }

    func test_templeTapped_sendsOpenTemple() {
        templeTapped.send(())
        XCTAssertEqual(events, [.openTemple("p13")])
    }

    // MARK: - Edit mode
    func test_editTapped_switchesToEditWithDraftFromUseCase() {
        enterEdit()
        XCTAssertEqual(latest?.mode, .edit)
        XCTAssertEqual(latest?.draft, mockUseCase.draft)
    }

    func test_backTapped_inEditMode_discardsEditAndStaysOnScreen() {
        enterEdit()
        nameChanged.send("Tên khác")
        backTapped.send(())
        XCTAssertEqual(latest?.mode, .view)
        XCTAssertEqual(latest?.name, "Nguyễn Hữu Minh")
        XCTAssertTrue(events.isEmpty)
    }

    func test_fieldEdits_updateDraft() {
        enterEdit()
        nameChanged.send("Nguyễn Văn A")
        genderSelected.send(.female)
        residenceChanged.send("Hà Nội")
        anniversaryChanged.send("15 tháng Chạp")
        burialPlaceChanged.send("Hành Thiện")
        dharmaNameChanged.send("Phúc Thiện")
        tabletTempleChanged.send("Chùa Keo")
        noteChanged.send("Tiểu sử")
        let draft = latest?.draft
        XCTAssertEqual(draft?.name, "Nguyễn Văn A")
        XCTAssertEqual(draft?.gender, .female)
        XCTAssertEqual(draft?.residence, "Hà Nội")
        XCTAssertEqual(draft?.anniversary, "15 tháng Chạp")
        XCTAssertEqual(draft?.burialPlace, "Hành Thiện")
        XCTAssertEqual(draft?.dharmaName, "Phúc Thiện")
        XCTAssertEqual(draft?.tabletTemple, "Chùa Keo")
        XCTAssertEqual(draft?.note, "Tiểu sử")
    }

    func test_yearFields_keepOnlyFourDigits() {
        enterEdit()
        birthYearChanged.send("19a8x7 9")
        deathYearChanged.send("20-1x5y")
        XCTAssertEqual(latest?.draft.birthYear, "1987")
        XCTAssertEqual(latest?.draft.deathYear, "2015")
    }

    func test_livingSelected_updatesDraftStatus() {
        enterEdit()
        livingSelected.send(false)
        XCTAssertEqual(latest?.draft.isLiving, false)
        livingSelected.send(true)
        XCTAssertEqual(latest?.draft.isLiving, true)
    }

    func test_fieldEdits_inViewMode_areIgnored() {
        nameChanged.send("Tên khác")
        XCTAssertEqual(latest?.draft, ILFamilyTreeMemberDraft())
    }

    // MARK: - Save
    func test_saveTapped_withIssue_showsErrorAndStaysInEdit() {
        mockUseCase.result = .failure(.init(field: .name, message: "Vui lòng nhập họ và tên."))
        enterEdit()
        saveTapped.send(())
        XCTAssertEqual(latest?.mode, .edit)
        XCTAssertEqual(latest?.errorField, .name)
        XCTAssertEqual(latest?.error(for: .name), "Vui lòng nhập họ và tên.")
        XCTAssertTrue(events.isEmpty)
        XCTAssertTrue(mockUseCase.savedTrees.isEmpty)
    }

    func test_editAfterIssue_clearsError() {
        mockUseCase.result = .failure(.init(field: .name, message: "x"))
        enterEdit()
        saveTapped.send(())
        nameChanged.send("Nguyễn Văn A")
        XCTAssertNil(latest?.errorField)
        XCTAssertNil(latest?.errorMessage)
    }

    func test_saveTapped_success_savesReturnsToViewAndEmitsSaved() async {
        let saved = expectation(description: "saved event")
        sut.navigationEventPublisher
            .sink { event in
                if case .saved = event { saved.fulfill() }
            }
            .store(in: &cancellables)

        enterEdit()
        saveTapped.send(())
        await fulfillment(of: [saved], timeout: 1)

        XCTAssertEqual(mockUseCase.receivedMemberIDs, ["p13"])
        XCTAssertEqual(mockUseCase.savedTrees, [renamedTree])
        XCTAssertEqual(events, [.saved(tree: renamedTree, memberID: "p13")])
        XCTAssertEqual(latest?.mode, .view)
        XCTAssertEqual(latest?.name, "Nguyễn Hữu Trí")
        XCTAssertEqual(latest?.isSubmitting, false)
    }

    func test_saveTapped_whenSaveFails_staysInEditAndPublishesFailure() async {
        struct SaveError: Error {}
        mockUseCase.saveError = SaveError()
        enterEdit()
        saveTapped.send(())
        for _ in 0..<20 where latestFailure == nil { await Task.yield() }

        XCTAssertNotNil(latestFailure)
        XCTAssertEqual(latest?.mode, .edit)
        XCTAssertEqual(latest?.isSubmitting, false)
        XCTAssertTrue(events.isEmpty)
    }

    func test_saveTapped_inViewMode_doesNothing() {
        saveTapped.send(())
        XCTAssertTrue(mockUseCase.receivedDrafts.isEmpty)
    }
}
