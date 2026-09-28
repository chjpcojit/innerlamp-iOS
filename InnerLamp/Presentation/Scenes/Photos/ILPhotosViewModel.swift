//
//  ILPhotosViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILPhotosNavEvent: Equatable {
    /// Nút ‹ ở header — đóng màn Ảnh chùa đẹp.
    case back
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
        let backTapped: AnyPublisher<Void, Never>
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
    private var currentEntity: ILPhotosEntity
    private var currentState: ILPhotosStateModel
    private let useCase: ILPhotosUseCase
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILPhotosUseCase) {
        self.useCase = useCase
        let initialEntity = useCase.getInitialState()
        self.currentEntity = initialEntity
        let initialState = Self.makeStateModel(
            from: initialEntity,
            photos: useCase.filteredPhotos(in: initialEntity)
        )
        self.currentState = initialState
        self.stateSubject = CurrentValueSubject(.success(initialState))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.categorySelected
            .sink { [weak self] category in self?.handleCategorySelected(category) }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.back) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        applyEntity(useCase.getInitialState())
    }

    private func handleCategorySelected(_ category: ILPhotosCategory?) {
        applyEntity(useCase.selectCategory(category, in: currentEntity))
    }

    // MARK: - Entity -> StateModel
    /// `Entity -> StateModel` là việc riêng của presentation (nhãn danh mục `.localized`, phụ đề
    /// "N ảnh · Danh mục") nên nằm ở đây, không phải trong Mapper dùng chung (xem
    /// `references/data_layer_boundaries.md`).
    private func applyEntity(_ entity: ILPhotosEntity) {
        currentEntity = entity
        currentState = Self.makeStateModel(from: entity, photos: useCase.filteredPhotos(in: entity))
        stateSubject.send(.success(currentState))
    }

    private static func makeStateModel(
        from entity: ILPhotosEntity,
        photos: [ILPhotosPhotoEntity]
    ) -> ILPhotosStateModel {
        var state = ILPhotosStateModel()

        state.categories = Self.makeCategoryModels(selected: entity.selectedCategory)
        state.photos = photos.map { photo in
            ILPhotosPhotoModel(
                id: photo.id,
                title: photo.title,
                place: photo.place,
                imageHeight: photo.imageHeight,
                categoryLabel: labelKey(for: photo.category).localized
            )
        }
        state.subtitle = makeSubtitle(count: photos.count, selected: entity.selectedCategory)

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
