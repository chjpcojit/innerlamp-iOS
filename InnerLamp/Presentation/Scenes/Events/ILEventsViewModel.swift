//
//  ILEventsViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILEventsNavEvent: Equatable {
    case goBack
    case openRegister(eventId: String)
}

protocol ILEventsViewModelProtocol: ViewModelType {
    /// Độc lập với `transform(input:)` — `ILEventsCoordinator` subscribe trực tiếp trong
    /// `start()`, trước khi `ViewController`/`Input` tồn tại.
    var navigationEventPublisher: AnyPublisher<ILEventsNavEvent, Never> { get }
}

final class ILEventsViewModel: ILEventsViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let tabSelected: AnyPublisher<ILEventsTab, Never>
        let registerTapped: AnyPublisher<String, Never>
        let backTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILEventsStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILEventsNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILEventsNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILEventsStateModel>, Never>
    private var events: ILEventsEntity
    private var currentState: ILEventsStateModel
    private let useCase: ILEventsUseCase
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILEventsUseCase) {
        self.useCase = useCase
        let initialEvents = useCase.getEvents()
        self.events = initialEvents
        let initialState = ILEventsViewModel.makeStateModel(events: initialEvents, tab: .upcoming)
        self.currentState = initialState
        self.stateSubject = CurrentValueSubject(.success(initialState))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.tabSelected
            .sink { [weak self] tab in self?.handleTabSelected(tab) }
            .store(in: &cancellables)

        input.registerTapped
            .sink { [weak self] id in self?.handleRegisterTapped(id: id) }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.goBack) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        events = useCase.getEvents()
        currentState = ILEventsViewModel.makeStateModel(events: events, tab: currentState.selectedTab)
        stateSubject.send(.success(currentState))
    }

    private func handleTabSelected(_ tab: ILEventsTab) {
        currentState = ILEventsViewModel.makeStateModel(events: events, tab: tab)
        stateSubject.send(.success(currentState))
    }

    private func handleRegisterTapped(id: String) {
        guard !id.isEmpty else { return }
        navigationEventSubject.send(.openRegister(eventId: id))
    }

    // MARK: - Entity -> StateModel mapping
    /// Việc riêng của presentation (ghép nhãn trạng thái, tiêu đề mục) nên nằm ở đây,
    /// không phải trong Mapper dùng chung (xem `references/data_layer_boundaries.md`).
    private static func makeStateModel(events: ILEventsEntity, tab: ILEventsTab) -> ILEventsStateModel {
        var model = ILEventsStateModel()
        model.selectedTab = tab

        model.featured = events.featured.map { featured in
            ILEventsFeaturedModel(
                id: featured.id,
                day: featured.day,
                monthLabel: featured.monthLabel,
                eyebrowText: "events.hero.eyebrow".localized,
                title: featured.title,
                metaText: featured.meta,
                ctaTitle: "events.hero.cta".localized,
                seatsText: String(format: "events.hero.seatsLeft".localized, featured.seatsLeft)
            )
        }

        model.listTitle = sectionTitle(for: tab)
        model.items = items(for: tab, from: events).map { event in
            ILEventsListItemModel(
                id: event.id,
                day: event.day,
                monthLabel: event.monthLabel,
                title: event.name,
                subtitle: event.subtitle,
                statusText: statusText(event.status, isCourse: tab == .courses),
                tone: event.tone
            )
        }
        return model
    }

    private static func items(for tab: ILEventsTab, from events: ILEventsEntity) -> [ILEventsEventEntity] {
        switch tab {
        case .upcoming: return events.upcoming
        case .courses: return events.courses
        case .registered: return events.registered
        }
    }

    private static func sectionTitle(for tab: ILEventsTab) -> String {
        switch tab {
        case .upcoming: return "events.section.upcoming".localized
        case .courses: return "events.section.courses".localized
        case .registered: return "events.section.registered".localized
        }
    }

    private static func statusText(_ status: ILEventsStatus, isCourse: Bool) -> String {
        switch status {
        case .open:
            return isCourse ? "events.status.open".localized : "events.status.register".localized
        case .closing(let seatsLeft):
            return String(format: "events.status.seatsLeft".localized, seatsLeft)
        case .upcoming:
            return "events.status.upcoming".localized
        case .registered:
            return "events.status.registered".localized
        }
    }
}
