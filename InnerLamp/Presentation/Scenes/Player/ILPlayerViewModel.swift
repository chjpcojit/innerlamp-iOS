//
//  ILPlayerViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILPlayerNavEvent: Equatable {
    /// Back chip on the header — close the player and return to the previous screen.
    case back
    /// "Mục lục" pill on the header — open the chapter list (detail screen, not built yet).
    case openTableOfContents
}

protocol ILPlayerViewModelProtocol: ViewModelType {
    /// Independent of `transform(input:)` — `ILPlayerCoordinator` subscribes directly in `start()`,
    /// before the ViewController exists (see `references/coordinator_navigation_rules.md`).
    var navigationEventPublisher: AnyPublisher<ILPlayerNavEvent, Never> { get }
}

final class ILPlayerViewModel: ILPlayerViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        let tableOfContentsTapped: AnyPublisher<Void, Never>
        let playPauseTapped: AnyPublisher<Void, Never>
        let rewindTapped: AnyPublisher<Void, Never>
        let forwardTapped: AnyPublisher<Void, Never>
        let speedSelected: AnyPublisher<Int, Never>
        let sleepSelected: AnyPublisher<Int, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILPlayerStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILPlayerNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILPlayerNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILPlayerStateModel>, Never>
    private var currentEntity: ILPlayerEntity
    private var currentState: ILPlayerStateModel
    private let useCase: ILPlayerUseCase
    private let initialSutraID: String
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILPlayerUseCase, sutraID: String) {
        self.useCase = useCase
        self.initialSutraID = sutraID
        let initialEntity = useCase.getInitialState(sutraID: sutraID)
        self.currentEntity = initialEntity
        self.currentState = Self.makeStateModel(from: initialEntity, useCase: useCase)
        self.stateSubject = CurrentValueSubject(.success(currentState))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.back) }
            .store(in: &cancellables)

        input.tableOfContentsTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openTableOfContents) }
            .store(in: &cancellables)

        input.playPauseTapped
            .sink { [weak self] _ in self?.handlePlayPauseTapped() }
            .store(in: &cancellables)

        input.rewindTapped
            .sink { [weak self] _ in self?.handleRewindTapped() }
            .store(in: &cancellables)

        input.forwardTapped
            .sink { [weak self] _ in self?.handleForwardTapped() }
            .store(in: &cancellables)

        input.speedSelected
            .sink { [weak self] index in self?.handleSpeedSelected(index) }
            .store(in: &cancellables)

        input.sleepSelected
            .sink { [weak self] index in self?.handleSleepSelected(index) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        applyEntity(useCase.getInitialState(sutraID: initialSutraID))
    }

    private func handlePlayPauseTapped() {
        applyEntity(useCase.togglePlayPause(currentEntity))
    }

    private func handleRewindTapped() {
        applyEntity(useCase.rewind(currentEntity))
    }

    private func handleForwardTapped() {
        applyEntity(useCase.forward(currentEntity))
    }

    private func handleSpeedSelected(_ index: Int) {
        applyEntity(useCase.selectSpeed(currentEntity, index: index))
    }

    private func handleSleepSelected(_ index: Int) {
        applyEntity(useCase.selectSleepTimer(currentEntity, index: index))
    }

    // MARK: - Entity -> StateModel
    /// `Entity -> StateModel` is presentation-specific (formatted times, the sleep note, the option
    /// labels) so it lives here, not in a shared Mapper — see `references/data_layer_boundaries.md`.
    private func applyEntity(_ entity: ILPlayerEntity) {
        currentEntity = entity
        currentState = Self.makeStateModel(from: entity, useCase: useCase)
        stateSubject.send(.success(currentState))
    }

    private static func makeStateModel(
        from entity: ILPlayerEntity,
        useCase: ILPlayerUseCase
    ) -> ILPlayerStateModel {
        var state = ILPlayerStateModel()

        state.headerTitle = "player.header.title".localized
        state.tableOfContentsActionTitle = "player.header.tableOfContents".localized

        let track = useCase.currentTrack(in: entity)
        state.trackTitle = track?.title ?? ""
        state.trackSubtitle = track?.subtitle ?? ""

        let total = track?.totalDurationSeconds ?? 0
        let elapsed = max(0, entity.elapsedSeconds)
        state.elapsedText = String(format: "player.time.elapsed".localized, elapsed / 60, elapsed % 60)
        if total > 0 {
            let remaining = max(0, total - elapsed)
            state.remainingText = String(
                format: "player.time.remaining".localized,
                remaining / 60,
                remaining % 60
            )
            state.playbackProgress = min(1, max(0, Double(elapsed) / Double(total)))
        }
        state.isPlaying = entity.isPlaying

        state.rewindTitle = "player.seek.rewind".localized
        state.forwardTitle = "player.seek.forward".localized

        state.speedSectionTitle = "player.speed.title".localized
        state.speedOptions = (0..<ILPlayerUseCaseImpl.speedOptionCount).map {
            "player.speed.\($0)".localized
        }
        state.selectedSpeedIndex = entity.playbackSpeedIndex

        state.sleepSectionTitle = "player.sleep.title".localized
        state.sleepOptions = [
            "player.sleep.off".localized,
            "player.sleep.fifteen".localized,
            "player.sleep.thirty".localized,
            "player.sleep.endOfTrack".localized
        ]
        state.selectedSleepIndex = entity.sleepTimerIndex
        state.sleepNote = sleepNote(for: entity.sleepTimerIndex)

        return state
    }

    /// Maps a sleep-timer index to its explanatory footnote (matches the `sleepNote` logic in the
    /// design handoff `player` screen).
    private static func sleepNote(for index: Int) -> String {
        switch index {
        case 0:
            return "player.sleep.note.off".localized
        case 3:
            return "player.sleep.note.endOfTrack".localized
        case 1:
            return String(format: "player.sleep.note.minutesFormat".localized, 15)
        case 2:
            return String(format: "player.sleep.note.minutesFormat".localized, 30)
        default:
            return "player.sleep.note.off".localized
        }
    }
}
