//
//  ILLibraryViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILLibraryNavEvent: Equatable {
    case openSearch
    case openItem(id: String, kind: ILLibraryContentKind)
}

protocol ILLibraryViewModelProtocol: ViewModelType {
    /// Độc lập với `transform(input:)` — `ILLibraryCoordinator` subscribe trực tiếp trong
    /// `start()`, trước khi `ViewController`/`Input` tồn tại.
    var navigationEventPublisher: AnyPublisher<ILLibraryNavEvent, Never> { get }
}

final class ILLibraryViewModel: ILLibraryViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let categorySelected: AnyPublisher<ILLibraryCategory, Never>
        let searchTapped: AnyPublisher<Void, Never>
        let featuredTapped: AnyPublisher<Void, Never>
        let itemTapped: AnyPublisher<String, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILLibraryStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILLibraryNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILLibraryNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILLibraryStateModel>, Never>
    private var catalog: ILLibraryEntity
    private var selectedCategory: ILLibraryCategory = .all
    private var currentState: ILLibraryStateModel
    private let useCase: ILLibraryUseCase
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILLibraryUseCase) {
        self.useCase = useCase
        let initialCatalog = useCase.getCatalog()
        self.catalog = initialCatalog
        let initialState = ILLibraryViewModel.makeStateModel(
            catalog: initialCatalog,
            items: useCase.items(in: initialCatalog, category: .all),
            selectedCategory: .all
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

        input.searchTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openSearch) }
            .store(in: &cancellables)

        input.featuredTapped
            .sink { [weak self] _ in self?.handleFeaturedTapped() }
            .store(in: &cancellables)

        input.itemTapped
            .sink { [weak self] id in self?.handleItemTapped(id: id) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        catalog = useCase.getCatalog()
        selectedCategory = .all
        publishState()
    }

    private func handleCategorySelected(_ category: ILLibraryCategory) {
        guard category != selectedCategory else { return }
        selectedCategory = category
        publishState()
    }

    private func handleFeaturedTapped() {
        guard let featured = catalog.featured else { return }
        navigationEventSubject.send(.openItem(id: featured.id, kind: .talk))
    }

    private func handleItemTapped(id: String) {
        guard let item = catalog.items.first(where: { $0.id == id }) else { return }
        navigationEventSubject.send(.openItem(id: item.id, kind: item.kind))
    }

    private func publishState() {
        currentState = ILLibraryViewModel.makeStateModel(
            catalog: catalog,
            items: useCase.items(in: catalog, category: selectedCategory),
            selectedCategory: selectedCategory
        )
        stateSubject.send(.success(currentState))
    }

    // MARK: - Entity -> StateModel mapping
    /// Việc riêng của presentation (nhãn chip, tiêu đề mục theo nhóm, format thời lượng) nên nằm
    /// ở đây, không phải trong Mapper dùng chung (xem `references/data_layer_boundaries.md`).
    private static func makeStateModel(
        catalog: ILLibraryEntity,
        items: [ILLibraryItemEntity],
        selectedCategory: ILLibraryCategory
    ) -> ILLibraryStateModel {
        var model = ILLibraryStateModel()
        model.chips = ILLibraryCategory.allCases.map {
            ILLibraryChipModel(category: $0, title: chipTitle(for: $0), isSelected: $0 == selectedCategory)
        }
        model.featured = catalog.featured.map {
            ILLibraryFeaturedModel(
                id: $0.id,
                eyebrow: $0.eyebrow,
                title: $0.title,
                ctaTitle: String(format: "library.featured.cta".localized, formatDuration(minutes: $0.durationMinutes))
            )
        }
        model.sectionTitle = sectionTitle(for: selectedCategory)
        model.rows = items.map {
            ILLibraryRowModel(
                id: $0.id,
                title: $0.title,
                subtitle: $0.subtitle,
                durationText: formatDuration(minutes: $0.durationMinutes),
                tone: $0.tone
            )
        }
        model.emptyTitle = "library.empty.title".localized
        model.emptyMessage = "library.empty.message".localized
        return model
    }

    /// < 60 phút → "38 phút"; >= 60 phút → "2g 10p" (bỏ phần phút nếu tròn giờ).
    static func formatDuration(minutes: Int) -> String {
        guard minutes >= 60 else {
            return String(format: "library.duration.minutes".localized, minutes)
        }
        let hours = minutes / 60
        let remainder = minutes % 60
        if remainder == 0 {
            return String(format: "library.duration.hours".localized, hours)
        }
        return String(format: "library.duration.hoursMinutes".localized, hours, remainder)
    }

    private static func chipTitle(for category: ILLibraryCategory) -> String {
        switch category {
        case .all: return "library.chip.all".localized
        case .sutra: return "library.chip.sutra".localized
        case .meditation: return "library.chip.meditation".localized
        case .talk: return "library.chip.talk".localized
        }
    }

    private static func sectionTitle(for category: ILLibraryCategory) -> String {
        switch category {
        case .all: return "library.section.all".localized
        case .sutra: return "library.section.sutra".localized
        case .meditation: return "library.section.meditation".localized
        case .talk: return "library.section.talk".localized
        }
    }
}
