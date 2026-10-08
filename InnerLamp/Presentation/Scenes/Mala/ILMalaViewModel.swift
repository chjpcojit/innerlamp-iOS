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
        /// Chip mục tiêu (21 / 54 / 108 biến) được chọn.
        let goalSelected: AnyPublisher<Int, Never>
        /// "Niệm tiếp vòng mới" trên popup đủ vòng.
        let continueTapped: AnyPublisher<Void, Never>
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
    private let soundPlayer: ILPracticeSoundPlaying
    /// Câu niệm do màn gọi truyền vào (vd. danh hiệu / thần chú từ màn chi tiết Phật & Bồ Tát);
    /// `nil` dùng câu mặc định "Nam mô A Di Đà Phật".
    private let mantraText: String?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILMalaUseCase, soundPlayer: ILPracticeSoundPlaying, mantraText: String? = nil) {
        self.useCase = useCase
        self.soundPlayer = soundPlayer
        self.mantraText = mantraText
        let initialEntity = useCase.getInitialState()
        self.currentEntity = initialEntity
        let initialState = ILMalaViewModel.makeStateModel(from: initialEntity, milestone: nil, mantraText: mantraText)
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

        input.goalSelected
            .sink { [weak self] goal in self?.handleGoalSelected(goal) }
            .store(in: &cancellables)

        input.continueTapped
            .sink { [weak self] _ in self?.handleContinueTapped() }
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
        let milestone = useCase.milestone(for: advanced)
        // Every bead plays a soft click; completing a round (reaching the goal) also rings the bell.
        soundPlayer.playBead()
        if milestone == .roundComplete {
            soundPlayer.playBell()
        }
        applyEntity(advanced, milestone: milestone)
    }

    private func handleResetTapped() {
        applyEntity(useCase.resetBeads(currentEntity), milestone: nil)
    }

    private func handleGoalSelected(_ goal: Int) {
        applyEntity(useCase.selectGoal(goal, for: currentEntity), milestone: nil)
    }

    private func handleContinueTapped() {
        applyEntity(useCase.startNextRound(currentEntity), milestone: nil)
    }

    private func handleDoneTapped() {
        navigationEventSubject.send(.goBack)
    }

    private func handleBackTapped() {
        navigationEventSubject.send(.goBack)
    }

    // MARK: - Entity <-> StateModel mapping
    /// `Entity -> StateModel` là việc riêng của presentation (nhãn tĩnh, "Vòng N · biến x / y") nên
    /// nằm ở đây, không phải trong một Mapper dùng chung (xem `references/data_layer_boundaries.md`).
    private func applyEntity(_ entity: ILMalaEntity, milestone: ILMalaMilestone?) {
        currentEntity = entity
        currentState = ILMalaViewModel.makeStateModel(from: entity, milestone: milestone, mantraText: mantraText)
        stateSubject.send(.success(currentState))
    }

    private static func makeStateModel(
        from entity: ILMalaEntity,
        milestone: ILMalaMilestone?,
        mantraText: String?
    ) -> ILMalaStateModel {
        var state = ILMalaStateModel()
        state.headerTitle = "mala.header.title".localized
        state.headerSubtitle = String(format: "mala.header.progressFormat".localized, entity.round, entity.count, entity.goal)
        state.doneTitle = "mala.action.done".localized

        state.count = entity.count
        state.goal = entity.goal
        state.goalOptions = ILMalaEntity.goalOptions.map {
            ILMalaStateModel.GoalOption(
                value: $0,
                title: String(format: "mala.goal.optionFormat".localized, $0),
                isSelected: $0 == entity.goal
            )
        }

        state.mantraText = mantraText ?? "mala.mantra".localized
        state.strandAccessibilityLabel = "mala.strand.accessibility".localized
        state.resetTitle = "mala.action.reset".localized

        state.isRoundComplete = entity.isRoundComplete
        state.completionTitle = String(format: "mala.complete.titleFormat".localized, entity.goal)
        state.completionMessage = String(format: "mala.complete.messageFormat".localized, entity.round)
        state.continueTitle = "mala.complete.continue".localized

        state.milestone = milestone
        return state
    }
}
