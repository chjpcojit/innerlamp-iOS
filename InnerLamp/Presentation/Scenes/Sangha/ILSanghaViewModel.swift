//
//  ILSanghaViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILSanghaNavEvent: Equatable {
    case openFindSangha
    case startSitting
    case openCompose
    case openEvents
    case openCommunity(id: String)
    case openPost(id: String)
}

protocol ILSanghaViewModelProtocol: ViewModelType {
    /// Độc lập với `transform(input:)` — `ILSanghaCoordinator` subscribe trực tiếp trong
    /// `start()`, trước khi `ViewController`/`Input` tồn tại.
    var navigationEventPublisher: AnyPublisher<ILSanghaNavEvent, Never> { get }
}

final class ILSanghaViewModel: ILSanghaViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let findSanghaTapped: AnyPublisher<Void, Never>
        let sitTogetherTapped: AnyPublisher<Void, Never>
        let composeTapped: AnyPublisher<Void, Never>
        let eventsTapped: AnyPublisher<Void, Never>
        let communityTapped: AnyPublisher<Void, Never>
        let postTapped: AnyPublisher<String, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILSanghaStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILSanghaNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILSanghaNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILSanghaStateModel>, Never>
    private var sangha: ILSanghaEntity
    private var currentState: ILSanghaStateModel
    private let useCase: ILSanghaUseCase
    private let now: () -> Date
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILSanghaUseCase, now: @escaping () -> Date = Date.init) {
        self.useCase = useCase
        self.now = now
        let initialSangha = useCase.getSangha()
        self.sangha = initialSangha
        let initialState = ILSanghaViewModel.makeStateModel(sangha: initialSangha, now: now())
        self.currentState = initialState
        self.stateSubject = CurrentValueSubject(.success(initialState))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.findSanghaTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openFindSangha) }
            .store(in: &cancellables)

        input.sitTogetherTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.startSitting) }
            .store(in: &cancellables)

        input.composeTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openCompose) }
            .store(in: &cancellables)

        input.eventsTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openEvents) }
            .store(in: &cancellables)

        input.communityTapped
            .sink { [weak self] _ in self?.handleCommunityTapped() }
            .store(in: &cancellables)

        input.postTapped
            .sink { [weak self] id in self?.handlePostTapped(id: id) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        sangha = useCase.getSangha()
        currentState = ILSanghaViewModel.makeStateModel(sangha: sangha, now: now())
        stateSubject.send(.success(currentState))
    }

    private func handleCommunityTapped() {
        guard let community = sangha.community else { return }
        navigationEventSubject.send(.openCommunity(id: community.id))
    }

    private func handlePostTapped(id: String) {
        guard sangha.posts.contains(where: { $0.id == id }) else { return }
        navigationEventSubject.send(.openPost(id: id))
    }

    // MARK: - Entity -> StateModel mapping
    /// Việc riêng của presentation (format số, ghép câu phụ, thời gian tương đối) nên nằm ở đây,
    /// không phải trong Mapper dùng chung (xem `references/data_layer_boundaries.md`).
    private static func makeStateModel(sangha: ILSanghaEntity, now: Date) -> ILSanghaStateModel {
        var model = ILSanghaStateModel()

        model.liveSession = sangha.liveSession.map {
            ILSanghaLiveSessionModel(
                title: "sangha.live.title".localized,
                countText: formatCount($0.participantCount),
                captionText: String(format: "sangha.live.caption".localized, $0.sessionMinutes),
                ctaTitle: "sangha.live.cta".localized
            )
        }

        model.community = sangha.community.map {
            ILSanghaCommunityModel(
                id: $0.id,
                name: $0.name,
                metaText: String(format: "sangha.community.meta".localized, $0.memberCount, $0.district),
                announcement: $0.announcement
            )
        }

        model.posts = sangha.posts.map {
            ILSanghaPostModel(
                id: $0.id,
                authorName: $0.authorName,
                authorInitials: initial(of: $0.authorName),
                metaText: String(
                    format: "sangha.post.meta".localized,
                    formatRelativeTime(from: $0.postedAt, now: now),
                    $0.authorStreakDays
                ),
                body: $0.body,
                likeText: String(format: "sangha.post.like".localized, $0.likeCount),
                replyText: String(format: "sangha.post.reply".localized, $0.replyCount)
            )
        }
        return model
    }

    /// Nhóm hàng nghìn theo kiểu Việt: 1248 → "1.248".
    static func formatCount(_ count: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter.string(from: NSNumber(value: count)) ?? String(count)
    }

    /// < 1 giờ → "x phút trước" (tối thiểu 1); < 24 giờ → "x giờ trước"; còn lại → "x ngày trước".
    static func formatRelativeTime(from date: Date, now: Date) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(date)))
        let minutes = seconds / 60
        if minutes < 60 {
            return String(format: "sangha.time.minutesAgo".localized, max(1, minutes))
        }
        let hours = minutes / 60
        if hours < 24 {
            return String(format: "sangha.time.hoursAgo".localized, hours)
        }
        return String(format: "sangha.time.daysAgo".localized, hours / 24)
    }

    /// Chữ cái đầu của tên gọi (từ cuối) — "Diệu Hạnh" → "H".
    static func initial(of name: String) -> String {
        guard let lastWord = name.split(separator: " ").last, let first = lastWord.first else { return "" }
        return String(first).uppercased()
    }
}
