//
//  ILTempleFinderViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILTempleFinderViewModelTests: XCTestCase {

    private var mockUseCase: MockILTempleFinderUseCase!
    private var sut: ILTempleFinderViewModel!
    private var cancellables: Set<AnyCancellable>!
    private var latest: ILTempleFinderStateModel?
    private var latestState: ViewState<ILTempleFinderStateModel> = .idle
    private var latestChips: [ILTempleFinderRegionChipModel] = []
    /// Called on every `.success` — lets a test wait for a reload.
    private var onSuccess: (() -> Void)?

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var queryChangedSubject: PassthroughSubject<String, Never>!
    private var regionSelectedSubject: PassthroughSubject<ILTempleFinderRegionFilter, Never>!
    private var templeTappedSubject: PassthroughSubject<String, Never>!
    private var pickTappedSubject: PassthroughSubject<String, Never>!
    private var retryTappedSubject: PassthroughSubject<Void, Never>!
    private var addTappedSubject: PassthroughSubject<Void, Never>!
    private var addCancelledSubject: PassthroughSubject<Void, Never>!
    private var addSubmittedSubject: PassthroughSubject<ILTempleFinderProposal, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILTempleFinderUseCase()
        sut = ILTempleFinderViewModel(useCase: mockUseCase)
        cancellables = []
        latest = nil
        latestState = .idle
        viewDidLoadSubject = PassthroughSubject()
        backTappedSubject = PassthroughSubject()
        queryChangedSubject = PassthroughSubject()
        regionSelectedSubject = PassthroughSubject()
        templeTappedSubject = PassthroughSubject()
        pickTappedSubject = PassthroughSubject()
        retryTappedSubject = PassthroughSubject()
        addTappedSubject = PassthroughSubject()
        addCancelledSubject = PassthroughSubject()
        addSubmittedSubject = PassthroughSubject()
    }

    override func tearDown() {
        cancellables = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    /// Binds, sends `viewDidLoad` and waits for the load to settle (success or failure).
    private func load(file: StaticString = #filePath, line: UInt = #line) {
        let settled = expectation(description: "load settled")
        settled.assertForOverFulfill = false
        let output = sut.transform(input: ILTempleFinderViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            queryChanged: queryChangedSubject.eraseToAnyPublisher(),
            regionSelected: regionSelectedSubject.eraseToAnyPublisher(),
            templeTapped: templeTappedSubject.eraseToAnyPublisher(),
            pickTapped: pickTappedSubject.eraseToAnyPublisher(),
            retryTapped: retryTappedSubject.eraseToAnyPublisher(),
            addTapped: addTappedSubject.eraseToAnyPublisher(),
            addCancelled: addCancelledSubject.eraseToAnyPublisher(),
            addSubmitted: addSubmittedSubject.eraseToAnyPublisher()
        ))
        output.state.sink { [weak self] state in
            self?.latestState = state
            if case .success(let model) = state {
                self?.latest = model
                self?.onSuccess?()
            }
            switch state {
            case .success, .failure: settled.fulfill()
            default: break
            }
        }.store(in: &cancellables)
        output.filters.sink { [weak self] in self?.latestChips = $0 }.store(in: &cancellables)
        viewDidLoadSubject.send(())
        wait(for: [settled], timeout: 2)
    }

    private func navigationEvent(_ action: () -> Void) -> ILTempleFinderNavEvent? {
        var received: ILTempleFinderNavEvent?
        sut.navigationEventPublisher.sink { received = $0 }.store(in: &cancellables)
        action()
        return received
    }

    private func proposal(name: String = "", province: String = "") -> ILTempleFinderProposal {
        ILTempleFinderProposal(name: name, address: "", province: province, phone: "")
    }

    // MARK: - Loading

    func test_viewDidLoad_listsEveryTemple_andMarksTheChosenOne() {
        mockUseCase.myTemple = (id: "tq", name: "Chùa Từ Quang")
        load()

        XCTAssertEqual(latest?.rows.map(\.id), ["tq", "vn", "mc"])
        XCTAssertEqual(latest?.rows.map(\.isMine), [true, false, false])
        XCTAssertEqual(latest?.subtitle, String(format: "templeFinder.subtitle.current".localized, "Chùa Từ Quang"))
        XCTAssertNil(latest?.emptyText)
        XCTAssertNil(latest?.addForm)
    }

    func test_viewDidLoad_withoutChosenTemple_showsNoCurrentTempleSubtitle() {
        load()

        XCTAssertEqual(latest?.subtitle, "templeFinder.subtitle.none".localized)
    }

    func test_viewDidLoad_onFailure_emitsFailure_andRetryReloads() {
        mockUseCase.result = .failure(ILCatalogError.offline)
        load()
        guard case .failure = latestState else { return XCTFail("expected .failure, got \(latestState)") }

        mockUseCase.result = .success(MockILTempleFinderUseCase.defaultTemples)
        let reloaded = expectation(description: "reloaded")
        onSuccess = { reloaded.fulfill() }
        retryTappedSubject.send(())
        wait(for: [reloaded], timeout: 2)
        XCTAssertEqual(mockUseCase.loadCount, 2)
    }

    // MARK: - Search & region filter

    func test_queryChanged_matchesNameOrAddress_ignoringDiacriticsAndCase() {
        load()

        queryChangedSubject.send("tu QUANG")
        XCTAssertEqual(latest?.rows.map(\.id), ["tq"])

        queryChangedSubject.send("ha noi")
        XCTAssertEqual(latest?.rows.map(\.id), ["mc"])
    }

    func test_queryChanged_withNoMatch_showsEmptyText() {
        load()

        queryChangedSubject.send("xyz")

        XCTAssertEqual(latest?.rows, [])
        XCTAssertEqual(latest?.emptyText, String(format: "templeFinder.empty.query".localized, "xyz"))
    }

    func test_regionSelected_filtersByRegion_andMovesTheSelectedChip() {
        load()

        regionSelectedSubject.send(.north)

        XCTAssertEqual(latest?.rows.map(\.id), ["mc"])
        XCTAssertEqual(latestChips.filter(\.isSelected).map(\.filter), [.north])
    }

    func test_regionSelected_withNoTempleInRegion_showsRegionEmptyText() {
        load()

        regionSelectedSubject.send(.central)

        XCTAssertEqual(latest?.emptyText, String(format: "templeFinder.empty.region".localized, "templeFinder.region.central".localized))
    }

    // MARK: - Navigation & pick

    func test_templeTapped_opensThatTemple() {
        load()

        XCTAssertEqual(navigationEvent { templeTappedSubject.send("vn") }, .openTemple(id: "vn"))
    }

    func test_pickTapped_savesTheTemple_andClosesWithPicked() {
        load()

        let event = navigationEvent { pickTappedSubject.send("vn") }

        XCTAssertEqual(event, .picked)
        XCTAssertEqual(mockUseCase.selected?.id, "vn")
    }

    func test_backTapped_sendsBack() {
        load()

        XCTAssertEqual(navigationEvent { backTappedSubject.send(()) }, .back)
    }

    // MARK: - Add temple proposal (UI only)

    func test_addTapped_opensFormPrefilledWithTheQuery() {
        load()
        queryChangedSubject.send("  Pháp Hoa ")

        addTappedSubject.send(())

        XCTAssertEqual(latest?.addForm, ILTempleFinderAddFormModel(prefillName: "Pháp Hoa", errorMessage: nil, errorField: nil))
    }

    func test_addCancelled_closesTheForm() {
        load()
        addTappedSubject.send(())

        addCancelledSubject.send(())

        XCTAssertNil(latest?.addForm)
    }

    func test_addSubmitted_withoutName_flagsTheNameField() {
        load()
        addTappedSubject.send(())

        addSubmittedSubject.send(proposal(name: "  ", province: "Đà Nẵng"))

        XCTAssertEqual(latest?.addForm?.errorField, .name)
        XCTAssertEqual(latest?.addForm?.errorMessage, "templeFinder.add.error.name".localized)
        XCTAssertNil(latest?.sentMessage)
    }

    func test_addSubmitted_withoutProvince_flagsTheProvinceField() {
        load()
        addTappedSubject.send(())

        addSubmittedSubject.send(proposal(name: "Chùa Pháp Hoa"))

        XCTAssertEqual(latest?.addForm?.errorField, .province)
        XCTAssertEqual(latest?.addForm?.errorMessage, "templeFinder.add.error.province".localized)
    }

    func test_addSubmitted_forATempleAlreadyListed_flagsADuplicate() {
        load()
        addTappedSubject.send(())

        addSubmittedSubject.send(proposal(name: "chua tu quang", province: "Hồ Chí Minh"))

        XCTAssertEqual(latest?.addForm?.errorField, .name)
        XCTAssertEqual(latest?.addForm?.errorMessage, String(format: "templeFinder.add.error.duplicate".localized, "Chùa Từ Quang"))
    }

    func test_addSubmitted_sameNameInAnotherProvince_isNotADuplicate() {
        load()
        addTappedSubject.send(())

        addSubmittedSubject.send(proposal(name: "Chùa Từ Quang", province: "Đà Nẵng"))

        XCTAssertNil(latest?.addForm)
        XCTAssertEqual(latest?.sentMessage, String(format: "templeFinder.sent".localized, "Chùa Từ Quang"))
    }

    func test_addSubmitted_valid_closesTheForm_showsSentMessage_andClearsTheQuery() {
        load()
        queryChangedSubject.send("pháp")
        addTappedSubject.send(())

        addSubmittedSubject.send(proposal(name: "Chùa Pháp Hoa", province: "Đà Nẵng"))

        XCTAssertNil(latest?.addForm)
        XCTAssertEqual(latest?.sentMessage, String(format: "templeFinder.sent".localized, "Chùa Pháp Hoa"))
        XCTAssertEqual(latest?.rows.count, 3)
        XCTAssertNil(mockUseCase.selected)
    }

    func test_normalize_foldsDiacriticsCaseAndD() {
        XCTAssertEqual(ILTempleFinderViewModel.normalize("Chùa Đại Từ"), "chua dai tu")
    }
}

// MARK: - Mock

final class MockILTempleFinderUseCase: ILTempleFinderUseCase {

    static let defaultTemples = [
        ILTempleFinderUseCaseTests.makeTemple(
            id: "tq", name: "Chùa Từ Quang", address: "Bình Thạnh, TP. Hồ Chí Minh", region: .south
        ),
        ILTempleFinderUseCaseTests.makeTemple(
            id: "vn", name: "Chùa Vĩnh Nghiêm", address: "Quận 3, TP. Hồ Chí Minh", region: .south
        ),
        ILTempleFinderUseCaseTests.makeTemple(
            id: "mc", name: "Chùa Một Cột", address: "Ba Đình, Hà Nội", region: .north
        )
    ]

    var result: Result<[ILTempleSummaryEntity], Error> = .success(defaultTemples)
    var myTemple: (id: String, name: String)?
    private(set) var selected: ILTempleSummaryEntity?
    private(set) var loadCount = 0

    func loadTemples() async throws -> [ILTempleSummaryEntity] {
        loadCount += 1
        return try result.get()
    }

    func loadMyTemple() async -> (id: String, name: String)? { myTemple }
    func selectMyTemple(_ temple: ILTempleSummaryEntity) { selected = temple }
}
