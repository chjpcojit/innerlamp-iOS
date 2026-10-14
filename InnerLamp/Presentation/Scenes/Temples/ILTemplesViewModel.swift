//
//  ILTemplesViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILTemplesNavEvent: Equatable {
    case back
    /// Chạm 1 chùa — mở Trang chùa.
    case openTemple(id: String)
}

protocol ILTemplesViewModelProtocol: ViewModelType {
    var navigationEventPublisher: AnyPublisher<ILTemplesNavEvent, Never> { get }
}

/// Màn "Tất cả chùa" (`temples` trong design handoff): nạp toàn bộ danh bạ, lọc theo từ khóa +
/// miền ở client. Dùng lại `ILTempleFinderRegionFilter` / chip của màn Chọn chùa tu tập.
final class ILTemplesViewModel: ILTemplesViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        let queryChanged: AnyPublisher<String, Never>
        let regionSelected: AnyPublisher<ILTempleFinderRegionFilter, Never>
        /// Chạm thẻ chùa — mang theo `id`.
        let templeTapped: AnyPublisher<String, Never>
        let retryTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILTemplesStateModel>, Never>
        /// Chip miền — có từ khung hình đầu, độc lập với việc nạp danh bạ.
        let filters: AnyPublisher<[ILTempleFinderRegionChipModel], Never>
        /// Tiêu đề / nội dung khi không có chùa nào khớp bộ lọc.
        let emptyText: AnyPublisher<(title: String, message: String)?, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILTemplesNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILTemplesNavEvent, Never>()
    private let stateSubject = CurrentValueSubject<ViewState<ILTemplesStateModel>, Never>(.idle)
    private lazy var filtersSubject = CurrentValueSubject<[ILTempleFinderRegionChipModel], Never>(
        Self.makeChips(selected: region)
    )
    private let emptySubject = CurrentValueSubject<(title: String, message: String)?, Never>(nil)
    private let useCase: ILTemplesUseCase
    private var cancellables = Set<AnyCancellable>()
    private var loadTask: Task<Void, Never>?

    private var temples: [ILTempleSummaryEntity] = []
    private var hasLoaded = false
    private var query = ""
    private var region: ILTempleFinderRegionFilter = .all

    // MARK: - Initializer
    init(useCase: ILTemplesUseCase) {
        self.useCase = useCase
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.load() }
            .store(in: &cancellables)

        input.retryTapped
            .sink { [weak self] _ in self?.load() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.back) }
            .store(in: &cancellables)

        input.queryChanged
            .sink { [weak self] text in
                self?.query = text
                self?.publishIfLoaded()
            }
            .store(in: &cancellables)

        input.regionSelected
            .sink { [weak self] filter in
                guard let self, filter != region else { return }
                region = filter
                filtersSubject.send(Self.makeChips(selected: filter))
                publishIfLoaded()
            }
            .store(in: &cancellables)

        input.templeTapped
            .sink { [weak self] id in self?.navigationEventSubject.send(.openTemple(id: id)) }
            .store(in: &cancellables)

        return Output(
            state: stateSubject.eraseToAnyPublisher(),
            filters: filtersSubject.eraseToAnyPublisher(),
            emptyText: emptySubject.eraseToAnyPublisher()
        )
    }

    // MARK: - Loading
    private func load() {
        loadTask?.cancel()
        stateSubject.send(.loading)
        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let loaded = try await useCase.loadTemples()
                guard !Task.isCancelled else { return }
                temples = loaded
                hasLoaded = true
                publish()
            } catch {
                guard !Task.isCancelled else { return }
                stateSubject.send(.failure(error))
            }
        }
    }

    private func publishIfLoaded() {
        guard hasLoaded else { return }
        publish()
    }

    private func publish() {
        stateSubject.send(.success(makeState()))
    }

    // MARK: - Entity -> StateModel
    private func makeState() -> ILTemplesStateModel {
        var state = ILTemplesStateModel()
        state.subtitle = String(format: "temples.header.subtitleFormat".localized, temples.count)

        let needle = Self.normalize(query.trimmingCharacters(in: .whitespacesAndNewlines))
        let matches = temples.filter { temple in
            region.matches(temple.region)
                && (needle.isEmpty || Self.normalize(temple.name + " " + temple.location.address).contains(needle))
        }
        state.rows = matches.map {
            ILTemplesRowModel(
                id: $0.id,
                name: $0.name,
                place: ILTempleCatalogLabels.shortPlace(from: $0.location.address),
                note: ILHomeViewModel.templeNote(rank: $0.heritageRank, establishedYear: $0.establishedYear),
                thumbnailURL: $0.thumbnailURL
            )
        }
        emptySubject.send(matches.isEmpty
            ? ("temples.empty.title".localized, "temples.empty.message".localized)
            : nil)
        return state
    }

    private static func makeChips(selected: ILTempleFinderRegionFilter) -> [ILTempleFinderRegionChipModel] {
        ILTempleFinderRegionFilter.allCases.map {
            ILTempleFinderRegionChipModel(filter: $0, label: $0.title, isSelected: $0 == selected)
        }
    }

    /// Chữ thường, bỏ dấu, `đ` → `d` — tìm "tu quang" ra "Từ Quang".
    static func normalize(_ text: String) -> String {
        ILTempleFinderViewModel.normalize(text)
    }
}
