//
//  ILDeitiesViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILDeitiesNavEvent: Equatable {
    /// Nút ‹ ở header — đóng màn danh sách "Chư Phật & Bồ Tát".
    case back
    /// Chạm 1 thẻ trong lưới — mở màn chi tiết Phật / Bồ Tát (`Deity`) theo `id`.
    case openDeity(id: String)
}

protocol ILDeitiesViewModelProtocol: ViewModelType {
    /// Độc lập với `transform(input:)` — `ILDeitiesCoordinator` subscribe trực tiếp trong
    /// `start()`, trước khi `ViewController`/`Input` tồn tại.
    var navigationEventPublisher: AnyPublisher<ILDeitiesNavEvent, Never> { get }
}

final class ILDeitiesViewModel: ILDeitiesViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        /// Chip lọc được chạm (`nil` = "Tất cả").
        let filterSelected: AnyPublisher<ILDeityKind?, Never>
        /// Chạm 1 thẻ trong lưới — mang theo `id` vị.
        let deityTapped: AnyPublisher<String, Never>
        /// Nút "Thử lại" trên trạng thái lỗi — nạp lại catalog từ server.
        let retryTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILDeitiesStateModel>, Never>
        /// The 3 filter chips (Tất cả / Chư Phật / Bồ Tát) — available from the first frame and in
        /// every screen state (loading, empty, error), independent of the catalog load.
        let filters: AnyPublisher<[ILDeitiesFilterModel], Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILDeitiesNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILDeitiesNavEvent, Never>()
    private let stateSubject = CurrentValueSubject<ViewState<ILDeitiesStateModel>, Never>(.idle)
    private lazy var filtersSubject = CurrentValueSubject<[ILDeitiesFilterModel], Never>(
        Self.makeFilterModels(selected: selectedKind)
    )
    private var currentEntity: ILDeitiesEntity = .empty
    /// Bộ lọc đang chọn — UI state, giữ ở ViewModel (không đưa lên Entity).
    private var selectedKind: ILDeityKind?
    /// `false` until the catalog has loaded — filter taps before that only move the selection.
    private var hasLoaded = false
    private var loadTask: Task<Void, Never>?
    private let useCase: ILDeitiesUseCase
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILDeitiesUseCase) {
        self.useCase = useCase
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.loadDeities() }
            .store(in: &cancellables)

        input.retryTapped
            .sink { [weak self] _ in self?.loadDeities() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.back) }
            .store(in: &cancellables)

        input.filterSelected
            .sink { [weak self] kind in self?.handleFilterSelected(kind) }
            .store(in: &cancellables)

        input.deityTapped
            .sink { [weak self] id in self?.navigationEventSubject.send(.openDeity(id: id)) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher(), filters: filtersSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    /// Nạp catalog từ server (`/v1/deities?page=N`, fallback `/v1/deities/top`): `.loading` →
    /// `.success` (rỗng → "Đang cập nhật") hoặc `.failure` (có nút "Thử lại").
    private func loadDeities() {
        loadTask?.cancel()
        stateSubject.send(.loading)
        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let entity = try await self.useCase.loadDeities()
                guard !Task.isCancelled else { return }
                self.currentEntity = entity
                self.hasLoaded = true
                self.publishState()
            } catch {
                guard !Task.isCancelled else { return }
                self.stateSubject.send(.failure(error))
            }
        }
    }

    private func handleFilterSelected(_ kind: ILDeityKind?) {
        // Chạm lại chip đang chọn: giữ nguyên (khớp hành vi màn Thư viện).
        guard kind != selectedKind else { return }
        selectedKind = kind
        filtersSubject.send(Self.makeFilterModels(selected: kind))
        guard hasLoaded else { return }
        publishState()
    }

    private func publishState() {
        stateSubject.send(.success(Self.makeStateModel(from: currentEntity, selectedKind: selectedKind, useCase: useCase)))
    }

    // MARK: - Entity -> StateModel
    /// `Entity -> StateModel` là việc riêng của presentation (nhãn chip `.localized`, placeholder
    /// "Đang cập nhật", lọc theo loại) nên nằm ở đây, không phải trong một Mapper dùng chung
    /// (xem `references/data_layer_boundaries.md`).
    private static func makeStateModel(
        from entity: ILDeitiesEntity,
        selectedKind: ILDeityKind?,
        useCase: ILDeitiesUseCase
    ) -> ILDeitiesStateModel {
        var state = ILDeitiesStateModel()
        state.subtitle = entity.deities.isEmpty
            ? "deities.updating".localized
            : String(format: "deities.header.subtitleFormat".localized, entity.deities.count)
        state.filters = makeFilterModels(selected: selectedKind)
        state.items = useCase.deities(in: entity, kind: selectedKind).map { deity in
            ILDeitiesItemModel(
                id: deity.id,
                kind: deity.kind,
                kindLabel: kindLabel(for: deity.kind),
                name: deity.nameVi,
                role: deity.coreVirtue,
                // `ILDeitySummaryEntity` has no memorial days (not in the list API) — placeholder.
                memorialText: "deities.memorialUpdating".localized,
                thumbnailURL: deity.thumbnailURL.isEmpty ? deity.imageURL : deity.thumbnailURL
            )
        }
        if state.items.isEmpty {
            state.emptyTitle = "deities.updating".localized
            state.emptyMessage = "deities.empty.message".localized
        }
        return state
    }

    /// 3 chip theo thứ tự hiển thị: "Tất cả" (nil) → "Chư Phật" → "Bồ Tát".
    private static func makeFilterModels(selected: ILDeityKind?) -> [ILDeitiesFilterModel] {
        [
            ILDeitiesFilterModel(
                id: "all",
                label: "deities.filter.all".localized,
                kind: nil,
                isSelected: selected == nil
            ),
            ILDeitiesFilterModel(
                id: "buddha",
                label: "deities.filter.buddha".localized,
                kind: .buddha,
                isSelected: selected == .buddha
            ),
            ILDeitiesFilterModel(
                id: "bodhisattva",
                label: "deities.filter.bodhisattva".localized,
                kind: .bodhisattva,
                isSelected: selected == .bodhisattva
            )
        ]
    }

    static func kindLabel(for kind: ILDeityKind) -> String {
        switch kind {
        case .buddha: return "deity.kind.buddha".localized
        case .bodhisattva: return "deity.kind.bodhisattva".localized
        case .deva: return "deity.kind.deva".localized
        }
    }
}
