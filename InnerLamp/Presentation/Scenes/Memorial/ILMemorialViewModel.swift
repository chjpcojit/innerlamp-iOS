//
//  ILMemorialViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILMemorialNavEvent: Equatable {
    case back
    /// "Thêm" / "Thêm người thân" — open the form blank.
    case addEntry
    /// Highlight card or a row — open the form for this entry.
    case editEntry(ILMemorialEntity)
    /// "Gia phả" link — open the family tree.
    case openFamilyTree
}

protocol ILMemorialViewModelProtocol: ViewModelType {
    /// Independent of `transform(input:)` — the coordinator subscribes in `start()`.
    var navigationEventPublisher: AnyPublisher<ILMemorialNavEvent, Never> { get }

    /// Called by the coordinator when the form closed after a save or delete: reloads the list and
    /// shows `message` as a transient banner.
    func didFinishEditing(message: String)
}

final class ILMemorialViewModel: ILMemorialViewModelProtocol {

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        let addTapped: AnyPublisher<Void, Never>
        let itemTapped: AnyPublisher<String, Never>
        let familyTreeTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILMemorialStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILMemorialNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    /// How long the confirmation banner stays on screen.
    private static let bannerDuration: Duration = .milliseconds(3600)

    private let navigationEventSubject = PassthroughSubject<ILMemorialNavEvent, Never>()
    private let stateSubject = CurrentValueSubject<ViewState<ILMemorialStateModel>, Never>(.success(.initial))
    private var currentState = ILMemorialStateModel.initial
    private var items: [ILMemorialItem] = []
    private var bannerTask: Task<Void, Never>?
    private let useCase: ILMemorialUseCase
    private let now: () -> Date
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILMemorialUseCase, now: @escaping () -> Date = Date.init) {
        self.useCase = useCase
        self.now = now
    }

    deinit {
        bannerTask?.cancel()
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.reload() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.back) }
            .store(in: &cancellables)

        input.addTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.addEntry) }
            .store(in: &cancellables)

        input.itemTapped
            .sink { [weak self] id in self?.handleItemTapped(id) }
            .store(in: &cancellables)

        input.familyTreeTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openFamilyTree) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Coordinator hook
    func didFinishEditing(message: String) {
        reload()
        showBanner(message)
    }

    // MARK: - Actions
    private func reload() {
        Task { [weak self] in
            guard let self else { return }
            do {
                self.items = try await self.useCase.loadItems(now: self.now())
                self.applyItems()
            } catch {
                // A failed load falls back to the empty "Sổ giỗ còn trống" page instead of an error.
                self.items = []
                self.applyItems()
            }
        }
    }

    private func handleItemTapped(_ id: String) {
        guard let item = items.first(where: { $0.id == id }) else { return }
        navigationEventSubject.send(.editEntry(item.entry))
    }

    private func showBanner(_ message: String) {
        bannerTask?.cancel()
        currentState.bannerText = message
        stateSubject.send(.success(currentState))
        bannerTask = Task { [weak self] in
            try? await Task.sleep(for: Self.bannerDuration)
            guard !Task.isCancelled, let self else { return }
            self.currentState.bannerText = ""
            self.stateSubject.send(.success(self.currentState))
        }
    }

    // MARK: - Item -> StateModel mapping
    /// `Entity -> StateModel` is presentation-only (labels, emphasis) so it lives here, not in a
    /// shared mapper.
    private func applyItems() {
        var state = ILMemorialStateModel(bannerText: currentState.bannerText)
        state.isEmpty = items.isEmpty
        state.subtitle = items.isEmpty
            ? "memorial.subtitle.empty".localized
            : String(format: "memorial.subtitle.format".localized, items.count)

        if let top = items.first {
            let ordinal = ILMemorialFormatter.ordinalText(top.next.ordinal)
            let relation = ILMemorialFormatter.relationshipLabel(top.entry.relationship)
            state.highlight = ILMemorialHighlightModel(
                id: top.id,
                eyebrow: ILMemorialFormatter.eyebrow(days: top.next.daysUntil),
                name: top.entry.name,
                relationLine: ordinal.isEmpty ? relation : "\(relation) · \(ordinal)",
                dateLine: ILMemorialFormatter.storedDateLine(top.entry),
                whenLine: ILMemorialFormatter.solarLine(top.next.date),
                remindLine: ILMemorialFormatter.reminderLine(top.entry)
            )
        }

        state.rows = items.map { item in
            ILMemorialRowModel(
                id: item.id,
                name: item.entry.name,
                subtitle: "\(ILMemorialFormatter.relationshipLabel(item.entry.relationship)) · \(ILMemorialFormatter.storedDateLine(item.entry))",
                daysText: ILMemorialFormatter.daysLabel(item.next.daysUntil),
                isSoon: item.next.daysUntil <= 7,
                reminderTag: item.entry.reminder == nil ? "" : "memorial.reminder.tag".localized
            )
        }

        currentState = state
        stateSubject.send(.success(state))
    }
}
