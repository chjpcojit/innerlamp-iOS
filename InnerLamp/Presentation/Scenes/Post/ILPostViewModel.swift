//
//  ILPostViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILPostNavEvent: Equatable {
    /// Nút ‹ ở header — đóng màn Bài đăng đạo tràng.
    case back
    /// Nút "Chia sẻ" ở chân bài — mở modal chia sẻ câu kinh (màn `share` chưa build).
    case share
}

protocol ILPostViewModelProtocol: ViewModelType {
    /// Độc lập với `transform(input:)` — `ILPostCoordinator` subscribe trực tiếp trong `start()`,
    /// trước khi `ViewController`/`Input` tồn tại.
    var navigationEventPublisher: AnyPublisher<ILPostNavEvent, Never> { get }
}

final class ILPostViewModel: ILPostViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        let likeTapped: AnyPublisher<Void, Never>
        let shareTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILPostStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILPostNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILPostNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILPostStateModel>, Never>
    private var currentEntity: ILPostEntity
    private var currentState: ILPostStateModel
    private let useCase: ILPostUseCase
    private let postID: String
    private let now: () -> Date
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILPostUseCase, postID: String, now: @escaping () -> Date = Date.init) {
        self.useCase = useCase
        self.postID = postID
        self.now = now
        let initialEntity = useCase.getInitialState(postID: postID)
        self.currentEntity = initialEntity
        self.currentState = Self.makeStateModel(entity: initialEntity, now: now())
        self.stateSubject = CurrentValueSubject(.success(currentState))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.back) }
            .store(in: &cancellables)

        input.likeTapped
            .sink { [weak self] _ in self?.handleLikeTapped() }
            .store(in: &cancellables)

        input.shareTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.share) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        applyEntity(useCase.getInitialState(postID: postID))
    }

    private func handleLikeTapped() {
        applyEntity(useCase.toggleLike(in: currentEntity))
    }

    // MARK: - Entity -> StateModel
    /// `Entity -> StateModel` là việc riêng của presentation (thời gian tương đối, số đã format,
    /// màu avatar suy từ tên) nên nằm ở đây, không phải trong Mapper dùng chung.
    private func applyEntity(_ entity: ILPostEntity) {
        currentEntity = entity
        currentState = Self.makeStateModel(entity: entity, now: now())
        stateSubject.send(.success(currentState))
    }

    private static func makeStateModel(entity: ILPostEntity, now: Date) -> ILPostStateModel {
        var state = ILPostStateModel()
        let post = entity.post

        state.communityName = post.communityName
        state.memberCountText = String(
            format: "post.header.members".localized,
            formatCount(post.communityMemberCount)
        )

        state.authorName = post.authorName
        state.authorInitials = post.authorInitials
        state.authorTone = tone(for: post.authorName)
        state.metaText = "\(formatRelativeTime(from: post.postedAt, now: now)) · \(post.tag)"
        state.body = post.body

        state.isLiked = entity.isLiked
        state.likeCountText = formatCount(post.likeCount + (entity.isLiked ? 1 : 0))
        state.commentCountText = formatCount(post.commentCount)
        state.commentsHeaderText = String(
            format: "post.comments.header".localized,
            formatCount(post.commentCount)
        )

        state.comments = entity.comments.map { comment in
            ILPostCommentModel(
                id: comment.id,
                authorName: comment.authorName,
                authorInitials: comment.authorInitials,
                timeText: formatRelativeTime(from: comment.postedAt, now: now),
                text: comment.text,
                tone: tone(for: comment.authorName),
                likeText: String(
                    format: "post.comments.action.like".localized,
                    formatCount(comment.likeCount)
                ),
                depth: comment.parentID == nil ? 0 : 1
            )
        }

        return state
    }

    // MARK: - Helpers

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
            return String(format: "post.time.minutesAgo".localized, max(1, minutes))
        }
        let hours = minutes / 60
        if hours < 24 {
            return String(format: "post.time.hoursAgo".localized, hours)
        }
        return String(format: "post.time.daysAgo".localized, hours / 24)
    }

    /// Màu avatar suy xác định (deterministic) từ tên tác giả, để có đa dạng gold/green/rose mà
    /// không nhét dữ liệu UI vào Entity. Xấp xỉ các tone theo tác giả trong prototype (tone chính
    /// xác theo design handoff cần thêm sau, khi có dữ liệu tác giả thật).
    static func tone(for name: String) -> ILPostAuthorTone {
        let tones: [ILPostAuthorTone] = [.gold, .green, .rose]
        let hash = name.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) }
        let index = ((hash % tones.count) + tones.count) % tones.count
        return tones[index]
    }
}
