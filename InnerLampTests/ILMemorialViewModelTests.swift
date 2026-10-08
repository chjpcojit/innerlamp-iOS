//
//  ILMemorialViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILMemorialViewModelTests: XCTestCase {

    private typealias Factory = ILMemorialTestFactory

    private var mockUseCase: MockILMemorialUseCase!
    private var sut: ILMemorialViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var addTappedSubject: PassthroughSubject<Void, Never>!
    private var itemTappedSubject: PassthroughSubject<String, Never>!
    private var familyTreeTappedSubject: PassthroughSubject<Void, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILMemorialUseCase()
        sut = ILMemorialViewModel(useCase: mockUseCase, now: { Factory.date(2026, 10, 3) })
        cancellables = []
        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
        addTappedSubject = PassthroughSubject<Void, Never>()
        itemTappedSubject = PassthroughSubject<String, Never>()
        familyTreeTappedSubject = PassthroughSubject<Void, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        backTappedSubject = nil
        addTappedSubject = nil
        itemTappedSubject = nil
        familyTreeTappedSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILMemorialViewModel.Input {
        ILMemorialViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            addTapped: addTappedSubject.eraseToAnyPublisher(),
            itemTapped: itemTappedSubject.eraseToAnyPublisher(),
            familyTreeTapped: familyTreeTappedSubject.eraseToAnyPublisher()
        )
    }

    /// Sends `viewDidLoad` and waits for the first state satisfying `predicate`.
    private func loadAndWait(
        for predicate: @escaping (ILMemorialStateModel) -> Bool,
        file: StaticString = #filePath, line: UInt = #line
    ) -> ILMemorialStateModel? {
        let output = sut.transform(input: makeInput())
        let expectation = expectation(description: "state matching predicate")
        var matched: ILMemorialStateModel?
        output.state
            .sink { state in
                if case .success(let model) = state, matched == nil, predicate(model) {
                    matched = model
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        wait(for: [expectation], timeout: 1)
        return matched
    }

    // MARK: - Initial state

    func test_initialState_isBlank_withoutEmptyStateFlash() {
        let output = sut.transform(input: makeInput())
        var first: ILMemorialStateModel?
        output.state
            .prefix(1)
            .sink { state in
                if case .success(let model) = state { first = model }
            }
            .store(in: &cancellables)

        XCTAssertEqual(first, .initial)
        XCTAssertEqual(first?.isEmpty, false, "No empty state before the first load answers")
    }

    // MARK: - Load

    func test_viewDidLoad_withEntries_showsSubtitleHighlightAndRows() {
        mockUseCase.loadItemsResult = .success([
            Factory.item(id: "a", name: "Nguyễn Văn An", daysUntil: 2),
            Factory.item(id: "b", name: "Trần Thị Bình", daysUntil: 43)
        ])

        let model = loadAndWait { !$0.rows.isEmpty }

        XCTAssertEqual(model?.subtitle, String(format: "memorial.subtitle.format".localized, 2))
        XCTAssertEqual(model?.isEmpty, false)
        XCTAssertEqual(model?.highlight?.id, "a")
        XCTAssertEqual(model?.highlight?.name, "Nguyễn Văn An")
        XCTAssertEqual(model?.rows.map(\.id), ["a", "b"])
    }

    func test_viewDidLoad_withNoEntries_showsEmptyState() {
        mockUseCase.loadItemsResult = .success([])

        let model = loadAndWait { $0.isEmpty }

        XCTAssertEqual(model?.subtitle, "memorial.subtitle.empty".localized)
        XCTAssertNil(model?.highlight)
        XCTAssertTrue(model?.rows.isEmpty == true)
    }

    func test_viewDidLoad_failure_emitsEmptyState() {
        mockUseCase.loadItemsResult = .failure(MemorialTestError())
        let output = sut.transform(input: makeInput())
        let expectation = expectation(description: "empty state")
        output.state
            .sink { state in
                if case .success(let model) = state, model.isEmpty { expectation.fulfill() }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        wait(for: [expectation], timeout: 1)
    }

    // MARK: - Highlight + rows formatting

    func test_highlight_eyebrow_forToday_tomorrow_andLater() {
        XCTAssertEqual(ILMemorialFormatter.eyebrow(days: 0), "memorial.eyebrow.today".localized)
        XCTAssertEqual(ILMemorialFormatter.eyebrow(days: 1), "memorial.eyebrow.tomorrow".localized)
        XCTAssertEqual(ILMemorialFormatter.eyebrow(days: 12), String(format: "memorial.eyebrow.format".localized, 12))
    }

    func test_highlight_relationLine_includesOrdinal_whenPresent() {
        mockUseCase.loadItemsResult = .success([Factory.item(daysUntil: 5, ordinal: 1)])

        let model = loadAndWait { $0.highlight != nil }

        XCTAssertEqual(
            model?.highlight?.relationLine,
            "memorial.relationship.paternalGrandfather".localized + " · " + "memorial.ordinal.first".localized
        )
    }

    func test_highlight_relationLine_withoutOrdinal_isJustTheRelationship() {
        mockUseCase.loadItemsResult = .success([Factory.item(daysUntil: 5, ordinal: nil)])

        let model = loadAndWait { $0.highlight != nil }

        XCTAssertEqual(model?.highlight?.relationLine, "memorial.relationship.paternalGrandfather".localized)
    }

    func test_highlight_lines_comeFromTheEntryAndNextDate() {
        mockUseCase.loadItemsResult = .success([Factory.item(daysUntil: 5)])

        let model = loadAndWait { $0.highlight != nil }

        XCTAssertEqual(model?.highlight?.dateLine, String(format: "memorial.date.solarFormat".localized, 15, 11))
        XCTAssertEqual(model?.highlight?.whenLine, ILMemorialFormatter.solarLine(Factory.date(2026, 11, 15)))
        XCTAssertEqual(
            model?.highlight?.remindLine,
            String(format: "memorial.reminder.lead.format".localized, 1) + " · 07:00 · " + "memorial.reminder.inReminders".localized
        )
    }

    func test_highlight_remindLine_whenReminderOff() {
        mockUseCase.loadItemsResult = .success([Factory.item(daysUntil: 5, reminder: nil)])

        let model = loadAndWait { $0.highlight != nil }

        XCTAssertEqual(model?.highlight?.remindLine, "memorial.reminder.off".localized)
    }

    func test_rows_daysLabel_isSoonFlag_andReminderTag() {
        mockUseCase.loadItemsResult = .success([
            Factory.item(id: "today", daysUntil: 0),
            Factory.item(id: "week", daysUntil: 7),
            Factory.item(id: "far", daysUntil: 8, reminder: nil)
        ])

        let model = loadAndWait { $0.rows.count == 3 }

        XCTAssertEqual(model?.rows[0].daysText, "memorial.days.today".localized)
        XCTAssertEqual(model?.rows[1].daysText, String(format: "memorial.days.format".localized, 7))
        XCTAssertEqual(model?.rows.map(\.isSoon), [true, true, false])
        XCTAssertEqual(model?.rows.map(\.reminderTag), ["memorial.reminder.tag".localized, "memorial.reminder.tag".localized, ""])
    }

    func test_ordinalText_coversFirstSecondAndNth() {
        XCTAssertEqual(ILMemorialFormatter.ordinalText(nil), "")
        XCTAssertEqual(ILMemorialFormatter.ordinalText(1), "memorial.ordinal.first".localized)
        XCTAssertEqual(ILMemorialFormatter.ordinalText(2), "memorial.ordinal.second".localized)
        XCTAssertEqual(ILMemorialFormatter.ordinalText(7), String(format: "memorial.ordinal.format".localized, 7))
    }

    func test_storedDateLine_lunarAndSolar() {
        let lunar = Factory.entry(calendarKind: .lunar, day: 15, month: 12)
        let solar = Factory.entry(calendarKind: .solar, day: 5, month: 3)

        XCTAssertEqual(
            ILMemorialFormatter.storedDateLine(lunar),
            String(format: "memorial.date.lunarFormat".localized, 15, "lunarCalendar.month.12".localized)
        )
        XCTAssertEqual(ILMemorialFormatter.storedDateLine(solar), String(format: "memorial.date.solarFormat".localized, 5, 3))
    }

    // MARK: - Navigation

    func test_backTapped_firesBack() {
        _ = sut.transform(input: makeInput())
        var event: ILMemorialNavEvent?
        sut.navigationEventPublisher.sink { event = $0 }.store(in: &cancellables)

        backTappedSubject.send(())

        XCTAssertEqual(event, .back)
    }

    func test_addTapped_firesAddEntry() {
        _ = sut.transform(input: makeInput())
        var event: ILMemorialNavEvent?
        sut.navigationEventPublisher.sink { event = $0 }.store(in: &cancellables)

        addTappedSubject.send(())

        XCTAssertEqual(event, .addEntry)
    }

    func test_familyTreeTapped_firesOpenFamilyTree() {
        _ = sut.transform(input: makeInput())
        var event: ILMemorialNavEvent?
        sut.navigationEventPublisher.sink { event = $0 }.store(in: &cancellables)

        familyTreeTappedSubject.send(())

        XCTAssertEqual(event, .openFamilyTree)
    }

    func test_itemTapped_afterLoad_firesEditEntryWithThatEntry() {
        let item = Factory.item(id: "b", name: "Trần Thị Bình", daysUntil: 9)
        mockUseCase.loadItemsResult = .success([Factory.item(id: "a", daysUntil: 2), item])
        _ = loadAndWait { $0.rows.count == 2 }
        var event: ILMemorialNavEvent?
        sut.navigationEventPublisher.sink { event = $0 }.store(in: &cancellables)

        itemTappedSubject.send("b")

        XCTAssertEqual(event, .editEntry(item.entry))
    }

    func test_itemTapped_unknownID_firesNothing() {
        mockUseCase.loadItemsResult = .success([Factory.item(id: "a", daysUntil: 2)])
        _ = loadAndWait { $0.rows.count == 1 }
        var events: [ILMemorialNavEvent] = []
        sut.navigationEventPublisher.sink { events.append($0) }.store(in: &cancellables)

        itemTappedSubject.send("ghost")

        XCTAssertTrue(events.isEmpty)
    }

    // MARK: - Return from the form

    func test_didFinishEditing_reloadsAndShowsBanner() {
        mockUseCase.loadItemsResult = .success([Factory.item(id: "a", daysUntil: 2)])
        _ = loadAndWait { $0.rows.count == 1 }
        let loadsBefore = mockUseCase.loadItemsCallCount

        let output = sut.transform(input: makeInput())
        let expectation = expectation(description: "banner shown")
        output.state
            .sink { state in
                if case .success(let model) = state, model.bannerText == "memorial.message.saved".localized {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.didFinishEditing(message: "memorial.message.saved".localized)

        wait(for: [expectation], timeout: 1)
        let reloaded = self.expectation(description: "reloaded")
        DispatchQueue.main.async { reloaded.fulfill() }
        wait(for: [reloaded], timeout: 1)
        XCTAssertGreaterThan(mockUseCase.loadItemsCallCount, loadsBefore)
    }
}
