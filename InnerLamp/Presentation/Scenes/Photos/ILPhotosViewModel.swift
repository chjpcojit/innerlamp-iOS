//
//  ILPhotosViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILPhotosNavEvent: Equatable {
    /// Nút ‹ ở header — đóng màn Ảnh chùa đẹp.
    case back
    /// Chạm 1 ảnh — mở màn xem ảnh trên danh sách đang hiển thị, bắt đầu từ `selectedID`.
    case openPhoto(photos: [ILPhotosPhotoModel], selectedID: String)
}

protocol ILPhotosViewModelProtocol: ViewModelType {
    /// Độc lập với `transform(input:)` — `ILPhotosCoordinator` subscribe trực tiếp trong
    /// `start()`, trước khi `ViewController`/`Input` tồn tại.
    var navigationEventPublisher: AnyPublisher<ILPhotosNavEvent, Never> { get }
}

final class ILPhotosViewModel: ILPhotosViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        /// Danh mục được chạm trên chip lọc (`nil` = "Tất cả").
        let categorySelected: AnyPublisher<ILPhotosCategory?, Never>
        /// Fired when the grid nears the bottom of its content.
        let loadMoreTriggered: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        /// Id of the photo whose tile was tapped.
        let photoSelected: AnyPublisher<String, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILPhotosStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILPhotosNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILPhotosNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILPhotosStateModel>, Never>
    private var currentEntity: ILPhotosEntity = .empty
    private var currentState: ILPhotosStateModel
    private let useCase: ILPhotosUseCase
    private var cancellables = Set<AnyCancellable>()
    /// Bumped on every category change so a response for an earlier selection is discarded.
    private var requestGeneration = 0
    /// Category of the newest first-page request (may be ahead of `currentEntity` while loading).
    private var requestedCategory: ILPhotosCategory?

    // MARK: - Initializer
    init(useCase: ILPhotosUseCase) {
        self.useCase = useCase
        let initialState = Self.makeStateModel(from: .empty)
        self.currentState = initialState
        self.stateSubject = CurrentValueSubject(.success(initialState))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.loadFirstPage(category: nil) }
            .store(in: &cancellables)

        input.categorySelected
            .sink { [weak self] category in self?.handleCategorySelected(category) }
            .store(in: &cancellables)

        input.loadMoreTriggered
            .sink { [weak self] _ in self?.handleLoadMore() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.back) }
            .store(in: &cancellables)

        input.photoSelected
            .sink { [weak self] id in self?.handlePhotoSelected(id) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handlePhotoSelected(_ id: String) {
        let photos = currentState.photos
        guard photos.contains(where: { $0.id == id }) else { return }
        navigationEventSubject.send(.openPhoto(photos: photos, selectedID: id))
    }

    private func handleCategorySelected(_ category: ILPhotosCategory?) {
        // Re-tapping the selected chip retries only when nothing is shown (e.g. the first load failed).
        guard category != requestedCategory || currentEntity.photos.isEmpty else { return }
        loadFirstPage(category: category)
    }

    /// Loads page 1 for `category`. The photos of the previous selection stay on screen (only the
    /// chip moves) until the response arrives, so the grid can crossfade straight to the new
    /// photos instead of flashing empty. Any request still in flight for the previous selection is
    /// invalidated by `requestGeneration`.
    private func loadFirstPage(category: ILPhotosCategory?) {
        requestGeneration += 1
        let generation = requestGeneration
        requestedCategory = category

        currentState = Self.makeStateModel(from: currentEntity)
        currentState.categories = Self.makeCategoryModels(selected: category)
        currentState.isLoadingMore = true
        stateSubject.send(.success(currentState))

        runRequest(generation: generation, revertsSelectionOnFailure: true) { [useCase] in
            try await useCase.loadFirstPage(category: category)
        }
    }

    private func handleLoadMore() {
        // Guard against duplicate/concurrent loads and against loading past the end of the list.
        guard currentState.hasMore, !currentState.isLoadingMore else { return }

        let entity = currentEntity
        currentState.isLoadingMore = true
        stateSubject.send(.success(currentState))

        runRequest(generation: requestGeneration) { [useCase] in try await useCase.loadNextPage(after: entity) }
    }

    /// Runs one page request. On failure the photos already loaded are kept, the spinner is cleared
    /// and the error is surfaced afterwards. A failed category switch also moves the chip back to
    /// the category whose photos are still shown.
    private func runRequest(
        generation: Int,
        revertsSelectionOnFailure: Bool = false,
        _ request: @escaping () async throws -> ILPhotosEntity
    ) {
        Task { [weak self] in
            do {
                let entity = try await request()
                guard let self, generation == self.requestGeneration else { return }
                self.applyEntity(entity)
            } catch {
                guard let self, generation == self.requestGeneration else { return }
                if revertsSelectionOnFailure {
                    self.requestedCategory = self.currentEntity.selectedCategory
                    self.currentState = Self.makeStateModel(from: self.currentEntity)
                } else {
                    self.currentState.isLoadingMore = false
                }
                self.stateSubject.send(.success(self.currentState))
                self.stateSubject.send(.failure(error))
            }
        }
    }

    // MARK: - Entity -> StateModel
    /// `Entity -> StateModel` là việc riêng của presentation (nhãn danh mục `.localized`, phụ đề
    /// "N ảnh · Danh mục") nên nằm ở đây, không phải trong Mapper dùng chung (xem
    /// `references/data_layer_boundaries.md`).
    private func applyEntity(_ entity: ILPhotosEntity) {
        currentEntity = entity
        requestedCategory = entity.selectedCategory
        currentState = Self.makeStateModel(from: entity)
        stateSubject.send(.success(currentState))
    }

    private static func makeStateModel(from entity: ILPhotosEntity) -> ILPhotosStateModel {
        var state = ILPhotosStateModel()

        state.categories = Self.makeCategoryModels(selected: entity.selectedCategory)
        state.photos = entity.photos.map {
            ILPhotosPhotoModel(
                id: $0.id,
                title: $0.title,
                place: $0.place,
                thumbnailURL: $0.thumbnailURL,
                imageURL: $0.imageURL,
                categoryLabel: labelKey(for: $0.category).localized
            )
        }
        state.subtitle = makeSubtitle(count: entity.totalCount, selected: entity.selectedCategory)
        state.hasMore = entity.hasMore

        return state
    }

    /// Chip lọc theo thứ tự hiển thị: "Tất cả" (nil) rồi tới 4 danh mục theo `CaseIterable`.
    private static func makeCategoryModels(selected: ILPhotosCategory?) -> [ILPhotosCategoryModel] {
        var models: [ILPhotosCategoryModel] = [
            ILPhotosCategoryModel(
                id: "all",
                label: "photos.category.all".localized,
                category: nil,
                isSelected: selected == nil
            )
        ]

        for category in ILPhotosCategory.allCases {
            models.append(
                ILPhotosCategoryModel(
                    id: id(for: category),
                    label: labelKey(for: category).localized,
                    category: category,
                    isSelected: selected == category
                )
            )
        }

        return models
    }

    private static func makeSubtitle(count: Int, selected: ILPhotosCategory?) -> String {
        guard let category = selected else {
            return String(format: "photos.subtitle.count".localized, count)
        }
        return String(
            format: "photos.subtitle.countCategory".localized,
            count,
            labelKey(for: category).localized
        )
    }

    // MARK: - Copy keys
    private static func id(for category: ILPhotosCategory) -> String {
        switch category {
        case .temple: return "temple"
        case .buddhaStatue: return "buddha"
        case .meditation: return "meditation"
        case .festival: return "festival"
        }
    }

    private static func labelKey(for category: ILPhotosCategory) -> String {
        switch category {
        case .temple: return "photos.category.temple"
        case .buddhaStatue: return "photos.category.buddha"
        case .meditation: return "photos.category.meditation"
        case .festival: return "photos.category.festival"
        }
    }
}
