//
//  ILMeditationSetupViewModel.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import Foundation
import Combine

enum ILMeditationSetupNavEvent: Equatable {
    /// Bắt đầu phiên thiền với thời lượng đang chọn — `guided = true` khi có hướng dẫn (nút
    /// "Bắt đầu"), `false` khi ngồi im lặng không hướng dẫn ("Ngồi im lặng, không hướng dẫn").
    case startSession(durationMinutes: Int, guided: Bool)
    /// Nút ✕ trên header — đóng màn Chuẩn bị thiền.
    case close
}

protocol ILMeditationSetupViewModelProtocol: ViewModelType {
    /// Độc lập với `transform(input:)` — `ILMeditationSetupCoordinator` subscribe trực tiếp trong
    /// `start()`, trước khi `ViewController`/`Input` tồn tại.
    var navigationEventPublisher: AnyPublisher<ILMeditationSetupNavEvent, Never> { get }
}

final class ILMeditationSetupViewModel: ILMeditationSetupViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        /// Chọn một mức thời lượng (giá trị phút).
        let durationSelected: AnyPublisher<Int, Never>
        let startTapped: AnyPublisher<Void, Never>
        let silentTapped: AnyPublisher<Void, Never>
        let closeTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILMeditationSetupStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILMeditationSetupNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILMeditationSetupNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILMeditationSetupStateModel>, Never>
    private var currentEntity: ILMeditationSetupEntity
    private var currentState: ILMeditationSetupStateModel
    private let useCase: ILMeditationSetupUseCase
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILMeditationSetupUseCase) {
        self.useCase = useCase
        let initialEntity = useCase.getInitialState()
        self.currentEntity = initialEntity
        let initialState = ILMeditationSetupViewModel.makeStateModel(from: initialEntity)
        self.currentState = initialState
        self.stateSubject = CurrentValueSubject(.success(initialState))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.durationSelected
            .sink { [weak self] minutes in self?.handleDurationSelected(minutes) }
            .store(in: &cancellables)

        input.startTapped
            .sink { [weak self] _ in self?.handleStartTapped() }
            .store(in: &cancellables)

        input.silentTapped
            .sink { [weak self] _ in self?.handleSilentTapped() }
            .store(in: &cancellables)

        input.closeTapped
            .sink { [weak self] _ in self?.handleCloseTapped() }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        applyEntity(useCase.getInitialState())
    }

    private func handleDurationSelected(_ minutes: Int) {
        applyEntity(useCase.selectDuration(minutes, in: currentEntity))
    }

    private func handleStartTapped() {
        navigationEventSubject.send(.startSession(durationMinutes: currentEntity.durationMinutes, guided: true))
    }

    private func handleSilentTapped() {
        navigationEventSubject.send(.startSession(durationMinutes: currentEntity.durationMinutes, guided: false))
    }

    private func handleCloseTapped() {
        navigationEventSubject.send(.close)
    }

    // MARK: - Entity <-> StateModel mapping
    /// `Entity -> StateModel` là việc riêng của presentation (chuỗi `.localized`, "Bắt đầu · N phút")
    /// nên nằm ở đây, không phải trong một Mapper dùng chung (xem `references/data_layer_boundaries.md`).
    private func applyEntity(_ entity: ILMeditationSetupEntity) {
        currentEntity = entity
        currentState = ILMeditationSetupViewModel.makeStateModel(from: entity)
        stateSubject.send(.success(currentState))
    }

    private static func makeStateModel(from entity: ILMeditationSetupEntity) -> ILMeditationSetupStateModel {
        var state = ILMeditationSetupStateModel()
        state.headerTitle = "meditationSetup.header.title".localized
        state.title = "meditationSetup.title".localized
        state.subtitle = "meditationSetup.subtitle".localized

        state.durationSectionTitle = "meditationSetup.duration.section".localized
        state.durationOptions = entity.durationOptions
        state.selectedDurationIndex = entity.durationOptions.firstIndex(of: entity.durationMinutes) ?? 0
        state.durationHint = "meditationSetup.duration.hint".localized

        state.bellSectionTitle = "meditationSetup.bell.section".localized
        state.openingBellTitle = "meditationSetup.bell.opening.title".localized
        state.openingBellValue = "meditationSetup.bell.opening.value".localized
        state.intervalBellTitle = "meditationSetup.bell.interval.title".localized
        state.intervalBellValue = "meditationSetup.bell.interval.value".localized
        state.backgroundSoundTitle = "meditationSetup.bell.sound.title".localized
        state.backgroundSoundValue = "meditationSetup.bell.sound.value".localized

        state.tipText = "meditationSetup.tip".localized
        state.startButtonTitle = String(format: "meditationSetup.cta.startFormat".localized, entity.durationMinutes)
        state.silentButtonTitle = "meditationSetup.cta.silent".localized
        return state
    }
}
