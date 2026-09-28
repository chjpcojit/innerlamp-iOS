//
//  ILMeditationSessionViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILMeditationSessionNavEvent: Equatable {
    /// Header back / leading ghost button — leave the session and return to "Chuẩn bị thiền".
    case goBack
    /// The sit ended (countdown reached zero, or "Kết thúc sớm" / stop) and was recorded.
    case finished(elapsedSeconds: Int)
}

protocol ILMeditationSessionViewModelProtocol: ViewModelType {
    /// Independent of `transform(input:)` — `ILMeditationSessionCoordinator` subscribes to this
    /// directly in `start()`, before any ViewController/Input exists.
    var navigationEventPublisher: AnyPublisher<ILMeditationSessionNavEvent, Never> { get }
}

final class ILMeditationSessionViewModel: ILMeditationSessionViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let playPauseTapped: AnyPublisher<Void, Never>
        /// Header back button and the leading ghost button.
        let backTapped: AnyPublisher<Void, Never>
        /// Trailing stop button and the "Kết thúc sớm" footnote.
        let endTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILMeditationSessionStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILMeditationSessionNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILMeditationSessionNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILMeditationSessionStateModel>, Never>
    private var currentEntity: ILMeditationSessionEntity
    private var currentState: ILMeditationSessionStateModel
    private var isFinishing = false
    private var hasStarted = false
    private let useCase: ILMeditationSessionUseCase
    private let soundPlayer: ILPracticeSoundPlaying
    private let ticker: AnyPublisher<Void, Never>
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    /// - Parameter ticker: Fires once per second of wall-clock time. Injected so tests can drive
    ///   the countdown deterministically; defaults to a main-run-loop `Timer`.
    init(
        durationMinutes: Int,
        isGuided: Bool,
        useCase: ILMeditationSessionUseCase,
        soundPlayer: ILPracticeSoundPlaying,
        ticker: AnyPublisher<Void, Never> = ILMeditationSessionViewModel.makeSecondTicker()
    ) {
        self.useCase = useCase
        self.soundPlayer = soundPlayer
        self.ticker = ticker
        let initialEntity = useCase.makeSession(durationMinutes: durationMinutes, isGuided: isGuided)
        self.currentEntity = initialEntity
        let initialState = ILMeditationSessionViewModel.makeStateModel(from: initialEntity)
        self.currentState = initialState
        self.stateSubject = CurrentValueSubject(.success(initialState))
    }

    static func makeSecondTicker() -> AnyPublisher<Void, Never> {
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.playPauseTapped
            .sink { [weak self] _ in self?.handlePlayPauseTapped() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.handleBackTapped() }
            .store(in: &cancellables)

        input.endTapped
            .sink { [weak self] _ in self?.handleEndTapped() }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        applyEntity(currentEntity)
        guard !hasStarted else { return }
        hasStarted = true
        // Opening bell, then the countdown starts.
        soundPlayer.playBell()
        ticker
            .sink { [weak self] _ in self?.handleTick() }
            .store(in: &cancellables)
    }

    private func handleTick() {
        guard !isFinishing, currentEntity.isRunning else { return }
        applyEntity(useCase.tick(currentEntity))
        if currentEntity.isCompleted {
            finishSession()
        }
    }

    private func handlePlayPauseTapped() {
        guard !isFinishing else { return }
        applyEntity(useCase.togglePause(currentEntity))
    }

    private func handleBackTapped() {
        navigationEventSubject.send(.goBack)
    }

    private func handleEndTapped() {
        finishSession()
    }

    /// Shared by the natural end and "Kết thúc sớm": stop, ring the closing bell, record the sit,
    /// then hand over to the coordinator.
    private func finishSession() {
        guard !isFinishing else { return }
        isFinishing = true
        applyEntity(useCase.endSession(currentEntity))
        soundPlayer.playBell()

        let finishedSession = currentEntity
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.useCase.recordSession(finishedSession)
                self.navigationEventSubject.send(.finished(elapsedSeconds: finishedSession.elapsedSeconds))
            } catch {
                self.isFinishing = false
                self.stateSubject.send(.failure(error))
            }
        }
    }

    // MARK: - Entity <-> StateModel mapping
    /// `Entity -> StateModel` is presentation-specific (`.localized` copy, "mm:ss"), so it lives
    /// here rather than in a shared Mapper (see `references/data_layer_boundaries.md`).
    private func applyEntity(_ entity: ILMeditationSessionEntity) {
        currentEntity = entity
        currentState = ILMeditationSessionViewModel.makeStateModel(from: entity)
        stateSubject.send(.success(currentState))
    }

    private static func makeStateModel(from entity: ILMeditationSessionEntity) -> ILMeditationSessionStateModel {
        let durationMinutes = entity.durationSeconds / 60
        var state = ILMeditationSessionStateModel()

        state.headerTitle = "meditationSession.header.title".localized
        state.headerSubtitle = entity.isGuided
            ? String(format: "meditationSession.header.durationFormat".localized, durationMinutes)
            : String(format: "meditationSession.header.silentFormat".localized, durationMinutes)

        state.timerText = formatCountdown(entity.remainingSeconds)
        state.timerCaption = String(format: "meditationSession.timer.remainingFormat".localized, durationMinutes)

        state.breathPhase = entity.breathPhase
        state.secondsLeftInBreathPhase = entity.secondsLeftInBreathPhase
        if entity.isGuided {
            switch entity.breathPhase {
            case .inhale:
                state.cueText = "meditationSession.cue.inhale".localized
                state.cueTranslation = "meditationSession.cue.inhale.translation".localized
            case .exhale:
                state.cueText = "meditationSession.cue.exhale".localized
                state.cueTranslation = "meditationSession.cue.exhale.translation".localized
            }
        }

        state.isPlaying = entity.isRunning
        state.endEarlyTitle = "meditationSession.endEarly".localized

        state.exitAccessibilityLabel = "meditationSession.accessibility.exit".localized
        state.pauseAccessibilityLabel = "meditationSession.accessibility.pause".localized
        state.resumeAccessibilityLabel = "meditationSession.accessibility.resume".localized
        state.endAccessibilityLabel = "meditationSession.accessibility.end".localized
        return state
    }

    /// "mm:ss" — minutes are not wrapped into hours (the longest preset is 45 minutes).
    private static func formatCountdown(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
