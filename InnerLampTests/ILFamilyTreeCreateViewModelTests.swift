//
//  ILFamilyTreeCreateViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILFamilyTreeCreateViewModelTests: XCTestCase {

    private var mockUseCase: MockILFamilyTreeCreateUseCase!
    private var sut: ILFamilyTreeCreateViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var clanNameChangedSubject: PassthroughSubject<String, Never>!
    private var hometownChangedSubject: PassthroughSubject<String, Never>!
    private var founderNameChangedSubject: PassthroughSubject<String, Never>!
    private var birthYearChangedSubject: PassthroughSubject<String, Never>!
    private var livingSelectedSubject: PassthroughSubject<Bool, Never>!
    private var deathYearChangedSubject: PassthroughSubject<String, Never>!
    private var anniversaryChangedSubject: PassthroughSubject<String, Never>!
    private var spouseNameChangedSubject: PassthroughSubject<String, Never>!
    private var createTappedSubject: PassthroughSubject<Void, Never>!

    private var latest: ILFamilyTreeCreateStateModel?
    private var events: [ILFamilyTreeCreateNavEvent] = []

    override func setUp() {
        super.setUp()
        mockUseCase = MockILFamilyTreeCreateUseCase()
        sut = ILFamilyTreeCreateViewModel(useCase: mockUseCase, now: {
            DateComponents(calendar: .current, year: 2026, month: 10, day: 3).date ?? Date()
        })
        cancellables = []
        viewDidLoadSubject = .init()
        backTappedSubject = .init()
        clanNameChangedSubject = .init()
        hometownChangedSubject = .init()
        founderNameChangedSubject = .init()
        birthYearChangedSubject = .init()
        livingSelectedSubject = .init()
        deathYearChangedSubject = .init()
        anniversaryChangedSubject = .init()
        spouseNameChangedSubject = .init()
        createTappedSubject = .init()
        latest = nil
        events = []

        let output = sut.transform(input: .init(
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

    private func fillValidForm() {
        clanNameChangedSubject.send("Trần Văn")
        hometownChangedSubject.send("Hành Thiện")
        founderNameChangedSubject.send("Trần Văn Khải")
        birthYearChangedSubject.send("1820")
        deathYearChangedSubject.send("1890")
    }

    /// Lets the `Task` started by a successful create run to completion.
    private func settle() async {
        for _ in 0..<5 { await Task.yield() }
    }

    // MARK: - Initial state
    func test_viewDidLoad_publishesPlaceholderHeaderAndDeceasedStatus() {
        viewDidLoadSubject.send(())

        XCTAssertEqual(latest?.headerTitle, "familyTreeCreate.header.title.placeholder".localized)
        XCTAssertEqual(latest?.headerSubtitle, "familyTreeCreate.header.subtitle.placeholder".localized)
        XCTAssertEqual(latest?.isFounderLiving, false)
        XCTAssertNil(latest?.errorField)
        XCTAssertEqual(latest?.isSubmitting, false)
    }

    // MARK: - Field edits
    func test_fieldChanges_mirrorIntoState() {
        clanNameChangedSubject.send("Trần Văn")
        hometownChangedSubject.send("Nam Định")
        founderNameChangedSubject.send("Khải")
        anniversaryChangedSubject.send("15 tháng Chạp")
        spouseNameChangedSubject.send("Hiền")

        XCTAssertEqual(latest?.clanName, "Trần Văn")
        XCTAssertEqual(latest?.hometown, "Nam Định")
        XCTAssertEqual(latest?.founderName, "Khải")
        XCTAssertEqual(latest?.anniversary, "15 tháng Chạp")
        XCTAssertEqual(latest?.spouseName, "Hiền")
    }

    func test_clanNameChanged_updatesHeaderTitleThroughUseCase() {
        clanNameChangedSubject.send("Trần Văn")
        XCTAssertEqual(latest?.headerTitle, "Họ Trần Văn")

        clanNameChangedSubject.send("  ")
        XCTAssertEqual(latest?.headerTitle, "familyTreeCreate.header.title.placeholder".localized)
    }

    func test_hometownAndFounderChanged_updateHeaderSubtitle() {
        hometownChangedSubject.send("Nam Định")
        XCTAssertEqual(latest?.headerSubtitle, "Nam Định")

        founderNameChangedSubject.send("Khải")
        XCTAssertEqual(latest?.headerSubtitle, "Nam Định · " + String(format: "familyTreeCreate.header.subtitle.founder".localized, "Khải"))

        hometownChangedSubject.send("")
        XCTAssertEqual(latest?.headerSubtitle, String(format: "familyTreeCreate.header.subtitle.founder".localized, "Khải"))
    }

    func test_yearFields_keepOnlyFourDigits() {
        birthYearChangedSubject.send("18a2b0c99")
        deathYearChangedSubject.send("x1-8 9 0")

        XCTAssertEqual(latest?.birthYear, "1820")
        XCTAssertEqual(latest?.deathYear, "1890")
    }

    func test_livingSelected_togglesStatus() {
        livingSelectedSubject.send(true)
        XCTAssertEqual(latest?.isFounderLiving, true)

        livingSelectedSubject.send(false)
        XCTAssertEqual(latest?.isFounderLiving, false)
    }

    // MARK: - Create
    func test_createTapped_withInvalidForm_showsErrorAndDoesNotSave() async {
        mockUseCase.result = .failure(ILFamilyTreeCreateIssue(field: .hometown, message: "boom"))

        createTappedSubject.send(())
        await settle()

        XCTAssertEqual(latest?.errorField, .hometown)
        XCTAssertEqual(latest?.errorMessage, "boom")
        XCTAssertEqual(latest?.error(for: .hometown), "boom")
        XCTAssertNil(latest?.error(for: .clanName))
        XCTAssertFalse(mockUseCase.saveCalled)
        XCTAssertEqual(events, [])
    }

    func test_editingAfterError_clearsTheError() {
        mockUseCase.result = .failure(ILFamilyTreeCreateIssue(field: .hometown, message: "boom"))
        createTappedSubject.send(())

        hometownChangedSubject.send("Nam Định")

        XCTAssertNil(latest?.errorField)
        XCTAssertNil(latest?.errorMessage)
    }

    func test_createTapped_passesTypedDraftAndCurrentYearToUseCase() {
        fillValidForm()
        livingSelectedSubject.send(false)
        spouseNameChangedSubject.send("Lê Thị Hiền")

        createTappedSubject.send(())

        XCTAssertEqual(mockUseCase.lastDraft?.clanName, "Trần Văn")
        XCTAssertEqual(mockUseCase.lastDraft?.birthYear, "1820")
        XCTAssertEqual(mockUseCase.lastDraft?.deathYear, "1890")
        XCTAssertEqual(mockUseCase.lastDraft?.spouseName, "Lê Thị Hiền")
        XCTAssertEqual(mockUseCase.lastDraft?.isFounderLiving, false)
        XCTAssertEqual(mockUseCase.lastYear, 2026)
    }

    func test_createTapped_withValidForm_savesThenEmitsCreated() async {
        let tree = ILFamilyTreeEntity(clanName: "Họ Trần Văn", hometown: "Hành Thiện", members: [])
        mockUseCase.result = .success(tree)
        fillValidForm()

        createTappedSubject.send(())
        XCTAssertEqual(latest?.isSubmitting, true)
        await settle()

        XCTAssertTrue(mockUseCase.saveCalled)
        XCTAssertEqual(mockUseCase.savedTree, tree)
        XCTAssertEqual(latest?.isSubmitting, false)
        XCTAssertEqual(events, [.created(tree)])
    }

    func test_createTapped_whileSaving_isIgnored() async {
        mockUseCase.result = .success(.empty)

        createTappedSubject.send(())
        createTappedSubject.send(())
        await settle()

        XCTAssertEqual(mockUseCase.saveCount, 1)
    }

    func test_createTapped_whenSaveFails_publishesFailureAndStaysOnScreen() async {
        struct SaveError: Error {}
        mockUseCase.result = .success(.empty)
        mockUseCase.saveError = SaveError()
        var failure: Error?
        sut.transform(input: .init(
            viewDidLoad: Empty().eraseToAnyPublisher(), backTapped: Empty().eraseToAnyPublisher(),
            clanNameChanged: Empty().eraseToAnyPublisher(), hometownChanged: Empty().eraseToAnyPublisher(),
            founderNameChanged: Empty().eraseToAnyPublisher(), birthYearChanged: Empty().eraseToAnyPublisher(),
            livingSelected: Empty().eraseToAnyPublisher(), deathYearChanged: Empty().eraseToAnyPublisher(),
            anniversaryChanged: Empty().eraseToAnyPublisher(), spouseNameChanged: Empty().eraseToAnyPublisher(),
            createTapped: Empty().eraseToAnyPublisher()
        )).state
            .sink { if case .failure(let error) = $0 { failure = error } }
            .store(in: &cancellables)

        createTappedSubject.send(())
        await settle()

        XCTAssertNotNil(failure)
        XCTAssertEqual(latest?.isSubmitting, false)
        XCTAssertEqual(events, [])
    }

    // MARK: - Back
    func test_backTapped_emitsBack() {
        backTappedSubject.send(())
        XCTAssertEqual(events, [.back])
    }
}

// MARK: - Mock ILFamilyTreeCreateUseCase
final class MockILFamilyTreeCreateUseCase: ILFamilyTreeCreateUseCase {
    var result: Result<ILFamilyTreeEntity, ILFamilyTreeCreateIssue> = .success(.empty)
    var lastDraft: ILFamilyTreeCreateDraft?
    var lastYear: Int?

    var saveCalled: Bool { saveCount > 0 }
    var saveCount = 0
    var savedTree: ILFamilyTreeEntity?
    var saveError: Error?

    func clanDisplayName(_ rawName: String) -> String {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "" : "Họ " + name
    }

    func createTree(from draft: ILFamilyTreeCreateDraft, currentYear: Int) -> Result<ILFamilyTreeEntity, ILFamilyTreeCreateIssue> {
        lastDraft = draft
        lastYear = currentYear
        return result
    }

    func save(_ tree: ILFamilyTreeEntity) async throws {
        saveCount += 1
        savedTree = tree
        if let saveError { throw saveError }
    }
}
