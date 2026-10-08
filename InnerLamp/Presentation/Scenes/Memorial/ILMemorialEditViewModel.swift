//
//  ILMemorialEditViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILMemorialEditNavEvent: Equatable {
    case back
    /// Saved — close the form and tell the list to show `message`.
    case saved(message: String)
    /// Deleted — close the form and tell the list to show `message`.
    case deleted(message: String)
}

protocol ILMemorialEditViewModelProtocol: ViewModelType {
    var navigationEventPublisher: AnyPublisher<ILMemorialEditNavEvent, Never> { get }
}

final class ILMemorialEditViewModel: ILMemorialEditViewModelProtocol {

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        let saveTapped: AnyPublisher<Void, Never>
        let deleteTapped: AnyPublisher<Void, Never>
        let nameChanged: AnyPublisher<String, Never>
        let relationshipSelected: AnyPublisher<ILMemorialRelationship, Never>
        let calendarSelected: AnyPublisher<ILMemorialCalendarKind, Never>
        let daySelected: AnyPublisher<Int, Never>
        let monthSelected: AnyPublisher<Int, Never>
        /// `0` = unknown.
        let yearSelected: AnyPublisher<Int, Never>
        let noteChanged: AnyPublisher<String, Never>
        let reminderToggled: AnyPublisher<Bool, Never>
        let leadSelected: AnyPublisher<Int, Never>
        let timeSelected: AnyPublisher<Int, Never>
        let syncToggled: AnyPublisher<Bool, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILMemorialEditStateModel>, Never>
    }

    // MARK: - Constants
    /// Choices from the design handoff.
    private static let leadChoices = [0, 1, 3, 7]
    private static let hourChoices = [6, 7, 12, 19]
    /// Years offered for the death year: the current year and the 96 before it.
    private static let yearSpan = 96

    /// Longest day the pickers offer: 30 for a lunar month; for a solar month its length, with
    /// February at 29 (the server accepts 29 February when the death year is unknown).
    private static func maxDay(kind: ILMemorialCalendarKind, month: Int) -> Int {
        guard kind == .solar else { return 30 }
        let lengths = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        return lengths[(month - 1) % 12]
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILMemorialEditNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILMemorialEditNavEvent, Never>()
    private let stateSubject = CurrentValueSubject<ViewState<ILMemorialEditStateModel>, Never>(.success(.initial))
    private var currentState = ILMemorialEditStateModel.initial
    /// The entry being edited — mirrors the form, mutated as the user changes it.
    private var draft: ILMemorialEntity
    private let isNew: Bool
    private let useCase: ILMemorialUseCase
    private let now: () -> Date
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    /// `entry == nil` opens the form blank (add mode); otherwise it edits `entry`.
    init(useCase: ILMemorialUseCase, entry: ILMemorialEntity?, now: @escaping () -> Date = Date.init) {
        self.useCase = useCase
        self.now = now
        self.isNew = entry == nil
        self.draft = entry ?? useCase.makeNewEntry()
        self.currentState = makeState()
        self.stateSubject.send(.success(currentState))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.publish() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.back) }
            .store(in: &cancellables)

        input.saveTapped
            .sink { [weak self] _ in self?.handleSave() }
            .store(in: &cancellables)

        input.deleteTapped
            .sink { [weak self] _ in self?.handleDelete() }
            .store(in: &cancellables)

        input.nameChanged
            .sink { [weak self] name in self?.handleNameChanged(name) }
            .store(in: &cancellables)

        input.relationshipSelected
            .sink { [weak self] relationship in self?.update { $0.relationship = relationship } }
            .store(in: &cancellables)

        input.calendarSelected
            .sink { [weak self] kind in self?.handleCalendarSelected(kind) }
            .store(in: &cancellables)

        input.daySelected
            .sink { [weak self] day in self?.update { $0.day = day } }
            .store(in: &cancellables)

        input.monthSelected
            .sink { [weak self] month in self?.update { $0.month = month; $0.day = min($0.day, Self.maxDay(kind: $0.calendarKind, month: month)) } }
            .store(in: &cancellables)

        input.yearSelected
            .sink { [weak self] year in self?.update { $0.deathYear = year > 0 ? year : nil } }
            .store(in: &cancellables)

        input.noteChanged
            .sink { [weak self] note in self?.draft.note = note }
            .store(in: &cancellables)

        input.reminderToggled
            .sink { [weak self] isOn in self?.handleReminderToggled(isOn) }
            .store(in: &cancellables)

        input.leadSelected
            .sink { [weak self] lead in self?.update { $0.reminder?.leadDays = lead } }
            .store(in: &cancellables)

        input.timeSelected
            .sink { [weak self] hour in self?.update { $0.reminder?.hour = hour; $0.reminder?.minute = 0 } }
            .store(in: &cancellables)

        input.syncToggled
            .sink { [weak self] isOn in self?.update { $0.syncToReminders = isOn } }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleNameChanged(_ name: String) {
        draft.name = name
        // Typing must not re-render the whole form; only the error needs to go away.
        guard currentState.nameError != nil else { return }
        currentState.nameError = nil
        stateSubject.send(.success(currentState))
    }

    private func handleCalendarSelected(_ kind: ILMemorialCalendarKind) {
        update {
            $0.calendarKind = kind
            $0.day = min($0.day, Self.maxDay(kind: kind, month: $0.month))
        }
    }

    private func handleReminderToggled(_ isOn: Bool) {
        update { entry in
            if !isOn {
                entry.reminder = nil
            } else if entry.reminder == nil {
                entry.reminder = ILMemorialReminder(leadDays: 1, hour: 7, minute: 0)
            }
        }
    }

    private func handleSave() {
        guard !currentState.isSaving else { return }
        guard useCase.isValid(name: draft.name) else {
            currentState.nameError = "memorial.edit.nameError".localized
            stateSubject.send(.success(currentState))
            return
        }

        let entry = draft
        currentState.isSaving = true
        stateSubject.send(.success(currentState))
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.useCase.save(entry)
                self.navigationEventSubject.send(.saved(message: Self.savedMessage(for: entry)))
            } catch {
                self.currentState.isSaving = false
                self.stateSubject.send(.failure(error))
                self.stateSubject.send(.success(self.currentState))
            }
        }
    }

    // @ai: assumption — see Docs/Assumptions/Memorial/AS-Memorial-004-delete-without-confirmation.md
    private func handleDelete() {
        guard !isNew, !currentState.isSaving else { return }
        let entry = draft
        currentState.isSaving = true
        stateSubject.send(.success(currentState))
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.useCase.delete(id: entry.id)
                let name = entry.name.trimmingCharacters(in: .whitespacesAndNewlines)
                let shown = name.isEmpty ? "memorial.message.deletedFallbackName".localized : name
                self.navigationEventSubject.send(.deleted(message: String(format: "memorial.message.deleted".localized, shown)))
            } catch {
                self.currentState.isSaving = false
                self.stateSubject.send(.failure(error))
                self.stateSubject.send(.success(self.currentState))
            }
        }
    }

    private static func savedMessage(for entry: ILMemorialEntity) -> String {
        guard entry.reminder != nil, entry.syncToReminders else {
            return "memorial.message.saved".localized
        }
        let relationship = ILMemorialFormatter.relationshipLabel(entry.relationship).lowercased()
        return String(format: "memorial.message.savedWithReminder".localized, relationship)
    }

    // MARK: - Draft -> StateModel
    private func update(_ change: (inout ILMemorialEntity) -> Void) {
        change(&draft)
        publish()
    }

    private func publish() {
        currentState = makeState(keepingFlagsFrom: currentState)
        stateSubject.send(.success(currentState))
    }

    /// `Entity -> StateModel` is presentation-only (option lists, labels, preview), so it lives
    /// here rather than in a shared mapper.
    private func makeState(keepingFlagsFrom previous: ILMemorialEditStateModel? = nil) -> ILMemorialEditStateModel {
        var state = ILMemorialEditStateModel()
        state.title = isNew ? "memorial.edit.titleNew".localized : "memorial.edit.titleEdit".localized
        state.saveTitle = isNew ? "memorial.edit.saveNew".localized : "memorial.edit.saveEdit".localized
        state.canDelete = !isNew
        state.isSaving = previous?.isSaving ?? false
        state.nameError = previous?.nameError

        state.name = draft.name
        state.note = draft.note

        state.relationships = ILMemorialRelationship.allCases.enumerated().map { index, relationship in
            ILMemorialOptionModel(
                id: index,
                title: ILMemorialFormatter.relationshipLabel(relationship),
                isSelected: relationship == draft.relationship
            )
        }

        let isLunar = draft.calendarKind == .lunar
        state.calendarKind = draft.calendarKind
        state.selectedDay = draft.day
        state.selectedMonth = draft.month
        state.selectedYear = draft.deathYear ?? 0
        state.dayOptions = (1...Self.maxDay(kind: draft.calendarKind, month: draft.month)).map { day in
            let title = isLunar && day <= 10
                ? String(format: "memorial.edit.day.lunarFormat".localized, day)
                : "\(day)"
            return ILMemorialOptionModel(id: day, title: title, isSelected: day == draft.day)
        }
        state.monthOptions = (1...12).map { month in
            let title = isLunar
                ? String(format: "lunarCalendar.month.label".localized, ILMemorialFormatter.lunarMonthName(month))
                : String(format: "memorial.edit.month.solarFormat".localized, month)
            return ILMemorialOptionModel(id: month, title: title, isSelected: month == draft.month)
        }
        let currentYear = Calendar(identifier: .gregorian).component(.year, from: now())
        state.yearOptions = [ILMemorialOptionModel(id: 0, title: "memorial.edit.year.unknown".localized, isSelected: draft.deathYear == nil)]
            + (0...Self.yearSpan).map { offset in
                let year = currentYear - offset
                return ILMemorialOptionModel(id: year, title: "\(year)", isSelected: year == draft.deathYear)
            }

        if let next = useCase.nextAnniversary(for: draft, now: now()) {
            let days = ILMemorialFormatter.daysLabel(next.daysUntil).lowercased()
            state.previewNext = String(format: "memorial.preview.next".localized, ILMemorialFormatter.solarLine(next.date), days)
            let suffix = ILMemorialFormatter.ordinalSuffix(next.ordinal)
            state.previewDetail = isLunar
                ? String(format: "memorial.preview.lunarFormat".localized, draft.day, ILMemorialFormatter.lunarMonthName(draft.month), suffix)
                : String(format: "memorial.preview.solarFormat".localized, next.lunarDay, ILMemorialFormatter.lunarMonthName(next.lunarMonth), suffix)
        }

        state.reminderOn = draft.reminder != nil
        state.syncOn = draft.syncToReminders
        state.leadOptions = Self.leadChoices.map {
            ILMemorialOptionModel(id: $0, title: ILMemorialFormatter.leadLabel($0), isSelected: $0 == draft.reminder?.leadDays)
        }
        state.timeOptions = Self.hourChoices.map {
            ILMemorialOptionModel(id: $0, title: ILMemorialFormatter.timeLabel(hour: $0, minute: 0), isSelected: $0 == draft.reminder?.hour && draft.reminder?.minute == 0)
        }
        return state
    }
}
