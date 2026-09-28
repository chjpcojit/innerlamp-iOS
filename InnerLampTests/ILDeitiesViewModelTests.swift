//
//  ILDeitiesViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILDeitiesViewModelTests: XCTestCase {

    private var mockUseCase: MockILDeitiesUseCase!
    private var sut: ILDeitiesViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var filterSelectedSubject: PassthroughSubject<ILDeityKind?, Never>!
    private var deityTappedSubject: PassthroughSubject<String, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILDeitiesUseCase()
        sut = ILDeitiesViewModel(useCase: mockUseCase)
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
        filterSelectedSubject = PassthroughSubject<ILDeityKind?, Never>()
        deityTappedSubject = PassthroughSubject<String, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        backTappedSubject = nil
        filterSelectedSubject = nil
        deityTappedSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILDeitiesViewModel.Input {
        ILDeitiesViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            filterSelected: filterSelectedSubject.eraseToAnyPublisher(),
            deityTapped: deityTappedSubject.eraseToAnyPublisher()
        )
    }

    private func observeLatestState() -> () -> ILDeitiesStateModel? {
        let output = sut.transform(input: makeInput())
        var latest: ILDeitiesStateModel?
        output.state
            .sink { state in
                if case .success(let model) = state { latest = model }
            }
            .store(in: &cancellables)
        return { latest }
    }

    func test_viewDidLoad_showsAllDeitiesWithAllFilterSelected() {
        let latest = observeLatestState()

        viewDidLoadSubject.send(())

        XCTAssertTrue(mockUseCase.getInitialStateCalled)
        let state = latest()
        XCTAssertEqual(state?.items.count, 3)
        // Chip lọc: "Tất cả" + "Chư Phật" + "Bồ Tát".
        XCTAssertEqual(state?.filters.count, 3)
        XCTAssertEqual(state?.filters.first?.isSelected, true)
        XCTAssertEqual(state?.filters.first?.kind, nil)
        XCTAssertEqual(
            state?.subtitle,
            String(format: "deities.header.subtitleFormat".localized, 3)
        )
    }

    func test_viewDidLoad_mapsDeityFieldsAndMemorialDay() {
        let latest = observeLatestState()

        viewDidLoadSubject.send(())

        let first = latest()?.items.first
        XCTAssertEqual(first?.id, "buddha-1")
        XCTAssertEqual(first?.name, "buddha-1")
        XCTAssertEqual(first?.role, "virtue-buddha-1")
        XCTAssertEqual(first?.kindLabel, "deity.kind.buddha".localized)
        XCTAssertEqual(
            first?.memorialText,
            String(format: "deities.memorialFormat".localized, 15, 4)
        )
    }

    func test_filterSelected_buddha_filtersItemsAndMovesSelection() {
        let latest = observeLatestState()
        viewDidLoadSubject.send(())

        filterSelectedSubject.send(.buddha)

        let state = latest()
        XCTAssertEqual(state?.items.count, 1)
        XCTAssertEqual(state?.items.first?.kind, .buddha)
        XCTAssertEqual(state?.filters.first { $0.isSelected }?.kind, .buddha)
    }

    func test_filterSelected_bodhisattva_filtersItemsAndMovesSelection() {
        let latest = observeLatestState()
        viewDidLoadSubject.send(())

        filterSelectedSubject.send(.bodhisattva)

        let state = latest()
        XCTAssertEqual(state?.items.count, 2)
        XCTAssertEqual(state?.items.allSatisfy { $0.kind == .bodhisattva }, true)
        XCTAssertEqual(state?.filters.first { $0.isSelected }?.kind, .bodhisattva)
    }

    func test_filterSelected_nil_resetsToAllDeities() {
        let latest = observeLatestState()
        viewDidLoadSubject.send(())
        filterSelectedSubject.send(.buddha)

        filterSelectedSubject.send(nil)

        let state = latest()
        XCTAssertEqual(state?.items.count, 3)
        XCTAssertEqual(state?.filters.first?.isSelected, true)
    }

    func test_filterSelected_sameKind_isIgnored() {
        let latest = observeLatestState()
        viewDidLoadSubject.send(())
        filterSelectedSubject.send(.buddha)
        _ = latest()

        let requestCount = mockUseCase.requestedKinds.count
        filterSelectedSubject.send(.buddha)

        // Chạm lại chip đang chọn không lọc lại.
        XCTAssertEqual(mockUseCase.requestedKinds.count, requestCount)
    }

    func test_backTapped_firesBackNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILDeitiesNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        backTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .back)
    }

    func test_deityTapped_firesOpenDeityEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILDeitiesNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        deityTappedSubject.send("bodhisattva-2")

        XCTAssertEqual(receivedEvent, .openDeity(id: "bodhisattva-2"))
    }
}

// MARK: - UseCase tests

final class ILDeitiesUseCaseTests: XCTestCase {

    private let sut = ILDeitiesUseCaseImpl(deityUseCase: ILDeityUseCaseImpl())

    func test_getInitialState_returnsFullCatalog() {
        XCTAssertEqual(sut.getInitialState().deities.count, 18)
    }

    func test_deities_nilKind_returnsWholeCatalog() {
        let entity = sut.getInitialState()
        XCTAssertEqual(sut.deities(in: entity, kind: nil).count, 18)
    }

    func test_deities_filtersByKind() {
        let entity = sut.getInitialState()
        XCTAssertEqual(sut.deities(in: entity, kind: .buddha).count, 6)
        XCTAssertEqual(sut.deities(in: entity, kind: .bodhisattva).count, 12)
    }
}

// MARK: - Mock ILDeitiesUseCase
/// Catalog cố định 3 vị (1 Phật + 2 Bồ Tát) — đủ để test lọc theo loại mà không cần dựng cả 18 vị.
final class MockILDeitiesUseCase: ILDeitiesUseCase {
    var getInitialStateCalled = false
    var requestedKinds: [ILDeityKind?] = []

    static func makeDeity(id: String, kind: ILDeityKind) -> ILDeityEntity {
        ILDeityEntity(
            id: id,
            kind: kind,
            nameVi: id,
            nameSanskrit: "",
            nameChinese: "",
            titleHonorific: "",
            canonicalSource: "",
            coreVirtue: "virtue-\(id)",
            pureLand: "",
            memorialDays: [
                ILDeityMemorialDayEntity(lunarDay: 15, lunarMonth: 4, eventName: "Ngày Vía")
            ],
            iconography: ILDeityIconographyEntity(
                posture: "",
                mountOrThrone: "",
                sacredArtifacts: [],
                symbolicMeaning: ""
            ),
            biographySummary: "",
            greatVows: [],
            mantra: ILDeityMantraEntity(
                shortSanskrit: "",
                shortSinoVietnamese: "",
                dharaniName: "",
                dharaniSnippet: ""
            )
        )
    }

    func getInitialState() -> ILDeitiesEntity {
        getInitialStateCalled = true
        return ILDeitiesEntity(deities: [
            Self.makeDeity(id: "buddha-1", kind: .buddha),
            Self.makeDeity(id: "bodhisattva-1", kind: .bodhisattva),
            Self.makeDeity(id: "bodhisattva-2", kind: .bodhisattva)
        ])
    }

    func deities(in entity: ILDeitiesEntity, kind: ILDeityKind?) -> [ILDeityEntity] {
        requestedKinds.append(kind)
        guard let kind else { return entity.deities }
        return entity.deities.filter { $0.kind == kind }
    }
}
