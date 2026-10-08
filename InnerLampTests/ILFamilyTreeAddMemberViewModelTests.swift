//
//  ILFamilyTreeAddMemberViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

private final class MockILFamilyTreeAddMemberUseCase: ILFamilyTreeAddMemberUseCase {
    var result: Result<ILFamilyTreeAddMemberResult, ILFamilyTreeAddMemberIssue>
    private(set) var receivedDrafts: [ILFamilyTreeAddMemberDraft] = []
    private(set) var savedTrees: [ILFamilyTreeEntity] = []
    var saveError: Error?

    init(result: Result<ILFamilyTreeAddMemberResult, ILFamilyTreeAddMemberIssue>) {
        self.result = result
    }

    func addMember(
        _ draft: ILFamilyTreeAddMemberDraft, to tree: ILFamilyTreeEntity, currentYear: Int
    ) -> Result<ILFamilyTreeAddMemberResult, ILFamilyTreeAddMemberIssue> {
        receivedDrafts.append(draft)
        return result
    }

    func save(_ tree: ILFamilyTreeEntity) async throws {
        savedTrees.append(tree)
        if let saveError { throw saveError }
    }
}

final class ILFamilyTreeAddMemberViewModelTests: XCTestCase {

    private let tree = ILFamilyTreeTestFactory.tree
    private var mockUseCase: MockILFamilyTreeAddMemberUseCase!
    private var sut: ILFamilyTreeAddMemberViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var closeTapped: PassthroughSubject<Void, Never>!
    private var relationSelected: PassthroughSubject<ILFamilyAddRelation, Never>!
    private var pickerToggled: PassthroughSubject<Void, Never>!
    private var relativePicked: PassthroughSubject<String, Never>!
    private var nameChanged: PassthroughSubject<String, Never>!
    private var genderSelected: PassthroughSubject<ILFamilyGender, Never>!
    private var birthYearChanged: PassthroughSubject<String, Never>!
    private var livingSelected: PassthroughSubject<Bool, Never>!
    private var deathYearChanged: PassthroughSubject<String, Never>!
    private var saveTapped: PassthroughSubject<Void, Never>!

    private var latest: ILFamilyTreeAddMemberStateModel?
    private var events: [ILFamilyTreeAddMemberNavEvent] = []

    override func setUp() {
        super.setUp()
        let updated = ILFamilyTreeEntity(clanName: tree.clanName, hometown: tree.hometown, members: tree.members)
        mockUseCase = MockILFamilyTreeAddMemberUseCase(result: .success(.init(tree: updated, memberID: "new")))
        sut = ILFamilyTreeAddMemberViewModel(
            useCase: mockUseCase, tree: tree, relativeID: "p13",
            now: { DateComponents(calendar: .current, year: 2026, month: 10, day: 3).date ?? Date() }
        )
        cancellables = []
        closeTapped = .init(); relationSelected = .init(); pickerToggled = .init(); relativePicked = .init()
        nameChanged = .init(); genderSelected = .init(); birthYearChanged = .init(); livingSelected = .init()
        deathYearChanged = .init(); saveTapped = .init()
        latest = nil
        events = []

        let never = Empty<String, Never>().eraseToAnyPublisher()
        let output = sut.transform(input: .init(
            viewDidLoad: Just(()).eraseToAnyPublisher(),
            closeTapped: closeTapped.eraseToAnyPublisher(),
            relationSelected: relationSelected.eraseToAnyPublisher(),
            pickerToggled: pickerToggled.eraseToAnyPublisher(),
            relativePicked: relativePicked.eraseToAnyPublisher(),
            nameChanged: nameChanged.eraseToAnyPublisher(),
            genderSelected: genderSelected.eraseToAnyPublisher(),
            birthYearChanged: birthYearChanged.eraseToAnyPublisher(),
            livingSelected: livingSelected.eraseToAnyPublisher(),
            deathYearChanged: deathYearChanged.eraseToAnyPublisher(),
            anniversaryChanged: never,
            residenceChanged: never,
            burialPlaceChanged: never,
            noteChanged: never,
            saveTapped: saveTapped.eraseToAnyPublisher()
        ))
        output.state
            .sink { [weak self] state in
                if case .success(let model) = state { self?.latest = model }
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
        super.tearDown()
    }

    func test_initialState_describesRelativeAndPreview() {
        XCTAssertEqual(latest?.relativeName, "Nguyễn Hữu Minh")
        XCTAssertEqual(latest?.preview, "Đời 6 · con của Nguyễn Hữu Minh và Trần Thị Hạnh")
        XCTAssertEqual(latest?.people.count, tree.members.count)
        XCTAssertEqual(latest?.people.filter(\.isSelected).map(\.id), ["p13"])
    }

    func test_closeTapped_sendsClose() {
        closeTapped.send(())
        XCTAssertEqual(events, [.close])
    }

    func test_pickerToggled_opensAndCloses() {
        pickerToggled.send(())
        XCTAssertEqual(latest?.isPickerOpen, true)
        pickerToggled.send(())
        XCTAssertEqual(latest?.isPickerOpen, false)
    }

    func test_relativePicked_switchesRelativeAndClosesPicker() {
        pickerToggled.send(())
        relativePicked.send("p18")
        XCTAssertEqual(latest?.relativeName, "Nguyễn Hữu Nam")
        XCTAssertEqual(latest?.isPickerOpen, false)
    }

    func test_spouseRelation_locksGenderToOppositeOfRelative() {
        relationSelected.send(.spouse)
        XCTAssertEqual(latest?.isGenderLocked, true)
        XCTAssertEqual(latest?.shownGender, .female)
        genderSelected.send(.male)
        XCTAssertEqual(latest?.shownGender, .female)
    }

    func test_childRelation_followsChosenGender() {
        genderSelected.send(.female)
        XCTAssertEqual(latest?.isGenderLocked, false)
        XCTAssertEqual(latest?.shownGender, .female)
    }

    func test_birthYear_keepsFourDigitsOnly() {
        birthYearChanged.send("19a98x7")
        XCTAssertEqual(latest?.draft.birthYear, "1998")
    }

    func test_saveTapped_invalid_showsIssueAndDoesNotNavigate() {
        mockUseCase.result = .failure(.init(field: .name, message: "Vui lòng nhập họ và tên."))
        saveTapped.send(())
        XCTAssertEqual(latest?.error(for: .name), "Vui lòng nhập họ và tên.")
        XCTAssertTrue(events.isEmpty)
    }

    func test_editingAfterError_clearsIt() {
        mockUseCase.result = .failure(.init(field: .name, message: "x"))
        saveTapped.send(())
        nameChanged.send("A")
        XCTAssertNil(latest?.errorField)
    }

    func test_saveTapped_valid_savesAndSendsSaved() async throws {
        nameChanged.send("Bảo")
        saveTapped.send(())
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(mockUseCase.receivedDrafts.last?.name, "Bảo")
        XCTAssertEqual(mockUseCase.savedTrees.count, 1)
        XCTAssertEqual(events.count, 1)
        if case .saved(_, let id)? = events.first { XCTAssertEqual(id, "new") } else { XCTFail("expected .saved") }
        XCTAssertEqual(latest?.isSubmitting, false)
    }
}
