//
//  ILLampGardenViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILLampGardenViewModelTests: XCTestCase {

    private typealias Factory = ILLightLampTestFactory

    private var mockUseCase: MockILLightLampUseCase!
    private var sut: ILLampGardenViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var lightTappedSubject: PassthroughSubject<Void, Never>!
    private var filterSelectedSubject: PassthroughSubject<ILLampKind?, Never>!
    private var loadMoreTappedSubject: PassthroughSubject<Void, Never>!

    private var latestModel: ILLampGardenStateModel?
    private var failureCount = 0
    private var modelObserver: ((ILLampGardenStateModel) -> Void)?

    override func setUp() {
        super.setUp()
        mockUseCase = MockILLightLampUseCase()
        sut = ILLampGardenViewModel(useCase: mockUseCase, now: { Factory.date(2026, 10, 11) })
        cancellables = []
        viewDidLoadSubject = PassthroughSubject()
        backTappedSubject = PassthroughSubject()
        lightTappedSubject = PassthroughSubject()
        filterSelectedSubject = PassthroughSubject()
        loadMoreTappedSubject = PassthroughSubject()
        latestModel = nil
        failureCount = 0

        let output = sut.transform(input: .init(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            lightTapped: lightTappedSubject.eraseToAnyPublisher(),
            filterSelected: filterSelectedSubject.eraseToAnyPublisher(),
            loadMoreTapped: loadMoreTappedSubject.eraseToAnyPublisher()
        ))
        output.state
            .sink { [weak self] state in
                switch state {
                case .success(let model):
                    self?.latestModel = model
                    self?.modelObserver?(model)
                case .failure: self?.failureCount += 1
                case .idle, .loading: break
                }
            }
            .store(in: &cancellables)
    }

    override func tearDown() {
        cancellables = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    /// Loads `lamps` through `viewDidLoad` and waits for the first model that carries them.
    private func load(_ lamps: [ILLampEntity]) {
        mockUseCase.activeLamps = lamps
        let expectation = expectation(description: "loaded")
        let initialSubtitle = latestModel?.subtitle
        modelObserver = { [weak self] model in
            guard model.subtitle != initialSubtitle else { return }
            expectation.fulfill()
            self?.modelObserver = nil
        }
        viewDidLoadSubject.send(())
        wait(for: [expectation], timeout: 1)
        modelObserver = nil
    }

    private func lamps(count: Int, kind: ILLampKind = .oil, idPrefix: String = "l") -> [ILLampEntity] {
        (0..<count).map {
            Factory.lamp(id: "\(idPrefix)\($0)", kind: kind, litAt: Factory.date(2026, 10, 11))
        }
    }

    // MARK: - Content

    func test_load_showsSubtitleChipsAndCards() {
        load([
            Factory.lamp(id: "a", kind: .oil, intention: .peace, target: "Mẹ Hoa", durationDays: 7, litAt: Factory.date(2026, 10, 9)),
            Factory.lamp(id: "b", kind: .lotus, litAt: Factory.date(2026, 10, 11))
        ])

        XCTAssertEqual(latestModel?.subtitle, String(format: "lightLamp.garden.subtitle.format".localized, 2))
        XCTAssertEqual(latestModel?.chips.map(\.count), ["2", "1", "1", "0"])
        XCTAssertEqual(latestModel?.cards.count, 2)
        XCTAssertEqual(
            latestModel?.cards.first(where: { $0.id == "a" })?.target,
            String(format: "lightLamp.garden.card.target.format".localized, "mẹ Hoa")
        )
        XCTAssertEqual(
            latestModel?.cards.first(where: { $0.id == "a" })?.remaining,
            String(format: "lightLamp.garden.card.left.format".localized, 5)
        )
        XCTAssertEqual(
            latestModel?.cards.first(where: { $0.id == "b" })?.target,
            "lightLamp.garden.card.target.all".localized
        )
    }

    func test_cardOnLastDay_showsLastDayLabel() {
        load([Factory.lamp(id: "a", durationDays: 1, litAt: Factory.date(2026, 10, 11))])

        XCTAssertEqual(latestModel?.cards.first?.remaining, "lightLamp.garden.card.left.lastDay".localized)
    }

    // MARK: - Filter

    func test_filterSelected_showsOnlyThatKind() {
        load(lamps(count: 3, kind: .oil, idPrefix: "o") + lamps(count: 2, kind: .lotus, idPrefix: "t"))

        filterSelectedSubject.send(.lotus)

        XCTAssertEqual(latestModel?.cards.count, 2)
        XCTAssertTrue(latestModel?.cards.allSatisfy { $0.kind == .lotus } ?? false)
        XCTAssertEqual(latestModel?.chips.first(where: \.isSelected)?.kind, .lotus)
    }

    func test_filterNoMatch_isEmpty() {
        load(lamps(count: 2, kind: .oil))

        filterSelectedSubject.send(.float)

        XCTAssertEqual(latestModel?.isEmpty, true)
    }

    // MARK: - Paging

    func test_load_moreThanOnePage_showsFirstPageAndMoreButton() {
        load(lamps(count: 30))

        XCTAssertEqual(latestModel?.cards.count, 12)
        XCTAssertEqual(latestModel?.hasMore, true)
    }

    func test_loadMoreTapped_appendsNextPage() {
        load(lamps(count: 30))

        loadMoreTappedSubject.send(())

        XCTAssertEqual(latestModel?.cards.count, 24)
        XCTAssertEqual(latestModel?.hasMore, true)
    }

    func test_filterChange_resetsPaging() {
        load(lamps(count: 20, kind: .oil, idPrefix: "o") + lamps(count: 20, kind: .lotus, idPrefix: "t"))
        loadMoreTappedSubject.send(())
        XCTAssertEqual(latestModel?.cards.count, 24)

        filterSelectedSubject.send(.lotus)

        XCTAssertEqual(latestModel?.cards.count, 12)
    }

    // MARK: - Navigation

    func test_lightTapped_firesOpenLighting() {
        var event: ILLampGardenNavEvent?
        sut.navigationEventPublisher.sink { event = $0 }.store(in: &cancellables)

        lightTappedSubject.send(())

        XCTAssertEqual(event, .openLighting)
    }

    func test_backTapped_firesBack() {
        var event: ILLampGardenNavEvent?
        sut.navigationEventPublisher.sink { event = $0 }.store(in: &cancellables)

        backTappedSubject.send(())

        XCTAssertEqual(event, .back)
    }
}
