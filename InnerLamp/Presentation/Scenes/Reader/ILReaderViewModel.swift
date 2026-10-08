//
//  ILReaderViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILReaderNavEvent: Equatable {
    /// The ‹ button in the header — close the Reader screen.
    case back
}

protocol ILReaderViewModelProtocol: ViewModelType {
    /// Independent of `transform(input:)` — `ILReaderCoordinator` subscribes in `start()`, before
    /// the view controller / `Input` exist.
    var navigationEventPublisher: AnyPublisher<ILReaderNavEvent, Never> { get }
}

final class ILReaderViewModel: ILReaderViewModelProtocol {

    // MARK: - Constants
    /// Real-time interval of one playback tick; fed to `ILReaderUseCase.advance`.
    static let tickInterval: TimeInterval = 0.25
    private static let seekStepInLines = 2
    private static let speedOptions: [Double] = [1.0, 1.2, 1.5]
    /// "Mặc định", "Vàng cát", "Đen OLED" — indexes map to view-side palettes.
    private static let themeKeys = ["reader.theme.default", "reader.theme.sand", "reader.theme.oled"]
    private static let defaultFontSizeIndex = 1
    private static let fontSizeCount = 4

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        /// "Aa" in the header — show/hide the font-size + background panel.
        let settingsTapped: AnyPublisher<Void, Never>
        let autoScrollToggled: AnyPublisher<Void, Never>
        /// Tap on the chant text: closes the settings panel if open, otherwise toggles play/pause.
        let contentTapped: AnyPublisher<Void, Never>
        let playPauseTapped: AnyPublisher<Void, Never>
        let seekBackTapped: AnyPublisher<Void, Never>
        let seekForwardTapped: AnyPublisher<Void, Never>
        let speedSelected: AnyPublisher<Double, Never>
        let fontSizeSelected: AnyPublisher<Int, Never>
        let themeSelected: AnyPublisher<Int, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILReaderStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILReaderNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILReaderNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILReaderStateModel>, Never>
    private var entity: ILReaderEntity
    private var ui = UIPreferences()
    private let useCase: ILReaderUseCase
    private let initialSutraID: String
    private let tickPublisher: AnyPublisher<Void, Never>
    private var cancellables = Set<AnyCancellable>()

    /// UI-only choices that never reach the Domain layer.
    private struct UIPreferences {
        var fontSizeIndex = ILReaderViewModel.defaultFontSizeIndex
        var themeIndex = 0
        var isSettingsVisible = false
        var isAutoScrollEnabled = true
    }

    // MARK: - Initializer
    /// - Parameter tickPublisher: emits once per `tickInterval` while the screen is alive; defaults
    ///   to a main-run-loop timer. Injected in tests so playback can be driven deterministically.
    init(
        useCase: ILReaderUseCase,
        sutraID: String,
        tickPublisher: AnyPublisher<Void, Never> = ILReaderViewModel.makeTimerPublisher()
    ) {
        self.useCase = useCase
        self.initialSutraID = sutraID
        self.tickPublisher = tickPublisher
        let initialEntity = useCase.getInitialState(sutraID: sutraID)
        self.entity = initialEntity
        self.stateSubject = CurrentValueSubject(
            .success(Self.makeStateModel(from: initialEntity, ui: UIPreferences(), useCase: useCase))
        )
    }

