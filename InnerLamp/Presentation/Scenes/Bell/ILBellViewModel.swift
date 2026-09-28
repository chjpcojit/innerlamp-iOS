//
//  ILBellViewModel.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import Foundation
import Combine

enum ILBellNavEvent: Equatable {
    /// Back button on the header — close the "Chuông mõ" screen and return to Home.
    case goBack
}

protocol ILBellViewModelProtocol: ViewModelType {
    /// Independent of `transform(input:)` — `ILBellCoordinator` subscribes to this directly in
    /// `start()`, before the `ViewController`/`Input` exists.
    var navigationEventPublisher: AnyPublisher<ILBellNavEvent, Never> { get }
}

final class ILBellViewModel: ILBellViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        /// Index of the tapped preset chip.
        let presetSelected: AnyPublisher<Int, Never>
        /// The selected playback mode.
        let modeSelected: AnyPublisher<ILBellMode, Never>
        /// Index into `ILBellUseCase.everyOptions` of the tapped "ring bell after every" option.
        let everySelected: AnyPublisher<Int, Never>
        /// -1 (slower) or +1 (faster).
        let rateAdjustTapped: AnyPublisher<Int, Never>
        /// Tap on the center pad (strike).
        let padTapped: AnyPublisher<Void, Never>
        /// The round play/pause button.
        let toggleTapped: AnyPublisher<Void, Never>
        /// Left pill — "Đặt lại" in bell mode, "Dồn mõ" otherwise.
        let leftButtonTapped: AnyPublisher<Void, Never>
        /// Right pill — "Thỉnh chuông".
        let ringBellTapped: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILBellStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILBellNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILBellNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILBellStateModel>, Never>
    private var currentEntity: ILBellEntity
    private var currentState: ILBellStateModel
    private let useCase: ILBellUseCase
    private let soundPlayer: ILPracticeSoundPlaying
    private var cancellables = Set<AnyCancellable>()

    // Playback scheduling (steady rhythm + accelerating roll). Each strike routes its sound through
    // `soundPlayer` so taps, the auto rhythm, and the "dồn mõ" roll all produce audio.
    private var tickTimer: Timer?
    private var rollWorkItems: [DispatchWorkItem] = []
    private var delayedBellWorkItem: DispatchWorkItem?

    // MARK: - Initializer
    init(useCase: ILBellUseCase, soundPlayer: ILPracticeSoundPlaying) {
        self.useCase = useCase
        self.soundPlayer = soundPlayer
        let initialEntity = useCase.getInitialState()
        self.currentEntity = initialEntity
        self.currentState = ILBellViewModel.makeStateModel(
            from: initialEntity,
            presets: useCase.presets,
            everyOptions: useCase.everyOptions
        )
        self.stateSubject = CurrentValueSubject(.success(self.currentState))
    }

    deinit {
        stopAutoTick()
        cancelRoll()
        delayedBellWorkItem?.cancel()
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.presetSelected
            .sink { [weak self] index in self?.handlePresetSelected(index) }
            .store(in: &cancellables)

        input.modeSelected
            .sink { [weak self] mode in self?.handleModeSelected(mode) }
            .store(in: &cancellables)

        input.everySelected
            .sink { [weak self] index in self?.handleEverySelected(index) }
            .store(in: &cancellables)

        input.rateAdjustTapped
            .sink { [weak self] delta in self?.handleRateAdjust(delta) }
            .store(in: &cancellables)

        input.padTapped
            .sink { [weak self] _ in self?.handlePadTapped() }
            .store(in: &cancellables)

        input.toggleTapped
            .sink { [weak self] _ in self?.handleToggleTapped() }
            .store(in: &cancellables)

        input.leftButtonTapped
            .sink { [weak self] _ in self?.handleLeftButtonTapped() }
            .store(in: &cancellables)

        input.ringBellTapped
            .sink { [weak self] _ in self?.handleRingBellTapped() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.goBack) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        applyEntity(useCase.getInitialState())
    }

    private func handlePresetSelected(_ index: Int) {
        stopAutoTick()
        cancelRoll()
        applyEntity(useCase.selectPreset(index, on: currentEntity))
    }

    private func handleModeSelected(_ mode: ILBellMode) {
        stopAutoTick()
        cancelRoll()
        applyEntity(useCase.selectMode(mode, on: currentEntity))
    }

    private func handleEverySelected(_ index: Int) {
        let options = useCase.everyOptions
        guard options.indices.contains(index) else { return }
        applyEntity(useCase.selectEvery(options[index], on: currentEntity))
    }

    private func handleRateAdjust(_ delta: Int) {
        applyEntity(useCase.adjustRate(by: delta, on: currentEntity))
        // If the steady rhythm is running, re-time it to the new interval.
        if currentEntity.isRunning { restartAutoTick() }
    }

    private func handlePadTapped() {
        guard !currentEntity.isRolling else { return }
        if currentEntity.mode == .bell {
            strikeBell()
        } else {
            strikeMo()
        }
    }

    private func handleToggleTapped() {
        if currentEntity.isRolling {
            // Stop the roll before switching to the steady rhythm.
            cancelRoll()
            applyEntity(useCase.setRolling(false, on: currentEntity))
        }
        let running = !currentEntity.isRunning
        applyEntity(useCase.setRunning(running, on: currentEntity))
        if running {
            startAutoTick()
        } else {
            stopAutoTick()
        }
    }

    private func handleLeftButtonTapped() {
        if currentEntity.mode == .bell {
            // "Đặt lại" — reset counters and stop playback.
            stopAutoTick()
            cancelRoll()
            applyEntity(useCase.resetCounters(currentEntity))
        } else {
            startRoll()
        }
    }

    private func handleRingBellTapped() {
        strikeBell()
    }

    // MARK: - Strikes
    private func strikeMo() {
        soundPlayer.playMo()
        applyEntity(useCase.strikeMo(currentEntity))
        if useCase.shouldRingBellAfterMo(currentEntity) {
            scheduleDelayedBell(after: 0.18)
        }
    }

    private func strikeBell() {
        soundPlayer.playBell()
        applyEntity(useCase.strikeBell(currentEntity))
    }

    private func scheduleDelayedBell(after delay: TimeInterval) {
        delayedBellWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.strikeBell() }
        delayedBellWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    // MARK: - Steady auto rhythm
    private func startAutoTick() {
        stopAutoTick()
        scheduleNextTick()
    }

    private func restartAutoTick() {
        startAutoTick()
    }

    private func scheduleNextTick() {
        guard currentEntity.isRunning else { return }
        let interval = useCase.intervalSeconds(for: currentEntity)
        tickTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.performTick()
        }
    }

    private func performTick() {
        guard currentEntity.isRunning else { return }
        if currentEntity.mode == .bell {
            strikeBell()
        } else {
            strikeMo()
        }
        scheduleNextTick()
    }

    private func stopAutoTick() {
        tickTimer?.invalidate()
        tickTimer = nil
    }

    // MARK: - Dồn mõ (accelerating roll)
    /// 16 accelerating wooden-fish strikes (gap 440ms × 0.8 each step, min 70ms), then one bell.
    private func startRoll() {
        guard !currentEntity.isRolling else { return }
        stopAutoTick()
        applyEntity(useCase.setRunning(false, on: currentEntity))
        applyEntity(useCase.setRolling(true, on: currentEntity))

        cancelRoll()
        var delay: TimeInterval = 0
        var gap: TimeInterval = 0.44
        for _ in 0..<16 {
            let work = DispatchWorkItem { [weak self] in
                guard let self, self.currentEntity.isRolling else { return }
                self.strikeMo()
            }
            rollWorkItems.append(work)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
            delay += gap
            gap = max(0.07, gap * 0.8)
        }
        let finish = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.strikeBell()
            self.applyEntity(self.useCase.setRolling(false, on: self.currentEntity))
        }
        rollWorkItems.append(finish)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.26, execute: finish)
    }

    private func cancelRoll() {
        rollWorkItems.forEach { $0.cancel() }
        rollWorkItems.removeAll()
    }

    // MARK: - Entity <-> StateModel mapping
    /// `Entity -> StateModel` is a Presentation concern (resolved labels, formatted values) so it
    /// lives here, not in a shared mapper — see `references/data_layer_boundaries.md`.
    private func applyEntity(_ entity: ILBellEntity) {
        currentEntity = entity
        currentState = ILBellViewModel.makeStateModel(
            from: entity,
            presets: useCase.presets,
            everyOptions: useCase.everyOptions
        )
        stateSubject.send(.success(currentState))
    }

    private static func makeStateModel(
        from entity: ILBellEntity,
        presets: [ILBellPreset],
        everyOptions: [Int]
    ) -> ILBellStateModel {
        var state = ILBellStateModel()

        state.headerTitle = "bell.header.title".localized
        state.headerSubtitle = makeHeaderSubtitle(from: entity, presets: presets)

        state.presetLabels = presets.map { $0.titleKey.localized }
        state.selectedPresetIndex = entity.presetIndex

        state.modeLabels = [
            "bell.mode.mo".localized,
            "bell.mode.bell".localized,
            "bell.mode.both".localized,
        ]
        state.selectedMode = entity.mode

        state.everyOptionLabels = everyOptions.map { value in
            value == 0 ? "bell.every.off".localized : "\(value)"
        }
        state.selectedEveryIndex = everyOptions.firstIndex(of: entity.everyCount) ?? 0
        state.showEveryRow = entity.mode == .moAndBell

        state.rateLabel = entity.mode == .bell
            ? "bell.rate.bellLabel".localized
            : "bell.rate.moLabel".localized
        state.rateValue = entity.mode == .bell
            ? String(format: "bell.rate.gapFormat".localized, entity.gapSeconds)
            : String(format: "bell.rate.bpmFormat".localized, entity.bpm)

        state.padTag = entity.mode == .bell
            ? "bell.pad.tag.bell".localized
            : "bell.pad.tag.mo".localized
        state.padNumber = entity.mode == .bell ? entity.bellCount : entity.moCount
        state.padHint = makePadHint(from: entity)

        state.isRunning = entity.isRunning
        state.isRolling = entity.isRolling

        state.moCount = entity.moCount
        state.bellCount = entity.bellCount
        state.moCountText = String(format: "bell.count.moFormat".localized, entity.moCount)
        state.bellCountText = String(format: "bell.count.bellFormat".localized, entity.bellCount)

        state.leftButtonTitle = entity.mode == .bell
            ? "bell.action.reset".localized
            : "bell.action.roll".localized
        state.ringBellTitle = "bell.action.ringBell".localized

        return state
    }

    private static func makeHeaderSubtitle(from entity: ILBellEntity, presets: [ILBellPreset]) -> String {
        let base: String
        if presets.indices.contains(entity.presetIndex) {
            base = presets[entity.presetIndex].titleKey.localized
        } else {
            base = entity.mode == .bell
                ? "bell.mode.bell".localized
                : (entity.mode == .mo ? "bell.mode.mo".localized : "bell.mode.both".localized)
        }
        if entity.isRolling { return base + "bell.status.rolling".localized }
        if entity.isRunning { return base + "bell.status.running".localized }
        return base
    }

    private static func makePadHint(from entity: ILBellEntity) -> String {
        if entity.isRolling { return "bell.pad.hint.rolling".localized }
        if entity.isRunning { return "bell.pad.hint.running".localized }
        return entity.mode == .bell ? "bell.pad.hint.tapBell".localized : "bell.pad.hint.tapMo".localized
    }
}
