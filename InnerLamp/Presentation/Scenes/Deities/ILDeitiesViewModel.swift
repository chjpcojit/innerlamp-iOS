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
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILDeitiesStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILDeitiesNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILDeitiesNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILDeitiesStateModel>, Never>
    private var currentEntity: ILDeitiesEntity
    private var currentState: ILDeitiesStateModel
    /// Bộ lọc đang chọn — UI state, giữ ở ViewModel (không đưa lên Entity).
    private var selectedKind: ILDeityKind?
    private let useCase: ILDeitiesUseCase
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILDeitiesUseCase) {
        self.useCase = useCase
        let initialEntity = useCase.getInitialState()
        self.currentEntity = initialEntity
        let initialState = Self.makeStateModel(
            from: initialEntity,
            selectedKind: nil,
            useCase: useCase
        )
        self.currentState = initialState
        self.stateSubject = CurrentValueSubject(.success(initialState))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
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

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        applyEntity(useCase.getInitialState())
    }

    private func handleFilterSelected(_ kind: ILDeityKind?) {
        // Chạm lại chip đang chọn: giữ nguyên (khớp hành vi màn Thư viện).
        guard kind != selectedKind else { return }
        selectedKind = kind
        publishState()
    }

    private func applyEntity(_ entity: ILDeitiesEntity) {
        currentEntity = entity
        publishState()
    }

    private func publishState() {
        currentState = Self.makeStateModel(from: currentEntity, selectedKind: selectedKind, useCase: useCase)
        stateSubject.send(.success(currentState))
    }

    // MARK: - Entity -> StateModel
    /// `Entity -> StateModel` là việc riêng của presentation (nhãn chip `.localized`, format ngày
    /// vía, lọc theo loại) nên nằm ở đây, không phải trong một Mapper dùng chung
    /// (xem `references/data_layer_boundaries.md`).
    private static func makeStateModel(
        from entity: ILDeitiesEntity,
        selectedKind: ILDeityKind?,
        useCase: ILDeitiesUseCase
    ) -> ILDeitiesStateModel {
        var state = ILDeitiesStateModel()
        state.subtitle = String(format: "deities.header.subtitleFormat".localized, entity.deities.count)
        state.filters = makeFilterModels(selected: selectedKind)
        state.items = useCase.deities(in: entity, kind: selectedKind).map { deity in
            ILDeitiesItemModel(
                id: deity.id,
                kind: deity.kind,
                kindLabel: kindLabel(for: deity.kind),
                name: deity.nameVi,
                role: deity.coreVirtue,
                memorialText: deity.primaryMemorialDay.map {
                    String(format: "deities.memorialFormat".localized, $0.lunarDay, $0.lunarMonth)
                } ?? ""
            )
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
        kind == .buddha ? "deity.kind.buddha".localized : "deity.kind.bodhisattva".localized
    }
}