    static func makeTimerPublisher() -> AnyPublisher<Void, Never> {
        Timer.publish(every: tickInterval, on: .main, in: .common)
            .autoconnect()
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.back) }
            .store(in: &cancellables)

        input.settingsTapped
            .sink { [weak self] _ in self?.updateUI { $0.isSettingsVisible.toggle() } }
            .store(in: &cancellables)

        input.autoScrollToggled
            .sink { [weak self] _ in self?.updateUI { $0.isAutoScrollEnabled.toggle() } }
            .store(in: &cancellables)

        input.contentTapped
            .sink { [weak self] _ in self?.handleContentTapped() }
            .store(in: &cancellables)

        input.playPauseTapped
            .sink { [weak self] _ in self?.togglePlayPause() }
            .store(in: &cancellables)

        input.seekBackTapped
            .sink { [weak self] _ in self?.seek(by: -Self.seekStepInLines) }
            .store(in: &cancellables)

        input.seekForwardTapped
            .sink { [weak self] _ in self?.seek(by: Self.seekStepInLines) }
            .store(in: &cancellables)

        input.speedSelected
            .sink { [weak self] speed in self?.select(speed: speed) }
            .store(in: &cancellables)

        input.fontSizeSelected
            .sink { [weak self] index in
                guard (0..<Self.fontSizeCount).contains(index) else { return }
                self?.updateUI { $0.fontSizeIndex = index }
            }
            .store(in: &cancellables)

        input.themeSelected
            .sink { [weak self] index in
                guard Self.themeKeys.indices.contains(index) else { return }
                self?.updateUI { $0.themeIndex = index }
            }
            .store(in: &cancellables)

        tickPublisher
            .sink { [weak self] _ in self?.handleTick() }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        entity = useCase.getInitialState(sutraID: initialSutraID)
        publishState()
    }

    private func handleContentTapped() {
        if ui.isSettingsVisible {
            updateUI { $0.isSettingsVisible = false }
        } else {
            togglePlayPause()
        }
    }

    private func togglePlayPause() {
        entity = useCase.togglePlayPause(entity)
        publishState()
    }

    private func handleTick() {
        guard entity.isPlaying else { return }
        entity = useCase.advance(entity, byMilliseconds: Self.tickInterval * 1000)
        publishState()
    }

    private func seek(by lines: Int) {
        entity = useCase.seek(entity, byLines: lines)
        publishState()
    }

    private func select(speed: Double) {
        entity = useCase.setSpeed(entity, to: speed)
        publishState()
    }

    private func updateUI(_ mutate: (inout UIPreferences) -> Void) {
        mutate(&ui)
        publishState()
    }

    private func publishState() {
        stateSubject.send(.success(Self.makeStateModel(from: entity, ui: ui, useCase: useCase)))
    }

    // MARK: - Entity -> StateModel
    /// `Entity -> StateModel` is presentation work (time/speed formatting, status line, cue glyphs,
    /// labels), so it lives here rather than in a shared Mapper.
    private static func makeStateModel(
        from entity: ILReaderEntity,
        ui: UIPreferences,
        useCase: ILReaderUseCase
    ) -> ILReaderStateModel {
        var state = ILReaderStateModel()
        let sutra = useCase.currentSutra(in: entity)
        let hasAudio = sutra?.hasAudio ?? false

        state.title = sutra?.title ?? ""
        state.fontSizeActionTitle = "reader.header.fontSizeAction".localized
        if hasAudio {
            state.statusText = entity.isPlaying
                ? String(format: "reader.status.chantingFormat".localized, sutra?.narrator ?? "")
                : "reader.status.paused".localized
        } else {
            state.statusText = "reader.status.textOnly".localized
        }

        state.autoScrollTitle = "reader.autoScroll.title".localized
        state.keepAwakeNote = "reader.keepAwake.note".localized
        state.hintText = (entity.isPlaying ? "reader.hint.playing" : "reader.hint.paused").localized
        state.isAutoScrollEnabled = ui.isAutoScrollEnabled

        state.isSettingsVisible = ui.isSettingsVisible
        state.fontSizeTitle = "reader.settings.fontSize".localized
        state.fontSizeOptionTitle = "reader.settings.fontSizeOption".localized
        state.backgroundTitle = "reader.settings.background".localized
        state.themeTitles = themeKeys.map { $0.localized }
        state.fontSizeIndex = ui.fontSizeIndex
        state.themeIndex = ui.themeIndex

        var rows: [ILReaderRowState] = []
        var lineIndex = 0
        for section in sutra?.sections ?? [] {
            rows.append(.heading(section.heading))
            for line in section.lines {
                let isCurrent = lineIndex == entity.currentLineIndex
                if isCurrent { state.currentRowIndex = rows.count }
                rows.append(.line(ILReaderLineRowState(
                    text: line.text,
                    gloss: line.gloss,
                    cueGlyph: cueGlyph(for: line.cue),
                    isCurrent: isCurrent
                )))
                lineIndex += 1
            }
        }
        state.rows = rows
        state.legendBellText = "reader.legend.bell".localized
        state.legendKnockText = "reader.legend.knock".localized

        state.hasAudio = hasAudio
        state.positionText = formatTime(seconds: useCase.elapsedSeconds(in: entity))
        state.durationText = formatTime(seconds: sutra?.totalDurationSeconds ?? 0)
        state.progress = useCase.progress(in: entity)
        state.isPlaying = entity.isPlaying
        state.seekBackTitle = "reader.seek.back".localized
        state.seekForwardTitle = "reader.seek.forward".localized
        state.speedLabel = (hasAudio ? "reader.speed.label" : "reader.speed.scrollLabel").localized
        state.speedOptions = speedOptions.map { speed in
            ILReaderSpeedOptionState(
                speed: speed,
                title: String(format: "reader.speed.optionFormat".localized, speed),
                isSelected: speed == entity.playbackSpeed
            )
        }
        return state
    }

    private static func cueGlyph(for cue: ILReaderCue) -> String {
        switch cue {
        case .none: return ""
        case .knock: return "•"
        case .bell: return "◉"
        }
    }

    /// "724" -> "12:04".
    private static func formatTime(seconds: Int) -> String {
        let clamped = max(0, seconds)
        return String(format: "reader.playback.timeFormat".localized, clamped / 60, clamped % 60)
    }
}
