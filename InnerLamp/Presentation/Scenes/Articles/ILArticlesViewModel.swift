//
//  ILArticlesViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILArticlesNavEvent: Equatable {
    /// Back chip in the header — dismisses the "All articles" screen.
    case back
    /// Tapping one article row — opens the Article detail screen with the article's `id`.
    case openArticle(id: String)
}

protocol ILArticlesViewModelProtocol: ViewModelType {
    /// Independent of `transform(input:)` — `ILArticlesCoordinator` subscribes to this directly in
    /// `start()`, before the ViewController exists.
    var navigationEventPublisher: AnyPublisher<ILArticlesNavEvent, Never> { get }
}

final class ILArticlesViewModel: ILArticlesViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        /// Tapping one article row — carries the article `id`.
        let articleTapped: AnyPublisher<String, Never>
        /// Fired when the scroll view nears the bottom of the list.
        let loadMoreTriggered: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILArticlesStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILArticlesNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILArticlesNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILArticlesStateModel>, Never>
    private var currentEntity: ILArticlesEntity
    private var currentState: ILArticlesStateModel
    private let useCase: ILArticlesUseCase
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILArticlesUseCase) {
        self.useCase = useCase
        let initialEntity = useCase.getInitialState()
        self.currentEntity = initialEntity
        self.currentState = Self.makeStateModel(from: initialEntity)
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

        input.articleTapped
            .sink { [weak self] id in self?.navigationEventSubject.send(.openArticle(id: id)) }
            .store(in: &cancellables)

        input.loadMoreTriggered
            .sink { [weak self] _ in self?.handleLoadMore() }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        applyEntity(useCase.getInitialState())
    }

    private func handleLoadMore() {
        // Guard against duplicate/concurrent loads and against loading past the end of the list.
        guard currentState.hasMore, !currentState.isLoadingMore else { return }

        currentState.isLoadingMore = true
        stateSubject.send(.success(currentState))

        Task { [weak self] in
            guard let self else { return }
            do {
                // The real implementation would append the next page here; the stub is a no-op,
                // so we simply clear the loading flag and re-emit (see data_layer_boundaries.md).
                try await self.useCase.loadMoreArticles()
                self.currentState.isLoadingMore = false
                self.stateSubject.send(.success(self.currentState))
            } catch {
                self.currentState.isLoadingMore = false
                self.stateSubject.send(.failure(error))
            }
        }
    }

    // MARK: - Entity -> StateModel
    /// `Entity -> StateModel` is presentation-specific (the "N / M bài" subtitle, the "… phút đọc"
    /// string) so it lives here, not in a shared Mapper (see references/data_layer_boundaries.md).
    private func applyEntity(_ entity: ILArticlesEntity) {
        currentEntity = entity
        currentState = Self.makeStateModel(from: entity)
        stateSubject.send(.success(currentState))
    }

    private static func makeStateModel(from entity: ILArticlesEntity) -> ILArticlesStateModel {
        var state = ILArticlesStateModel()
        state.subtitle = String(
            format: "articles.header.subtitleFormat".localized,
            entity.loadedCount,
            entity.totalCount
        )
        state.articles = entity.articles.map {
            ILArticlesArticleModel(
                id: $0.id,
                category: $0.category,
                title: $0.title,
                author: $0.author,
                readText: String(format: "articles.readFormat".localized, $0.readMinutes)
            )
        }
        state.hasMore = entity.hasMore
        return state
    }
}
