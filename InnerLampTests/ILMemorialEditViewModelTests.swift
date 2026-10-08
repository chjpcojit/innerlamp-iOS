//
//  ILMemorialEditViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILMemorialEditViewModelTests: XCTestCase {

    private typealias Factory = ILMemorialTestFactory

    private var mockUseCase: MockILMemorialUseCase!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var saveTappedSubject: PassthroughSubject<Void, Never>!
    private var deleteTappedSubject: PassthroughSubject<Void, Never>!
    private var nameChangedSubject: PassthroughSubject<String, Never>!
    private var relationshipSelectedSubject: PassthroughSubject<ILMemorialRelationship, Never>!
    private var calendarSelectedSubject: PassthroughSubject<ILMemorialCalendarKind, Never>!
    private var daySelectedSubject: PassthroughSubject<Int, Never>!
    private var monthSelectedSubject: PassthroughSubject<Int, Never>!
    private var yearSelectedSubject: PassthroughSubject<Int, Never>!
    private var noteChangedSubject: PassthroughSubject<String, Never>!
    private var reminderToggledSubject: PassthroughSubject<Bool, Never>!
    private var leadSelectedSubject: PassthroughSubject<Int, Never>!
    private var timeSelectedSubject: PassthroughSubject<Int, Never>!
    private var syncToggledSubject: PassthroughSubject<Bool, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILMemorialUseCase()
        cancellables = []
        viewDidLoadSubject = .init()
        backTappedSubject = .init()
        saveTappedSubject = .init()
        deleteTappedSubject = .init()
        nameChangedSubject = .init()
        relationshipSelectedSubject = .init()
        calendarSelectedSubject = .init()
        daySelectedSubject = .init()
        monthSelectedSubject = .init()
        yearSelectedSubject = .init()
        noteChangedSubject = .init()
        reminderToggledSubject = .init()
        leadSelectedSubject = .init()
        timeSelectedSubject = .init()
        syncToggledSubject = .init()
    }

    override func tearDown() {
        cancellables = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeSUT(entry: ILMemorialEntity?) -> ILMemorialEditViewModel {
        ILMemorialEditViewModel(useCase: mockUseCase, entry: entry, now: { Factory.date(2026, 10, 3) })
    }

    private func makeInput() -> ILMemorialEditViewModel.Input {
        ILMemorialEditViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            saveTapped: saveTappedSubject.eraseToAnyPublisher(),
            deleteTapped: deleteTappedSubject.eraseToAnyPublisher(),
            nameChanged: nameChangedSubject.eraseToAnyPublisher(),
            relationshipSelected: relationshipSelectedSubject.eraseToAnyPublisher(),
            calendarSelected: calendarSelectedSubject.eraseToAnyPublisher(),
            daySelected: daySelectedSubject.eraseToAnyPublisher(),
            monthSelected: monthSelectedSubject.eraseToAnyPublisher(),
            yearSelected: yearSelectedSubject.eraseToAnyPublisher(),
            noteChanged: noteChangedSubject.eraseToAnyPublisher(),
            reminderToggled: reminderToggledSubject.eraseToAnyPublisher(),
            leadSelected: leadSelectedSubject.eraseToAnyPublisher(),
            timeSelected: timeSelectedSubject.eraseToAnyPublisher(),
            syncToggled: syncToggledSubject.eraseToAnyPublisher()
        )
    }

    /// Subscribes and returns a box that always holds the latest successful state.
    private func observe(_ sut: ILMemorialEditViewModel) -> StateBox {
        let box = StateBox()
        sut.transform(input: makeInput()).state
            .sink { state in
                switch state {
                case .success(let model): box.latest = model
                case .failure: box.failureCount += 1
                default: break
                }
            }
            .store(in: &cancellables)
        return box
    }

    private final class StateBox {
        var latest = ILMemorialEditStateModel.initial
        var failureCount = 0
    }

    private func settle() {
        let settled = expectation(description: "async work settles")
        DispatchQueue.main.async { settled.fulfill() }
        wait(for: [settled], timeout: 1)
    }

    private func waitForEvent(_ sut: ILMemorialEditViewModel, trigger: () -> Void) -> ILMemorialEditNavEvent? {
        let expectation = expectation(description: "nav event")
        var received: ILMemorialEditNavEvent?
        sut.navigationEventPublisher
            .sink { event in
                received = event
                expectation.fulfill()
            }
            .store(in: &cancellables)
        trigger()
        wait(for: [expectation], timeout: 1)
        return received
    }

    // MARK: - Initial state

    func test_addMode_hasDefaults() {
        let sut = makeSUT(entry: nil)
        let box = observe(sut)
        viewDidLoadSubject.send(())

        let state = box.latest
        XCTAssertEqual(state.title, "memorial.edit.titleNew".localized)
        XCTAssertEqual(state.saveTitle, "memorial.edit.saveNew".localized)
        XCTAssertFalse(state.canDelete)
        XCTAssertEqual(state.calendarKind, .lunar)
        XCTAssertEqual(state.selectedDay, 1)
        XCTAssertEqual(state.selectedMonth, 1)
        XCTAssertEqual(state.selectedYear, 0)
        XCTAssertTrue(state.reminderOn)
        XCTAssertTrue(state.syncOn)
        XCTAssertEqual(state.relationships.first(where: \.isSelected)?.id, 0, "Ông nội is selected by default")
        XCTAssertEqual(state.leadOptions.first(where: \.isSelected)?.id, 1)
        XCTAssertEqual(state.timeOptions.first(where: \.isSelected)?.id, 7)
        XCTAssertNil(state.nameError)
    }

    func test_editMode_prefillsEntry_andOffersDelete() {
        let entry = Factory.entry(
            name: "Trần Thị Bình", relationship: .mother, calendarKind: .solar, day: 5, month: 3,
            deathYear: 2020, note: "Ghi chú", reminder: nil, syncToReminders: false
        )
        let box = observe(makeSUT(entry: entry))
        viewDidLoadSubject.send(())

        let state = box.latest
        XCTAssertEqual(state.title, "memorial.edit.titleEdit".localized)
        XCTAssertEqual(state.saveTitle, "memorial.edit.saveEdit".localized)
        XCTAssertTrue(state.canDelete)
        XCTAssertEqual(state.name, "Trần Thị Bình")
        XCTAssertEqual(state.note, "Ghi chú")
        XCTAssertEqual(state.calendarKind, .solar)
        XCTAssertEqual(state.selectedDay, 5)
        XCTAssertEqual(state.selectedMonth, 3)
        XCTAssertEqual(state.selectedYear, 2020)
        XCTAssertFalse(state.reminderOn)
        XCTAssertFalse(state.syncOn)
        XCTAssertEqual(state.relationships.first(where: \.isSelected)?.id, ILMemorialRelationship.allCases.firstIndex(of: .mother))
    }

    // MARK: - Option lists

    func test_lunarOptions_dayLabels_andThirtyDays() {
        let box = observe(makeSUT(entry: nil))
        viewDidLoadSubject.send(())

        XCTAssertEqual(box.latest.dayOptions.count, 30)
        XCTAssertEqual(box.latest.dayOptions.first?.title, String(format: "memorial.edit.day.lunarFormat".localized, 1))
        XCTAssertEqual(box.latest.dayOptions[10].title, "11")
        XCTAssertEqual(box.latest.monthOptions.first?.title, String(format: "lunarCalendar.month.label".localized, "lunarCalendar.month.1".localized))
    }

    func test_solarOptions_thirtyOneDays_andNumericMonths() {
        let box = observe(makeSUT(entry: nil))
        viewDidLoadSubject.send(())

        calendarSelectedSubject.send(.solar)

        XCTAssertEqual(box.latest.dayOptions.count, 31)
        XCTAssertEqual(box.latest.dayOptions.first?.title, "1")
        XCTAssertEqual(box.latest.monthOptions.first?.title, String(format: "memorial.edit.month.solarFormat".localized, 1))
    }

    func test_yearOptions_unknownThenCurrentYearBackNinetySixYears() {
        let box = observe(makeSUT(entry: nil))
        viewDidLoadSubject.send(())

        let years = box.latest.yearOptions
        XCTAssertEqual(years.first?.id, 0)
        XCTAssertEqual(years.first?.title, "memorial.edit.year.unknown".localized)
        XCTAssertEqual(years.count, 1 + 97)
        XCTAssertEqual(years[1].id, 2026)
        XCTAssertEqual(years.last?.id, 2026 - 96)
    }

    // MARK: - Editing

    func test_switchingCalendar_clampsDayToNewMaximum() {
        let box = observe(makeSUT(entry: Factory.entry(calendarKind: .solar, day: 31, month: 1)))
        viewDidLoadSubject.send(())

        calendarSelectedSubject.send(.lunar)

        XCTAssertEqual(box.latest.calendarKind, .lunar)
        XCTAssertEqual(box.latest.selectedDay, 30)
    }

    func test_selectingRelationship_dayMonthYear_updatesState() {
        let box = observe(makeSUT(entry: nil))
        viewDidLoad()

        relationshipSelectedSubject.send(.mother)
        daySelectedSubject.send(15)
        monthSelectedSubject.send(8)
        yearSelectedSubject.send(2021)

        XCTAssertEqual(box.latest.relationships.first(where: \.isSelected)?.id, ILMemorialRelationship.allCases.firstIndex(of: .mother))
        XCTAssertEqual(box.latest.selectedDay, 15)
        XCTAssertEqual(box.latest.selectedMonth, 8)
        XCTAssertEqual(box.latest.selectedYear, 2021)
    }

    func test_selectingUnknownYear_clearsDeathYear() {
        let box = observe(makeSUT(entry: Factory.entry(deathYear: 2020)))
        viewDidLoad()

        yearSelectedSubject.send(0)

        XCTAssertEqual(box.latest.selectedYear, 0)
    }

    func test_preview_isFilledFromNextAnniversary() {
        mockUseCase.nextAnniversaryResult = Factory.next(daysUntil: 43, ordinal: 2)
        let box = observe(makeSUT(entry: Factory.entry(calendarKind: .solar)))
        viewDidLoad()

        XCTAssertEqual(
            box.latest.previewNext,
            String(format: "memorial.preview.next".localized, ILMemorialFormatter.solarLine(Factory.date(2026, 11, 15)), String(format: "memorial.days.format".localized, 43))
        )
        XCTAssertEqual(
            box.latest.previewDetail,
            String(format: "memorial.preview.solarFormat".localized, 6, "lunarCalendar.month.10".localized, " · " + "memorial.ordinal.second".localized)
        )
    }

    func test_preview_lunarEntry_usesLunarFormat() {
        mockUseCase.nextAnniversaryResult = Factory.next(daysUntil: 5, ordinal: nil)
        let box = observe(makeSUT(entry: Factory.entry(calendarKind: .lunar, day: 15, month: 12)))
        viewDidLoad()

        XCTAssertEqual(
            box.latest.previewDetail,
            String(format: "memorial.preview.lunarFormat".localized, 15, "lunarCalendar.month.12".localized, "")
        )
    }

    // MARK: - Reminder

    func test_reminderOff_clearsReminder_andHidesOptions() {
        let box = observe(makeSUT(entry: nil))
        viewDidLoad()

        reminderToggledSubject.send(false)

        XCTAssertFalse(box.latest.reminderOn)
        XCTAssertNil(box.latest.leadOptions.first(where: \.isSelected))
    }

    func test_reminderOn_afterOff_restoresDefaults() {
        let box = observe(makeSUT(entry: Factory.entry(reminder: nil)))
        viewDidLoad()

        reminderToggledSubject.send(true)

        XCTAssertTrue(box.latest.reminderOn)
        XCTAssertEqual(box.latest.leadOptions.first(where: \.isSelected)?.id, 1)
        XCTAssertEqual(box.latest.timeOptions.first(where: \.isSelected)?.id, 7)
    }

    func test_selectingLeadAndTime_updatesReminder() {
        let box = observe(makeSUT(entry: nil))
        viewDidLoad()

        leadSelectedSubject.send(7)
        timeSelectedSubject.send(19)

        XCTAssertEqual(box.latest.leadOptions.first(where: \.isSelected)?.id, 7)
        XCTAssertEqual(box.latest.timeOptions.first(where: \.isSelected)?.id, 19)
    }

    func test_syncToggle_updatesState() {
        let box = observe(makeSUT(entry: nil))
        viewDidLoad()

        syncToggledSubject.send(false)

        XCTAssertFalse(box.latest.syncOn)
    }

    // MARK: - Save

    func test_save_withEmptyName_showsError_andDoesNotSave() {
        let sut = makeSUT(entry: nil)
        let box = observe(sut)
        var events: [ILMemorialEditNavEvent] = []
        sut.navigationEventPublisher.sink { events.append($0) }.store(in: &cancellables)
        viewDidLoad()

        saveTappedSubject.send(())
        settle()

        XCTAssertEqual(box.latest.nameError, "memorial.edit.nameError".localized)
        XCTAssertTrue(mockUseCase.savedEntries.isEmpty)
        XCTAssertTrue(events.isEmpty)
    }

    func test_save_withWhitespaceOnlyName_isRejected() {
        let sut = makeSUT(entry: nil)
        let box = observe(sut)
        viewDidLoad()
        nameChangedSubject.send("   ")

        saveTappedSubject.send(())
        settle()

        XCTAssertNotNil(box.latest.nameError)
        XCTAssertTrue(mockUseCase.savedEntries.isEmpty)
    }

    func test_typingAfterError_clearsError() {
        let sut = makeSUT(entry: nil)
        let box = observe(sut)
        viewDidLoad()
        saveTappedSubject.send(())
        XCTAssertNotNil(box.latest.nameError)

        nameChangedSubject.send("A")

        XCTAssertNil(box.latest.nameError)
    }

    func test_save_withValidName_savesEntry_andFiresSavedWithReminderMessage() {
        let sut = makeSUT(entry: nil)
        _ = observe(sut)
        viewDidLoad()
        nameChangedSubject.send("Nguyễn Văn An")
        noteChangedSubject.send("Mâm chay")
        relationshipSelectedSubject.send(.father)

        let event = waitForEvent(sut) { saveTappedSubject.send(()) }

        let relationship = "memorial.relationship.father".localized.lowercased()
        XCTAssertEqual(event, .saved(message: String(format: "memorial.message.savedWithReminder".localized, relationship)))
        XCTAssertEqual(mockUseCase.savedEntries.count, 1)
        XCTAssertEqual(mockUseCase.savedEntries.first?.name, "Nguyễn Văn An")
        XCTAssertEqual(mockUseCase.savedEntries.first?.note, "Mâm chay")
        XCTAssertEqual(mockUseCase.savedEntries.first?.relationship, .father)
    }

    func test_save_withReminderOff_firesPlainSavedMessage() {
        let sut = makeSUT(entry: nil)
        _ = observe(sut)
        viewDidLoad()
        nameChangedSubject.send("An")
        reminderToggledSubject.send(false)

        let event = waitForEvent(sut) { saveTappedSubject.send(()) }

        XCTAssertEqual(event, .saved(message: "memorial.message.saved".localized))
        XCTAssertNil(mockUseCase.savedEntries.first?.reminder)
    }

    func test_save_withSyncOff_firesPlainSavedMessage() {
        let sut = makeSUT(entry: nil)
        _ = observe(sut)
        viewDidLoad()
        nameChangedSubject.send("An")
        syncToggledSubject.send(false)

        let event = waitForEvent(sut) { saveTappedSubject.send(()) }

        XCTAssertEqual(event, .saved(message: "memorial.message.saved".localized))
    }

    func test_save_failure_emitsFailure_andLeavesFormUsable() {
        mockUseCase.saveError = MemorialTestError()
        let sut = makeSUT(entry: nil)
        let box = observe(sut)
        var events: [ILMemorialEditNavEvent] = []
        sut.navigationEventPublisher.sink { events.append($0) }.store(in: &cancellables)
        viewDidLoad()
        nameChangedSubject.send("An")

        saveTappedSubject.send(())
        settle()

        XCTAssertEqual(box.failureCount, 1)
        XCTAssertFalse(box.latest.isSaving, "The form must be tappable again after a failed save")
        XCTAssertTrue(events.isEmpty)
    }

    // MARK: - Delete

    func test_delete_inEditMode_deletesEntry_andFiresDeletedMessageWithName() {
        let entry = Factory.entry(id: "x", name: "Trần Thị Bình")
        let sut = makeSUT(entry: entry)
        _ = observe(sut)
        viewDidLoad()

        let event = waitForEvent(sut) { deleteTappedSubject.send(()) }

        XCTAssertEqual(mockUseCase.deletedIDs, ["x"])
        XCTAssertEqual(event, .deleted(message: String(format: "memorial.message.deleted".localized, "Trần Thị Bình")))
    }

    func test_delete_withBlankName_usesFallbackName() {
        let sut = makeSUT(entry: Factory.entry(id: "x", name: "  "))
        _ = observe(sut)
        viewDidLoad()

        let event = waitForEvent(sut) { deleteTappedSubject.send(()) }

        XCTAssertEqual(event, .deleted(message: String(format: "memorial.message.deleted".localized, "memorial.message.deletedFallbackName".localized)))
    }

    func test_delete_inAddMode_doesNothing() {
        let sut = makeSUT(entry: nil)
        _ = observe(sut)
        var events: [ILMemorialEditNavEvent] = []
        sut.navigationEventPublisher.sink { events.append($0) }.store(in: &cancellables)
        viewDidLoad()

        deleteTappedSubject.send(())
        settle()

        XCTAssertTrue(mockUseCase.deletedIDs.isEmpty)
        XCTAssertTrue(events.isEmpty)
    }

    func test_delete_failure_emitsFailure() {
        mockUseCase.deleteError = MemorialTestError()
        let sut = makeSUT(entry: Factory.entry(id: "x"))
        let box = observe(sut)
        viewDidLoad()

        deleteTappedSubject.send(())
        settle()

        XCTAssertEqual(box.failureCount, 1)
        XCTAssertFalse(box.latest.isSaving)
    }

    // MARK: - Navigation

    func test_backTapped_firesBack_withoutSaving() {
        let sut = makeSUT(entry: nil)
        _ = observe(sut)
        viewDidLoad()

        let event = waitForEvent(sut) { backTappedSubject.send(()) }

        XCTAssertEqual(event, .back)
        XCTAssertTrue(mockUseCase.savedEntries.isEmpty)
    }

    // MARK: - Helpers
    private func viewDidLoad() {
        viewDidLoadSubject.send(())
    }
}
