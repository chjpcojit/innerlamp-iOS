//
//  ILMalaViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILMalaNavEvent: Equatable {
    /// Nút back trên header hoặc nút "Xong" — đóng màn Tràng hạt, quay lại màn trước.
    case goBack
}

protocol ILMalaViewModelProtocol: ViewModelType {
    /// Độc lập với `transform(input:)` — `ILMalaCoordinator` subscribe trực tiếp trong `start()`,
    /// trước khi `ViewController`/`Input` tồn tại.
    var navigationEventPublisher: AnyPublisher<ILMalaNavEvent, Never> { get }
}

final class ILMalaViewModel: ILMalaViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        /// Một hạt vừa trượt xong về giữa vạch (chạm hoặc kéo).
        let beadAdvanced: AnyPublisher<Void, Never>
        let resetTapped: AnyPublisher<Void, Never>
        let doneTapped: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILMalaStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILMalaNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILMalaNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILMalaStateModel>, Never>
    private var currentEntity: ILMalaEntity
    private var currentState: ILMalaStateModel
    private let useCase: ILMalaUseCase
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILMalaUseCase) {
        self.useCase = useCase
        let initialEntity = useCase.getInitialState()
        self.currentEntity = initialEntity
        let initialState = ILMalaViewModel.makeStateModel(from: initialEntity, milestone: nil)
        self.currentState = initialState
        self.stateSubject = CurrentValueSubject(.success(initialState))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.beadAdvanced
            .sink { [weak self] _ in self?.handleBeadAdvanced() }
            .store(in: &cancellables)

        input.resetTapped
            .sink { [weak self] _ in self?.handleResetTapped() }
            .store(in: &cancellables)

        input.doneTapped
            .sink { [weak self] _ in self?.handleDoneTapped() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.handleBackTapped() }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        applyEntity(currentEntity, milestone: nil)
    }

    private func handleBeadAdvanced() {
        let advanced = useCase.advanceBead(currentEntity)
        applyEntity(advanced, milestone: useCase.milestone(for: advanced))
    }

    private func handleResetTapped() {
        applyEntity(useCase.resetBeads(currentEntity), milestone: nil)
    }

    private func handleDoneTapped() {
        navigationEventSubject.send(.goBack)
    }

    private func handleBackTapped() {
        navigationEventSubject.send(.goBack)
    }

    // MARK: - Entity <-> StateModel mapping
    /// `Entity -> StateModel` là việc riêng của presentation (nhãn tĩnh, "N tràng", "/ 108") nên
    /// nằm ở đây, không phải trong một Mapper dùng chung (xem `references/data_layer_boundaries.md`).
    private func applyEntity(_ entity: ILMalaEntity, milestone: ILMalaMilestone?) {
        currentEntity = entity
        currentState = ILMalaViewModel.makeStateModel(from: entity, milestone: milestone)
        stateSubject.send(.success(currentState))
    }

    private static func makeStateModel(from entity: ILMalaEntity, milestone: ILMalaMilestone?) -> ILMalaStateModel {
        var state = ILMalaStateModel()
        state.headerTitle = "mala.header.title".localized
        state.headerSubtitle = String(format: "mala.header.roundsFormat".localized, entity.completedRounds)

        state.count = entity.count
        state.goal = entity.goal
        state.goalText = String(format: "mala.count.goalFormat".localized, entity.goal)

        state.mantraText = "mala.mantra".localized
        state.hintText = "mala.hint".localized
        state.strandAccessibilityLabel = "mala.strand.accessibility".localized
        state.resetTitle = "mala.action.reset".localized
        state.doneTitle = "mala.action.done".localized
        state.footnoteText = "mala.footnote".localized

        state.milestone = milestone
        return state
    }
}
