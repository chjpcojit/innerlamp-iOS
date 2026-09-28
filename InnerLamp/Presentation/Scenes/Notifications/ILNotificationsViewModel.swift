//
//  ILNotificationsViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILNotificationsNavEvent: Equatable {
    /// "Đóng" — quay về màn trước (pop).
    case goBack
    /// "Ngồi ngay" — sang màn chuẩn bị thiền (`setup`, chưa build).
    case openSetup
}

protocol ILNotificationsViewModelProtocol: ViewModelType {
    /// Độc lập với `transform(input:)` — `ILNotificationsCoordinator` subscribe trực tiếp trong
    /// `start()`, trước khi `ViewController`/`Input` tồn tại.
    var navigationEventPublisher: AnyPublisher<ILNotificationsNavEvent, Never> { get }
}

final class ILNotificationsViewModel: ILNotificationsViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let closeTapped: AnyPublisher<Void, Never>
        let sitNowTapped: AnyPublisher<Void, Never>
        let skipTonightTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILNotificationsStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILNotificationsNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILNotificationsNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILNotificationsStateModel>, Never>
    private var currentState: ILNotificationsStateModel
    private let useCase: ILNotificationsUseCase
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILNotificationsUseCase) {
        self.useCase = useCase
        let initialState = ILNotificationsViewModel.makeStateModel(useCase: useCase)
        self.currentState = initialState
        self.stateSubject = CurrentValueSubject(.success(initialState))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.closeTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.goBack) }
            .store(in: &cancellables)

        input.sitNowTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openSetup) }
            .store(in: &cancellables)

        input.skipTonightTapped
            .sink { [weak self] _ in self?.handleSkipTonight() }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        currentState = ILNotificationsViewModel.makeStateModel(useCase: useCase)
        stateSubject.send(.success(currentState))
    }

    private func handleSkipTonight() {
        currentState.hero = nil
        stateSubject.send(.success(currentState))
    }

    // MARK: - Entity -> StateModel mapping
    /// Việc riêng của presentation (format thời gian tương đối) nên nằm ở đây, không phải trong
    /// Mapper dùng chung (xem `references/data_layer_boundaries.md`).
    private static func makeStateModel(useCase: ILNotificationsUseCase) -> ILNotificationsStateModel {
        var model = ILNotificationsStateModel()

        if let upcoming = useCase.getUpcoming() {
            model.hero = ILNotificationsHeroModel(
                eyebrow: upcoming.eyebrow,
                title: upcoming.title
            )
        }

        model.items = useCase.getNotifications().map { notification in
            ILNotificationItemModel(
                id: notification.id,
                kind: notification.kind,
                title: notification.title,
                body: notification.body,
                relativeTime: formatRelativeTime(notification.timestamp),
                isRead: notification.isRead
            )
        }
        return model
    }

    /// Format thời gian tương đối thuần theo ngưỡng (không phụ thuộc lịch/ngày để dễ test và khớp
    /// 4 nhãn của prototype): "vừa xong" / "N phút" / "N giờ" / "hôm qua" / "N ngày".
    static func formatRelativeTime(_ date: Date, now: Date = Date()) -> String {
        let seconds = max(0, now.timeIntervalSince(date))
        if seconds < 60 {
            return "notifications.time.justNow".localized
        }
        if seconds < 3_600 {
            return String(format: "notifications.time.minutesAgo".localized, Int(seconds / 60))
        }
        if seconds < 86_400 {
            return String(format: "notifications.time.hoursAgo".localized, Int(seconds / 3_600))
        }
        let days = Int(seconds / 86_400)
        if days == 1 {
            return "notifications.time.yesterday".localized
        }
        return String(format: "notifications.time.daysAgo".localized, days)
    }
}
