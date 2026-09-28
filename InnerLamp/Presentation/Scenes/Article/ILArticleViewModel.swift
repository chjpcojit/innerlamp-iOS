//
//  ILArticleViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILArticleNavEvent: Equatable {
    /// Nút ‹ ở header — đóng màn Bài viết Phật pháp.
    case back
    /// Nút "Chia sẻ" — mở modal chia sẻ câu kinh (màn `share` chưa build).
    case share
}

protocol ILArticleViewModelProtocol: ViewModelType {
    /// Độc lập với `transform(input:)` — `ILArticleCoordinator` subscribe trực tiếp trong
    /// `start()`, trước khi `ViewController`/`Input` tồn tại.
    var navigationEventPublisher: AnyPublisher<ILArticleNavEvent, Never> { get }
}

final class ILArticleViewModel: ILArticleViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        let saveTapped: AnyPublisher<Void, Never>
        let shareTapped: AnyPublisher<Void, Never>
        /// Chạm 1 bài trong danh sách "Đọc tiếp" — mang theo `id` bài được chọn.
        let nextArticleTapped: AnyPublisher<String, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILArticleStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILArticleNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILArticleNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILArticleStateModel>, Never>
    private var currentEntity: ILArticleEntity
    private var currentState: ILArticleStateModel
    private let useCase: ILArticleUseCase
    private let initialArticleID: String
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILArticleUseCase, articleID: String) {
        self.useCase = useCase
        self.initialArticleID = articleID
        let initialEntity = useCase.getInitialState(articleID: articleID)
        self.currentEntity = initialEntity
        self.currentState = Self.makeStateModel(from: initialEntity, useCase: useCase)
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

        input.saveTapped
            .sink { [weak self] _ in self?.handleSaveTapped() }
            .store(in: &cancellables)

        input.shareTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.share) }
            .store(in: &cancellables)

        input.nextArticleTapped
            .sink { [weak self] id in self?.handleNextArticleTapped(id) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        applyEntity(useCase.getInitialState(articleID: initialArticleID))
    }

    private func handleSaveTapped() {
        applyEntity(useCase.toggleSave(currentEntity.currentArticleID, in: currentEntity))
    }

    private func handleNextArticleTapped(_ id: String) {
        applyEntity(useCase.selectArticle(id, in: currentEntity))
    }

    // MARK: - Entity -> StateModel
    /// `Entity -> StateModel` là việc riêng của presentation (nhãn nút Lưu/Đã lưu, chuỗi
    /// "N phút đọc", viết hoa danh mục "Đọc tiếp") nên nằm ở đây, không phải trong Mapper dùng
    /// chung (xem `references/data_layer_boundaries.md`).
    private func applyEntity(_ entity: ILArticleEntity) {
        currentEntity = entity
        currentState = Self.makeStateModel(from: entity, useCase: useCase)
        stateSubject.send(.success(currentState))
    }

    private static func makeStateModel(
        from entity: ILArticleEntity,
        useCase: ILArticleUseCase
    ) -> ILArticleStateModel {
        var state = ILArticleStateModel()

        if let article = useCase.currentArticle(in: entity) {
            state.headerCategory = article.category
            state.headerReadText = String(format: "article.readFormat".localized, article.readMinutes)
            state.title = article.title
            state.author = article.author
            state.authorInitials = article.authorInitials
            state.dateReadText = "\(article.date) · \(state.headerReadText)"
            state.bodyParagraphs = article.bodyParagraphs
            state.quote = article.quote
            state.quoteSource = article.quoteSource
        }

        state.isSaved = entity.savedArticleIDs.contains(entity.currentArticleID)
        state.saveButtonTitle = (state.isSaved ? "article.saved" : "article.save").localized
        state.shareButtonTitle = "article.share".localized
        state.readMoreTitle = "article.readMore".localized

        state.nextArticles = useCase.nextArticles(after: entity.currentArticleID, in: entity).map {
            ILArticleNextArticleModel(id: $0.id, categoryLabel: $0.category.uppercased(), title: $0.title)
        }

        return state
    }
}
