//
//  ILLibraryViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

/// 4 điểm truy cập nhanh của lưới đầu màn — mỗi ô mở 1 màn danh sách/hub riêng (khác `openItem`,
/// vốn mở thẳng 1 nội dung). Khớp `libTiles` trong design handoff (`isLib`).
enum ILLibraryQuickAccessKind: Equatable {
    case sutras
    case meditation
    case talk
    case buddhas
}

enum ILLibraryNavEvent: Equatable {
    case openSearch
    case openItem(id: String, kind: ILLibraryContentKind)
    case openQuickAccess(ILLibraryQuickAccessKind)
    case openDeity(id: String)
    /// Link "Xem tất cả" ở khối "Chư Phật & Bồ Tát" — mở màn danh sách đầy đủ.
    case openDeities
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
        let quickAccessTapped: AnyPublisher<ILLibraryQuickAccessKind, Never>
        let searchTapped: AnyPublisher<Void, Never>
        let featuredTapped: AnyPublisher<Void, Never>
        let deityTapped: AnyPublisher<String, Never>
        let deitiesViewAllTapped: AnyPublisher<Void, Never>
        let sutrasViewAllTapped: AnyPublisher<Void, Never>
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
    private var currentState: ILLibraryStateModel
    private var deitiesLoaded = false
    private let useCase: ILLibraryUseCase
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILLibraryUseCase) {
        self.useCase = useCase
        let initialCatalog = useCase.getCatalog()
        self.catalog = initialCatalog
        let initialState = ILLibraryViewModel.makeStateModel(catalog: initialCatalog, deitiesLoaded: false)
        self.currentState = initialState
        self.stateSubject = CurrentValueSubject(.success(initialState))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.quickAccessTapped
            .sink { [weak self] kind in self?.navigationEventSubject.send(.openQuickAccess(kind)) }
            .store(in: &cancellables)

        input.searchTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openSearch) }
            .store(in: &cancellables)

        input.featuredTapped
            .sink { [weak self] _ in self?.handleFeaturedTapped() }
            .store(in: &cancellables)

        input.deityTapped
            .sink { [weak self] id in self?.navigationEventSubject.send(.openDeity(id: id)) }
            .store(in: &cancellables)

        input.deitiesViewAllTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openDeities) }
            .store(in: &cancellables)

        input.sutrasViewAllTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openQuickAccess(.sutras)) }
            .store(in: &cancellables)

        input.itemTapped
            .sink { [weak self] id in self?.handleItemTapped(id: id) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        let deities = catalog.deities
        catalog = useCase.getCatalog()
        catalog.deities = deities
        publishState()
        loadTopDeities()
    }

    /// Server-only carousel (`/v1/deities/top`, cached offline): an error or empty list shows
    /// "Đang cập nhật" instead of mock data — same behaviour as Home.
    private func loadTopDeities() {
        Task { [weak self] in
            guard let self else { return }
            do {
                self.catalog.deities = try await self.useCase.loadTopDeities()
            } catch {
                #if DEBUG
                print("[Library] loadTopDeities failed: \(error)")
                #endif
                self.catalog.deities = []
            }
            self.deitiesLoaded = true
            self.publishState()
        }
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
        currentState = ILLibraryViewModel.makeStateModel(catalog: catalog, deitiesLoaded: deitiesLoaded)
        stateSubject.send(.success(currentState))
    }

    // MARK: - Entity -> StateModel mapping
    /// Việc riêng của presentation (nhãn ô truy cập nhanh, format ngày vía, format thời lượng) nên
    /// nằm ở đây, không phải trong Mapper dùng chung (xem `references/data_layer_boundaries.md`).
    private static func makeStateModel(catalog: ILLibraryEntity, deitiesLoaded: Bool) -> ILLibraryStateModel {
        var model = ILLibraryStateModel()
        model.quickAccess = quickAccessTiles()
        model.featured = catalog.featured.map {
            ILLibraryFeaturedModel(
                id: $0.id,
                eyebrow: $0.eyebrow,
                title: $0.title,
                ctaTitle: String(format: "library.featured.cta".localized, formatDuration(minutes: $0.durationMinutes))
            )
        }
        model.deitiesTitle = "library.deity.title".localized
        model.deitiesViewAllText = "library.deity.viewAll".localized
        model.deities = catalog.deities.map { deity in
            let memorialText = deity.memorialDay.map {
                String(format: "home.deity.memorialFormat".localized, $0.lunarDay, $0.lunarMonth)
            } ?? "home.deity.memorialUpdating".localized
            return ILHomeDeityModel(
                id: deity.id,
                kind: deity.kind,
                kindLabel: ILDeitiesViewModel.kindLabel(for: deity.kind),
                name: deity.name,
                memorialText: memorialText,
                thumbnailURL: deity.thumbnailURL
            )
        }
        model.deitiesLoading = !deitiesLoaded && catalog.deities.isEmpty
        model.deitiesEmptyText = deitiesLoaded && catalog.deities.isEmpty ? "home.deity.updating".localized : ""
        model.sutrasSectionTitle = "library.section.sutra".localized
        model.sutrasViewAllText = "library.section.sutra.viewAll".localized
        model.rows = catalog.items.map {
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

    /// 4 ô cố định (không phụ thuộc catalog) — nhãn/glyph khớp `libTiles` trong design handoff.
    private static func quickAccessTiles() -> [ILLibraryQuickAccessModel] {
        [
            ILLibraryQuickAccessModel(
                id: "sutras", kind: .sutras,
                label: "library.tile.sutra.label".localized,
                subtitle: "library.tile.sutra.subtitle".localized,
                glyph: "經", tone: .gold
            ),
            ILLibraryQuickAccessModel(
                id: "meditation", kind: .meditation,
                label: "library.tile.meditation.label".localized,
                subtitle: "library.tile.meditation.subtitle".localized,
                glyph: "禪", tone: .green
            ),
            ILLibraryQuickAccessModel(
                id: "talk", kind: .talk,
                label: "library.tile.talk.label".localized,
                subtitle: "library.tile.talk.subtitle".localized,
                glyph: "法", tone: .rose
            ),
            ILLibraryQuickAccessModel(
                id: "buddhas", kind: .buddhas,
                label: "library.tile.buddha.label".localized,
                subtitle: "library.tile.buddha.subtitle".localized,
                glyph: "佛", tone: .ink
            )
        ]
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
}
